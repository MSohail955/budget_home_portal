import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool rememberMe = true;
  bool obscurePassword = true;
  bool isSubmitting = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage('Please enter email and password');
      return;
    }

    if (!email.contains('@')) {
      showMessage('Please enter a valid email address');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    final result = await context.read<AuthProvider>().login(
          email: email,
          password: password,
        );

    if (!mounted) return;

    setState(() {
      isSubmitting = false;
    });

    showMessage(result.message);

    if (result.success) {
      context.go('/app');
    }
  }

  void openForgotPasswordSheet() {
    final parentContext = context;

    final resetEmailController = TextEditingController(
      text: emailController.text.trim(),
    );
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    bool isResetting = false;

    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (localContext, setSheetState) {
            void showSheetMessage(String message) {
              if (!mounted) return;

              ScaffoldMessenger.of(parentContext).showSnackBar(
                SnackBar(content: Text(message)),
              );
            }

            Future<void> resetPassword() async {
              final email = resetEmailController.text.trim();
              final newPassword = newPasswordController.text.trim();
              final confirmPassword = confirmPasswordController.text.trim();

              if (email.isEmpty ||
                  newPassword.isEmpty ||
                  confirmPassword.isEmpty) {
                showSheetMessage('Please fill all reset password fields');
                return;
              }

              if (!email.contains('@')) {
                showSheetMessage('Please enter a valid email address');
                return;
              }

              if (newPassword.length < 6) {
                showSheetMessage('New password must be at least 6 characters');
                return;
              }

              if (newPassword != confirmPassword) {
                showSheetMessage(
                  'New password and confirm password do not match',
                );
                return;
              }

              setSheetState(() {
                isResetting = true;
              });

              final result =
                  await parentContext.read<AuthProvider>().resetPassword(
                        email: email,
                        newPassword: newPassword,
                        confirmPassword: confirmPassword,
                      );

              if (!mounted || !localContext.mounted) return;

              if (result.success) {
                emailController.text = email;
                passwordController.clear();

                Navigator.of(sheetContext, rootNavigator: true).pop();

                Future.microtask(() {
                  if (!mounted) return;

                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text(result.message)),
                  );
                });

                return;
              }

              setSheetState(() {
                isResetting = false;
              });

              showSheetMessage(result.message);
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(localContext).size.height * 0.90,
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(localContext).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SheetHeader(
                          title: 'Reset Password',
                          subtitle:
                              'Enter your registered email and set a new password for your local account.',
                          icon: Icons.lock_reset_outlined,
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
                          controller: newPasswordController,
                          hint: 'New password',
                          icon: Icons.lock_outline,
                          obscureText: obscureNewPassword,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setSheetState(() {
                                obscureNewPassword = !obscureNewPassword;
                              });
                            },
                            icon: Icon(
                              obscureNewPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _AuthField(
                          controller: confirmPasswordController,
                          hint: 'Confirm new password',
                          icon: Icons.verified_user_outlined,
                          obscureText: obscureConfirmPassword,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setSheetState(() {
                                obscureConfirmPassword =
                                    !obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFBFDBFE),
                            ),
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
                                  'This reset works for locally saved frontend accounts. Backend email reset will be added in production.',
                                  style: TextStyle(
                                    color: Color(0xFF1E3A8A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: isResetting ? null : resetPassword,
                            icon: isResetting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.lock_reset_outlined),
                            label: Text(
                              isResetting
                                  ? 'Resetting password...'
                                  : 'Reset Password',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF94A3B8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: isResetting
                                ? null
                                : () {
                                    Navigator.of(
                                      sheetContext,
                                      rootNavigator: true,
                                    ).pop();
                                  },
                            icon: const Icon(Icons.close),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF475569),
                              side: const BorderSide(
                                color: Color(0xFFE2E8F0),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F172A),
              Color(0xFF2563EB),
              Color(0xFF7C3AED),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -110,
              right: -90,
              child: _GlowCircle(
                size: 280,
                color: Color(0xFF38BDF8),
              ),
            ),
            const Positioned(
              bottom: -130,
              left: -100,
              child: _GlowCircle(
                size: 300,
                color: Color(0xFF8B5CF6),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: _AnimatedEntry(
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.55),
                              Colors.white.withOpacity(0.10),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(36),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(isWide ? 26 : 20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.96),
                            borderRadius: BorderRadius.circular(34),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.22),
                                blurRadius: 38,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          child: isWide
                              ? Row(
                                  children: [
                                    const Expanded(
                                      child: _AuthSidePanel(),
                                    ),
                                    const SizedBox(width: 26),
                                    Expanded(
                                      child: _LoginForm(
                                        emailController: emailController,
                                        passwordController: passwordController,
                                        rememberMe: rememberMe,
                                        obscurePassword: obscurePassword,
                                        isSubmitting: isSubmitting,
                                        onRememberChanged: (value) {
                                          setState(() {
                                            rememberMe = value;
                                          });
                                        },
                                        onTogglePassword: () {
                                          setState(() {
                                            obscurePassword = !obscurePassword;
                                          });
                                        },
                                        onForgotPassword:
                                            openForgotPasswordSheet,
                                        onLogin: login,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    const _AuthSidePanel(),
                                    const SizedBox(height: 22),
                                    _LoginForm(
                                      emailController: emailController,
                                      passwordController: passwordController,
                                      rememberMe: rememberMe,
                                      obscurePassword: obscurePassword,
                                      isSubmitting: isSubmitting,
                                      onRememberChanged: (value) {
                                        setState(() {
                                          rememberMe = value;
                                        });
                                      },
                                      onTogglePassword: () {
                                        setState(() {
                                          obscurePassword = !obscurePassword;
                                        });
                                      },
                                      onForgotPassword: openForgotPasswordSheet,
                                      onLogin: login,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.emailController,
    required this.passwordController,
    required this.rememberMe,
    required this.obscurePassword,
    required this.isSubmitting,
    required this.onRememberChanged,
    required this.onTogglePassword,
    required this.onForgotPassword,
    required this.onLogin,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final bool obscurePassword;
  final bool isSubmitting;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onForgotPassword;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SmallBadge(
            icon: Icons.lock_open_outlined,
            label: 'Secure Login',
          ),
          const SizedBox(height: 18),
          const Text(
            'Welcome Back',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Login to manage your home budget, bills, rent, loans, reports and reminders.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          _AuthField(
            controller: emailController,
            hint: 'Email address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _AuthField(
            controller: passwordController,
            hint: 'Password',
            icon: Icons.lock_outline,
            obscureText: obscurePassword,
            suffixIcon: IconButton(
              onPressed: onTogglePassword,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Checkbox(
                value: rememberMe,
                activeColor: const Color(0xFF2563EB),
                onChanged: (value) => onRememberChanged(value ?? false),
              ),
              const Expanded(
                child: Text(
                  'Remember me',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: onForgotPassword,
                child: const Text(
                  'Forgot?',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton.icon(
              onPressed: isSubmitting ? null : onLogin,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login),
              label: Text(isSubmitting ? 'Logging in...' : 'Login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF94A3B8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'New here?',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/register'),
                child: const Text(
                  'Create account',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuthSidePanel extends StatelessWidget {
  const _AuthSidePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -50,
            top: -60,
            child: _GlowCircle(size: 170, color: Color(0xFF38BDF8)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0x22FFFFFF),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Budget Home Portal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'A premium home finance workspace for income, expenses, bills, rent, loans, reports and reminders.',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              const Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _FeaturePill(
                    icon: Icons.receipt_long_outlined,
                    label: 'Bills',
                  ),
                  _FeaturePill(
                    icon: Icons.home_work_outlined,
                    label: 'Rent',
                  ),
                  _FeaturePill(
                    icon: Icons.handshake_outlined,
                    label: 'Loans',
                  ),
                  _FeaturePill(
                    icon: Icons.notifications_active_outlined,
                    label: 'Alerts',
                  ),
                  _FeaturePill(
                    icon: Icons.analytics_outlined,
                    label: 'Reports',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.16)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_outlined, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Frontend preview ready. Backend API, database, and real email/SMS reminders will be added next.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: const Color(0xFFEFF6FF),
          child: Icon(
            icon,
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 18),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _AnimatedEntry extends StatelessWidget {
  const _AnimatedEntry({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 650),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}