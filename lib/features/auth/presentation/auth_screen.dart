import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLogin = true;
  bool isPasswordVisible = false;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    final auth = context.read<AuthProvider>();

    final result = isLogin
        ? await auth.login(
            email: emailController.text,
            password: passwordController.text,
          )
        : await auth.register(
            name: nameController.text,
            email: emailController.text,
            password: passwordController.text,
          );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );

    if (result.success) {
      context.go('/app');
    }
  }

  void toggleMode() {
    setState(() {
      isLogin = !isLogin;
      passwordController.clear();

      if (isLogin) {
        nameController.clear();
      }
    });
  }

  void openForgotPasswordSheet() {
    final resetEmailController = TextEditingController(text: emailController.text);
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter your account email, OTP if required, and create a new password.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    _AuthField(
                      controller: resetEmailController,
                      hint: 'Registered email address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _AuthField(
                      controller: otpController,
                      hint: 'OTP code if required by backend',
                      icon: Icons.pin_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: _authDecoration(
                        hint: 'New password',
                        icon: Icons.lock_reset_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: _authDecoration(
                        hint: 'Confirm new password',
                        icon: Icons.verified_user_outlined,
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset Password'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: () async {
                          final result =
                              await context.read<AuthProvider>().resetPassword(
                                    email: resetEmailController.text,
                                    newPassword: newPasswordController.text,
                                    confirmPassword:
                                        confirmPasswordController.text,
                                    otp: otpController.text,
                                  );

                          if (!mounted) return;

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result.message)),
                          );

                          if (result.success) {
                            setState(() {
                              isLogin = true;
                              emailController.text =
                                  resetEmailController.text.trim();
                              passwordController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Backend note: Password reset is connected with the API. If OTP is enabled, enter the OTP sent to your email before resetting.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 850;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 35,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(child: _AuthHeroPanel()),
                          const SizedBox(width: 18),
                          Expanded(
                            child: _AuthFormPanel(
                              isLogin: isLogin,
                              isLoading: isLoading,
                              isPasswordVisible: isPasswordVisible,
                              nameController: nameController,
                              emailController: emailController,
                              passwordController: passwordController,
                              onSubmit: submit,
                              onToggleMode: toggleMode,
                              onForgotPassword: openForgotPasswordSheet,
                              onTogglePassword: () {
                                setState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          const _AuthHeroPanel(),
                          const SizedBox(height: 18),
                          _AuthFormPanel(
                            isLogin: isLogin,
                            isLoading: isLoading,
                            isPasswordVisible: isPasswordVisible,
                            nameController: nameController,
                            emailController: emailController,
                            passwordController: passwordController,
                            onSubmit: submit,
                            onToggleMode: toggleMode,
                            onForgotPassword: openForgotPasswordSheet,
                            onTogglePassword: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
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

class _AuthHeroPanel extends StatelessWidget {
  const _AuthHeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 470),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LogoBox(),
          SizedBox(height: 28),
          Text(
            'Budget Home',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Manage home income, expenses, rent, bills, loans and reports in one premium dashboard.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 70),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _HeroBadge(
                icon: Icons.lock_outline,
                label: 'JWT Security',
              ),
              _HeroBadge(
                icon: Icons.insights_outlined,
                label: 'SQL Server API',
              ),
              _HeroBadge(
                icon: Icons.devices_outlined,
                label: 'Responsive App',
              ),
            ],
          ),
          SizedBox(height: 18),
          _FreshDataNotice(),
        ],
      ),
    );
  }
}

class _LogoBox extends StatelessWidget {
  const _LogoBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: const Icon(
        Icons.account_balance_wallet_outlined,
        color: Colors.white,
        size: 32,
      ),
    );
  }
}

class _FreshDataNotice extends StatelessWidget {
  const _FreshDataNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.trending_up,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Secure backend authentication is active with JWT session support.',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthFormPanel extends StatelessWidget {
  const _AuthFormPanel({
    required this.isLogin,
    required this.isLoading,
    required this.isPasswordVisible,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.onSubmit,
    required this.onToggleMode,
    required this.onForgotPassword,
    required this.onTogglePassword,
  });

  final bool isLogin;
  final bool isLoading;
  final bool isPasswordVisible;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onSubmit;
  final VoidCallback onToggleMode;
  final VoidCallback onForgotPassword;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isLogin ? 'Welcome Back 👋' : 'Create Account 🚀',
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLogin
                ? 'Login securely with backend authentication and JWT session.'
                : 'Create your secure backend account for Budget Home.',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          if (!isLogin) ...[
            _AuthField(
              controller: nameController,
              hint: 'Full name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 14),
          ],
          _AuthField(
            controller: emailController,
            hint: 'Email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: passwordController,
            obscureText: !isPasswordVisible,
            decoration: _authDecoration(
              hint: 'Password',
              icon: Icons.lock_outline,
              suffixIcon: IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
          if (isLogin) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isLoading ? null : onForgotPassword,
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isLogin ? 'Login' : 'Create Account',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLogin ? "Don't have an account?" : 'Already have an account?',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: isLoading ? null : onToggleMode,
                child: Text(
                  isLogin ? 'Register' : 'Login',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Color(0xFF2563EB),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Secure backend authentication is active. Your session is protected with server-side login and JWT token storage.',
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      height: 1.35,
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

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _authDecoration(
        hint: hint,
        icon: icon,
      ),
    );
  }
}

InputDecoration _authDecoration({
  required String hint,
  required IconData icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
  );
}