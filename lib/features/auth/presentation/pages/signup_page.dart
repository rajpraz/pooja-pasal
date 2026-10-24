import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/errors/app_exception.dart';
import 'package:pooja_pasal/core/widgets/feedback.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';

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

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneNumberController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final shopName = _shopNameController.text.trim();
    final isSeller = widget.role == 'seller';

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
            role: widget.role,
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

  Widget _fieldLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
      );

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
    return SafeArea(
      child: Scaffold(
        body: ColoredBox(
          // Plain page, matching the login screen.
          color: AppColors.background,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(widget.role == 'seller' ? 'Seller Sign Up' : 'Create Account',
                      style: TextStyle(
                          fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 8),
                  Text(
                    widget.role == 'seller'
                        ? 'Apply to sell your pooja items. An admin reviews every new seller.'
                        : 'Join Pooja Pasal for trusted puja essentials.',
                    style: TextStyle(fontSize: 16, color: AppColors.muted),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text(
                        'Create an account to save addresses, track orders, and shop your favorite rituals faster.'),
                  ),
                  const SizedBox(height: 20),
                  _fieldLabel('Full name'),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline), hintText: 'Enter your full name'),
                  ),
                  const SizedBox(height: 16),
                  if (widget.role == 'seller') ...[
                    _fieldLabel('Shop name'),
                    TextFormField(
                      controller: _shopNameController,
                      decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.storefront_outlined),
                          hintText: 'Name buyers will see on your products'),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _fieldLabel('Phone number'),
                  TextFormField(
                    controller: _phoneNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: 'Enter your phone number'),
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('Address'),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_on_outlined),
                        hintText: 'Enter your address'),
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('Email'),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'Enter your email address'),
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('Password'),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obsecure,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obsecure = !_obsecure),
                        tooltip: _obsecure ? 'Show password' : 'Hide password',
                        icon:
                            Icon(_obsecure ? Icons.remove_red_eye : Icons.remove_red_eye_outlined),
                      ),
                      hintText: 'At least 6 characters',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _fieldLabel('Confirm password'),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obsecure1,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obsecure1 = !_obsecure1),
                        tooltip: _obsecure1 ? 'Show password' : 'Hide password',
                        icon:
                            Icon(_obsecure1 ? Icons.remove_red_eye : Icons.remove_red_eye_outlined),
                      ),
                      hintText: 'Re-enter your password',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _signUp,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                                  CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                            )
                          : const Text('Sign Up',
                              style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
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
