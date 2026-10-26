import 'package:flutter/material.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/widgets/product_image.dart';
import 'package:pooja_pasal/features/cart/domain/entities/cart_item.dart';
import 'package:pooja_pasal/features/checkout/domain/checkout_totals.dart';
import 'package:pooja_pasal/features/payments/domain/entities/payment_method.dart';

/// The building blocks of the checkout page. All presentational: the page
/// owns the state and passes values and callbacks down.

/// A titled checkout section.
class CheckoutSection extends StatelessWidget {
  final String title;
  final Widget child;

  const CheckoutSection({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Bordered surface every checkout card sits on.
class _CheckoutCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;

  const _CheckoutCard({
    required this.child,
    this.borderColor,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: child,
    );
  }
}

/// Where the order goes: the chosen address, a detecting spinner, or why
/// detection failed (with a retry).
class DeliveryAddressCard extends StatelessWidget {
  final String address;
  final String? label;
  final bool locating;
  final String? error;
  final VoidCallback onChange;
  final VoidCallback onRetry;

  const DeliveryAddressCard({
    super.key,
    required this.address,
    required this.locating,
    required this.onChange,
    required this.onRetry,
    this.label,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return _CheckoutCard(
      borderColor: hasError ? AppColors.error : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  hasError
                      ? Icons.location_off_outlined
                      : Icons.location_on_outlined,
                  color: hasError ? AppColors.error : AppColors.accent),
              const SizedBox(width: 10),
              Expanded(
                child: locating
                    ? const Row(
                        children: [
                          SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          SizedBox(width: 10),
                          Text('Detecting your location...'),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (label != null && label!.isNotEmpty)
                            Text(label!,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accent)),
                          Text(
                            address.isEmpty
                                ? (error ?? 'No address set')
                                : address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: hasError
                                    ? AppColors.error
                                    : AppColors.text),
                          ),
                        ],
                      ),
              ),
              TextButton(onPressed: onChange, child: const Text('Change')),
            ],
          ),
          if (hasError && !locating)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 34),
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry detection'),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerLeft),
              ),
            ),
        ],
      ),
    );
  }
}

/// The delivery option and its fee.
class DeliveryOptionCard extends StatelessWidget {
  final double fee;

  const DeliveryOptionCard({super.key, required this.fee});

  @override
  Widget build(BuildContext context) {
    return _CheckoutCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.local_shipping_outlined, color: AppColors.accent),
          const SizedBox(width: 10),
          const Expanded(child: Text('Standard Delivery (1-2 Days)')),
          Text('Rs.${fee.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Coupon code entry: Apply while none is applied, Remove once one is.
class CouponField extends StatelessWidget {
  final TextEditingController controller;
  final String? appliedCode;
  final bool applying;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  const CouponField({
    super.key,
    required this.controller,
    required this.applying,
    required this.onApply,
    required this.onRemove,
    this.appliedCode,
  });

  @override
  Widget build(BuildContext context) {
    final applied = appliedCode != null;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: !applied && !applying,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => onApply(),
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.local_offer_outlined),
                hintText: 'Enter coupon code'),
          ),
        ),
        const SizedBox(width: 10),
        if (applied)
          TextButton(onPressed: onRemove, child: const Text('Remove'))
        else
          OutlinedButton(
            onPressed: applying ? null : onApply,
            child: applying
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Apply'),
          ),
      ],
    );
  }
}

/// One payment option; greyed out when the server doesn't offer it.
class PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final bool enabled;
  final ValueChanged<PaymentMethod> onSelected;

  const PaymentMethodTile({
    super.key,
    required this.method,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  (IconData, Color) get _look => switch (method) {
        PaymentMethod.khalti => (
            Icons.account_balance_wallet,
            AppColors.khaltiPurple
          ),
        PaymentMethod.esewa => (Icons.payments_outlined, AppColors.success),
        PaymentMethod.cod => (Icons.money, AppColors.muted),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _look;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: selected ? AppColors.accent : AppColors.border,
                width: 1.4),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? () => onSelected(method) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        enabled
                            ? method.label
                            : '${method.label} (Unavailable)',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected ? AppColors.accent : AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtotal, coupon, delivery and total.
class OrderSummaryCard extends StatelessWidget {
  final CheckoutTotals totals;
  final String? couponCode;

  const OrderSummaryCard({super.key, required this.totals, this.couponCode});

  Widget _row(String label, String value, {bool emphasised = false}) {
    final style = emphasised
        ? TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: emphasised
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null),
          Text(value, style: style),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CheckoutCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _row('Subtotal', 'Rs.${totals.subtotal.toStringAsFixed(2)}'),
          if (totals.discount > 0)
            _row(couponCode == null ? 'Discount' : 'Discount ($couponCode)',
                '- Rs.${totals.discount.toStringAsFixed(2)}'),
          _row('Delivery', 'Rs.${totals.deliveryFee.toStringAsFixed(0)}'),
          const Divider(height: 18),
          _row('Total Payable', 'Rs.${totals.total.toStringAsFixed(2)}',
              emphasised: true),
        ],
      ),
    );
  }
}

/// One line of the order being placed.
class CheckoutItemTile extends StatelessWidget {
  final CartItem item;

  const CheckoutItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ProductImage(
            url: item.image,
            name: item.name,
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(8)),
        title: Text(item.name),
        subtitle: Text('Qty: ${item.qty}'),
        trailing: Text('Rs.${item.subtotal.toStringAsFixed(2)}'),
      ),
    );
  }
}
