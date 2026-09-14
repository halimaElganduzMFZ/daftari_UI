import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../data/auth/auth_repository.dart';
import '../../data/session/app_session.dart';
import '../shell/main_shell.dart';

/// مقابلة شاشة login.php — الدخول عبر Nest API الحقيقي.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();

  bool _obscure = true;
  bool _submitting = false;

  @override
  void dispose() {
    _employeeNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);

    try {
      final pair = await _authRepository.login(
        employeeNumber: _employeeNumberController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      AppSession.applyLogin(pair);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      await _showError(
        title: error.isTooManyRequests
            ? AppStrings.loginRateLimitedTitle
            : AppStrings.loginFailedTitle,
        message: error.message,
      );
    } catch (_) {
      if (!mounted) return;
      await _showError(
        title: AppStrings.loginFailedTitle,
        message: AppStrings.loginConnectionError,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showError({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEDEDEB),
              AppColors.background,
              Color(0xFFE8E6E1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    const Text(
                      AppStrings.orgName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.charcoal,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      AppStrings.permissionsAppTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldDeep,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.line),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 24,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              AppStrings.welcomeEmployee,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.charcoal,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              AppStrings.loginSubtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.slate,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 26),
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                AppStrings.username,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.charcoal,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _employeeNumberController,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.text,
                              autofillHints: const [AutofillHints.username],
                              decoration: const InputDecoration(
                                hintText: AppStrings.usernameHint,
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'أدخل رقم الموظف';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                AppStrings.password,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.charcoal,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscure,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                hintText: '********',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'أدخل كلمة المرور';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 22),
                            SizedBox(
                              height: 52,
                              child: FilledButton(
                                onPressed: _submitting ? null : _submit,
                                child: _submitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(AppStrings.login),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              AppStrings.apiLoginHint,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.slate,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      '${AppStrings.footerRights} © $year',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.slate,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      AppStrings.footerOrg,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.slate,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
