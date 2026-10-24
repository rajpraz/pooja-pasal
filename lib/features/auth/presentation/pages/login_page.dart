import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:pooja_pasal/app/router/route_names.dart';
import 'package:pooja_pasal/app/theme/app_colors.dart';
import 'package:pooja_pasal/core/errors/app_exception.dart';
import 'package:pooja_pasal/core/widgets/feedback.dart';
import 'package:pooja_pasal/features/auth/presentation/providers/auth_providers.dart';

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
  late String currentRole;

  @override
  void initState() {
    super.initState();
    currentRole = widget.role;
  }

  void _signUp() {
    context.push('${RouteNames.signup}?role=$currentRole');
  }

  void _forgetPassword() {
    context.push(RouteNames.forgotPassword);
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
      await authRepository.signIn(email: email, password: password);
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
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _isloading
            ? Center(child: SpinKitCircle(color: AppColors.accent, size: 60))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text('Welcome Back!',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 6),
                    Text('Login to continue',
                        style: TextStyle(fontSize: 15, color: AppColors.muted)),
                    const SizedBox(height: 20),

                    // Buyer / seller selector
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _roleTab('Buyer', 'buyer'),
                          ),
                          Expanded(
                            child: _roleTab('Seller', 'seller'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text('Email',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'Email address',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Password',
                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.text)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obsecure,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _obsecure = !_obsecure),
                          child: Icon(
                              _obsecure ? Icons.remove_red_eye : Icons.remove_red_eye_outlined),
                        ),
                        hintText: 'Enter your password',
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgetPassword,
                        child: Text('Forgot password?', style: TextStyle(color: AppColors.accent)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _login,
                        child: const Text('Login',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('New here? '),
                        GestureDetector(
                          onTap: _signUp,
                          child: Text(
                            'Create ${currentRole == 'seller' ? 'seller' : 'a buyer'} account',
                            style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _roleTab(String label, String role) {
    final bool selected = currentRole == role;
    return GestureDetector(
      onTap: () => setState(() => currentRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
