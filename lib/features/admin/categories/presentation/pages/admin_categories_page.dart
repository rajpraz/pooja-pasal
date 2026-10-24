import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/network/upload_service.dart';
import 'package:pooja_pasal/core/utils/error_mapper.dart';
import 'package:pooja_pasal/features/categories/domain/entities/category.dart';
import 'package:pooja_pasal/features/categories/presentation/providers/category_providers.dart';
import 'package:pooja_pasal/shared/widgets/empty_view.dart';
import 'package:pooja_pasal/shared/widgets/loading_view.dart';

/// Admin category management — reuses the existing `CategoryRepository`
/// (extended with admin CRUD methods, no duplicate category model). The
/// API only accepts these writes from admins.
class AdminCategoriesPage extends ConsumerWidget {
  const AdminCategoriesPage({super.key});

  Future<void> _toggleActive(BuildContext context, WidgetRef ref, Category category) async {
    try {
      await ref
          .read(categoryControllerProvider.notifier)
          .setActive(category.id, !category.isActive);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(category.isActive
              ? '${category.name} deactivated.'
              : '${category.name} activated.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  void _openForm(BuildContext context, WidgetRef ref, {Category? existing}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategoryFormSheet(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref),
        child: const Icon(Icons.add),
      ),
      body: categoriesAsync.when(
        loading: () => const LoadingView(),
        error: (err, st) => Center(child: Text('Could not load categories: $err')),
        data: (categories) {
          if (categories.isEmpty) {
            return const EmptyView(
              icon: Icons.category_outlined,
              title: 'No categories yet',
              subtitle: 'Tap + to create the first one.',
            );
          }
          return ListView.builder(
            // Bottom room for the "+" button over the last row.
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Opacity(
                  opacity: category.isActive ? 1 : 0.6,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: category.imageUrl.isEmpty
                            ? Container(
                                color: AppColors.card,
                                alignment: Alignment.center,
                                child: Icon(Icons.category_outlined, color: AppColors.primary),
                              )
                            : Image.network(category.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.card,
                                    alignment: Alignment.center,
                                    child:
                                        Icon(Icons.category_outlined, color: AppColors.primary))),
                      ),
                    ),
                    title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(category.isActive
                        ? 'Active • sort ${category.sortOrder}'
                        : 'Inactive • sort ${category.sortOrder}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: AppColors.primary),
                          tooltip: 'Edit',
                          onPressed: () => _openForm(context, ref, existing: category),
                        ),
                        IconButton(
                          icon: Icon(
                              category.isActive
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: category.isActive ? AppColors.error : AppColors.success),
                          tooltip: category.isActive ? 'Deactivate' : 'Activate',
                          onPressed: () => _toggleActive(context, ref, category),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryFormSheet extends ConsumerStatefulWidget {
  final Category? existing;
  const _CategoryFormSheet({this.existing});

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  final _nameController = TextEditingController();
  final _sortOrderController = TextEditingController(text: '0');
  bool _isActive = true;
  String _existingImageUrl = '';
  File? _pickedImage;
  bool _isSaving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _sortOrderController.text = '${existing.sortOrder}';
      _isActive = existing.isActive;
      _existingImageUrl = existing.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _pickedImage = File(picked.path));
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Category name is required.')));
      return;
    }
    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;

    setState(() => _isSaving = true);
    try {
      var imageUrl = _existingImageUrl;
      if (_pickedImage != null) {
        imageUrl = await ref
            .read(uploadServiceProvider)
            .uploadImage(_pickedImage!, folder: UploadFolders.categoryImages);
      }

      if (_isEditing) {
        await ref.read(categoryControllerProvider.notifier).editCategory(widget.existing!.id, {
          'name': name,
          'imageUrl': imageUrl,
          'sortOrder': sortOrder,
          'isActive': _isActive,
        });
      } else {
        await ref.read(categoryControllerProvider.notifier).create(Category(
              id: '',
              name: name,
              imageUrl: imageUrl,
              sortOrder: sortOrder,
              isActive: _isActive,
            ));
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEditing ? 'Edit Category' : 'New Category',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Center(
              child: InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _pickedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_pickedImage!, fit: BoxFit.cover))
                      : _existingImageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(_existingImageUrl, fit: BoxFit.cover))
                          : Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Category name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sortOrderController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Sort order'),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _isActive,
              onChanged: (value) => setState(() => _isActive = value),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isEditing ? 'Save Changes' : 'Create Category'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
