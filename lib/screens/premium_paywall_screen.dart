import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/screens/medical_citations_screen.dart';
import 'package:nutrify/theme/app_theme.dart';
import 'package:nutrify/utils/ai_strings.dart';

/// Opens the premium paywall as a modal bottom sheet.
Future<void> showPremiumPaywall(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PremiumPaywallSheet(),
  );
}

class _PremiumPaywallSheet extends StatefulWidget {
  const _PremiumPaywallSheet();

  @override
  State<_PremiumPaywallSheet> createState() => _PremiumPaywallSheetState();
}

class _PremiumPaywallSheetState extends State<_PremiumPaywallSheet> {
  String _selectedProductId = 'BNYAD_Y1';
  bool _loading = false;
  final Map<String, String> _prices = {};
  bool _aiAvailabilityChecked = false;
  bool? _aiAvailable;
  @override
  void initState() {
    super.initState();
    _loadPrices();
    _checkAiAvailability();
  }

  Future<void> _checkAiAvailability() async {
    final state = context.read<AppState>();
    await state.getAiConsent();
    if (!mounted) return;
    setState(() {
      _aiAvailable = state.aiServiceAvailable;
      _aiAvailabilityChecked = true;
    });
  }

  Future<void> _loadPrices() async {
    if (kIsWeb || !context.read<AppState>().supportsOptionalDeviceServices) {
      return;
    }
    try {
      final products = await Purchases.getProducts(['BNYAD_M1', 'BNYAD_Y1']);
      if (!mounted) return;
      setState(() {
        for (final p in products) {
          _prices[p.identifier] = p.priceString;
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.isDark;
    final t = state.t;

    final perks = <(_PerkIcon, String)>[
      (_PerkIcon.mealPlan, t.premiumPerkMealPlan),
      (_PerkIcon.scanner, t.premiumPerkScanner),
      (_PerkIcon.tips, t.premiumPerkAiTips),
      (_PerkIcon.nutrients, t.premiumPerkNutrients),
      (_PerkIcon.swap, t.premiumPerkSwapMeals),
      (_PerkIcon.recipes, t.premiumPerkRecipes),
    ];

    final bg = isDark ? const Color(0xFF0F1117) : Colors.white;
    final title = isDark ? AppTheme.slate50 : AppTheme.slate900;
    final muted = isDark ? AppTheme.slate400 : AppTheme.slate600;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark
                  ? AppTheme.slate700.withValues(alpha: 0.6)
                  : AppTheme.slate200,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.slate600 : AppTheme.slate300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Hero(isDark: isDark),
                      const SizedBox(height: 22),
                      Text(
                        t.premiumTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                          color: title,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.premiumSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (_aiAvailable != true) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.slate800
                                : AppTheme.slate100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            AiStrings.get(
                              state.lang,
                              !_aiAvailabilityChecked
                                  ? 'availabilityChecking'
                                  : _aiAvailable == false
                                  ? 'premiumAiPaused'
                                  : 'availabilityUnknown',
                            ),
                            style: TextStyle(color: title, height: 1.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Plan Selection Cards
                      _buildPlanCard(
                        productId: 'BNYAD_M1',
                        title: t.monthlyPlan,
                        price: _prices['BNYAD_M1'] ?? t.storePrice,
                        period: '',
                        description: t.monthlyBilling,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildPlanCard(
                        productId: 'BNYAD_Y1',
                        title: t.yearlyPlan,
                        price: _prices['BNYAD_Y1'] ?? t.storePrice,
                        period: '',
                        description: t.yearlyBilling,

                        isDark: isDark,
                      ),

                      const SizedBox(height: 26),
                      for (final (icon, label) in perks)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _PerkRow(
                            icon: icon,
                            label: label,
                            isDark: isDark,
                          ),
                        ),
                      const SizedBox(height: 18),
                      Text(
                        t.premiumFooterNote,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _ActivateButton(
                        state: state,
                        selectedProductId: _selectedProductId,
                        loading: _loading,
                        onLoadingChanged: (val) {
                          if (mounted) setState(() => _loading = val);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () async {
                                setState(() => _loading = true);
                                final success = await state.restorePurchases();
                                if (!mounted) return;
                                setState(() => _loading = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? t.restoreSuccess
                                            : state.purchaseVerificationPending
                                            ? t.purchaseVerificationPending
                                            : t.restoreNotFound,
                                      ),
                                    ),
                                  );
                                  if (success) Navigator.of(context).pop();
                                }
                              },
                        child: Text(
                          t.premiumRestore,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Subscription Legal Disclosure Text (Guideline 3.1.2c)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Text(
                          kIsWeb
                              ? t.get('webRenewal')
                              : defaultTargetPlatform == TargetPlatform.android
                              ? t.get('androidRenewal')
                              : t.subscriptionAutoRenewTerms,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.45,
                            color: muted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Functional Links: Privacy Policy, Terms of Use (EULA) & Medical Citations
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 6,
                        children: [
                          GestureDetector(
                            onTap: () => _launchURL(
                              'https://nutrify-api-lovat.vercel.app/terms',
                            ),
                            child: Text(
                              t.termsOfUseEula,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.indigo,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          Text(
                            '•',
                            style: TextStyle(color: muted, fontSize: 11),
                          ),
                          GestureDetector(
                            onTap: () => _launchURL(
                              'https://nutrify-api-lovat.vercel.app/privacy',
                            ),
                            child: Text(
                              t.privacyPolicy,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.indigo,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          Text(
                            '•',
                            style: TextStyle(color: muted, fontSize: 11),
                          ),
                          GestureDetector(
                            onTap: () => showMedicalCitationsModal(context),
                            child: Text(
                              t.medicalSourcesCitations,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.indigo,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        t.premiumComingSoon,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          color: muted.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchURL(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Widget _buildPlanCard({
    required String productId,
    required String title,
    required String price,
    required String period,
    required String description,
    String? badge,
    required bool isDark,
  }) {
    final isSelected = _selectedProductId == productId;
    final primaryColor = AppTheme.indigo;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedProductId = productId;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected
              ? primaryColor.withValues(alpha: isDark ? 0.08 : 0.04)
              : (isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.4)
                    : const Color(0xFFF8FAFC)),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (badge != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.indigo, AppTheme.violet],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        price,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isSelected
                              ? (isDark
                                    ? AppTheme.indigoLight
                                    : AppTheme.indigo)
                              : (isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B)),
                        ),
                      ),
                      Text(
                        period,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: -6,
              right: -6,
              child: isSelected
                  ? Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: isDark ? AppTheme.indigoLight : AppTheme.indigo,
                    )
                  : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppTheme.brandGradient,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.indigo.withValues(alpha: isDark ? 0.5 : 0.35),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(
          Icons.workspace_premium_rounded,
          size: 44,
          color: Colors.white,
        ),
      ),
    );
  }
}

enum _PerkIcon { mealPlan, scanner, tips, nutrients, swap, recipes }

extension on _PerkIcon {
  IconData get icon {
    switch (this) {
      case _PerkIcon.mealPlan:
        return Icons.restaurant_menu_rounded;
      case _PerkIcon.scanner:
        return Icons.qr_code_scanner_rounded;
      case _PerkIcon.tips:
        return Icons.auto_awesome_rounded;
      case _PerkIcon.nutrients:
        return Icons.biotech_rounded;
      case _PerkIcon.swap:
        return Icons.swap_horiz_rounded;
      case _PerkIcon.recipes:
        return Icons.menu_book_rounded;
    }
  }
}

class _PerkRow extends StatelessWidget {
  const _PerkRow({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  final _PerkIcon icon;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark
                ? AppTheme.indigo.withValues(alpha: 0.22)
                : AppTheme.indigo.withValues(alpha: 0.12),
          ),
          child: Icon(
            icon.icon,
            size: 20,
            color: isDark ? AppTheme.indigoLight : AppTheme.indigoDark,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.4,
              color: isDark ? AppTheme.slate100 : AppTheme.slate800,
            ),
          ),
        ),
        Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: isDark ? AppTheme.emerald : AppTheme.emeraldDeep,
        ),
      ],
    );
  }
}

class _ActivateButton extends StatelessWidget {
  const _ActivateButton({
    required this.state,
    required this.selectedProductId,
    required this.loading,
    required this.onLoadingChanged,
  });

  final AppState state;
  final String selectedProductId;
  final bool loading;
  final ValueChanged<bool> onLoadingChanged;

  @override
  Widget build(BuildContext context) {
    final isPremium = state.isPremium;
    final t = state.t;

    return ElevatedButton.icon(
      onPressed: loading
          ? null
          : () async {
              if (isPremium) {
                onLoadingChanged(true);
                await launchUrl(
                  Uri.parse(
                    defaultTargetPlatform == TargetPlatform.android
                        ? 'https://play.google.com/store/account/subscriptions'
                        : 'https://apps.apple.com/account/subscriptions',
                  ),
                  mode: LaunchMode.externalApplication,
                );
                onLoadingChanged(false);
                if (context.mounted) Navigator.of(context).pop();
              } else {
                onLoadingChanged(true);
                final success = await state.purchasePremium(
                  productId: selectedProductId,
                );
                onLoadingChanged(false);
                if (context.mounted) {
                  if (!success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.purchaseVerificationPending
                              ? state.t.purchaseVerificationPending
                              : state.t.purchaseFailed,
                        ),
                      ),
                    );
                  } else {
                    Navigator.of(context).pop();
                  }
                }
              }
            },
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(
              isPremium
                  ? Icons.lock_outline_rounded
                  : Icons.workspace_premium_rounded,
              size: 18,
            ),
      label: Text(isPremium ? t.manageSubscription : t.premiumActivate),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.indigo,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        textStyle: const TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontFamilyFallback: AppTheme.fontFamilyFallback,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        shadowColor: AppTheme.indigo.withValues(alpha: 0.45),
      ),
    );
  }
}
