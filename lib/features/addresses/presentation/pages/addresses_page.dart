import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/utils/error_mapper.dart';
import 'package:pooja_pasal/features/addresses/domain/entities/address.dart';
import 'package:pooja_pasal/features/addresses/presentation/providers/address_providers.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/shared/widgets/empty_view.dart';
import 'package:pooja_pasal/shared/widgets/loading_view.dart';

class AddressesPage extends ConsumerWidget {
  const AddressesPage({super.key});

  void _openForm(BuildContext context, WidgetRef ref, String uid,
      {Address? existing}) {
    final labelController =
        TextEditingController(text: existing?.label ?? 'Home');
    final nameController =
        TextEditingController(text: existing?.recipientName ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final addressController =
        TextEditingController(text: existing?.fullAddress ?? '');
    bool isDefault = existing?.isDefault ?? false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existing == null ? 'Add new address' : 'Edit address',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: ['Home', 'Office', 'Other'].map((option) {
                    return ChoiceChip(
                      label: Text(option),
                      selected: labelController.text == option,
                      onSelected: (_) =>
                          setSheetState(() => labelController.text = option),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration:
                      const InputDecoration(labelText: 'Recipient name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Full address'),
                ),
                const SizedBox(height: 6),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Set as default address'),
                  value: isDefault,
                  onChanged: (value) =>
                      setSheetState(() => isDefault = value ?? false),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final phone = phoneController.text.trim();
                      final fullAddress = addressController.text.trim();
                      if (name.isEmpty ||
                          phone.isEmpty ||
                          fullAddress.isEmpty) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                                content: Text('Please fill in all fields.')));
                        return;
                      }
                      if (!RegExp(r'^[0-9+ -]{7,15}$').hasMatch(phone)) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Please enter a valid phone number.')));
                        return;
                      }
                      final address = Address(
                        id: existing?.id ?? '',
                        label: labelController.text.trim().isEmpty
                            ? 'Home'
                            : labelController.text.trim(),
                        recipientName: name,
                        phone: phone,
                        fullAddress: fullAddress,
                        isDefault: isDefault,
                      );
                      try {
                        if (existing == null) {
                          await ref
                              .read(addressControllerProvider.notifier)
                              .add(uid, address);
                        } else {
                          await ref
                              .read(addressControllerProvider.notifier)
                              .updateAddress(uid, address);
                        }
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      } catch (e) {
                        if (!sheetContext.mounted) return;
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                            SnackBar(content: Text(friendlyErrorMessage(e))));
                      }
                    },
                    child: Text(
                        existing == null ? 'Save Address' : 'Save Changes'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, String uid, String addressId) async {
    try {
      await ref.read(addressControllerProvider.notifier).delete(uid, addressId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Address removed')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  Future<void> _setDefault(
      BuildContext context, WidgetRef ref, String uid, String addressId) async {
    try {
      await ref
          .read(addressControllerProvider.notifier)
          .setDefault(uid, addressId);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
    }
  }

  IconData _iconFor(String label) {
    switch (label) {
      case 'Office':
        return Icons.business_outlined;
      case 'Home':
        return Icons.home_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Addresses')),
        body: EmptyView(
          icon: Icons.location_on_outlined,
          title: 'Sign in to manage addresses',
          subtitle:
              'Saved addresses sync across devices once you\'re signed in.',
          action: ElevatedButton(
            onPressed: () => context.go('${RouteNames.login}?role=buyer'),
            child: const Text('Sign In'),
          ),
        ),
      );
    }

    final addressesAsync = ref.watch(addressesProvider(uid));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Addresses')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, ref, uid),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: addressesAsync.when(
        loading: () => const LoadingView(),
        error: (err, st) =>
            Center(child: Text('Could not load addresses: $err')),
        data: (addresses) {
          if (addresses.isEmpty) {
            return const EmptyView(
              icon: Icons.location_on_outlined,
              title: 'No saved addresses yet',
              subtitle: 'Tap + to add a delivery address.',
            );
          }
          return ListView.builder(
            // Bottom room for the "+" button over the last row.
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: address.isDefault
                          ? AppColors.accent
                          : AppColors.border,
                      width: address.isDefault ? 1.4 : 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_iconFor(address.label), color: AppColors.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(address.label,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  if (address.isDefault) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: AppColors.accent,
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: const Text('DEFAULT',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(address.recipientName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              Text(address.phone,
                                  style: TextStyle(color: AppColors.muted)),
                              Text(address.fullAddress,
                                  style: TextStyle(color: AppColors.muted)),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openForm(context, ref, uid, existing: address);
                            } else if (value == 'delete') {
                              _delete(context, ref, uid, address.id);
                            } else if (value == 'default') {
                              _setDefault(context, ref, uid, address.id);
                            }
                          },
                          itemBuilder: (context) => [
                            if (!address.isDefault)
                              const PopupMenuItem(
                                  value: 'default',
                                  child: Text('Set as default')),
                            const PopupMenuItem(
                                value: 'edit', child: Text('Edit')),
                            const PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
