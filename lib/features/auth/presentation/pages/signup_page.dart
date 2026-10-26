import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/errors/app_exception.dart';
import 'package:pooja_pasal/core/widgets/feedback.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';
import 'package:pooja_pasal/features/auth/presentation/widgets/auth_decor.dart';

class SignUpPage extends ConsumerStatefulWidget {
  final String role;
  const SignUpPage({super.key, this.role = 'buyer'});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obsecure = true;
  bool _obsecure1 = true;
  bool _isSaving = false;

  /// Asking to sell files a seller application; the account shops as a buyer
  /// until an admin approves it.
  late String _role = widget.role;

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneNumberController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final shopName = _shopNameController.text.trim();
    final isSeller = _role == 'seller';

    if (name.isEmpty ||
        address.isEmpty ||
        phone.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        (isSeller && shopName.isEmpty)) {
      showMessage(context, 'Please fill all fields');
      return;
    }

    if (password != confirmPassword) {
      showMessage(context, 'Passwords do not match');
      return;
    }

    if (password.length < 8) {
      showMessage(context, 'Password must be at least 8 characters');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(authRepositoryProvider).signUp(
            email: email,
            password: password,
            name: name,
            phone: phone,
            address: address,
            role: _role,
            shopName: isSeller ? shopName : null,
          );

      if (!mounted) return;
      // Signed in already. A seller account starts as a buyer until an
      // admin approves the application.
      showMessage(
          context,
          isSeller
              ? 'Account created. Your seller application is waiting for admin approval.'
              : 'Account created successfully');
      context.go(RouteNames.home);
    } on AuthException catch (e) {
      showMessage(context, e.message);
    } catch (e) {
      showMessage(context, 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shopNameController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSeller = _role == 'seller';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AuthBackdrop(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: AuthEntrance(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const DiyaLogo(size: 88),
                        const SizedBox(height: 14),
                        Text(
                          isSeller ? 'Become a Seller' : 'Join Pooja Pasal',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isSeller
                              ? 'Apply to sell your pooja items. An admin reviews every new seller.'
                              : 'Create an account for trusted puja essentials',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: AppColors.text),
                        ),
                        const SizedBox(height: 22),
                        AuthCard(child: _form(isSeller)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Already have an account? ',
                                style: TextStyle(color: AppColors.muted)),
                            GestureDetector(
                              onTap: _goToLogin,
                              child: Text('Login',
                                  style: TextStyle(
                                      color: AppColors.accent, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
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

  void _goToLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.login);
    }
  }

  Widget _form(bool isSeller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthModeSwitch(loginActive: false, onLogin: _goToLogin, onSignUp: () {}),
        const SizedBox(height: 20),
        const AuthLabel('I WANT TO'),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'buyer',
                  icon: Icon(Icons.shopping_bag_outlined),
                  label: Text('Shop')),
              ButtonSegment(
                  value: 'seller',
                  icon: Icon(Icons.storefront_outlined),
                  label: Text('Sell')),
            ],
            selected: {_role},
            onSelectionChanged: (v) => setState(() => _role = v.first),
          ),
        ),
        const SizedBox(height: 16),
        _field('FULL NAME', _nameController, Icons.person_outline, 'Enter your full name',
            hints: const [AutofillHints.name]),
        if (isSeller)
          _field('SHOP NAME', _shopNameController, Icons.storefront_outlined,
              'Name buyers will see on your products'),
        _field('PHONE NUMBER', _phoneNumberController, Icons.phone_outlined, '98XXXXXXXX',
            type: TextInputType.phone, hints: const [AutofillHints.telephoneNumber]),
        _field('ADDRESS', _addressController, Icons.location_on_outlined, 'Enter your address'),
        _field('EMAIL ADDRESS', _emailController, Icons.mail_outline, 'yourname@domain.com',
            type: TextInputType.emailAddress, hints: const [AutofillHints.email]),
        _field('PASSWORD', _passwordController, Icons.lock, 'At least 8 characters',
            obscure: _obsecure,
            onToggle: () => setState(() => _obsecure = !_obsecure),
            hints: const [AutofillHints.newPassword]),
        _field('CONFIRM PASSWORD', _confirmPasswordController, Icons.lock, 'Re-enter your password',
            obscure: _obsecure1,
            onToggle: () => setState(() => _obsecure1 = !_obsecure1),
            hints: const [AutofillHints.newPassword],
            last: true),
        const SizedBox(height: 8),
        AuthButton(
          label: 'Create Account',
          icon: Icons.check_circle_outline,
          loading: _isSaving,
          onTap: _signUp,
        ),
      ],
    );
  }

  /// A labelled field with the shared icon / spacing; [onToggle] adds the
  /// show-password eye.
  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint, {
    TextInputType? type,
    bool obscure = false,
    VoidCallback? onToggle,
    Iterable<String>? hints,
    bool last = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthLabel(label),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: type,
            obscureText: obscure,
            autofillHints: hints,
            textInputAction: last ? TextInputAction.done : TextInputAction.next,
            onFieldSubmitted: last ? (_) => _signUp() : null,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.accent),
              hintText: hint,
              suffixIcon: onToggle == null
                  ? null
                  : IconButton(
                      tooltip: obscure ? 'Show password' : 'Hide password',
                      onPressed: onToggle,
                      icon: Icon(
                          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
