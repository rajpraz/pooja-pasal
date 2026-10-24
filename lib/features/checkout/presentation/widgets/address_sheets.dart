import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/features/addresses/domain/entities/address.dart';
import 'package:pooja_pasal/features/addresses/presentation/providers/address_providers.dart';

/// How the buyer chose to set the delivery address.
sealed class AddressChoice {
  const AddressChoice();
}

class SavedAddressChoice extends AddressChoice {
  final Address address;
  const SavedAddressChoice(this.address);
}

class CurrentLocationChoice extends AddressChoice {
  const CurrentLocationChoice();
}

class ManualAddressChoice extends AddressChoice {
  const ManualAddressChoice();
}

/// Lets the buyer pick a saved address, detect their location, or type
/// one in. Completes with null if dismissed.
Future<AddressChoice?> showAddressPicker(BuildContext context, {required String? uid}) {
  return showModalBottomSheet<AddressChoice>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose delivery address',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (uid != null)
              Consumer(
                builder: (context, ref, _) => ref.watch(addressesProvider(uid)).when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (addresses) => Column(
                        children: [
                          for (final address in addresses)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.location_on_outlined, color: AppColors.accent),
                              title: Text(address.label.isEmpty ? 'Address' : address.label,
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${address.recipientName}\n${address.fullAddress}'),
                              isThreeLine: true,
                              onTap: () => Navigator.pop(sheetContext, SavedAddressChoice(address)),
                            ),
                          if (addresses.isNotEmpty) const Divider(),
                        ],
                      ),
                    ),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.my_location, color: AppColors.accent),
              title: const Text('Use my current location'),
              onTap: () => Navigator.pop(sheetContext, const CurrentLocationChoice()),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.edit_location_alt_outlined, color: AppColors.accent),
              title: const Text('Enter address manually'),
              onTap: () => Navigator.pop(sheetContext, const ManualAddressChoice()),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Contact details typed in at checkout, as one line in the same shape as
/// a saved address (`Name, address, phone`) so the seller gets a recipient
/// and a number to call. Completes with null if dismissed or left empty.
Future<String?> showContactDetailsSheet(
  BuildContext context, {
  required TextEditingController name,
  required TextEditingController phone,
  required TextEditingController address,
}) {
  final formKey = GlobalKey<FormState>();
  String? required(String? value) => (value ?? '').trim().isEmpty ? 'Required' : null;

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.of(sheetContext).viewInsets.bottom),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contact & delivery details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextFormField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number'),
              validator: required,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: address,
              decoration: const InputDecoration(labelText: 'Delivery address'),
              validator: required,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(
                    sheetContext,
                    [name.text.trim(), address.text.trim(), phone.text.trim()].join(', '),
                  );
                },
                child: const Text('Use this address'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
