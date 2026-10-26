import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/core/utils/error_mapper.dart';
import 'package:pooja_pasal/features/auth/domain/entities/app_user.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';

/// Lets a buyer apply to sell (or apply again after a rejection). The
/// account stays a buyer until an admin approves the application.
Future<void> showSellerApplicationDialog(
    BuildContext context, WidgetRef ref, AppUser user) async {
  final shopName = TextEditingController(text: user.shopName ?? '');
  final phone = TextEditingController(text: user.phone);
  final reason = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var submitting = false;

  String? required(String? value) =>
      (value ?? '').trim().isEmpty ? 'Required' : null;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: const Text('Become a seller'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                    'Tell us about your shop. An admin reviews every application.'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: shopName,
                  decoration: const InputDecoration(labelText: 'Shop name'),
                  validator: required,
                ),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  validator: required,
                ),
                TextFormField(
                  controller: reason,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'What will you sell? (optional)'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: submitting ? null : () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: submitting
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    setState(() => submitting = true);
                    try {
                      await ref.read(authRepositoryProvider).applyToSell(
                            shopName: shopName.text.trim(),
                            phone: phone.text.trim(),
                            reason: reason.text.trim(),
                          );
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text(
                              "Application sent. We'll notify you once it's reviewed.")));
                    } catch (e) {
                      setState(() => submitting = false);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(friendlyErrorMessage(e))));
                    }
                  },
            child: Text(submitting ? 'Sending…' : 'Apply'),
          ),
        ],
      ),
    ),
  );
  shopName.dispose();
  phone.dispose();
  reason.dispose();
}
