import 'dart:typed_data';
import 'package:nutrify/utils/ai_nutrition.dart';
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

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isAnalyzing = false;
  Map<String, dynamic>? _scannedFood;
  double _scanGrams = 100;

  /// Per-ingredient grams when AI returns composite [components].
  List<double>? _componentGrams;
  String? _error;

  void _initScanPortions(Map<String, dynamic> scan) {
    final components = parseAiFoodComponents(scan);
    if (components.isNotEmpty) {
      _componentGrams = components
          .map((c) => (c['grams'] as num?)?.toDouble() ?? 50)
          .toList();
      _scanGrams = _componentGrams!.fold(0.0, (a, b) => a + b);
    } else {
      _componentGrams = null;
      _scanGrams = 100;
    }
  }

  ({int cal, int pro, int carb, int fat}) _scaledComponentMacros(
    Map<String, dynamic> component,
    double userGrams,
  ) {
    final origG = (component['grams'] as num?)?.toDouble() ?? 0;
    final baseG = origG > 0 ? origG : 100;
    final ratio = userGrams / baseG;
    return (
      cal: (((component['calories'] as num?)?.toDouble() ?? 0) * ratio).round(),
      pro: (((component['protein'] as num?)?.toDouble() ?? 0) * ratio).round(),
      carb: (((component['carbs'] as num?)?.toDouble() ?? 0) * ratio).round(),
      fat: (((component['fat'] as num?)?.toDouble() ?? 0) * ratio).round(),
    );
  }

  // Fridge scanner state
  bool _fridgeAnalyzing = false;
  Map<String, dynamic>? _fridgeResult;
  String? _fridgeError;
  String _selectedMealType = 'lunch';

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final state = context.read<AppState>();
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
        _error = null;
      });

      final bytes = await image.readAsBytes();
      await _analyzeImage(bytes);
    } catch (e) {
      if (!mounted) return;
      final state = Provider.of<AppState>(context, listen: false);
      setState(() {
        _error = state.t.scanFailed;
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _analyzeImage(Uint8List bytes) async {
    final state = Provider.of<AppState>(context, listen: false);
    final isOnline = await state.checkConnectivity();
    if (!mounted) return;
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
        dailyCalories: dc,
        dailyProtein: dp,
        dailyCarbs: dcr,
        dailyFat: df,
        lang: state.lang,
      );
      if (!mounted) return;
      setState(() {
        if (result == null) {
          _error = AiStrings.get(state.lang, state.aiErrorCode);
          _scannedFood = null;
        } else {
          _scannedFood = result;
          _initScanPortions(result);
          _error = null;
        }
        _isAnalyzing = false;
      });
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

          // Results
          if (_scannedFood != null)
            Builder(
              builder: (context) {
                final scan = Map<String, dynamic>.from(_scannedFood!);
                final dishName = trilingualString(
                  scan,
                  mapKey: 'names',
                  legacyKey: 'name',
                  lang: state.lang,
                );
                final dishDesc = trilingualString(
                  scan,
                  mapKey: 'descriptions',
                  legacyKey: 'description',
                  lang: state.lang,
                );
                final stableName = trilingualString(
                  scan,
                  mapKey: 'names',
                  legacyKey: 'name',
                  lang: 'en',
                );
                final ratio = _scanGrams / 100.0;
                final cal100 = (scan['calories'] as num?)?.toDouble() ?? 0;
                final pro100 = (scan['protein'] as num?)?.toDouble() ?? 0;
                final carb100 = (scan['carbs'] as num?)?.toDouble() ?? 0;
                final fat100 = (scan['fat'] as num?)?.toDouble() ?? 0;
                final components = parseAiFoodComponents(scan);
                final hasComponents =
                    components.isNotEmpty && _componentGrams != null;
                late final int calScaled;
                late final int proScaled;
                late final int carbScaled;
                late final int fatScaled;
                late final double displayGrams;
                if (hasComponents) {
                  var cal = 0, pro = 0, carb = 0, fat = 0;
                  for (var i = 0; i < components.length; i++) {
                    final m = _scaledComponentMacros(
                      components[i],
                      _componentGrams![i],
                    );
                    cal += m.cal;
                    pro += m.pro;
                    carb += m.carb;
                    fat += m.fat;
                  }
                  calScaled = cal;
                  proScaled = pro;
                  carbScaled = carb;
                  fatScaled = fat;
                  displayGrams = _componentGrams!.fold(0.0, (a, b) => a + b);
                } else {
                  calScaled = (cal100 * ratio).round();
                  proScaled = (pro100 * ratio).round();
                  carbScaled = (carb100 * ratio).round();
                  fatScaled = (fat100 * ratio).round();
                  displayGrams = _scanGrams;
                }
                return Container(
                  padding: const EdgeInsets.all(20),
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
                      Text(
                        dishName,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.indigo.withValues(alpha: 0.2)
                              : AppTheme.lightSurfaceTint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          t.aiAnalyzed,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppTheme.indigoLight
                                : AppTheme.indigo,
                          ),
                        ),
                      ),
                      if (dishDesc.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          dishDesc,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        t.totalMacros,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildMacroGrid(
                        t: t,
                        isDark: isDark,
                        calories: calScaled,
                        protein: proScaled,
                        carbs: carbScaled,
                        fat: fatScaled,
                      ),
                      if (hasComponents) ...[
                        const SizedBox(height: 18),
                        Text(
                          t.ingredientBreakdown,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(components.length, (i) {
                          return _buildComponentRow(
                            components[i],
                            state.lang,
                            _componentGrams![i],
                            isDark,
                            t,
                            onGramsChanged: (g) {
                              setState(() {
                                _componentGrams![i] = g;
                                _scanGrams = _componentGrams!.fold(
                                  0.0,
                                  (a, b) => a + b,
                                );
                              });
                            },
                          );
                        }),
                      ] else if (components.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          t.ingredientBreakdown,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...components.map(
                          (c) => _buildComponentRow(
                            c,
                            state.lang,
                            (c['grams'] as num?)?.toDouble() ?? 100,
                            isDark,
                            t,
                          ),
                        ),
                      ],
                      if (!hasComponents) ...[
                        const SizedBox(height: 20),
                        _buildPortionAdjuster(t, isDark),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (!await confirmAiEstimate(
                                  context,
                                  state,
                                  details:
                                      '$dishName\n${displayGrams.round()} ${t.grams}',
                                ) ||
                                !mounted) {
                              return;
                            }
                            final saved = await state.addLogEntry(
                              LogEntry(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                foodId:
                                    'scanned-${stableName.isNotEmpty ? stableName : dishName}',
                                name: dishName.isNotEmpty
                                    ? dishName
                                    : t.unknownFood,
                                amount: displayGrams,
                                calories: calScaled,
                                protein: proScaled,
                                carbs: carbScaled,
                                fat: fatScaled,
                                timestamp:
                                    DateTime.now().millisecondsSinceEpoch,
                                micros: scaledAiScanMicros(
                                  scan,
                                  displayGrams,
                                  hasComponents ? _componentGrams : null,
                                ),
                              ),
                            );
                            if (!mounted || !saved) return;
                            setState(() {
                              _scannedFood = null;
                              _componentGrams = null;
                            });
                            state.setActiveTab(MainShellTab.foodLog);
                          },
                          icon: const Icon(Icons.add, size: 20),
                          label: Text(
                            '${t.logAsEaten} · ${displayGrams.round()} ${t.grams}',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
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

  Widget _buildPortionAdjuster(dynamic t, bool isDark) {
    final clamped = _scanGrams.clamp(10.0, 1000.0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.4)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.barcodeAmountLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF475569),
                ),
              ),
              Text(
                '${_scanGrams.round()} ${t.grams}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.indigo,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _portionStepButton(Icons.remove, () {
                setState(
                  () => _scanGrams = (_scanGrams - 10).clamp(10.0, 1000.0),
                );
              }, isDark),
              Expanded(
                child: Slider(
                  value: clamped.toDouble(),
                  min: 10,
                  max: 1000,
                  divisions: 99,
                  onChanged: (v) =>
                      setState(() => _scanGrams = v.roundToDouble()),
                ),
              ),
              _portionStepButton(Icons.add, () {
                setState(
                  () => _scanGrams = (_scanGrams + 10).clamp(10.0, 1000.0),
                );
              }, isDark),
            ],
          ),
          Wrap(
            spacing: 8,
            children: [50, 100, 150, 200, 300].map((g) {
              final active = _scanGrams.round() == g;
              return GestureDetector(
                onTap: () => setState(() => _scanGrams = g.toDouble()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? AppTheme.indigo
                        : (isDark ? const Color(0xFF0F172A) : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: active
                          ? AppTheme.indigo
                          : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Text(
                    '$g${t.grams}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: active
                          ? Colors.white
                          : (isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF475569)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _portionStepButton(IconData icon, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Icon(icon, size: 18, color: AppTheme.indigo),
      ),
    );
  }

  Widget _buildMacroGrid({
    required dynamic t,
    required bool isDark,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCol = constraints.maxWidth < 360;
        final children = [
          _scanStat(t.calories, calories, AppTheme.indigo, isDark),
          _scanStat(t.protein, protein, AppTheme.rose, isDark),
          _scanStat(t.carbs, carbs, AppTheme.amber, isDark),
          _scanStat(t.fat, fat, AppTheme.emerald, isDark),
        ];
        if (!twoCol) {
          return Row(
            children: [
              children[0],
              const SizedBox(width: 8),
              children[1],
              const SizedBox(width: 8),
              children[2],
              const SizedBox(width: 8),
              children[3],
            ],
          );
        }
        return Column(
          children: [
            Row(children: [children[0], const SizedBox(width: 8), children[1]]),
            const SizedBox(height: 8),
            Row(children: [children[2], const SizedBox(width: 8), children[3]]),
          ],
        );
      },
    );
  }

  Widget _buildComponentRow(
    Map<String, dynamic> component,
    String lang,
    double userGrams,
    bool isDark,
    dynamic t, {
    void Function(double grams)? onGramsChanged,
  }) {
    final name = trilingualString(
      component,
      mapKey: 'names',
      legacyKey: 'name',
      lang: lang,
    );
    final m = _scaledComponentMacros(component, userGrams);
    final cal = m.cal;
    final pro = m.pro;
    final carb = m.carb;
    final fat = m.fat;
    final clamped = userGrams.clamp(5.0, 2000.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.45)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name.isNotEmpty ? name : t.unknownFood,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          if (onGramsChanged != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _portionStepButton(Icons.remove, () {
                  onGramsChanged((userGrams - 10).clamp(5.0, 2000.0));
                }, isDark),
                Expanded(
                  child: Slider(
                    value: clamped,
                    min: 5,
                    max: 500,
                    divisions: 99,
                    label: '${userGrams.round()} ${t.grams}',
                    onChanged: (v) => onGramsChanged(v.roundToDouble()),
                  ),
                ),
                _portionStepButton(Icons.add, () {
                  onGramsChanged((userGrams + 10).clamp(5.0, 2000.0));
                }, isDark),
                const SizedBox(width: 6),
                Text(
                  '${userGrams.round()} ${t.grams}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.indigo,
                  ),
                ),
              ],
            ),
          ] else if (userGrams > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${userGrams.round()} ${t.grams}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _componentMacroChip(
                '${cal.round()} ${t.kcal}',
                AppTheme.indigo,
                isDark,
              ),
              _componentMacroChip(
                '${t.protein} ${pro.round()}g',
                AppTheme.rose,
                isDark,
              ),
              _componentMacroChip(
                '${t.carbs} ${carb.round()}g',
                AppTheme.amber,
                isDark,
              ),
              _componentMacroChip(
                '${t.fat} ${fat.round()}g',
                AppTheme.emerald,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _componentMacroChip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
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
