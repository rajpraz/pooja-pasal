import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/utils/error_mapper.dart';
import 'package:pooja_pasal/core/widgets/feedback.dart';
import 'package:pooja_pasal/features/addresses/domain/entities/address.dart';
import 'package:pooja_pasal/features/addresses/presentation/providers/address_providers.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/cart/domain/entities/cart_item.dart';
import 'package:pooja_pasal/features/cart/domain/pricing_service.dart';
import 'package:pooja_pasal/features/cart/presentation/providers/cart_providers.dart';
import 'package:pooja_pasal/features/checkout/domain/checkout_totals.dart';
import 'package:pooja_pasal/features/checkout/presentation/widgets/address_sheets.dart';
import 'package:pooja_pasal/features/checkout/presentation/widgets/checkout_sections.dart';
import 'package:pooja_pasal/features/coupons/domain/coupon_quote.dart';
import 'package:pooja_pasal/features/coupons/presentation/coupon_providers.dart';
import 'package:pooja_pasal/features/orders/domain/entities/order.dart';
import 'package:pooja_pasal/features/orders/presentation/providers/order_providers.dart';
import 'package:pooja_pasal/features/payments/domain/entities/payment_method.dart';
import 'package:pooja_pasal/features/payments/presentation/khalti_checkout.dart';
import 'package:pooja_pasal/features/payments/presentation/providers/payment_providers.dart';

/// Why the current location couldn't be turned into an address.
class _LocationUnavailable implements Exception {
  final String message;
  const _LocationUnavailable(this.message);
}

/// Places an order: where to deliver, an optional coupon, how to pay. The
/// API re-prices the order from live products, so totals here are only a
/// preview; the order's own total is what is charged.
class CheckoutPage extends ConsumerStatefulWidget {
  /// Cart subtotal shown until the server-priced cart has loaded.
  final double price;

  const CheckoutPage({super.key, required this.price});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  static const _notPaidMessage =
      'Payment was not completed. Your order was created and is waiting for payment — '
      'you can retry from My Orders.';

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _couponController = TextEditingController();

  List<CartItem> _cartItems = [];
  bool _loadingCart = true;
  bool _placingOrder = false;

  String _deliveryAddress = '';

  /// Set when the buyer picked one of their saved addresses.
  Address? _savedAddress;
  bool _locatingAddress = true;
  String? _locationError;

  /// Bumped whenever the address is chosen another way, so a location
  /// lookup still in flight can't overwrite what the buyer picked.
  int _locationRequest = 0;

  CouponQuote? _coupon;
  bool _applyingCoupon = false;
  PaymentMethod? _paymentMethod;

  /// Generated once per checkout attempt (not per network call), so a retry
  /// after a timeout reuses the same key and the API's idempotency check
  /// prevents a duplicate order.
  late final String _idempotencyKey =
      '${DateTime.now().microsecondsSinceEpoch}-${identityHashCode(this)}';

  String? get _uid => ref.read(authRepositoryProvider).currentUser?.uid;

  CheckoutTotals get _totals => CheckoutTotals.compute(
        items: _cartItems,
        fallbackSubtotal: widget.price,
        deliveryFee: PricingService.deliveryFee,
        couponDiscount: _coupon?.discount ?? 0,
      );

  @override
  void initState() {
    super.initState();
    unawaited(_loadCart());
    unawaited(_initAddress());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  // ---- Cart ---------------------------------------------------------------

  Future<void> _loadCart() async {
    final uid = _uid;
    if (uid == null) {
      setState(() => _loadingCart = false);
      return;
    }
    try {
      final items =
          await ref.read(cartRepositoryProvider).streamCart(uid).first;
      if (!mounted) return;
      setState(() {
        _cartItems = items;
        _loadingCart = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCart = false);
      showMessage(context, 'Could not load cart: ${friendlyErrorMessage(e)}');
    }
  }

  // ---- Delivery address ---------------------------------------------------

  /// Prefers the buyer's default saved address over live geolocation, which
  /// is the fallback for buyers with no saved addresses yet.
  Future<void> _initAddress() async {
    final uid = _uid;
    if (uid != null) {
      try {
        // Read the repository directly (as the cart does): awaiting an
        // unwatched provider's future can stall while Riverpod pauses it.
        final addresses = await ref
            .read(addressRepositoryProvider)
            .streamAddresses(uid)
            .first;
        final preferred = addresses.where((a) => a.isDefault).firstOrNull ??
            addresses.firstOrNull;
        if (preferred != null && mounted) {
          _useAddress(preferred.formatted, saved: preferred);
          return;
        }
      } catch (_) {
        // Fall through to live geolocation below.
      }
    }
    if (mounted) unawaited(_detectLocation());
  }

  /// Uses [address] as the delivery address, cancelling any detection.
  void _useAddress(String address, {Address? saved}) {
    setState(() {
      _locationRequest++;
      _deliveryAddress = address;
      _savedAddress = saved;
      _locatingAddress = false;
      _locationError = null;
    });
  }

  Future<void> _detectLocation() async {
    final request = ++_locationRequest;
    setState(() {
      _savedAddress = null;
      _locatingAddress = true;
      _locationError = null;
    });
    try {
      final address = await _addressFromLocation();
      if (!mounted || request != _locationRequest) return;
      setState(() {
        _deliveryAddress = address;
        _locatingAddress = false;
      });
    } catch (e) {
      if (!mounted || request != _locationRequest) return;
      setState(() {
        _locatingAddress = false;
        _locationError = e is _LocationUnavailable
            ? e.message
            : 'Could not detect your location. Enter your address manually.';
      });
    }
  }

  Future<String> _addressFromLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const _LocationUnavailable(
          'Location services are turned off. Enable them or enter your address manually.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const _LocationUnavailable(
          'Location permission denied. Enter your address manually instead.');
    }
    final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)));
    final places = await Geocoding()
        .placemarkFromCoordinates(position.latitude, position.longitude)
        .timeout(const Duration(seconds: 15));
    final place = places.first;
    final parts = [place.subLocality, place.locality, place.country]
        .whereType<String>()
        .where((part) => part.isNotEmpty);
    if (parts.isEmpty)
      throw const _LocationUnavailable('Enter your address manually.');
    return parts.join(', ');
  }

  Future<void> _changeAddress() async {
    final choice = await showAddressPicker(context, uid: _uid);
    if (!mounted || choice == null) return;
    switch (choice) {
      case SavedAddressChoice(:final address):
        _useAddress(address.formatted, saved: address);
      case CurrentLocationChoice():
        unawaited(_detectLocation());
      case ManualAddressChoice():
        final typed = await showContactDetailsSheet(
          context,
          name: _nameController,
          phone: _phoneController,
          address: _addressController,
        );
        if (typed != null && mounted) _useAddress(typed);
    }
  }

  // ---- Coupon -------------------------------------------------------------

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty || _applyingCoupon) return;
    setState(() => _applyingCoupon = true);
    try {
      final quote = await ref
          .read(couponDataSourceProvider)
          .validate(code, _totals.subtotal);
      if (!mounted) return;
      setState(() => _coupon = quote);
      showMessage(context,
          'Coupon ${quote.code} applied: Rs.${quote.discount.toStringAsFixed(0)} off');
    } catch (e) {
      if (!mounted) return;
      setState(() => _coupon = null);
      showMessage(context, friendlyErrorMessage(e));
    } finally {
      if (mounted) setState(() => _applyingCoupon = false);
    }
  }

  void _removeCoupon() {
    _couponController.clear();
    setState(() => _coupon = null);
  }

  // ---- Placing the order --------------------------------------------------

  Future<void> _placeOrder() async {
    final method = _paymentMethod;
    if (_deliveryAddress.isEmpty || method == null) {
      showMessage(
          context, 'Please choose a delivery address and payment method');
      return;
    }
    if (_cartItems.isEmpty) {
      showMessage(context, 'Your cart is empty');
      return;
    }

    setState(() => _placingOrder = true);
    try {
      final CreateOrderResult order;
      try {
        order = await ref.read(orderControllerProvider.notifier).placeOrder(
              items: _cartItems,
              shippingAddress: _deliveryAddress,
              paymentMethod: method.apiValue,
              idempotencyKey: _idempotencyKey,
              couponCode: _coupon?.code,
            );
      } catch (e) {
        if (mounted) showMessage(context, friendlyErrorMessage(e));
        return;
      }
      if (!mounted) return;

      switch (method) {
        case PaymentMethod.cod:
          await _finish(paid: false, totalAmount: order.totalAmount);
        case PaymentMethod.khalti:
          await _payWithKhalti(order);
        case PaymentMethod.esewa:
          await _payWithEsewa(order);
      }
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  /// The order exists; Khalti collects the payment and the API confirms it
  /// with Khalti before the order counts as paid.
  Future<void> _payWithKhalti(CreateOrderResult order) async {
    try {
      final paid = await payWithKhalti(context, ref, order.orderId);
      if (!mounted) return;
      if (paid) {
        await _finish(paid: true);
      } else {
        showMessage(context, _notPaidMessage);
      }
    } catch (e) {
      if (!mounted) return;
      showMessage(
          context,
          'Order placed, but payment could not be confirmed: ${friendlyErrorMessage(e)} '
          'Please check My Orders or contact support.');
    }
  }

  /// The eSewa page only returns true after the API verified the payment.
  Future<void> _payWithEsewa(CreateOrderResult order) async {
    setState(() => _placingOrder = false);
    final paid =
        await context.push<bool>(RouteNames.esewaPaymentPath(order.orderId));
    if (!mounted) return;
    if (paid ?? false) {
      await _finish(paid: true);
    } else {
      showMessage(context, _notPaidMessage);
    }
  }

  /// Clears the cart and confirms. [totalAmount] is the server-computed
  /// total, so a COD buyer is told exactly what they'll pay.
  Future<void> _finish({required bool paid, double? totalAmount}) async {
    final uid = _uid;
    if (uid != null)
      await ref.read(cartControllerProvider.notifier).clearCart(uid);
    if (!mounted) return;
    // Done: drop the busy overlay before confirming (not after the dialog
    // closes, or it would spin behind it).
    setState(() => _placingOrder = false);
    unawaited(showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Order placed successfully'),
        content: Text(paid
            ? 'Your puja essentials are being prepared for delivery.'
            : 'Your order has been placed. Pay Rs.${(totalAmount ?? _totals.total).toStringAsFixed(2)} on delivery.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go(RouteNames.home);
            },
            child: const Text('Continue shopping'),
          ),
        ],
      ),
    ));
  }

  // ---- UI -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final available = ref.watch(availablePaymentMethodsProvider).value ??
        [for (final method in PaymentMethod.values) method.apiValue];
    final totals = _totals;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: _loadingCart
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    CheckoutSection(
                      title: 'Deliver to',
                      child: DeliveryAddressCard(
                        address: _deliveryAddress,
                        label: _savedAddress?.label,
                        locating: _locatingAddress,
                        error: _locationError,
                        onChange: _changeAddress,
                        onRetry: _detectLocation,
                      ),
                    ),
                    const CheckoutSection(
                      title: 'Delivery Time',
                      child:
                          DeliveryOptionCard(fee: PricingService.deliveryFee),
                    ),
                    CheckoutSection(
                      title: 'Coupon',
                      child: CouponField(
                        controller: _couponController,
                        appliedCode: _coupon?.code,
                        applying: _applyingCoupon,
                        onApply: _applyCoupon,
                        onRemove: _removeCoupon,
                      ),
                    ),
                    CheckoutSection(
                      title: 'Payment Method',
                      child: Column(
                        children: [
                          for (final method in PaymentMethod.values)
                            PaymentMethodTile(
                              method: method,
                              selected: _paymentMethod == method,
                              enabled: available.contains(method.apiValue),
                              onSelected: (method) =>
                                  setState(() => _paymentMethod = method),
                            ),
                        ],
                      ),
                    ),
                    OrderSummaryCard(totals: totals, couponCode: _coupon?.code),
                    const SizedBox(height: 18),
                    CheckoutSection(
                      title: 'Items in your order',
                      child: _cartItems.isEmpty
                          ? Text('Your cart is empty',
                              style: TextStyle(color: AppColors.muted))
                          : Column(
                              children: [
                                for (final item in _cartItems)
                                  CheckoutItemTile(item: item),
                              ],
                            ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _placingOrder ? null : _placeOrder,
                        child: Text(
                            'Place Order • Rs.${totals.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
                if (_placingOrder)
                  const ColoredBox(
                    color: Colors.black26,
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
    );
  }
}
