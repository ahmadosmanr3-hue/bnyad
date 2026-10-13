import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/theme/app_theme.dart';

/// Opens the Medical Sources & Citations modal sheet.
Future<void> showMedicalCitationsModal(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const MedicalCitationsScreen(),
  );
}

class MedicalCitationsScreen extends StatelessWidget {
  const MedicalCitationsScreen({super.key});

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.read<AppState>().t.linkFailed)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.read<AppState>().t.linkFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = state.isDark;
    final t = state.t;

    final bg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final titleColor = isDark ? AppTheme.slate50 : AppTheme.slate900;
    final mutedColor = isDark ? AppTheme.slate400 : AppTheme.slate600;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final cardBorder = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    final citations = [
      _CitationItem(
        category: t.privacyMedicalSourcesBmrCategory,
        title: 'Mifflin–St Jeor Equation (1990)',
        authors:
            'Mifflin MD, St Jeor ST, Hill LA, Scott BJ, Daugherty SA, Koh YO',
        journal: 'The American Journal of Clinical Nutrition (51:2, 241-247)',
        description: t.privacyMedicalSourcesBmrDesc,
        url: 'https://pubmed.ncbi.nlm.nih.gov/2305711/',
      ),
      _CitationItem(
        category: t.privacyMedicalSourcesBmiCategory,
        title: 'WHO Body Mass Index (BMI) Standards',
        authors: 'World Health Organization (WHO)',
        journal: 'Global Health Observatory & WHO Technical Report Series',
        description: t.privacyMedicalSourcesBmiDesc,
        url:
            'https://www.who.int/data/gho/data/indicators/indicator-details/GHO/body-mass-index-(bmi)',
      ),
      _CitationItem(
        category: t.privacyMedicalSourcesBodyFatNavyCategory,
        title: 'US Navy Circumference Method (1984)',
        authors: 'Hodgdon LA, Beckett MB',
        journal: 'Naval Health Research Center Report No. 84-29',
        description: t.privacyMedicalSourcesBodyFatNavyDesc,
        url: 'https://apps.dtic.mil/sti/citations/ADA149170',
      ),
      _CitationItem(
        category: t.privacyMedicalSourcesBodyFatDeurenbergCategory,
        title: 'Deurenberg BMI Body Fat Formula (1991)',
        authors: 'Deurenberg P, Weststrate JA, Seidell JC',
        journal: 'British Journal of Nutrition (65:2, 105-114)',
        description: t.privacyMedicalSourcesBodyFatDeurenbergDesc,
        url: 'https://pubmed.ncbi.nlm.nih.gov/2043597/',
      ),
      _CitationItem(
        category: t.privacyMedicalSourcesMacrosCategory,
        title: 'ISSN Protein Position Stand & NIH DRI',
        authors:
            'Jäger R, Kerksick CM, Campbell BI, et al. / National Academies',
        journal:
            'Journal of the International Society of Sports Nutrition (14:20)',
        description: t.privacyMedicalSourcesMacrosDesc,
        url:
            'https://jissn.biomedcentral.com/articles/10.1186/s12970-017-0177-8',
      ),
      _CitationItem(
        category: t.privacyMedicalSourcesWaterCategory,
        title: 'EFSA Dietary Reference Values for Water (2010)',
        authors:
            'European Food Safety Authority (EFSA Panel on Dietetic Products)',
        journal: 'EFSA Journal 2010; 8(3):1459',
        description: t.privacyMedicalSourcesWaterDesc,
        url:
            'https://efsa.onlinelibrary.wiley.com/doi/10.2903/j.efsa.2010.1459',
      ),
      _CitationItem(
        category: t.privacyMedicalSourcesFoodDbCategory,
        title: 'Open Food Facts & USDA FoodData Central',
        authors:
            'Open Food Facts Organization / U.S. Department of Agriculture',
        journal: 'Global Open Nutritional Database',
        description: t.privacyMedicalSourcesFoodDbDesc,
        url: 'https://world.openfoodfacts.org/',
      ),
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.90,
      minChildSize: 0.50,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: cardBorder, width: 1),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 42,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.slate600 : AppTheme.slate300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.indigo.withValues(
                          alpha: isDark ? 0.25 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: AppTheme.indigo,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.privacyMedicalSourcesTitle,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t.privacyMedicalSourcesSubtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: mutedColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      color: mutedColor,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    // Disclaimer Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.amber.withValues(
                          alpha: isDark ? 0.15 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.amber.withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.health_and_safety_outlined,
                            color: AppTheme.amber,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.privacyMedicalDisclaimerTitle,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.amber,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  t.privacyMedicalDisclaimerBody,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.45,
                                    color: isDark
                                        ? AppTheme.slate200
                                        : AppTheme.slate700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Citations List
                    for (final item in citations) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.indigo.withValues(
                                  alpha: isDark ? 0.25 : 0.12,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.category,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.indigo,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.authors} — ${item.journal}',
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: mutedColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.description,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                color: isDark
                                    ? AppTheme.slate300
                                    : AppTheme.slate700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () => _launchURL(context, item.url),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.open_in_new_rounded,
                                      size: 15,
                                      color: AppTheme.indigo,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      t.privacyMedicalViewSourceLink,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.indigo,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CitationItem {
  final String category;
  final String title;
  final String authors;
  final String journal;
  final String description;
  final String url;

  const _CitationItem({
    required this.category,
    required this.title,
    required this.authors,
    required this.journal,
    required this.description,
    required this.url,
  });
}
