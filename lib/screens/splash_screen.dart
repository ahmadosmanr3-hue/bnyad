import 'dart:math';
import 'package:nutrify/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:nutrify/theme/app_theme.dart';
import 'package:nutrify/widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  final bool isDark;
  final String tagline;
  final String subline;
  final VoidCallback onComplete;

  const SplashScreen({
    super.key,
    required this.isDark,
    required this.tagline,
    required this.subline,
    required this.onComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgController;
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _exitController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoRotation;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;
  late final Animation<double> _sublineOpacity;
  late final Animation<Offset> _sublineSlide;
  late final Animation<double> _exitFade;

  final List<_FloatingOrb> _orbs = [];

  @override
  void initState() {
    super.initState();

    final rng = Random();
    for (int i = 0; i < 6; i++) {
      _orbs.add(
        _FloatingOrb(
          x: rng.nextDouble(),
          y: rng.nextDouble(),
          radius: 30 + rng.nextDouble() * 60,
          speed: 0.3 + rng.nextDouble() * 0.7,
          color: [
            ...AppTheme.splashOrbColors,
          ][i % AppTheme.splashOrbColors.length],
        ),
      );
    }

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoScale = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    _logoRotation = Tween(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _taglineOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _taglineSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _textController,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
          ),
        );
    _sublineOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
      ),
    );
    _sublineSlide = Tween(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _textController,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
          ),
        );
    _exitFade = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInCubic),
    );

    _startSequence();
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    await _exitController.forward();
    if (!mounted) return;
    widget.onComplete();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _logoController.dispose();
    _textController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _bgController,
        _logoController,
        _textController,
        _exitController,
      ]),
      builder: (context, _) {
        return Opacity(
          opacity: _exitFade.value.clamp(0.0, 1.0),
          child: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                // Gradient background
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? AppTheme.darkWelcomeGradient
                          : AppTheme.lightWelcomeGradient,
                    ),
                  ),
                ),

                // Floating orbs
                ..._orbs.map((orb) {
                  final t = _bgController.value * orb.speed;
                  final dx = orb.x * size.width + sin(t * 2 * pi) * 30;
                  final dy = orb.y * size.height + cos(t * 2 * pi + orb.x) * 25;
                  return Positioned(
                    left: dx - orb.radius / 2,
                    top: dy - orb.radius / 2,
                    child: Container(
                      width: orb.radius,
                      height: orb.radius,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            orb.color.withValues(alpha: isDark ? 0.15 : 0.2),
                            orb.color.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Center content
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated logo + title
                      Opacity(
                        opacity: _logoOpacity.value.clamp(0.0, 1.0),
                        child: Transform.rotate(
                          angle: _logoRotation.value,
                          child: Transform.scale(
                            scale: _logoScale.value.clamp(0.0, 1.2),
                            child: const AppBrandHeader(
                              logoSize: 110,
                              titleSize: 44,
                              spacing: 20,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Tagline
                      SlideTransition(
                        position: _taglineSlide,
                        child: Opacity(
                          opacity: _taglineOpacity.value.clamp(0.0, 1.0),
                          child: Text(
                            widget.tagline,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.9)
                                  : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Subline
                      SlideTransition(
                        position: _sublineSlide,
                        child: Opacity(
                          opacity: _sublineOpacity.value.clamp(0.0, 1.0),
                          child: Text(
                            widget.subline,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Bottom loading dots
                      Opacity(
                        opacity: _taglineOpacity.value.clamp(0.0, 1.0),
                        child: _LoadingDots(
                          controller: _bgController,
                          color: isDark
                              ? AppTheme.indigoLight
                              : AppTheme.indigo,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom branding bar
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: (_sublineOpacity.value * 0.5).clamp(0.0, 1.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.indigo.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations(
                            Localizations.localeOf(context).languageCode,
                          ).get('poweredByBnyad'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                            color: isDark
                                ? const Color(0xFF475569)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.indigo.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LoadingDots extends StatelessWidget {
  final AnimationController controller;
  final Color color;

  const _LoadingDots({required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final phase = (controller.value + i * 0.2) % 1.0;
        final scale = 0.5 + 0.5 * sin(phase * pi);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3 + scale * 0.7),
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _FloatingOrb {
  final double x;
  final double y;
  final double radius;
  final double speed;
  final Color color;

  _FloatingOrb({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.color,
  });
}
