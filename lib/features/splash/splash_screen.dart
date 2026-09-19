import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_mark.dart';
import '../auth/login_screen.dart';

/// شاشة افتتاح خفيفة: شعار يتنفس، نص يظهر بهدوء، ثم انتقال ناعم لتسجيل الدخول.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _enter;
  late final AnimationController _breathe;
  late final AnimationController _progress;
  late final AnimationController _orb;

  late final Animation<double> _markScale;
  late final Animation<double> _markFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subFade;
  late final Animation<double> _bar;

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _orb = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    );

    _markScale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _markFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.32, 0.78, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.32, 0.82, curve: Curves.easeOutCubic),
      ),
    );
    _subFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.48, 1, curve: Curves.easeOut),
      ),
    );
    _bar = CurvedAnimation(parent: _progress, curve: Curves.easeInOutCubic);

    _enter.forward();
    _breathe.repeat(reverse: true);
    _progress.forward();
    _orb.repeat();

    // Start the dwell clock only after the first frame so slow web/native
    // bootstrap cannot skip past the splash before it is visible.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _navTimer = Timer(const Duration(milliseconds: 2800), _goLogin);
    });
  }

  Future<void> _goLogin() async {
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _enter.dispose();
    _breathe.dispose();
    _progress.dispose();
    _orb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
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
          AnimatedBuilder(
            animation: _orb,
            builder: (context, _) {
              final t = _orb.value * math.pi * 2;
              return Stack(
                children: [
                  Positioned(
                    top: -size.height * 0.1 + math.sin(t) * 10,
                    left: -size.width * 0.16 + math.cos(t * 0.8) * 12,
                    child: _SoftOrb(
                      diameter: size.width * 0.7,
                      color: const Color(0x33B08D57),
                    ),
                  ),
                  Positioned(
                    bottom: -size.height * 0.16 + math.cos(t) * 14,
                    right: -size.width * 0.18 + math.sin(t * 0.7) * 10,
                    child: _SoftOrb(
                      diameter: size.width * 0.78,
                      color: const Color(0x22A18F6A),
                    ),
                  ),
                ],
              );
            },
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: Listenable.merge([_enter, _breathe]),
                      builder: (context, child) {
                        final breath = 1 + (_breathe.value * 0.035);
                        return Opacity(
                          opacity: _markFade.value,
                          child: Transform.scale(
                            scale: _markScale.value * breath,
                            child: child,
                          ),
                        );
                      },
                      child: const BrandMark(size: 104),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _titleFade,
                      child: SlideTransition(
                        position: _titleSlide,
                        child: const Text(
                          AppStrings.appName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppColors.charcoal,
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeTransition(
                      opacity: _subFade,
                      child: Text(
                        AppStrings.orgName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate.withValues(alpha: 0.95),
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    FadeTransition(
                      opacity: _subFade,
                      child: SizedBox(
                        width: 120,
                        child: AnimatedBuilder(
                          animation: _bar,
                          builder: (context, _) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: _bar.value,
                                minHeight: 3.5,
                                backgroundColor:
                                    AppColors.gold.withValues(alpha: 0.16),
                                color: AppColors.gold,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FadeTransition(
                      opacity: _subFade,
                      child: Text(
                        'جاري التجهيز…',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftOrb extends StatelessWidget {
  const _SoftOrb({required this.diameter, required this.color});

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
