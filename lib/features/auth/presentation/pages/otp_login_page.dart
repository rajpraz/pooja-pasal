import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/errors/app_exception.dart';
import 'package:pooja_pasal/core/widgets/feedback.dart';
import 'package:pooja_pasal/features/auth/presentation/pages/auth_navigation.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';

/// Phone-number login: enter a number, then the 6-digit code texted to it.
class OtpLoginPage extends ConsumerStatefulWidget {
  const OtpLoginPage({super.key});

  @override
  ConsumerState<OtpLoginPage> createState() => _OtpLoginPageState();
}

class _OtpLoginPageState extends ConsumerState<OtpLoginPage> {
  static const _resendSeconds = 30;

  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  /// Runs [action], showing API failures as a message. Returns whether it worked.
  Future<bool> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      return true;
    } on AuthException catch (e) {
      if (mounted) showMessage(context, e.message);
    } catch (_) {
      if (mounted) showMessage(context, 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    return false;
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.replaceAll(RegExp(r'\D'), '').length < 7) {
      showMessage(context, 'Enter a valid phone number');
      return;
    }
    final auth = ref.read(authRepositoryProvider);
    if (await _run(() => auth.sendOtp(phone)) && mounted) {
      setState(() => _codeSent = true);
      _codeController.clear();
      _startCountdown();
    }
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      showMessage(context, 'Enter the 6-digit code');
      return;
    }
    final auth = ref.read(authRepositoryProvider);
    final ok = await _run(() => auth.verifyOtp(_phoneController.text.trim(), code));
    if (ok && mounted) await goAfterSignIn(context, auth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.16),
                      blurRadius: 36,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.phone_android, size: 40, color: AppColors.accent),
                    const SizedBox(height: 12),
                    Text(_codeSent ? 'Enter the code' : 'Login with OTP',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    const SizedBox(height: 6),
                    Text(
                      _codeSent
                          ? 'We texted a 6-digit code to ${_phoneController.text.trim()}.'
                          : 'We will text a 6-digit code to your phone number.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 20),
                    if (!_codeSent)
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        onFieldSubmitted: (_) => _sendCode(),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.phone_outlined, color: AppColors.accent),
                          hintText: '98XXXXXXXX',
                          labelText: 'Phone number',
                        ),
                      )
                    else ...[
                      TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.oneTimeCode],
                        maxLength: 6,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onFieldSubmitted: (_) => _verify(),
                        style: const TextStyle(fontSize: 22, letterSpacing: 8),
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.pin_outlined, color: AppColors.accent),
                          hintText: '------',
                          counterText: '',
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                      _codeSent = false;
                                      _timer?.cancel();
                                      _secondsLeft = 0;
                                    }),
                            child: const Text('Change number'),
                          ),
                          TextButton(
                            onPressed: _busy || _secondsLeft > 0 ? null : _sendCode,
                            child: Text(_secondsLeft > 0 ? 'Resend in ${_secondsLeft}s' : 'Resend code'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _busy ? null : (_codeSent ? _verify : _sendCode),
                        child: _busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                              )
                            : Text(_codeSent ? 'Verify & Login' : 'Send code',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
