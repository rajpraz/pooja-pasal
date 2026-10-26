import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/errors/app_exception.dart';
import 'package:pooja_pasal/core/widgets/feedback.dart';
import 'package:pooja_pasal/features/auth/presentation/pages/auth_navigation.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/auth/presentation/widgets/auth_decor.dart';

class LoginPage extends ConsumerStatefulWidget {
  final String role;
  const LoginPage({super.key, this.role = 'buyer'});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obsecure = true;
  bool _isloading = false;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _prefillRememberedEmail();
  }

  Future<void> _prefillRememberedEmail() async {
    final email = await ref.read(authRepositoryProvider).rememberedEmail();
    // Don't overwrite anything the user typed while this was loading.
    if (!mounted || email == null || _emailController.text.isNotEmpty) return;
    _emailController.text = email;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signUp() => context.push(RouteNames.signup);

  void _forgetPassword() => context.push(RouteNames.forgotPassword);

  void _otpLogin() => context.push(RouteNames.otpLogin);

  Future<void> _googleLogin() async {
    setState(() => _isloading = true);
    final authRepository = ref.read(authRepositoryProvider);
    try {
      final signedIn = await authRepository.signInWithGoogle(rememberMe: _rememberMe);
      if (signedIn && mounted) await goAfterSignIn(context, authRepository);
    } on AuthException catch (e) {
      if (mounted) showMessage(context, e.message);
    } catch (e) {
      if (mounted) showMessage(context, 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isloading = false);
    }
  }

  void _routeAfterLogin(String role) {
    if (role == 'admin') {
      context.go(RouteNames.adminDashboard);
    } else if (role == 'seller') {
      context.go(RouteNames.sellerDashboard);
    } else {
      context.go(RouteNames.home);
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage(context, 'Please enter your email and password');
      return;
    }

    setState(() => _isloading = true);
    final authRepository = ref.read(authRepositoryProvider);

    try {
      await authRepository.signIn(email: email, password: password, rememberMe: _rememberMe);
      final user = authRepository.currentUser;
      final appUser = user == null ? null : await authRepository.getUserDoc(user.uid);

      if (!mounted) return;
      if (appUser == null) {
        showMessage(context, 'Account profile not found. Please sign up again.');
        return;
      }
      _routeAfterLogin(appUser.role);
    } on AuthException catch (e) {
      showMessage(context, e.message);
    } catch (e) {
      showMessage(context, 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AuthBackdrop(),
          SafeArea(
            child: _isloading
                ? Center(child: SpinKitCircle(color: AppColors.accent, size: 60))
                : Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: AuthEntrance(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const DiyaLogo(),
                              const SizedBox(height: 18),
                              Text(
                                'Pooja Pasal',
                                style: TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: AppColors.primaryDark,
                                  fontFeatures: const [FontFeature.enable('smcp')],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Pure Puja Essentials Delivered to Your Doorstep',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: AppColors.text),
                              ),
                              const SizedBox(height: 24),
                              _formCard(),
                              const SizedBox(height: 16),
                              const _TrustRow(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _formCard() {
    return AuthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthModeSwitch(
            loginActive: true,
            onLogin: () {},
            onSignUp: _signUp,
          ),
          const SizedBox(height: 20),
          const AuthLabel('EMAIL ADDRESS'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.mail_outline, color: AppColors.accent),
              hintText: 'yourname@domain.com',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const AuthLabel('PASSWORD'),
              GestureDetector(
                onTap: _forgetPassword,
                child: Text(
                  'Forgot?',
                  style: TextStyle(color: AppColors.accent, fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obsecure,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _login(),
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.lock, color: AppColors.accent),
              suffixIcon: IconButton(
                tooltip: _obsecure ? 'Show password' : 'Hide password',
                onPressed: () => setState(() => _obsecure = !_obsecure),
                icon: Icon(_obsecure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              ),
              hintText: 'Enter your password',
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _rememberMe = !_rememberMe),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: 22,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: AppColors.accent,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (v) => setState(() => _rememberMe = v ?? true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Remember me', style: TextStyle(fontSize: 13.5, color: AppColors.text)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          AuthButton(label: 'Enter Divine Store', onTap: _login),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR CONTINUE WITH',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.text,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppColors.border)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _altButton(
                  icon: Text('G',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.error)),
                  label: 'Google',
                  onTap: _googleLogin,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _altButton(
                  icon: Icon(Icons.phone_android, size: 18, color: AppColors.accent),
                  label: 'OTP Login',
                  onTap: _otpLogin,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _altButton({required Widget icon, required String label, required VoidCallback onTap}) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.text)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _tile(Icons.volunteer_activism_outlined, '100% Authentic', 'Puja Samagri'),
        const SizedBox(width: 10),
        _tile(Icons.local_shipping_outlined, 'Express', 'Temple Delivery'),
        const SizedBox(width: 10),
        _tile(Icons.shield_outlined, 'Sacred Quality', 'Purity Guaranteed'),
      ],
    );
  }

  Widget _tile(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: AppColors.accent),
            const SizedBox(height: 6),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.text)),
            const SizedBox(height: 2),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

