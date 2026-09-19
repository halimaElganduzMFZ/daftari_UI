import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';
import '../../core/constants/app_strings.dart';
import '../../core/di/app_services.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_mark.dart';
import '../../data/session/app_session.dart';
import '../../data/static/static_auth.dart';
import '../shell/main_shell.dart';
import 'which_app_screen.dart';

/// مقابلة شاشة login.php — تجريبي محلي أو Nest API حسب ApiConfig.
///
/// عبر الـ API: `POST /auth/login` يعيد التوكنات + ملف المستخدم بأعلامه،
/// فإن كان مسؤولاً عن هيكل تُعرض صفحة تحديد نوع الدخول (whichApp)،
/// وإلا يدخل كموظف مباشرة.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _employeeNumberController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscure = true;
  bool _submitting = false;
  late final AnimationController _intro;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic));
    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    _employeeNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);

    try {
      if (ApiConfig.useRemoteApi) {
        await _submitRemote();
      } else {
        await _submitDemo();
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitDemo() async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    final account = StaticAuth.login(
      employeeNumber: _employeeNumberController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (account == null) {
      await _showError(
        title: AppStrings.loginFailedTitle,
        message: AppStrings.loginFailedMessage,
      );
      return;
    }
    AppSession.applyDemoLogin(account);
    _routeAfterLogin();
  }

  Future<void> _submitRemote() async {
    try {
      final pair = await AppServices.auth.login(
        employeeNumber: _employeeNumberController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      AppSession.applyLogin(pair);
      _routeAfterLogin();
    } on ApiException catch (error) {
      if (!mounted) return;
      // رسائل الخادم إنجليزية عامة ("Invalid credentials")؛ نعرض المقابل العربي.
      final message = switch (error.statusCode) {
        401 => AppStrings.loginFailedMessage,
        403 => 'هذا الحساب غير مخوّل بتسجيل الدخول',
        _ => error.message,
      };
      await _showError(
        title: error.isTooManyRequests
            ? AppStrings.loginRateLimitedTitle
            : error.isNetwork
                ? 'لا يوجد اتصال'
                : AppStrings.loginFailedTitle,
        message: message,
      );
    } catch (_) {
      if (!mounted) return;
      await _showError(
        title: AppStrings.loginFailedTitle,
        message: AppStrings.loginConnectionError,
      );
    }
  }

  /// نفس المنطق للوضعين: مسؤول هيكل → whichApp، وإلا → واجهة الموظف.
  void _routeAfterLogin() {
    if (!AppSession.canManageStructures) {
      AppSession.enterAsEmployee();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const WhichAppScreen()),
    );
  }

  Future<void> _showError({
    required String title,
    required String message,
  }) {
    // أعد الزر لحالته قبل الحوار حتى لا يبقى مؤشر التحميل خلفه.
    if (_submitting) setState(() => _submitting = false);
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
    final hint = ApiConfig.useRemoteApi
        ? '${AppStrings.apiLoginHint} ${ApiConfig.displayHost}'
        : AppStrings.demoHint;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          // Atmosphere — soft warm field + gold light pools (not purple/glow kitsch).
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFFE9E6DF),
                  Color(0xFFF3F3F1),
                  Color(0xFFE4E1DA),
                ],
              ),
            ),
          ),
          Positioned(
            top: -size.height * 0.12,
            left: -size.width * 0.18,
            child: _GlowOrb(
              diameter: size.width * 0.72,
              color: const Color(0x33B08D57),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.18,
            right: -size.width * 0.2,
            child: _GlowOrb(
              diameter: size.width * 0.8,
              color: const Color(0x22A18F6A),
            ),
          ),
          Positioned(
            top: size.height * 0.28,
            right: -40,
            child: Transform.rotate(
              angle: -0.35,
              child: Container(
                width: 140,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(80),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.14),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          const BrandMark(size: 78),
                          const SizedBox(height: 18),
                          const Text(
                            AppStrings.orgName,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: AppColors.charcoal,
                              height: 1.2,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.goldSoft,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Text(
                              AppStrings.permissionsAppTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.goldDeep,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.fromLTRB(22, 28, 22, 22),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x18000000),
                                  blurRadius: 34,
                                  offset: Offset(0, 16),
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
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.charcoal,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    AppStrings.loginSubtitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.slate,
                                      fontSize: 13,
                                      height: 1.45,
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
                                    autofillHints: const [
                                      AutofillHints.username,
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: AppStrings.usernameHint,
                                      prefixIcon: Icon(Icons.badge_outlined),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
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
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    onFieldSubmitted: (_) => _submit(),
                                    decoration: InputDecoration(
                                      hintText: '********',
                                      prefixIcon:
                                          const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        onPressed: () => setState(
                                          () => _obscure = !_obscure,
                                        ),
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
                                    height: 54,
                                    child: FilledButton(
                                      onPressed:
                                          _submitting ? null : _submit,
                                      child: _submitting
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2.4,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(AppStrings.login),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    hint,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.slate,
                                      fontSize: 12,
                                      height: 1.45,
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
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.diameter, required this.color});

  final double diameter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
