import 'package:nutrify/models/scan_meal_draft.dart';
import 'package:nutrify/screens/scan_result_editor.dart';
import 'package:nutrify/l10n/scan_result_strings.dart';
import 'package:nutrify/widgets/meal_photo_review.dart';
import 'dart:typed_data';
import 'package:nutrify/models/meal.dart';
import 'package:nutrify/widgets/ai_consent.dart';
import 'package:nutrify/utils/ai_strings.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/navigation/main_shell_tabs.dart';
import 'package:nutrify/models/log_entry.dart';
import 'package:nutrify/theme/app_theme.dart';
import 'package:nutrify/utils/ai_trilingual_strings.dart';
import 'package:nutrify/services/camera_access.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, this.picker});
  final ImagePicker? picker;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late final ImagePicker _picker = widget.picker ?? ImagePicker();
  bool _isAnalyzing = false;
  Map<String, dynamic>? _scannedFood;
  ScanMealDraft? _scanDraft;
  int? _scanOwner;
  double? _weighedGrams;
  String? _error;

  Future<void> _reviewScan() async {
    final state = context.read<AppState>();
    final owner = state.sessionAccountId;
    final scan = _scannedFood;
    if (scan == null || owner == null || owner != _scanOwner) return;
    await state.catalog.load();
    if (!mounted || owner != state.sessionAccountId) return;
    final draft = _scanDraft ??= ScanMealDraft.fromScan(
      scan,
      state.catalog.foods,
      state.catalog.disabled,
      state.lang,
    );
    draft.weighedGrams = _weighedGrams;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => Consumer<AppState>(
          builder: (_, current, _) => ScanResultEditor(
            draft: draft,
            foods: current.catalog.foods,
            disabled: current.catalog.disabled,
            lang: state.lang,
            simulated: scan['simulated'] == true,
            onSave: (d) async {
              if (state.sessionAccountId != owner ||
                  state.catalog.revision == null) {
                return false;
              }
              return state.addReviewedScan(
                d.toRequest(state.catalog.revision!, state.lang),
              );
            },
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (saved == true) {
      setState(() {
        _scannedFood = null;
        _scanDraft = null;
      });
      state.setActiveTab(MainShellTab.foodLog);
    }
  }

  // Fridge scanner state
  bool _fridgeAnalyzing = false;
  Map<String, dynamic>? _fridgeResult;
  String? _fridgeError;
  String _selectedMealType = 'lunch';

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final state = context.read<AppState>();
    final owner = state.sessionAccountId;
    if (source == ImageSource.camera &&
        !await ensureCameraAccess(context, state.lang)) {
      return;
    }
    if (!mounted) return;
    if (!await ensureAiConsent(context, state) || !mounted) return;
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 1600,
        requestFullMetadata: false,
        imageQuality: 80,
      );
      if (image == null || !mounted) return;

      setState(() {
        _isAnalyzing = true;
        _scannedFood = null;
        _scanDraft = null;
        _error = null;
      });

      final bytes = await image.readAsBytes();
      if (!mounted) return;
      final photos = await showMealPhotoReview(
        context,
        initial: bytes,
        source: source,
        picker: _picker,
        lang: state.lang,
      );
      if (!mounted) return;
      if (photos == null) {
        setState(() => _isAnalyzing = false);
        return;
      }
      if (state.sessionAccountId != owner) {
        setState(() => _isAnalyzing = false);
        return;
      }
      await _analyzeImage(
        photos.$1,
        side: photos.$2,
        owner: owner,
        container: photos.$3,
      );
    } catch (e) {
      if (!mounted) return;
      final state = Provider.of<AppState>(context, listen: false);
      setState(() {
        _error = state.t.scanFailed;
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _analyzeImage(
    Uint8List bytes, {
    Uint8List? side,
    int? owner,
    Map<String, double>? container,
  }) async {
    final state = Provider.of<AppState>(context, listen: false);
    final isOnline = await state.checkConnectivity();
    if (!mounted) return;
    if (owner != state.sessionAccountId) {
      setState(() => _isAnalyzing = false);
      return;
    }
    if (!isOnline) {
      setState(() {
        _error = state.t.noInternet;
        _isAnalyzing = false;
      });
      return;
    }
    try {
      final g = state.goals;
      final p = state.userProfile;
      final dc = g?.calories ?? p?.dailyCalories ?? 2200;
      final dp = g?.protein ?? 120;
      final dcr = g?.carbs ?? 250;
      final df = g?.fat ?? 70;
      final result = await state.ai.analyzeFood(
        imageBytes: bytes,
        sideImageBytes: side,
        container: container,
        dailyCalories: dc,
        dailyProtein: dp,
        dailyCarbs: dcr,
        dailyFat: df,
        lang: state.lang,
      );
      if (!mounted || owner != state.sessionAccountId) return;
      setState(() {
        if (result == null) {
          _error = AiStrings.get(state.lang, state.aiErrorCode);
          _scannedFood = null;
          _scanDraft = null;
        } else {
          _scannedFood = result;
          _scanOwner = owner;
          _weighedGrams = container?['foodGrams'];
          _scanDraft = null;
          _error = null;
        }
        _isAnalyzing = false;
      });
      if (result != null) await _reviewScan();
    } catch (e) {
      if (!mounted) return;
      final errStr = e.toString();
      setState(() {
        _error =
            (errStr.contains('SocketException') ||
                errStr.contains('ClientException') ||
                errStr.contains('TimeoutException'))
            ? state.t.errorNetwork
            : state.t.scanFailed;
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _scanFridge(ImageSource source) async {
    final initialState = context.read<AppState>();
    if (source == ImageSource.camera &&
        !await ensureCameraAccess(context, initialState.lang)) {
      return;
    }
    if (!mounted) return;
    if (!await ensureAiConsent(context, initialState) || !mounted) return;
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1600,
        requestFullMetadata: false,
        imageQuality: 85,
      );
      if (image == null || !mounted) return;

      setState(() {
        _fridgeAnalyzing = true;
        _fridgeResult = null;
        _fridgeError = null;
      });

      final bytes = await image.readAsBytes();
      if (!mounted) return;
      final state = Provider.of<AppState>(context, listen: false);
      final isOnline = await state.checkConnectivity();
      if (!isOnline) {
        if (mounted) {
          setState(() {
            _fridgeError = state.t.noInternet;
            _fridgeAnalyzing = false;
          });
        }
        return;
      }
      final mealCalories = state.goals?.calories != null
          ? (state.goals!.calories ~/ 3)
          : 600;

      final alle = state.userProfile?.allergies ?? [];
      final g = state.goals;
      final p = state.userProfile;
      final dc = g?.calories ?? p?.dailyCalories ?? 2200;
      final dp = g?.protein ?? 120;
      final dcr = g?.carbs ?? 250;
      final df = g?.fat ?? 70;
      final result = await state.ai.analyzeFridge(
        imageBytes: bytes,
        mealPeriodLabel: _selectedMealType,
        targetCalories: mealCalories,
        goal: state.localizedNutritionGoalLabel,
        allergiesSummary: alle.isEmpty
            ? ''
            : state.formatAllergiesForPrompt(alle),
        dailyCalories: dc,
        dailyProtein: dp,
        dailyCarbs: dcr,
        dailyFat: df,
      );

      if (mounted) {
        setState(() {
          if (result != null) {
            _fridgeResult = result;
          } else {
            _fridgeError = AiStrings.get(state.lang, state.aiErrorCode);
          }
          _fridgeAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final state = Provider.of<AppState>(context, listen: false);
        setState(() {
          _fridgeError = e.toString().contains('SocketException')
              ? state.t.errorNetwork
              : state.t.fridgeScanError;
          _fridgeAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    final isDark = state.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.foodScanner,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: isDark ? AppTheme.slate50 : AppTheme.slate900,
            ),
          ),
          const SizedBox(height: 20),

          // Scanner Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.indigo.withValues(alpha: 0.1)
                        : AppTheme.lightSurfaceTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    size: 40,
                    color: AppTheme.indigo,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  t.readyToScan,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.scanSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing
                        ? null
                        : () => _pickAndAnalyze(ImageSource.camera),
                    icon: _isAnalyzing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.camera_alt, size: 20),
                    label: Text(t.startCamera),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isAnalyzing
                        ? null
                        : () => _pickAndAnalyze(ImageSource.gallery),
                    icon: const Icon(Icons.upload, size: 20),
                    label: Text(t.uploadPhoto),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Error
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.rose.withValues(alpha: 0.1)
                    : const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? AppTheme.rose.withValues(alpha: 0.3)
                      : const Color(0xFFFECDD3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 16,
                    color: AppTheme.rose,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.rose,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _error = null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.rose.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        t.tryAgain,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.rose,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_scannedFood != null)
            OutlinedButton.icon(
              key: const ValueKey('review-scan-result'),
              onPressed: _reviewScan,
              icon: const Icon(Icons.edit_note),
              label: Text(ScanResultStrings(state.lang).title),
            ),
          const SizedBox(height: 24),

          // ─── Fridge Scanner Section ────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.emerald.withValues(alpha: 0.1)
                        : const Color(0xFFF0FDF4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.kitchen, size: 32, color: AppTheme.emerald),
                ),
                const SizedBox(height: 12),
                Text(
                  t.scanFridge,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.scanFridgeDesc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 16),

                // Meal type selector
                Text(
                  t.selectMealType,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _mealChip(t.breakfast, 'breakfast', isDark),
                    const SizedBox(width: 6),
                    _mealChip(t.lunch, 'lunch', isDark),
                    const SizedBox(width: 6),
                    _mealChip(t.dinner, 'dinner', isDark),
                    const SizedBox(width: 6),
                    _mealChip(t.snacks, 'snacks', isDark),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _fridgeAnalyzing
                            ? null
                            : () => _scanFridge(ImageSource.camera),
                        icon: _fridgeAnalyzing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.camera_alt, size: 18),
                        label: Text(
                          t.startCamera,
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emerald,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _fridgeAnalyzing
                            ? null
                            : () => _scanFridge(ImageSource.gallery),
                        icon: const Icon(Icons.upload, size: 18),
                        label: Text(
                          t.uploadPhoto,
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_fridgeError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.rose.withValues(alpha: 0.1)
                    : const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? AppTheme.rose.withValues(alpha: 0.3)
                      : const Color(0xFFFECDD3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 16,
                    color: AppTheme.rose,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _fridgeError!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.rose,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _fridgeError = null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.rose.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        t.tryAgain,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.rose,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (_fridgeResult != null) ...[
            const SizedBox(height: 16),
            _buildFridgeResult(t, isDark, state),
          ],
        ],
      ),
    );
  }

  Widget _mealChip(String label, String value, bool isDark) {
    final active = _selectedMealType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMealType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? AppTheme.emerald
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? AppTheme.emerald
                  : (isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Center(
            child: Text(
              label,
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
    );
  }

  Widget _buildFridgeResult(dynamic t, bool isDark, AppState state) {
    final lang = state.lang;
    final root = Map<String, dynamic>.from(_fridgeResult!);
    final recipe = Map<String, dynamic>.from(root['recipe'] as Map? ?? {});
    final detected = trilingualRootStringList(
      root,
      mapKey: 'detected_ingredients',
      legacyKey: 'detected_ingredients',
      lang: lang,
    );
    final recipeName = trilingualString(
      recipe,
      mapKey: 'names',
      legacyKey: 'name',
      lang: lang,
    );
    final recipeNameEn = trilingualString(
      recipe,
      mapKey: 'names',
      legacyKey: 'name',
      lang: 'en',
    );
    final ingList = trilingualStringList(
      recipe,
      mapKey: 'ingredients',
      legacyKey: 'ingredients',
      lang: lang,
    );
    final instList = trilingualStringList(
      recipe,
      mapKey: 'instructions',
      legacyKey: 'instructions',
      lang: lang,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.6)
            : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.5)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detected.isNotEmpty) ...[
            Text(
              t.detectedIngredients,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: detected
                  .map(
                    (item) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.emerald.withValues(alpha: 0.1)
                            : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.emerald,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            t.suggestedRecipe,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            recipeName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _scanStat(
                t.calories,
                (recipe['calories'] as num?)?.round() ?? 0,
                AppTheme.indigo,
                isDark,
              ),
              const SizedBox(width: 8),
              _scanStat(
                t.protein,
                (recipe['protein'] as num?)?.round() ?? 0,
                AppTheme.rose,
                isDark,
              ),
              const SizedBox(width: 8),
              _scanStat(
                t.carbs,
                (recipe['carbs'] as num?)?.round() ?? 0,
                AppTheme.amber,
                isDark,
              ),
              const SizedBox(width: 8),
              _scanStat(
                t.fat,
                (recipe['fat'] as num?)?.round() ?? 0,
                AppTheme.emerald,
                isDark,
              ),
            ],
          ),
          if (ingList.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              t.ingredients,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 8),
            ...ingList.map(
              (ing) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.emerald,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        ing,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (instList.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              t.instructions,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 8),
            ...instList.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${e.key + 1}. ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.emerald,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                if (!await confirmAiEstimate(
                      context,
                      state,
                      details: ingList.join('\n'),
                    ) ||
                    !mounted) {
                  return;
                }
                final rawMicros =
                    recipe['micros'] as Map<String, dynamic>? ?? {};
                final saved = await state.addLogEntry(
                  LogEntry(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    foodId:
                        'fridge-${recipeNameEn.isNotEmpty ? recipeNameEn : recipeName}',
                    name: recipeName.isNotEmpty ? recipeName : t.unknownFood,
                    amount: Meal.fromMap(recipe).portionGrams ?? 100,
                    calories: (recipe['calories'] as num?)?.round() ?? 0,
                    protein: (recipe['protein'] as num?)?.round() ?? 0,
                    carbs: (recipe['carbs'] as num?)?.round() ?? 0,
                    fat: (recipe['fat'] as num?)?.round() ?? 0,
                    timestamp: DateTime.now().millisecondsSinceEpoch,
                    mealId: _selectedMealType,
                    micros: rawMicros.map(
                      (k, v) => MapEntry(k, (v as num).toDouble()),
                    ),
                  ),
                );
                if (!mounted || !saved) return;
                setState(() => _fridgeResult = null);
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text(t.logAsEaten),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emerald,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanStat(String label, int value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.5)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '$value',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
