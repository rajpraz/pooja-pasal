import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/utils/error_mapper.dart';
import 'package:pooja_pasal/features/payments/domain/entities/esewa_initiation.dart';
import 'package:pooja_pasal/features/payments/presentation/providers/payment_providers.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// eSewa's ePay v2 API takes a *form POST* of signed fields, not a plain
/// GET URL — there's no native eSewa SDK for Flutter, so the standard
/// mobile approach is to load a tiny self-submitting HTML form into a
/// WebView pointed at eSewa's hosted payment page, then watch for the
/// redirect back to the success/failure URLs.
///
/// The API (`POST /orders/{id}/pay`) signs the fields for the order's own
/// total and supplies the form URL (sandbox or live, per the server's
/// config) and its own success/failure URLs, which this page intercepts.
///
/// Server-side verification (`verifyEsewa`) is what actually confirms
/// payment — reaching the success URL only means eSewa *reported* success
/// in its own redirect, which this page never trusts on its own.
class EsewaPaymentPage extends ConsumerStatefulWidget {
  final String orderId;

  const EsewaPaymentPage({super.key, required this.orderId});

  @override
  ConsumerState<EsewaPaymentPage> createState() => _EsewaPaymentPageState();
}

class _EsewaPaymentPageState extends ConsumerState<EsewaPaymentPage> {
  WebViewController? _controller;
  EsewaInitiation? _fields;
  bool _initiating = true;
  bool _verifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initiate();
  }

  Future<void> _initiate() async {
    try {
      final EsewaInitiation fields =
          await ref.read(paymentControllerProvider.notifier).initiateEsewa(widget.orderId);
      if (!mounted) return;
      final controller = WebViewController();
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: _handleNavigation,
      ));
      await controller.loadHtmlString(_buildAutoSubmitHtml(fields), baseUrl: fields.formUrl);
      if (!mounted) return;
      setState(() {
        _fields = fields;
        _controller = controller;
        _initiating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initiating = false;
        _error = friendlyErrorMessage(e);
      });
    }
  }

  String _buildAutoSubmitHtml(EsewaInitiation fields) {
    // amount + tax_amount + service/delivery charges must sum to
    // total_amount per eSewa's own validation; only total_amount,
    // transaction_uuid, and product_code are actually signed (see
    // the API's PaymentService), so the rest are zeroed.
    return '''
<!DOCTYPE html>
<html>
<body onload="document.forms[0].submit()">
  <form action="${_attr(fields.formUrl)}" method="POST">
    <input type="hidden" name="amount" value="${_attr(fields.totalAmount)}" />
    <input type="hidden" name="tax_amount" value="0" />
    <input type="hidden" name="total_amount" value="${_attr(fields.totalAmount)}" />
    <input type="hidden" name="transaction_uuid" value="${_attr(fields.transactionUuid)}" />
    <input type="hidden" name="product_code" value="${_attr(fields.productCode)}" />
    <input type="hidden" name="product_service_charge" value="0" />
    <input type="hidden" name="product_delivery_charge" value="0" />
    <input type="hidden" name="success_url" value="${_attr(fields.successUrl)}" />
    <input type="hidden" name="failure_url" value="${_attr(fields.failureUrl)}" />
    <input type="hidden" name="signed_field_names" value="${_attr(fields.signedFieldNames)}" />
    <input type="hidden" name="signature" value="${_attr(fields.signature)}" />
  </form>
</body>
</html>
''';
  }

  /// Escapes a value for an HTML attribute.
  static String _attr(String value) => const HtmlEscape(HtmlEscapeMode.attribute).convert(value);

  NavigationDecision _handleNavigation(NavigationRequest request) {
    final fields = _fields;
    if (fields == null) return NavigationDecision.navigate;
    if (fields.successUrl.isNotEmpty && request.url.startsWith(fields.successUrl)) {
      _onRedirectSucceeded();
      return NavigationDecision.prevent;
    }
    if (fields.failureUrl.isNotEmpty && request.url.startsWith(fields.failureUrl)) {
      Navigator.of(context).pop(false);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  Future<void> _onRedirectSucceeded() async {
    if (_verifying) return;
    setState(() => _verifying = true);
    try {
      // eSewa's redirect claiming success is never trusted on its own —
      // this call independently confirms with eSewa's server-to-server
      // status API before the order is ever marked paid.
      await ref.read(paymentControllerProvider.notifier).verifyEsewa(widget.orderId);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = friendlyErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Pay with eSewa')),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Back to Checkout'),
                    ),
                  ],
                ),
              ),
            )
          : Stack(
              children: [
                if (_controller != null) WebViewWidget(controller: _controller!),
                if (_initiating || _verifying)
                  ColoredBox(
                    color: Colors.black26,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(
                            _verifying ? 'Confirming payment...' : 'Connecting to eSewa...',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
