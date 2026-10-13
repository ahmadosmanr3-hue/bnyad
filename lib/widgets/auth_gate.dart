import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/screens/login_required_screen.dart';
import 'package:nutrify/theme/app_theme.dart';

/// Runs [onAllowed] for signed-in users (registered or guest).
Future<void> guardAuth(BuildContext context, VoidCallback onAllowed) async {
  final state = context.read<AppState>();
  if (state.isLoggedIn) {
    onAllowed();
    return;
  }
  await showLoginRequired(context);
}

Future<void> showLoginRequired(BuildContext context) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const LoginRequiredScreen(),
    ),
  );
}

/// Locks content behind a registered account (guests see a login prompt).
class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
  });

  const AuthGate.block({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
  });

  final Widget child;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.isLoggedIn) return child;

    final isDark = state.isDark;
    final t = state.t;

    return _BlockLockOverlay(
      isDark: isDark,
      title: title ?? t.loginRequiredTitle,
      subtitle: subtitle ?? t.loginRequiredSubtitle,
      ctaLabel: t.loginRequiredCta,
      onTap: () => showLoginRequired(context),
      child: child,
    );
  }
}

class _BlockLockOverlay extends StatelessWidget {
  const _BlockLockOverlay({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onTap,
    required this.child,
  });

  final bool isDark;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          ignoring: true,
          child: Opacity(opacity: 0.45, child: child),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.55),
            ),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.indigo.withValues(alpha: isDark ? 0.9 : 1),
                        AppTheme.violet.withValues(alpha: isDark ? 0.85 : 1),
                      ],
                    ),
                  ),
                  child: const Icon(Icons.login_rounded, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.slate50 : AppTheme.slate900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    color: isDark ? AppTheme.slate300 : AppTheme.slate600,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.person_rounded, size: 18),
                  label: Text(ctaLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
