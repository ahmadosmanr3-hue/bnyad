import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nutrify/constants/app_branding.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/screens/login_screen.dart';
import 'package:nutrify/theme/app_theme.dart';
import 'package:nutrify/widgets/app_logo.dart';

/// Full-screen prompt when a guest tries to open a registered-only feature.
class LoginRequiredScreen extends StatelessWidget {
  const LoginRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    final isDark = state.isDark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? AppTheme.darkWelcomeGradient
                      : AppTheme.lightWelcomeGradient,
                ),
          color: isDark ? AppTheme.navy900 : null,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                const Spacer(),
                const AppBrandHeader(logoSize: 88, titleSize: 28, spacing: 14),
                Text(
                  t.loginRequiredTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  t.loginRequiredSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push<void>(
                        MaterialPageRoute<void>(
                          builder: (_) => const LoginScreen(fromGuestUpgrade: true),
                        ),
                      );
                      if (context.mounted && context.read<AppState>().isAuthenticated) {
                        Navigator.of(context).pop();
                      }
                    },
                    icon: const Icon(Icons.login_rounded),
                    label: Text(t.loginRequiredCta),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppBranding.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
