import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/models/log_entry.dart';
import 'package:nutrify/models/food_item.dart';
import 'package:nutrify/models/favorite_template.dart';
import 'package:nutrify/constants/food_group_registry.dart';
import 'package:nutrify/constants/food_serving_switch.dart';
import 'package:nutrify/navigation/main_shell_tabs.dart';
import 'package:nutrify/theme/app_theme.dart';
import 'package:nutrify/widgets/barcode_scan_flow.dart';
import 'package:nutrify/utils/meat_bone_adjustment.dart';
import 'package:nutrify/utils/micro_nutrient_calculator.dart';
import 'package:nutrify/utils/responsive.dart';

class FoodLogScreen extends StatefulWidget {
  const FoodLogScreen({super.key});

  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  AppState? _appState;
  bool _listenerAttached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_listenerAttached) return;
    _listenerAttached = true;
    _appState = context.read<AppState>();
    _appState!.addListener(_onAppStateChanged);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _tryOpenFoodLogIntent(),
    );
  }

  void _onAppStateChanged() {
    _tryOpenFoodLogIntent();
  }

  void _tryOpenFoodLogIntent() {
    final s = _appState;
    if (s == null || !mounted) return;
    if (s.activeTab != MainShellTab.foodLog || !s.openAddFoodSheet) return;
    final mealId = s.pendingLogMealId;
    s.consumeFoodLogIntent();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showAddFoodSheet(context, s, mealId: mealId);
    });
  }

  @override
  void dispose() {
    _appState?.removeListener(_onAppStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    final isDark = state.isDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.foodLog,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    color: isDark ? AppTheme.slate50 : AppTheme.slate900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddFoodSheet(context, state),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    t.addFood,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => openBarcodeScanFlow(context, state: state),
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: Text(
                    t.scanBarcode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(
                      color: isDark
                          ? AppTheme.cyan.withValues(alpha: 0.5)
                          : AppTheme.indigo.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showFavoritesSheet(context, state),
                  icon: const Icon(Icons.star_outline, size: 18),
                  label: Text(
                    t.favorites,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(
                      color: isDark ? AppTheme.slate700 : AppTheme.slate200,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: state.dailyLog.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 48,
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t.noEntries,
                          style: TextStyle(
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: state.dailyLog.length,
                    itemBuilder: (context, index) {
                      final entry = state.dailyLog[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    const Color(0xFF1A1D28),
                                    const Color(0xFF12141C),
                                  ]
                                : [Colors.white, const Color(0xFFF5F2ED)],
                          ),
                          border: Border.all(
                            color: isDark
                                ? AppTheme.slate700.withValues(alpha: 0.85)
                                : AppTheme.slate200,
                          ),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF5C5348,
                                    ).withValues(alpha: 0.05),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.indigo.withValues(alpha: 0.2)
                                    : AppTheme.lightSurfaceTint,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.restaurant,
                                size: 20,
                                color: isDark
                                    ? AppTheme.indigoLight
                                    : AppTheme.indigo,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    '${entry.amount.round()} ${t.grams} • ${entry.calories.round()} ${t.kcal}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 18,
                                color: isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFFCBD5E1),
                              ),
                              onPressed: () => state.removeLogEntry(entry.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddFoodSheet(
    BuildContext context,
    AppState state, {
    String? mealId,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FoodSearchSheet(
        state: state,
        mealId: mealId,
        onScanBarcode: () {
          Navigator.pop(ctx);
          openBarcodeScanFlow(context, state: state, mealId: mealId);
        },
      ),
    );
  }

  void _showFavoritesSheet(BuildContext context, AppState state) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FavoritesSheet(state: state),
    );
  }
}

class _FavoritesSheet extends StatelessWidget {
  final AppState state;
  const _FavoritesSheet({required this.state});

  @override
  Widget build(BuildContext context) {
    final t = state.t;
    final isDark = state.isDark;
    final list = state.favorites;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.favorites,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            t.noFavorites,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final f = list[i];
                          return Dismissible(
                            key: Key(f.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (_) => state.removeFavorite(f.id),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsetsDirectional.only(
                                end: 16,
                              ),
                              color: AppTheme.rose.withValues(alpha: 0.12),
                              child: const Icon(
                                Icons.delete_outline,
                                color: AppTheme.rose,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 4,
                              ),
                              title: Text(
                                f.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              subtitle: Text(
                                '${f.amount.round()} ${t.grams} · ${f.calories.round()} ${t.kcal}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.add_circle,
                                  color: isDark
                                      ? AppTheme.indigoLight
                                      : AppTheme.indigo,
                                ),
                                onPressed: () async {
                                  await state.logFromFavorite(f);
                                  if (context.mounted) Navigator.pop(context);
                                },
                              ),
                              onTap: () async {
                                await state.logFromFavorite(f);
                                if (context.mounted) Navigator.pop(context);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FoodSearchSheet extends StatefulWidget {
  final AppState state;
  final String? mealId;
  final VoidCallback? onScanBarcode;
  const _FoodSearchSheet({
    required this.state,
    this.mealId,
    this.onScanBarcode,
  });

  @override
  State<_FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends State<_FoodSearchSheet> {
  String _search = '';
  String? _selectedCategory;
  FoodPickGroup? _prepGroup;
  FoodPickGroup? _rootPrepGroup;
  bool _detailFromPrepStep = false;
  FoodItem? _selected;
  FoodServingMode _amountMode = FoodServingMode.grams;
  double _amount = 100;
  int _pieceCount = 1;
  int _bowlCount = 1;
  bool _withBones = false;

  static String _weightFieldText(double w) {
    try {
      if (!w.isFinite) return '?';
      if (w == w.roundToDouble()) return '${w.round()}';
      return w.toStringAsFixed(1);
    } catch (_) {
      return '?';
    }
  }

  /// Web hot reload can leave doubles invalid; avoids `.round()` on undefined/NaN.
  double _sanitizeGrams(double g) {
    try {
      if (!g.isFinite || g <= 0) return 100.0;
      return g.clamp(1.0, 100000.0);
    } catch (_) {
      return 100.0;
    }
  }

  double _macroRatioSafe(FoodItem food, double totalGrams) {
    final ref = food.nutritionReferenceG;
    try {
      if (!totalGrams.isFinite || !ref.isFinite || ref <= 0) return 0.0;
      final base = totalGrams / ref;
      return base * meatLogMacroMultiplier(food, withBones: _withBones);
    } catch (_) {
      return 1.0;
    }
  }

  int _safePieceCount() {
    try {
      final c = _pieceCount;
      if (c < 1) return 1;
      if (c > 1000) return 1000;
      return c;
    } catch (_) {
      return 1;
    }
  }

  int _safeBowlCount() {
    try {
      final c = _bowlCount;
      if (c < 1) return 1;
      if (c > 1000) return 1000;
      return c;
    } catch (_) {
      return 1;
    }
  }

  int _roundGramsDisplay(double g) {
    try {
      if (!g.isFinite) return 100;
      return g.round().clamp(0, 1000000000);
    } catch (_) {
      return 100;
    }
  }

  /// Piece: foods with a real piece/scoop/bowl weight, plus breads.
  bool _canPieceFor(FoodItem f) {
    if (f.usesDiscreteUnitsOnly) return true;
    if (kurdishHasPieceMode(f)) return true;
    if (f.category == 'Bread') return true;
    if (f.category == 'FastFood' || f.category == 'Supplement') {
      return defaultPieceGramsFor(f) != null;
    }
    return false;
  }

  /// Gram slider: disabled for foods that are defined only per piece/slice (bakery `bf*p` / `bf*s`).
  bool _canGramsFor(FoodItem f) => !f.usesDiscreteUnitsOnly;

  /// Piece/slice-only rows always use piece mode in the sheet (never the gram slider).
  FoodServingMode _effectiveServingMode(FoodItem selected) {
    if (selected.usesDiscreteUnitsOnly) return FoodServingMode.piece;
    return _amountMode;
  }

  /// Bowl: only Kurdish dishes with a real bowl line (rice, qara, etc.). No generic 150g bowl for other foods.
  bool _canBowlFor(FoodItem f) => kurdishHasBowlMode(f);

  static const _categories = [
    'Kurdish',
    'Bread',
    'RiceDishes',
    'Soup',
    'Arabic',
    'Protein',
    'Dairy',
    'Grains',
    'Fruit',
    'Vegetable',
    'Nuts',
    'Legumes',
    'International',
    'FastFood',
    'Supplement',
    'Beverage',
    'Snacks',
    'Oil',
  ];

  static const _categoryIcons = {
    'Kurdish': Icons.restaurant,
    'Bread': Icons.bakery_dining,
    'RiceDishes': Icons.rice_bowl,
    'Soup': Icons.soup_kitchen,
    'Arabic': Icons.restaurant_menu,
    'Protein': Icons.egg_alt,
    'Dairy': Icons.water_drop,
    'Grains': Icons.grain,
    'Fruit': Icons.apple,
    'Vegetable': Icons.eco,
    'Nuts': Icons.spa,
    'Legumes': Icons.grass,
    'International': Icons.public,
    'FastFood': Icons.fastfood,
    'Supplement': Icons.fitness_center,
    'Beverage': Icons.local_cafe,
    'Snacks': Icons.cookie,
    'Oil': Icons.opacity,
  };

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final t = state.t;
    final isDark = state.isDark;
    var filtered = foodsForFoodLogBrowse().where((row) {
      if (!foodBrowseRowMatchesCategory(row, _selectedCategory)) return false;
      return row.matchesQuery(_search);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _selected != null
                  ? _buildDetail(t, isDark, state)
                  : (_prepGroup != null
                        ? _buildPrepPicker(t, isDark)
                        : _buildSearch(t, isDark, filtered)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(dynamic t, bool isDark, List<FoodBrowseRow> filtered) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t.addFood,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        if (widget.mealId != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.indigo.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppTheme.indigo.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: isDark ? AppTheme.indigoLight : AppTheme.indigoDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    t.mealSlotLabel(widget.mealId!),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppTheme.indigoLight
                          : AppTheme.indigoDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (widget.onScanBarcode != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onScanBarcode,
              icon: const Icon(Icons.qr_code_scanner, size: 22),
              label: Text(t.scanBarcode),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(
                  color: AppTheme.indigo.withValues(
                    alpha: isDark ? 0.45 : 0.35,
                  ),
                ),
              ),
            ),
          ),
        if (widget.onScanBarcode != null) const SizedBox(height: 12),
        TextField(
          onChanged: (v) => setState(() => _search = v),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
            hintText: t.searchFood,
          ),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _categoryChip(null, t.browseFoods, Icons.apps, isDark),
              const SizedBox(width: 8),
              ..._categories.map(
                (cat) => Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: _categoryChip(
                    cat,
                    widget.state.t.getCategory(cat),
                    _categoryIcons[cat] ?? Icons.restaurant,
                    isDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.noEntries,
                        style: TextStyle(
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final row = filtered[i];
                    final food = row.displayFood;
                    final hasPrep =
                        row.group != null && row.group!.options.length > 1;
                    return GestureDetector(
                      onTap: () {
                        if (hasPrep) {
                          setState(() {
                            _rootPrepGroup = row.group;
                            _prepGroup = row.group;
                          });
                        } else {
                          _openFoodDetail(food);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFF1F5F9),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    row.nameForLang(widget.state.lang),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.state.t.getCategory(food.category),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF64748B),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  if (hasPrep)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        widget.state.t.choosePreparationHint,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppTheme.indigoLight
                                              : AppTheme.indigo,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (hasPrep)
                              Icon(
                                Icons.chevron_right,
                                color: isDark
                                    ? AppTheme.slate500
                                    : AppTheme.slate600,
                              )
                            else
                              Text(
                                '${browseDisplayCalories(food)} ${widget.state.t.kcal}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openPrepOption(FoodGroupOption opt, FoodPickGroup group) {
    if (opt.opensSubGroup && group.subGroups != null) {
      final sub = group.subGroups![opt.subGroupKey!];
      if (sub != null) {
        setState(() => _prepGroup = sub);
        return;
      }
    }
    final food = foodById(opt.foodId);
    if (food != null) _openFoodDetail(food, fromPrepStep: true);
  }

  void _popPrepPicker() {
    setState(() {
      if (_rootPrepGroup != null && _prepGroup != _rootPrepGroup) {
        _prepGroup = _rootPrepGroup;
      } else {
        _prepGroup = null;
        _rootPrepGroup = null;
      }
    });
  }

  void _openFoodDetail(FoodItem food, {bool fromPrepStep = false}) {
    final resolved = foodById(food.id) ?? food;
    setState(() {
      _detailFromPrepStep = fromPrepStep;
      if (!fromPrepStep) {
        _prepGroup = null;
        _rootPrepGroup = null;
      }
      _selected = resolved;
      final usePiece =
          resolved.usesDiscreteUnitsOnly ||
          (prefersPieceDefaultServing(resolved) &&
              kurdishHasPieceMode(resolved));
      _amountMode = usePiece ? FoodServingMode.piece : FoodServingMode.grams;
      _amount = defaultGramAmountFor(resolved).clamp(10, 1000);
      _pieceCount = 1;
      _bowlCount = 1;
      _withBones = false;
    });
  }

  Widget _buildPrepPicker(dynamic t, bool isDark) {
    final group = _prepGroup!;
    final lang = widget.state.lang;
    final isSubStep = _rootPrepGroup != null && group != _rootPrepGroup;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(
                widget.state.isRTL ? Icons.chevron_right : Icons.chevron_left,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
              onPressed: _popPrepPicker,
            ),
            Expanded(
              child: Text(
                isSubStep
                    ? group.titleForLang(lang)
                    : (_rootPrepGroup ?? group).titleForLang(lang),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isSubStep ? t.choosePreparation : t.chooseOilStep,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: group.options.length,
            itemBuilder: (_, i) {
              final opt = group.options[i];
              final food = opt.opensSubGroup ? null : foodById(opt.foodId);
              final kcal = food?.calories.round() ?? 0;
              final servingNote =
                  food?.servingLabelForLang(lang) ??
                  (food?.nutritionReferenceG == 100
                      ? '100g'
                      : '${food?.nutritionReferenceG.round()}g');
              return GestureDetector(
                onTap: () => _openPrepOption(opt, group),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          opt.labelForLang(lang),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      if (opt.opensSubGroup)
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: isDark ? AppTheme.slate500 : AppTheme.slate600,
                        )
                      else
                        Text(
                          '$kcal ${t.kcal} / $servingNote',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      if (!opt.opensSubGroup) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: isDark ? AppTheme.slate500 : AppTheme.slate600,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _categoryChip(
    String? category,
    String label,
    IconData icon,
    bool isDark,
  ) {
    final isActive = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.indigo
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppTheme.indigo
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive
                  ? Colors.white
                  : (isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive
                    ? Colors.white
                    : (isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _totalGramsForSelection(FoodItem selected) {
    final mode = _effectiveServingMode(selected);
    double raw;
    switch (mode) {
      case FoodServingMode.grams:
        raw = _amount;
        break;
      case FoodServingMode.piece:
        final food = foodForServingMode(selected, mode);
        raw = food.nutritionReferenceG * _safePieceCount();
        break;
      case FoodServingMode.bowl:
        final bowlFood = foodForServingMode(selected, FoodServingMode.bowl);
        raw = bowlFood.nutritionReferenceG * _safeBowlCount();
        break;
    }
    return _sanitizeGrams(raw);
  }

  Widget _buildDetail(dynamic t, bool isDark, AppState state) {
    final selected = _selected!;
    final mode = _effectiveServingMode(selected);
    final food = foodForServingMode(selected, mode);
    final totalGrams = _totalGramsForSelection(selected);
    final ratio = _macroRatioSafe(food, totalGrams);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(
                state.isRTL ? Icons.chevron_right : Icons.chevron_left,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
              onPressed: () {
                if (_detailFromPrepStep && _prepGroup != null) {
                  setState(() => _selected = null);
                } else {
                  setState(() {
                    _selected = null;
                    _prepGroup = null;
                    _rootPrepGroup = null;
                    _detailFromPrepStep = false;
                  });
                }
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.mealId != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        t.mealSlotLabel(widget.mealId!),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.indigo.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  Text(
                    _rootPrepGroup?.titleForLang(state.lang) ??
                        food.getLocalizedName(state.lang),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  if (_rootPrepGroup != null || _prepGroup != null)
                    Text(
                      food.getLocalizedName(state.lang),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: t.saveAsFavorite,
              icon: Icon(
                Icons.star_outline,
                color: isDark ? AppTheme.indigoLight : AppTheme.indigo,
              ),
              onPressed: () async {
                final totalGrams = _totalGramsForSelection(selected);
                final ratio = _macroRatioSafe(food, totalGrams);
                final boneMult = meatLogMacroMultiplier(
                  food,
                  withBones: _withBones,
                );
                await state.addFavorite(
                  FavoriteTemplate(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name:
                        food.getLocalizedName(state.lang) +
                        meatBoneSuffixForLang(
                          state.lang,
                          withBones: _withBones,
                        ),
                    foodId: food.id,
                    amount: totalGrams,
                    calories: food.calories * ratio,
                    protein: food.protein * ratio,
                    carbs: food.carbs * ratio,
                    fat: food.fat * ratio,
                    micros: scaleMicrosFromFood(
                      food,
                      totalGrams,
                      boneMult: boneMult,
                    ),
                  ),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(t.savedFavorite)));
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _modeButton(
                t.byGrams,
                mode == FoodServingMode.grams,
                _canGramsFor(selected)
                    ? () => setState(() => _amountMode = FoodServingMode.grams)
                    : null,
                isDark,
                enabled: _canGramsFor(selected),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _modeButton(
                t.byPiece,
                mode == FoodServingMode.piece,
                _canPieceFor(selected)
                    ? () => setState(() => _amountMode = FoodServingMode.piece)
                    : null,
                isDark,
                enabled: _canPieceFor(selected),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _modeButton(
                t.byBowl,
                mode == FoodServingMode.bowl,
                _canBowlFor(selected)
                    ? () => setState(() => _amountMode = FoodServingMode.bowl)
                    : null,
                isDark,
                enabled: _canBowlFor(selected),
              ),
            ),
          ],
        ),
        if (meatSupportsBoneChoice(food)) ...[
          const SizedBox(height: 14),
          Text(
            t.bonePortionLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _modeButton(
                  t.bonelessPortion,
                  !_withBones,
                  () => setState(() => _withBones = false),
                  isDark,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _modeButton(
                  t.withBonesPortion,
                  _withBones,
                  () => setState(() => _withBones = true),
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            t.bonePortionHint,
            style: TextStyle(
              fontSize: 11,
              height: 1.35,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
        const SizedBox(height: 16),

        if (mode == FoodServingMode.grams) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  '${t.amount} (${t.grams})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: scaleDownText(
                  '${_roundGramsDisplay(_amount)} ${t.grams}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.indigo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _amount,
            min: 10,
            max: 1000,
            divisions: 99,
            activeColor: AppTheme.indigo,
            inactiveColor: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF1F5F9),
            onChanged: (v) => setState(() => _amount = v),
          ),
        ] else if (mode == FoodServingMode.piece) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.perPiece,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        '${_weightFieldText(food.nutritionReferenceG)} ${t.grams}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    t.pieces,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _counterBtn('-', () {
                        if (_pieceCount > 1) setState(() => _pieceCount--);
                      }, isDark),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '$_pieceCount',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.indigo,
                          ),
                        ),
                      ),
                      _counterBtn(
                        '+',
                        () => setState(() => _pieceCount++),
                        isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${t.total}: ${_roundGramsDisplay(totalGrams)} ${t.grams}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.indigo,
              ),
            ),
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.perBowl,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        '${_weightFieldText(food.nutritionReferenceG)} ${t.grams}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    t.bowls,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _counterBtn('-', () {
                        if (_bowlCount > 1) setState(() => _bowlCount--);
                      }, isDark),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '$_bowlCount',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.indigo,
                          ),
                        ),
                      ),
                      _counterBtn(
                        '+',
                        () => setState(() => _bowlCount++),
                        isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${t.total}: ${_roundGramsDisplay(totalGrams)} ${t.grams}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppTheme.indigo,
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            _miniStat(t.calories, (food.calories * ratio).round(), isDark),
            const SizedBox(width: 8),
            _miniStat(t.protein, (food.protein * ratio).round(), isDark),
            const SizedBox(width: 8),
            _miniStat(t.carbs, (food.carbs * ratio).round(), isDark),
            const SizedBox(width: 8),
            _miniStat(t.fat, (food.fat * ratio).round(), isDark),
          ],
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              final boneMult = meatLogMacroMultiplier(
                food,
                withBones: _withBones,
              );
              final saved = await state.addLogEntry(
                LogEntry(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  foodId: food.id,
                  name:
                      food.getLocalizedName(state.lang) +
                      meatBoneSuffixForLang(state.lang, withBones: _withBones),
                  amount: totalGrams,
                  calories: food.calories * ratio,
                  protein: food.protein * ratio,
                  carbs: food.carbs * ratio,
                  fat: food.fat * ratio,
                  timestamp: DateTime.now().millisecondsSinceEpoch,
                  mealId: widget.mealId,
                  micros: scaleMicrosFromFood(
                    food,
                    totalGrams,
                    boneMult: boneMult,
                  ),
                ),
              );
              if (!mounted) return;
              if (!saved) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(t.saveFailed)));
                return;
              }
              Navigator.pop(context);
            },
            child: Text(t.addFood),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _modeButton(
    String label,
    bool active,
    VoidCallback? onTap,
    bool isDark, {
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.42,
      child: IgnorePointer(
        ignoring: !enabled,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: active
                  ? AppTheme.indigo
                  : (isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                        : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active
                    ? AppTheme.indigo
                    : (isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0)),
              ),
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? Colors.white
                      : (isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF475569)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _counterBtn(String label, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, int value, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.5)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 4),
            scaleDownText(
              '$value',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
