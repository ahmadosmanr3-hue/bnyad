import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/screens/premium_paywall_screen.dart';
import 'package:nutrify/theme/app_theme.dart';

/// Helper guard: runs [onAllowed] if the user is premium, otherwise opens the
/// paywall sheet. Use for AI buttons, locked actions, etc.
Future<void> guardPremium(BuildContext context, VoidCallback onAllowed) async {
  final state = context.read<AppState>();
  debugPrint('[Premium Guard check] User has premium features: ${state.hasPremiumFeatures}');
  if (state.hasPremiumFeatures) {
    onAllowed();
    return;
  }
  await showPremiumPaywall(context);
}

/// Wraps a child and locks it behind premium.
///
/// - [PremiumGate.block]   - keeps the child visible but blurred + intercepts
///   taps to open the paywall (use for whole tabs / large sections).
/// - [PremiumGate.inline]  - replaces the child with a compact lock card
///   (use in place of small dashboard tiles / settings rows).
class PremiumGate extends StatelessWidget {
  const PremiumGate._({
    required _PremiumGateVariant variant,
    required this.child,
    this.title,
    this.subtitle,
  }) : _variant = variant;

  /// Cover [child] with a frosted lock overlay.
  factory PremiumGate.block({
    String? title,
    String? subtitle,
    required Widget child,
  }) =>
      PremiumGate._(
        variant: _PremiumGateVariant.block,
        title: title,
        subtitle: subtitle,
        child: child,
      );

  /// Replace [child] entirely with a compact lock card.
  factory PremiumGate.inline({
    String? title,
    String? subtitle,
    required Widget child,
  }) =>
      PremiumGate._(
        variant: _PremiumGateVariant.inline,
        title: title,
        subtitle: subtitle,
        child: child,
      );

  final Widget child;
  final _PremiumGateVariant _variant;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    debugPrint('[PremiumGate build] Checking feature status: hasPremiumFeatures = ${state.hasPremiumFeatures}');
    if (state.hasPremiumFeatures) return child;

    final isDark = state.isDark;
    final t = state.t;

    if (_variant == _PremiumGateVariant.inline) {
      return _InlineLockCard(
        isDark: isDark,
        title: title ?? t.premiumLocked,
        subtitle: subtitle ?? t.premiumUnlockCta,
        onTap: () => showPremiumPaywall(context),
      );
    }

    return _BlockLockOverlay(
      isDark: isDark,
      title: title ?? t.premiumLocked,
      subtitle: subtitle ?? t.premiumSubtitle,
      ctaLabel: t.premiumUnlockCta,
      onTap: () => showPremiumPaywall(context),
      child: child,
    );
  }
}

enum _PremiumGateVariant { block, inline }

class _InlineLockCard extends StatelessWidget {
  const _InlineLockCard({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool isDark;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.indigo.withValues(alpha: isDark ? 0.28 : 0.14),
                AppTheme.violet.withValues(alpha: isDark ? 0.20 : 0.10),
              ],
            ),
            border: Border.all(
              color: isDark
                  ? AppTheme.indigoLight.withValues(alpha: 0.45)
                  : AppTheme.indigo.withValues(alpha: 0.40),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? AppTheme.indigo.withValues(alpha: 0.30)
                      : AppTheme.indigo.withValues(alpha: 0.18),
                ),
                child: Icon(
                  Icons.lock_rounded,
                  size: 18,
                  color: isDark ? AppTheme.indigoLight : AppTheme.indigoDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: isDark ? AppTheme.slate50 : AppTheme.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.slate400 : AppTheme.slate600,
                      ),
                    ),
                  ],
                ),
              ),
              const PremiumBadge(),
            ],
          ),
        ),
      ),
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
        // Underlying screen, dimmed and non-interactive.
        IgnorePointer(
          ignoring: true,
          child: Opacity(opacity: 0.45, child: child),
        ),
        // Frosted veil
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              color: (isDark ? Colors.black : Colors.white)
                  .withValues(alpha: 0.55),
            ),
          ),
        ),
        // Centered call-to-action.
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
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppTheme.brandGradient,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.indigo.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
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
                  icon: const Icon(Icons.lock_open_rounded, size: 18),
                  label: Text(ctaLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 14,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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

/// Small "PREMIUM" pill, used inside lock cards and on Settings rows.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppState>().t;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: AppTheme.brandGradient,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: compact ? 10 : 12,
            color: Colors.white,
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            t.premiumBadge,
            style: TextStyle(
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
