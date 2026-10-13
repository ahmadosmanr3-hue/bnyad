import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nutrify/l10n/app_localizations.dart';
import 'package:nutrify/navigation/main_shell_tabs.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/theme/app_theme.dart';

/// Floating dock with a raised center hub for Dashboard; other tabs sit in two side groups.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.t,
    required this.isDark,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final AppLocalizations t;
  final bool isDark;

  static const double _barHeight = 56;
  static const double _hubSize = 58;
  static const double _stackHeight = _barHeight + 24;

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<AppState>().hasPremiumFeatures;
    final items = <_NavSpec>[
      _NavSpec(Icons.settings_outlined, Icons.settings_rounded, t.settings),
      _NavSpec(
        Icons.restaurant_outlined,
        Icons.restaurant_rounded,
        t.foodLog,
      ),
      _NavSpec(Icons.dashboard_outlined, Icons.dashboard_rounded, t.dashboard),
      _NavSpec(
        Icons.add_circle_outline,
        Icons.add_circle_rounded,
        t.mealPlan,
        locked: !isPremium,
      ),
      _NavSpec(
        Icons.camera_alt_outlined,
        Icons.camera_alt_rounded,
        t.foodScanner,
        locked: !isPremium,
      ),
    ];

    /// Fills the system bottom inset so nothing “shows through” under the dock.
    final shelfColor =
        isDark ? AppTheme.navy900 : AppTheme.lightNavShelf;

    final barFill = isDark ? AppTheme.navy800 : Colors.white;
    final barBorder = isDark
        ? AppTheme.slate700.withValues(alpha: 0.65)
        : AppTheme.slate300;

    void tap(int i) {
      HapticFeedback.selectionClick();
      onDestinationSelected(i);
    }

    return Material(
      color: shelfColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.zero,
          child: SizedBox(
            height: _stackHeight,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _barHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: barFill,
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: barBorder, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.55)
                              : AppTheme.slate900.withValues(alpha: 0.10),
                          blurRadius: isDark ? 24 : 20,
                          offset: const Offset(0, 10),
                          spreadRadius: -2,
                        ),
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.25)
                              : AppTheme.indigo.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Expanded(
                                child: _DockTile(
                                  spec: items[0],
                                  selected: selectedIndex == 0,
                                  isDark: isDark,
                                  onTap: () => tap(0),
                                ),
                              ),
                              Expanded(
                                child: _DockTile(
                                  spec: items[1],
                                  selected: selectedIndex == 1,
                                  isDark: isDark,
                                  onTap: () => tap(1),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: _hubSize + 4),
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Expanded(
                                child: _DockTile(
                                  spec: items[3],
                                  selected: selectedIndex == 3,
                                  isDark: isDark,
                                  onTap: () => tap(3),
                                ),
                              ),
                              Expanded(
                                child: _DockTile(
                                  spec: items[4],
                                  selected: selectedIndex == 4,
                                  isDark: isDark,
                                  onTap: () => tap(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: _barHeight - _hubSize / 2,
                  child: Center(
                    child: _DashboardHub(
                      spec: items[MainShellTab.dashboard],
                      selected: selectedIndex == MainShellTab.dashboard,
                      isDark: isDark,
                      size: _hubSize,
                      onTap: () => tap(MainShellTab.dashboard),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec(this.outline, this.filled, this.label, {this.locked = false});
  final IconData outline;
  final IconData filled;
  final String label;
  final bool locked;
}

class _DashboardHub extends StatelessWidget {
  const _DashboardHub({
    required this.spec,
    required this.selected,
    required this.isDark,
    required this.size,
    required this.onTap,
  });

  final _NavSpec spec;
  final bool selected;
  final bool isDark;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected
        ? Colors.white
        : (isDark ? AppTheme.slate100 : AppTheme.slate800);

    return Semantics(
      button: true,
      selected: selected,
      label: spec.label,
      child: Material(
        color: Colors.transparent,
        elevation: selected ? 10 : 6,
        shadowColor: isDark
            ? Colors.black.withValues(alpha: 0.5)
            : AppTheme.indigo.withValues(alpha: 0.35),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          splashColor: AppTheme.indigo.withValues(alpha: 0.15),
          highlightColor: AppTheme.indigo.withValues(alpha: 0.08),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: selected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppTheme.brandGradient,
                    )
                  : null,
              color: selected
                  ? null
                  : (isDark ? AppTheme.navy750 : Colors.white),
              border: Border.all(
                color: selected
                    ? Colors.white.withValues(alpha: 0.45)
                    : (isDark
                        ? AppTheme.indigoLight.withValues(alpha: 0.55)
                        : AppTheme.indigo.withValues(alpha: 0.55)),
                width: selected ? 2.5 : 2,
              ),
            ),
            child: Icon(
              selected ? spec.filled : spec.outline,
              size: selected ? 30 : 26,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _DockTile extends StatelessWidget {
  const _DockTile({
    required this.spec,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final _NavSpec spec;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inactive = isDark ? AppTheme.slate400 : AppTheme.slate600;
    final active = isDark ? AppTheme.indigoLight : AppTheme.indigoDark;

    return Semantics(
      button: true,
      selected: selected,
      label: spec.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppTheme.indigo.withValues(alpha: isDark ? 0.18 : 0.14),
          highlightColor: AppTheme.indigo.withValues(alpha: isDark ? 0.08 : 0.06),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 10 : 6,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: selected
                    ? (isDark
                        ? AppTheme.indigo.withValues(alpha: 0.28)
                        : AppTheme.indigo.withValues(alpha: 0.14))
                    : null,
                border: selected
                    ? Border.all(
                        color: isDark
                            ? AppTheme.indigoLight.withValues(alpha: 0.45)
                            : AppTheme.indigo.withValues(alpha: 0.45),
                        width: 1.25,
                      )
                    : null,
                boxShadow: selected && !isDark
                    ? [
                        BoxShadow(
                          color: AppTheme.indigo.withValues(alpha: 0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: AnimatedScale(
                scale: selected ? 1.06 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      selected ? spec.filled : spec.outline,
                      size: selected ? 25 : 23,
                      color: selected ? active : inactive,
                    ),
                    if (spec.locked)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.indigo,
                            border: Border.all(
                              color: isDark
                                  ? AppTheme.navy800
                                  : Colors.white,
                              width: 1.4,
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 8,
                            color: Colors.white,
                          ),
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
