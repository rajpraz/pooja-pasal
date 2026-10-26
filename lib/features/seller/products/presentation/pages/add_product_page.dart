import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/network/upload_service.dart';
import 'package:pooja_pasal/core/utils/error_mapper.dart';
import 'package:pooja_pasal/core/widgets/feedback.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/products/domain/entities/product.dart';
import 'package:pooja_pasal/features/products/presentation/providers/product_providers.dart';

/// Reached either as `/seller/products/new` (no ID — [productId] is null)
/// or `/seller/products/:productId/edit`. When editing, the existing
/// product is fetched by ID via `productProvider` rather than being passed
/// through the route/constructor as a whole object.
class AddProductPage extends ConsumerWidget {
  final String? productId;

  const AddProductPage({super.key, this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (productId == null) {
      return const _AddProductForm(existing: null);
    }
    final productAsync = ref.watch(productProvider(productId!));
    return productAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Edit Product')),
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      ),
      error: (err, st) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Edit Product')),
        body: Center(child: Text('Could not load product: $err')),
      ),
      data: (product) {
        if (product == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text('Edit Product')),
            body: const Center(child: Text('Product not found')),
          );
        }
        return _AddProductForm(existing: product);
      },
    );
  }
}

class _AddProductForm extends ConsumerStatefulWidget {
  final Product? existing;

  const _AddProductForm({required this.existing});

  @override
  ConsumerState<_AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends ConsumerState<_AddProductForm> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'Pooja Kits';
  String _festivalTag = '';
  bool _isSaving = false;

  final List<File> _newImages = [];
  List<String> _existingImageUrls = [];

  static const List<String> _categories = [
    'Pooja Kits',
    'Flowers',
    'Incense',
    'Brass Items',
    'Idols',
    'Prasad',
    'Diyas',
  ];

  static const List<String> _festivals = [
    'Dashain',
    'Tihar',
    'Shivaratri',
    'Teej',
  ];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _priceController.text = existing.price.toString();
      _stockController.text = existing.stock.toString();
      _descriptionController.text = existing.description;
      _category = existing.category;
      _festivalTag = existing.festivalTag;
      _existingImageUrls = List.of(existing.images);
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) return;
    setState(() {
      _newImages.addAll(picked.map((x) => File(x.path)));
    });
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  void _removeExistingImage(int index) {
    setState(() => _existingImageUrls.removeAt(index));
  }

  Future<void> _saveProduct() async {
    final name = _nameController.text.trim();
    final price = _priceController.text.trim();
    final stock = _stockController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty || price.isEmpty || stock.isEmpty) {
      showMessage(context, 'Please fill in name, price and stock');
      return;
    }
    final parsedPrice = double.tryParse(price);
    if (parsedPrice == null) {
      showMessage(context, 'Price must be a number');
      return;
    }
    if (parsedPrice < 0) {
      showMessage(context, 'Price cannot be negative');
      return;
    }
    final parsedStock = int.tryParse(stock);
    if (parsedStock == null) {
      showMessage(context, 'Stock must be a whole number');
      return;
    }
    if (parsedStock < 0) {
      showMessage(context, 'Stock cannot be negative');
      return;
    }
    if (_existingImageUrls.isEmpty && _newImages.isEmpty) {
      showMessage(context, 'Please add at least one product image');
      return;
    }

    final authRepository = ref.read(authRepositoryProvider);
    final sellerId = authRepository.currentUser?.uid;
    if (sellerId == null) {
      showMessage(context, 'You must be signed in as a seller');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final uploadedUrls = await ref
          .read(uploadServiceProvider)
          .uploadImages(_newImages, folder: UploadFolders.productImages);
      final images = [..._existingImageUrls, ...uploadedUrls];
      final productRepository = ref.read(productRepositoryProvider);

      if (_isEditing) {
        await productRepository.updateProduct(widget.existing!.id, {
          'name': name,
          'price': parsedPrice,
          'stock': parsedStock,
          'description':
              description.isEmpty ? 'No description provided.' : description,
          'category': _category,
          'festivalTag': _festivalTag,
          'images': images,
        });
      } else {
        await productRepository.addProduct(Product(
          id: '',
          name: name,
          description:
              description.isEmpty ? 'No description provided.' : description,
          price: parsedPrice,
          category: _category,
          festivalTag: _festivalTag,
          images: images,
          stock: parsedStock,
          sellerId: sellerId,
          isActive: true,
          createdAt: DateTime.now(),
        ));
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      showMessage(
          context, 'Could not save product: ${friendlyErrorMessage(e)}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_isEditing ? 'Edit Product' : 'Add Product')),
      body: _isSaving
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                children: [
                  const Text('Product Images',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (int i = 0; i < _existingImageUrls.length; i++)
                        _imageTile(
                          child: Image.network(_existingImageUrls[i],
                              fit: BoxFit.cover),
                          onRemove: () => _removeExistingImage(i),
                        ),
                      for (int i = 0; i < _newImages.length; i++)
                        _imageTile(
                          child: Image.file(_newImages[i], fit: BoxFit.cover),
                          onRemove: () => _removeNewImage(i),
                        ),
                      Semantics(
                        button: true,
                        label: 'Add product image',
                        child: InkWell(
                          onTap: _pickImages,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Icon(Icons.add_a_photo_outlined,
                                color: AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Product Name',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration:
                        const InputDecoration(hintText: 'e.g. Brass Diya Set'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Price (Rs.)',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _priceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration:
                                  const InputDecoration(hintText: 'e.g. 850'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Stock Qty',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(hintText: 'e.g. 20'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Category',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _category = value ?? _category),
                  ),
                  const SizedBox(height: 16),
                  const Text('Festival Tag (optional)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Feature this product on a festival collection page',
                      style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue:
                              _festivalTag.isEmpty ? null : _festivalTag,
                          hint: const Text('None'),
                          items: _festivals
                              .map((f) =>
                                  DropdownMenuItem(value: f, child: Text(f)))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _festivalTag = value ?? ''),
                          isExpanded: true,
                        ),
                      ),
                      if (_festivalTag.isNotEmpty)
                        IconButton(
                          onPressed: () => setState(() => _festivalTag = ''),
                          tooltip: 'Clear festival tag',
                          icon: const Icon(Icons.clear, size: 18),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Description',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        hintText: 'Tell buyers about this product'),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProduct,
                      child: Text(_isEditing ? 'Save Changes' : 'Save Product'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _imageTile({required Widget child, required VoidCallback onRemove}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(width: 84, height: 84, child: child),
        ),
        Positioned(
          top: -10,
          right: -10,
          child: SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              onPressed: onRemove,
              tooltip: 'Remove image',
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                  minimumSize: const Size(32, 32)),
              icon: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
