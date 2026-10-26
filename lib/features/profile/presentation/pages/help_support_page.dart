import 'package:flutter/material.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/constants/support_contact.dart';
import 'package:pooja_pasal/core/widgets/feedback.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  static const List<Map<String, String>> faqs = [
    {
      'q': 'How do I track my order?',
      'a':
          'Go to Profile > My Orders to see the live status and timeline of your order.',
    },
    {
      'q': 'What payment methods are supported?',
      'a': 'We support Khalti, eSewa, and Cash on Delivery.',
    },
    {
      'q': 'Can I return a product?',
      'a':
          'Yes, most items can be returned within 3 days of delivery if unused and in original packaging.',
    },
    {
      'q': 'How do I become a seller?',
      'a':
          'Log out and choose "Seller" on the login screen, then create a seller account.',
    },
  ];

  /// Opens the dialer / mail app; says so when the device has none.
  Future<void> _open(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri).catchError((_) => false);
    if (!opened && context.mounted) {
      showMessage(context, 'No app available to open ${uri.path}.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Frequently Asked Questions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...faqs.map((faq) => Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ExpansionTile(
                    title: Text(faq['q']!,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(faq['a']!, style: TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 20),
          const Text('Contact Us',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.phone_outlined, color: AppColors.accent),
                  title: const Text('Call us'),
                  subtitle: const Text(SupportContact.phoneLabel),
                  onTap: () => _open(
                      context, Uri(scheme: 'tel', path: SupportContact.phone)),
                ),
                Divider(height: 1, color: AppColors.border),
                ListTile(
                  leading: Icon(Icons.email_outlined, color: AppColors.accent),
                  title: const Text('Email us'),
                  subtitle: const Text(SupportContact.email),
                  onTap: () => _open(
                    context,
                    Uri(
                      scheme: 'mailto',
                      path: SupportContact.email,
                      query: 'subject=Pooja Pasal support',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
