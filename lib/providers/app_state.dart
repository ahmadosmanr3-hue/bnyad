import 'dart:io' show InternetAddress;
import 'dart:async';
import 'package:nutrify/l10n/notification_text.dart';
import 'package:nutrify/l10n/native_locale.dart';
import '../activity/step_tracker.dart';
import '../activity/step_health_provider.dart';
import '../activity/step_models.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nutrify/services/food_barcode_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:nutrify/services/auth_service.dart';
import 'package:nutrify/services/api_service.dart';
import 'package:nutrify/services/local_account_cache.dart';
import 'package:nutrify/services/ai_service.dart';
import 'package:nutrify/services/notification_service.dart';
import 'package:nutrify/services/push_service.dart';
import 'package:nutrify/models/user_profile.dart';
import 'package:nutrify/models/log_entry.dart';
import 'package:nutrify/models/meal.dart';
import 'package:nutrify/models/nutritional_goals.dart';
import 'package:nutrify/utils/nutrition_calculator.dart';
import 'package:nutrify/utils/micro_nutrient_calculator.dart';
import 'package:nutrify/utils/micro_nutrient_goals.dart';
import 'package:nutrify/models/vitamin_entry.dart';
import 'package:nutrify/models/favorite_template.dart';
import 'package:nutrify/models/shopping_item.dart';
import 'package:nutrify/utils/shopping_list_utils.dart';
import 'package:nutrify/l10n/app_localizations.dart';
import 'package:nutrify/navigation/main_shell_tabs.dart';

String _nutritionDateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String sanitizeMealPlanCuisine(String? v) {
  if (v == 'kurdish' || v == 'arabic' || v == 'all') return v!;
  return 'all';
}

Map<String, dynamic> _logEntryToJson(LogEntry e) => {
  'id': e.id,
  'foodId': e.foodId,
  'name': e.name,
  'amount': e.amount,
  'amountUnit': e.amountUnit,
  'calories': e.calories,
  'protein': e.protein,
  'carbs': e.carbs,
  'fat': e.fat,
  'timestamp': e.timestamp,
  if (e.mealId != null) 'mealId': e.mealId,
  if (e.micros.isNotEmpty) 'micros': e.micros,
};

LogEntry _logEntryFromJson(Map<String, dynamic> m) {
  final rawMicros = m['micros'] as Map<String, dynamic>? ?? {};
  return LogEntry(
    id: m['id']?.toString() ?? '',
    foodId: m['foodId']?.toString() ?? '',
    name: m['name']?.toString() ?? '',
    amount: (m['amount'] as num?)?.toDouble() ?? 0,
    amountUnit: m['amountUnit'] == 'ml' ? 'ml' : 'g',
    calories: (m['calories'] as num?)?.toDouble() ?? 0,
    protein: (m['protein'] as num?)?.toDouble() ?? 0,
    carbs: (m['carbs'] as num?)?.toDouble() ?? 0,
    fat: (m['fat'] as num?)?.toDouble() ?? 0,
    timestamp: (m['timestamp'] as num?)?.toInt() ?? 0,
    mealId: m['mealId'] as String?,
    micros: rawMicros.map(
      (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
    ),
  );
}

class AppState extends ChangeNotifier {
  final AuthService _authService;
  final ApiService _apiService;

  // Auth — replaces the old Firebase User? with a simple logged-in flag.
  bool _isLoggedIn = false;
  bool _authLoading = true;
  bool _sessionNeedsRetry = false;
  bool _saveFailed = false;
  bool get saveFailed => _saveFailed;
  void dismissSaveError() {
    _saveFailed = false;
    notifyListeners();
  }

  Future<void>? _userDataFetch;
  String _displayName = '';

  // App State
  String _lang = 'en';
  String _themeMode = 'light';
  bool _onboardingComplete = false;
  int _activeTab = MainShellTab.dashboard;
  String? _targetMealId;

  bool _openAddFoodSheet = false;
  String? _pendingLogMealId;

  // Data
  UserProfile? _userProfile;
  NutritionalGoals? _goals;
  Map<String, double> _microGoals = {};
  List<LogEntry> _dailyLog = [];
  int _waterIntake = 0;
  MealPlanData? _currentMealPlan;
  Map<String, String>? _healthGuidanceByLang;

  Map<String, dynamic>? _savedRecipe;

  List<VitaminEntry> _vitamins = [];

  final Map<String, bool> _reminderEnabled = {
    'breakfast': false,
    'lunch': false,
    'dinner': false,
    'snacks': false,
  };
  final Map<String, TimeOfDay> _reminderTimes = {
    'breakfast': const TimeOfDay(hour: 8, minute: 0),
    'lunch': const TimeOfDay(hour: 12, minute: 30),
    'dinner': const TimeOfDay(hour: 19, minute: 0),
    'snacks': const TimeOfDay(hour: 15, minute: 30),
  };

  bool _isOnline = true;
  final Map<String, Map<String, int>> _nutritionHistory = {};
  final Map<String, double> _weightHistory = {};
  List<FavoriteTemplate> _favorites = [];
  List<ShoppingItem> _shoppingList = [];
  bool _weeklyDigestEnabled = false;
  String _mealPlanCuisine = 'all';

  bool _isPremium = false;
  DateTime? _premiumUntil;

  // Notifications inbox (pushed from the admin panel via the server).
  List<Map<String, dynamic>> _notifications = [];
  int _lastSeenNotificationId = 0;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  AppState({
    required AuthService authService,
    required ApiService apiService,
    bool initializeOnCreate = true,
    StepHealthProvider? stepHealthProvider,
    StepSettingsStore? stepSettingsStore,
    this.optionalDeviceServicesEnabled = true,
    UserProfile? Function()? stepProfile,
    void Function(String)? stepDiagnostics,
  }) : _authService = authService,
       _apiService = apiService {
    steps = StepTracker(
      provider: stepHealthProvider ?? NativeStepHealthProvider(),
      store: stepSettingsStore ?? LocalStepSettingsStore(),
      diagnostics: stepDiagnostics,
      profile: stepProfile ?? () => _userProfile,
      weightKg: stepProfile != null
          ? () => stepProfile()?.weight
          : () => latestWalkingWeight(
              _weightHistory,
              DateTime.now(),
              _userProfile?.weight,
            ),
    )..addListener(notifyListeners);
    steps.setForeground(
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    );
    _apiService.onSessionInvalidated = () {
      _sessionNeedsRetry = false;
      _clearData();
    };
    if (initializeOnCreate) unawaited(initializeSession());
  }

  late final StepTracker steps;

  /// Disable billing, notifications/push and connectivity probes for the
  /// isolated offline preview. This never disables the native health provider.
  final bool optionalDeviceServicesEnabled;
  bool get supportsOptionalDeviceServices =>
      optionalDeviceServicesEnabled && !kIsWeb;
  Future<void> _syncStepsAccount() => steps.attach(
    isLoggedIn
        ? '${_apiService.baseUrl}|${_isMockUser ? 'guest' : _apiService.userId}'
        : null,
  );

  Future<void> initializeSession() async {
    _authLoading = true;
    _sessionNeedsRetry = false;
    notifyListeners();
    try {
      await _init();
    } catch (e) {
      // Keychain temporarily unavailable or initialization failed: offer a
      // retry without deleting credentials or showing a false login screen.
      _sessionNeedsRetry = true;
    } finally {
      _authLoading = false;
      notifyListeners();
    }
  }

  bool get sessionNeedsRetry => _sessionNeedsRetry;

  void _applySessionUser(Map<String, dynamic> user) {
    final raw = user['profile'];
    if (raw is! Map<String, dynamic>) return;
    final profile = _apiService.profileFromJson(raw);
    _userProfile = profile;
    _displayName = profile.displayName.isNotEmpty
        ? profile.displayName
        : user['name']?.toString() ?? '';
    _onboardingComplete = profile.onboarded;
    _lang = profile.language;
    _themeMode = profile.theme;
    _goals = NutritionalGoals(
      calories: profile.dailyCalories,
      protein: profile.dailyProtein,
      carbs: profile.dailyCarbs,
      fat: profile.dailyFat,
    );
  }

  // ─── Getters ────────────────────────────────────────

  /// Whether the user is authenticated (API token present) or is a guest.
  bool get isLoggedIn => _isLoggedIn || _isMockUser;

  /// Guest / local-only session (no account).
  bool get isGuest => _isMockUser;

  /// Registered account with a server token.
  bool get isAuthenticated => _isLoggedIn && !_isMockUser;

  /// Guests unlock premium features locally (full APK demo without an account).
  bool get hasPremiumFeatures => isPremium;

  bool get authLoading => _authLoading;
  String get userDisplayName {
    if (_displayName.trim().isNotEmpty) return _displayName.trim();
    final profileName = _userProfile?.displayName.trim();
    if (profileName != null && profileName.isNotEmpty) return profileName;
    return '';
  }

  String get lang => _lang;
  String get themeMode => _themeMode;
  bool get isDark => _themeMode == 'dark';
  bool get onboardingComplete => _onboardingComplete;
  int get activeTab => _activeTab;
  String? get targetMealId => _targetMealId;
  bool get openAddFoodSheet => _openAddFoodSheet;
  String? get pendingLogMealId => _pendingLogMealId;
  UserProfile? get userProfile => _userProfile;
  NutritionalGoals? get goals => _goals;
  Map<String, double> get dailyMicroGoals =>
      resolveEffectiveMicroGoals(_microGoals);
  List<LogEntry> get dailyLog => _dailyLog;
  int get waterIntake => _waterIntake;

  int get dailyWaterTargetMl => _userProfile?.waterTargetMl ?? 2500;
  MealPlanData? get currentMealPlan => _currentMealPlan;
  String? get healthGuidance {
    final m = _healthGuidanceByLang;
    if (m == null) return null;
    final k = _lang == 'ar'
        ? 'ar'
        : ((_lang == 'ku' || _lang == 'ckb') ? 'ku' : 'en');
    final primary = m[k];
    if (primary != null && primary.trim().isNotEmpty) return primary;
    for (final fb in ['en', 'ar', 'ku']) {
      final t = m[fb];
      if (t != null && t.trim().isNotEmpty) return t;
    }
    return null;
  }

  AppLocalizations get t => AppLocalizations(_lang);

  String get localizedNutritionGoalLabel =>
      t.getGoal(_userProfile?.goal ?? 'stayHealthy');

  String formatSicknessesForPrompt(List<String> keys) =>
      keys.map((k) => t.getSickness(k)).join(', ');

  String formatAllergiesForPrompt(List<String> keys) =>
      keys.map((k) => t.getAllergy(k)).join(', ');
  bool get isRTL => _lang == 'ar' || (_lang == 'ku' || _lang == 'ckb');
  AiService get ai => AiService(api: _apiService);
  FoodBarcodeService get barcodes => FoodBarcodeService(api: _apiService);
  String get aiErrorCode => _apiService.aiErrorCode;
  int? get sessionAccountId => _apiService.userId;
  Future<bool?> getAiConsent() => _apiService.getAiConsent();
  bool? get aiServiceAvailable => _apiService.aiServiceAvailable;
  Future<bool> setAiConsent(bool enabled) async {
    final saved = await _apiService.setAiConsent(enabled);
    if (saved && !enabled) {
      _healthGuidanceByLang = null;
      notifyListeners();
    }
    return saved;
  }

  List<String> get eatenMeals =>
      _dailyLog.where((e) => e.mealId != null).map((e) => e.mealId!).toList();

  List<VitaminEntry> get vitamins => _vitamins;
  Map<String, dynamic>? get savedRecipe => _savedRecipe;

  bool getReminderEnabled(String mealId) => _reminderEnabled[mealId] ?? false;
  TimeOfDay getReminderTime(String mealId) =>
      _reminderTimes[mealId] ?? const TimeOfDay(hour: 12, minute: 0);

  bool get isOnline => kIsWeb ? true : _isOnline;
  Map<String, Map<String, int>> get nutritionHistory =>
      Map.unmodifiable(_nutritionHistory);
  Map<String, double> get weightHistory => Map.unmodifiable(_weightHistory);
  List<FavoriteTemplate> get favorites => List.unmodifiable(_favorites);
  List<ShoppingItem> get shoppingList => List.unmodifiable(_shoppingList);
  bool get weeklyDigestEnabled => _weeklyDigestEnabled;
  String get mealPlanCuisine => _mealPlanCuisine;

  bool get isPremium {
    if (!_isPremium) return false;
    final until = _premiumUntil;
    if (until == null) return true;
    return until.toUtc().isAfter(DateTime.now().toUtc());
  }

  DateTime? get premiumUntil => _premiumUntil;

  /// Days of premium left, or 0 when not premium / unlimited.
  int get premiumDaysLeft {
    final until = _premiumUntil;
    if (!isPremium || until == null) return 0;
    final diff = until.toUtc().difference(DateTime.now().toUtc());
    if (diff.isNegative) return 0;
    return (diff.inMilliseconds / 86400000).ceil();
  }

  /// Notifications inbox, newest first.
  List<Map<String, dynamic>> get notifications =>
      List.unmodifiable(_notifications);

  /// Count of notifications the user has not opened the inbox for yet.
  int get unreadNotificationCount => _notifications
      .where((n) => (n['id'] as int? ?? 0) > _lastSeenNotificationId)
      .length;

  List<String> last7DateKeys() {
    final now = DateTime.now();
    return List.generate(
      7,
      (i) => _nutritionDateKey(now.subtract(Duration(days: 6 - i))),
    );
  }

  Map<String, double> get dailyMicronutrients =>
      aggregateDailyMicros(_dailyLog);

  Map<String, int> get consumedStats {
    double cal = 0, pro = 0, car = 0, fa = 0;
    for (final e in _dailyLog) {
      cal += e.calories;
      pro += e.protein;
      car += e.carbs;
      fa += e.fat;
    }
    return {
      'calories': cal.round(),
      'protein': pro.round(),
      'carbs': car.round(),
      'fat': fa.round(),
    };
  }

  // ─── Init ──────────────────────────────────────────

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString('lang') ?? 'en';
    if (_lang == 'ckb') _lang = 'ku';
    _themeMode = prefs.getString('theme') ?? 'light';
    // Resolve credentials and cached onboarding before any navigation or
    // optional notification/store initialization can run.
    await _apiService.loadToken();
    if (_apiService.hasToken) {
      _isLoggedIn = true;
      _isMockUser = false;
      await prefs.remove('is_guest');
      final cached = await _apiService.cachedUser();
      if (cached != null) _applySessionUser(cached);
      final user = await _apiService.me();
      if (!_apiService.hasToken) {
        _clearData();
      } else if (user != null) {
        _applySessionUser(user);
      } else if (_userProfile == null) {
        _sessionNeedsRetry = true;
      }
    }

    final isGuest =
        !_apiService.hasToken && (prefs.getBool('is_guest') ?? false);
    if (isGuest) {
      _isMockUser = true;
      _displayName = prefs.getString('guest_display_name') ?? '';
      _onboardingComplete = prefs.getBool('guest_onboarded') ?? false;
      _authLoading = false;

      if (_onboardingComplete) {
        final extRaw = prefs.getString('guest_profile_ext');
        if (extRaw != null) {
          try {
            final map = jsonDecode(extRaw) as Map<String, dynamic>;
            _userProfile = UserProfile.fromMap({
              ...map,
              'uid': 'mock-user-123',
            });
            if (_displayName.isEmpty) {
              _displayName = _userProfile!.displayName;
            }
          } catch (_) {
            _userProfile = null;
          }
        }
        _userProfile ??= UserProfile(
          uid: 'mock-user-123',
          weight: prefs.getDouble('guest_weight') ?? 75.0,
          height: prefs.getDouble('guest_height') ?? 180.0,
          age: prefs.getInt('guest_age') ?? 30,
          gender: prefs.getString('guest_gender') ?? 'male',
          activityLevel:
              prefs.getString('guest_activity') ?? 'moderatelyActive',
          goal: prefs.getString('guest_goal') ?? 'stayHealthy',
          sicknesses: prefs.getStringList('guest_sicknesses') ?? [],
          allergies: prefs.getStringList('guest_allergies') ?? [],
          disabilities: prefs.getStringList('guest_disabilities') ?? [],
          dailyCalories: prefs.getInt('guest_calories') ?? 2200,
          dailyCarbs: prefs.getInt('guest_carbs') ?? 275,
          dailyProtein: prefs.getInt('guest_protein') ?? 110,
          dailyFat: prefs.getInt('guest_fat') ?? 73,
          language: _lang,
          theme: _themeMode,
          onboarded: true,
          displayName: _displayName,
        );
        _goals = NutritionalGoals(
          calories: prefs.getInt('guest_calories') ?? 2200,
          protein: prefs.getInt('guest_protein') ?? 110,
          carbs: prefs.getInt('guest_carbs') ?? 275,
          fat: prefs.getInt('guest_fat') ?? 73,
        );
      }

      notifyListeners();
    }

    await activateLocalAccount(
      prefs,
      _apiService.userId?.toString() ?? 'guest',
    );
    await _loadReminders(prefs);
    await _loadMicroGoals(prefs);
    await _loadVitamins(prefs);
    await _loadSavedRecipe(prefs);
    await _loadNutritionHistory(prefs);
    await _loadWeightHistory(prefs);
    await _loadFavorites(prefs);
    await _loadShoppingList(prefs);
    _weeklyDigestEnabled = prefs.getBool('weekly_digest_enabled') ?? false;
    _mealPlanCuisine = sanitizeMealPlanCuisine(
      prefs.getString('meal_plan_cuisine'),
    );
    _loadPremium(prefs);
    if (supportsOptionalDeviceServices && (_isMockUser || _isLoggedIn)) {
      unawaited(syncPremiumFromRevenueCat());
    }
    await _loadNotifications(prefs);

    if (_isMockUser && _onboardingComplete) {
      await _loadGuestDailyLog(prefs);
      await _loadGuestWater(prefs);
      await _loadGuestMealPlan(prefs);
      _persistDailyNutritionSnapshot();
    }

    await _ensureCurrentNutritionDay();
    unawaited(_syncStepsAccount());
    // Opening the app is not a new weight measurement.

    await prefs.setString('lang', _lang);
    unawaited(syncNativeLanguage(_lang));
    if (supportsOptionalDeviceServices) {
      await NotificationService.instance.setLanguage(_lang);
    }
    _startConnectivityListener();

    if (supportsOptionalDeviceServices) {
      try {
        await NotificationService.instance.init();
        await _rescheduleAllReminders();
        await _rescheduleAllSupplementReminders();
        if (_weeklyDigestEnabled) {
          await _persistWeeklyDigestNotifStrings();
          final title =
              prefs.getString('weekly_digest_notif_title') ??
              AppLocalizations(_lang).weeklyDigestTitle;
          final body =
              prefs.getString('weekly_digest_notif_body') ??
              AppLocalizations(_lang).weeklyDigestBody;
          await NotificationService.instance.scheduleWeeklySummary(
            title: title,
            body: body,
          );
        }
      } catch (e) {
        debugPrint('Notification init error: $e');
      }
    }

    // Check for existing API token instead of Firebase auth state.
    if (!_isMockUser) {
      if (_apiService.hasToken) {
        _isLoggedIn = true;
        unawaited(_fetchUserData());
      } else {
        _authLoading = false;
        notifyListeners();
      }
    }
  }

  /// Fetches user data from the API (replaces Firebase stream subscriptions).
  Future<void> _fetchUserData() async {
    if (!_isLoggedIn || !_apiService.hasToken) return;
    if (_userDataFetch != null) return _userDataFetch!;
    final fetch = _fetchUserDataOnce();
    _userDataFetch = fetch;
    try {
      await fetch;
    } finally {
      _userDataFetch = null;
    }
  }

  Future<void> _fetchUserDataOnce() async {
    final sessionUserId = _apiService.userId;
    try {
      final profile = await _apiService.getUserProfile();
      if (!_apiService.hasToken || _apiService.userId != sessionUserId) return;
      if (profile != null) {
        _userProfile = profile;
        if (profile.displayName.trim().isNotEmpty) {
          _displayName = profile.displayName.trim();
        }
        _lang = profile.language;
        _themeMode = profile.theme;
        _onboardingComplete = profile.onboarded;
        _goals = NutritionalGoals(
          calories: profile.dailyCalories,
          protein: profile.dailyProtein,
          carbs: profile.dailyCarbs,
          fat: profile.dailyFat,
        );
        if (profile.dailyMicroGoals.isNotEmpty) {
          _microGoals = Map<String, double>.from(profile.dailyMicroGoals);
          await _saveMicroGoals();
        } else {
          await _ensureMicroGoalsFromProfile();
        }
      }

      final today = _nutritionDateKey(DateTime.now());
      final logs = await _apiService.getDailyLogs(date: today);
      final water = await _apiService.getWaterIntake(date: today);
      final plan = await _apiService.getMealPlan();
      if (!_apiService.hasToken || _apiService.userId != sessionUserId) return;
      if (_apiService.lastLogReadSucceeded) _dailyLog = logs;
      _waterIntake = water;
      _currentMealPlan = plan;

      _persistDailyNutritionSnapshot();
      notifyListeners();

      if (supportsOptionalDeviceServices && _apiService.userId != null) {
        try {
          await Purchases.logIn(_apiService.userId!.toString());
        } catch (e) {
          debugPrint('Error logging in to RevenueCat: $e');
        }
        await syncPremiumFromRevenueCat();
      }
      await syncPremiumFromServer();
      unawaited(syncNotifications());
      if (supportsOptionalDeviceServices) {
        unawaited(PushService.instance.registerForUser(_apiService));
      }

      if (_isOnline) {
        unawaited(refreshNutritionHistoryFromCloud());
      }
    } catch (e) {
      debugPrint('_fetchUserData error: $e');
    }
  }

  bool _isMockUser = false;
  bool get isMockUser => _isMockUser;

  void _clearData() {
    steps.detach();
    if (_isMockUser) return;

    _userProfile = null;
    _goals = null;
    _dailyLog = [];
    _waterIntake = 0;
    _currentMealPlan = null;
    _healthGuidanceByLang = null;
    _onboardingComplete = false;
    _displayName = '';
    _isLoggedIn = false;
    _isPremium = false;
    _premiumUntil = null;
    _notifications = [];
    _nutritionHistory.clear();
    _weightHistory.clear();
    _favorites = [];
    _shoppingList = [];
    _vitamins = [];
    _savedRecipe = null;
    _microGoals = {};
    _saveFailed = false;
    notifyListeners();
  }

  Future<void> onAppResumed() async {
    await _syncStepsAccount();
    steps.setForeground(
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    );
    await _ensureCurrentNutritionDay();

    // Re-fetch data from API if logged in.
    if (_isLoggedIn && !_isMockUser) {
      unawaited(_fetchUserData());
    }

    if (!supportsOptionalDeviceServices) return;
    try {
      await NotificationService.instance.refreshSchedules(
        rescheduleAll: _rescheduleAllReminders,
      );
      if (_weeklyDigestEnabled) {
        final prefs = await SharedPreferences.getInstance();
        final title =
            prefs.getString('weekly_digest_notif_title') ??
            AppLocalizations(_lang).weeklyDigestTitle;
        final body =
            prefs.getString('weekly_digest_notif_body') ??
            AppLocalizations(_lang).weeklyDigestBody;
        await NotificationService.instance.scheduleWeeklySummary(
          title: title,
          body: body,
        );
      }
    } catch (e) {
      debugPrint('Notification refresh on resume: $e');
    }
  }

  Future<void> _ensureCurrentNutritionDay() async {
    final today = _nutritionDateKey(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final lastActive = prefs.getString('last_active_nutrition_date');

    final dayChanged = lastActive != null && lastActive != today;

    if (dayChanged) {
      if (_isMockUser) {
        _dailyLog = [];
        _waterIntake = 0;
        await _saveGuestDailyLog();
        await _saveGuestWater();
      } else if (_isLoggedIn) {
        unawaited(_fetchUserData());
      }
      await resetVitaminsTaken();
      notifyListeners();
    }

    await prefs.setString('last_active_nutrition_date', today);
  }

  // ─── Actions ────────────────────────────────────────

  void setActiveTab(int tab, {String? targetMealId}) {
    _activeTab = tab;
    _targetMealId = targetMealId;
    notifyListeners();
  }

  void clearTargetMealId() {
    _targetMealId = null;
  }

  void openFoodLog({String? mealId, bool openSheet = true}) {
    _activeTab = MainShellTab.foodLog;
    _pendingLogMealId = mealId;
    _openAddFoodSheet = openSheet;
    notifyListeners();
  }

  void consumeFoodLogIntent() {
    _openAddFoodSheet = false;
    _pendingLogMealId = null;
    notifyListeners();
  }

  Future<void> _languagePersistence = Future.value();

  Future<void> setLang(String newLang) async {
    if (newLang == 'ckb') newLang = 'ku';
    if (_lang == newLang) return;
    _lang = newLang;
    notifyListeners();
    _languagePersistence = _languagePersistence.then(
      (_) => _persistLang(newLang),
    );
    await _languagePersistence;
  }

  Future<void> _persistLang(String newLang) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lang', newLang);
      unawaited(syncNativeLanguage(newLang));
      if (_isLoggedIn && !_isMockUser) {
        await _apiService.updateProfileField({'language': newLang});
      }
      if (supportsOptionalDeviceServices) {
        await NotificationService.instance.setLanguage(newLang);
        await _rescheduleAllReminders();
        await _rescheduleAllSupplementReminders();
      }
      if (supportsOptionalDeviceServices && _weeklyDigestEnabled) {
        await _persistWeeklyDigestNotifStrings();
        final p = await SharedPreferences.getInstance();
        await NotificationService.instance.scheduleWeeklySummary(
          title:
              p.getString('weekly_digest_notif_title') ?? t.weeklyDigestTitle,
          body: p.getString('weekly_digest_notif_body') ?? t.weeklyDigestBody,
        );
      }
    } catch (e) {
      debugPrint('setLang persist error: $e');
    }
  }

  Future<void> setTheme(String newTheme) async {
    if (_themeMode == newTheme) return;
    _themeMode = newTheme;
    notifyListeners();
    unawaited(_persistTheme(newTheme));
  }

  Future<void> _persistTheme(String newTheme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme', newTheme);
      if (_isLoggedIn && !_isMockUser) {
        await _apiService.updateProfileField({'theme': newTheme});
      }
    } catch (e) {
      debugPrint('setTheme persist error: $e');
    }
  }

  Future<bool?> checkPhoneRegistered(String phoneNumber) =>
      _authService.isPhoneRegistered(phoneNumber);

  Future<String?> sendPhoneOtp(String phoneNumber) =>
      _authService.sendPhoneOtp(phoneNumber);

  Future<String?> verifyPhoneOtp(
    String phoneNumber,
    String code, {
    String? password,
    String? name,
  }) async {
    final result = await _authService.verifyPhoneOtp(
      phoneNumber: phoneNumber,
      code: code,
      password: password,
      name: name,
    );
    if (result.error == null && result.user != null) {
      await finishPhoneLogin(result.user!);
      return null;
    }
    return result.error;
  }

  Future<String?> loginWithPassword(String phoneNumber, String password) async {
    final result = await _authService.loginWithPassword(
      phoneNumber: phoneNumber,
      password: password,
    );
    if (result.error == null && result.user != null) {
      await finishPhoneLogin(result.user!);
      return null;
    }
    return result.error;
  }

  /// Completes API sign-in after OTP verification.
  Future<void> finishPhoneLogin(Map<String, dynamic> userData) async {
    if (_isMockUser) {
      await clearMockUser();
    }
    _isMockUser = false;
    final prefs = await SharedPreferences.getInstance();
    await activateLocalAccount(prefs, _apiService.userId!.toString());
    await _loadNutritionHistory(prefs);
    await _loadWeightHistory(prefs);
    await _loadFavorites(prefs);
    await _loadShoppingList(prefs);
    await _loadVitamins(prefs);
    await _loadNotifications(prefs);
    _loadPremium(prefs);
    _isLoggedIn = true;
    _authLoading = false;
    _sessionNeedsRetry = false;
    _applySessionUser(userData);
    unawaited(_syncStepsAccount());
    await _loadMicroGoals(prefs);
    await _loadSavedRecipe(prefs);
    await _loadReminders(prefs);

    final profile = userData['profile'] as Map<String, dynamic>?;
    final displayName = profile?['display_name']?.toString().trim();
    final name = userData['name']?.toString().trim();
    _displayName = (displayName != null && displayName.isNotEmpty)
        ? displayName
        : (name ?? '');

    final onboarded = profile?['onboarded'];
    _onboardingComplete = onboarded == true || onboarded == 1;

    notifyListeners();
    await _fetchUserData();
  }

  /// Completes guest sign-in after the name step (no API account).
  Future<void> completeSignInWithName(String displayName) async {
    final name = displayName.trim();
    if (_apiService.hasToken) {
      // Already signed in via OTP — only update display name if needed.
      if (name.isNotEmpty) {
        _displayName = name;
        await _apiService.updateProfileField({'display_name': name});
        notifyListeners();
      }
      return;
    }
    await loginWithMock(displayName: name);
  }

  Future<void> loginWithMock({required String displayName}) async {
    try {
      _displayName = displayName.trim();
      if (_displayName.isEmpty) return;

      _isMockUser = true;
      _isLoggedIn = false;
      _onboardingComplete = false;
      _userProfile = null;
      _goals = null;
      _dailyLog = [];
      _authLoading = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest', true);
      await prefs.setBool('guest_onboarded', false);
      await prefs.setString('guest_display_name', _displayName);
      unawaited(_syncStepsAccount());

      notifyListeners();
    } catch (_) {}
  }

  Future<void> clearMockUser() async {
    await steps.eraseAccount();
    _isMockUser = false;
    _displayName = '';
    _userProfile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_guest');
    await prefs.remove('guest_display_name');
    await prefs.remove('guest_onboarded');
    await prefs.remove('guest_weight');
    await prefs.remove('guest_height');
    await prefs.remove('guest_age');
    await prefs.remove('guest_gender');
    await prefs.remove('guest_activity');
    await prefs.remove('guest_goal');
    await prefs.remove('guest_sicknesses');
    await prefs.remove('guest_allergies');
    await prefs.remove('guest_disabilities');
    await prefs.remove('guest_calories');
    await prefs.remove('guest_protein');
    await prefs.remove('guest_carbs');
    await prefs.remove('guest_fat');
    await prefs.remove('guest_daily_log');
    await prefs.remove('guest_water_ml');
    await prefs.remove('guest_water_date');
    await prefs.remove('guest_meal_plan');
    await prefs.remove('last_active_nutrition_date');
    await prefs.remove('guest_profile_ext');
    _clearData();
  }

  Future<void> logout() async {
    if (_isMockUser) {
      await clearMockUser();
      return;
    }
    if (supportsOptionalDeviceServices) {
      await PushService.instance.unregisterForUser(_apiService);
      unawaited(Purchases.logOut());
    }
    await _authService.signOut();
    _clearData();
  }

  /// Permanently deletes the authenticated user account and all personal data.
  /// Adheres to App Store Review Guideline 5.1.1(v).
  Future<bool> deleteAccount() async {
    if (_isMockUser) {
      await clearMockUser();
      return true;
    }
    final success = await _authService.deleteAccount();
    if (!success) return false;
    await steps.eraseAccount();
    if (supportsOptionalDeviceServices) {
      unawaited(Purchases.logOut());
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('guest_display_name');
      await prefs.remove('guest_weight');
      await prefs.remove('guest_height');
      await prefs.remove('guest_age');
      await prefs.remove('guest_gender');
      await prefs.remove('guest_activity');
      await prefs.remove('guest_goal');
      await prefs.remove('guest_sicknesses');
      await prefs.remove('guest_allergies');
      await prefs.remove('guest_disabilities');
      await prefs.remove('guest_calories');
      await prefs.remove('guest_protein');
      await prefs.remove('guest_carbs');
      await prefs.remove('guest_fat');
      await prefs.remove('guest_daily_log');
      await prefs.remove('guest_water_ml');
      await prefs.remove('guest_water_date');
      await prefs.remove('guest_meal_plan');
      await prefs.remove('last_active_nutrition_date');
      await prefs.remove('guest_profile_ext');
      await prefs.remove('saved_recipe');
      await prefs.remove('saved_custom_recipes');
      await prefs.remove('nutrition_history');
      await prefs.remove('weight_history');
    } catch (_) {}

    _clearData();
    return success;
  }

  UserProfile _profileFromOnboardingMap(
    String uid,
    NutritionalGoals goals,
    Map<String, dynamic> profile, {
    Map<String, double> microGoals = const {},
  }) {
    return UserProfile(
      uid: uid,
      weight: (profile['weight'] as num).toDouble(),
      height: (profile['height'] as num).toDouble(),
      age: profile['age'] as int,
      gender: profile['gender'] as String,
      activityLevel: profile['activity'] as String,
      goal: profile['goal'] as String,
      sicknesses: List<String>.from(profile['sicknesses'] ?? []),
      allergies: List<String>.from(profile['allergies'] ?? []),
      disabilities: List<String>.from(profile['disabilities'] ?? []),
      dailyCalories: goals.calories,
      dailyCarbs: goals.carbs,
      dailyProtein: goals.protein,
      dailyFat: goals.fat,
      language: _lang,
      theme: _themeMode,
      onboarded: true,
      displayName: _displayName,
      targetWeight: (profile['targetWeight'] as num?)?.toDouble(),
      pace: profile['pace'] as String? ?? 'moderate',
      bodyFatPct: (profile['bodyFatPct'] as num?)?.toDouble(),
      pregnancyStatus: profile['pregnancyStatus'] as String? ?? 'none',
      dietaryPattern: profile['dietaryPattern'] as String? ?? 'omnivore',
      dislikedFoods: List<String>.from(profile['dislikedFoods'] ?? []),
      cuisinePreference: profile['cuisinePreference'] as String? ?? 'mixed',
      mealsPerDay: (profile['mealsPerDay'] as num?)?.toInt() ?? 3,
      fastingWindow: profile['fastingWindow'] as String? ?? 'none',
      sleepHours: (profile['sleepHours'] as num?)?.toDouble(),
      stressLevel: profile['stressLevel'] as String? ?? 'medium',
      waterTargetMl: (profile['waterTargetMl'] as num?)?.toInt(),
      medications: profile['medications'] as String? ?? '',
      workoutDaysPerWeek: (profile['workoutDaysPerWeek'] as num?)?.toInt() ?? 0,
      workoutType: profile['workoutType'] as String? ?? 'none',
      cookingSkill: profile['cookingSkill'] as String? ?? 'intermediate',
      cookingTime: profile['cookingTime'] as String? ?? 'under30',
      dailyMicroGoals: microGoals,
    );
  }

  Future<void> finishOnboarding(
    NutritionalGoals newGoals,
    Map<String, dynamic> profile,
  ) async {
    final microGoals = await generateAiMicroGoals(profile);
    _microGoals = microGoals;
    await _saveMicroGoals();

    if (_isMockUser) {
      _goals = newGoals;
      _onboardingComplete = true;
      _userProfile = _profileFromOnboardingMap(
        'mock-user-123',
        newGoals,
        profile,
        microGoals: microGoals,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('guest_onboarded', true);
      await prefs.setDouble(
        'guest_weight',
        (profile['weight'] as num).toDouble(),
      );
      await prefs.setDouble(
        'guest_height',
        (profile['height'] as num).toDouble(),
      );
      await prefs.setInt('guest_age', profile['age'] as int);
      await prefs.setString('guest_gender', profile['gender'] as String);
      await prefs.setString('guest_activity', profile['activity'] as String);
      await prefs.setString('guest_goal', profile['goal'] as String);
      await prefs.setStringList(
        'guest_sicknesses',
        List<String>.from(profile['sicknesses'] ?? []),
      );
      await prefs.setStringList(
        'guest_allergies',
        List<String>.from(profile['allergies'] ?? []),
      );
      await prefs.setStringList(
        'guest_disabilities',
        List<String>.from(profile['disabilities'] ?? []),
      );
      await prefs.setInt('guest_calories', newGoals.calories);
      await prefs.setInt('guest_protein', newGoals.protein);
      await prefs.setInt('guest_carbs', newGoals.carbs);
      await prefs.setInt('guest_fat', newGoals.fat);

      await prefs.setString(
        'guest_profile_ext',
        jsonEncode(_userProfile!.toMap()),
      );

      await recordTodayWeight(_userProfile!.weight);
      notifyListeners();
      return;
    }

    if (!isLoggedIn) return;

    final uid = _apiService.userId?.toString() ?? '';
    final fullProfile = _profileFromOnboardingMap(
      uid,
      newGoals,
      profile,
      microGoals: microGoals,
    );

    // Update local state and move to the home screen immediately so the UI is
    // never stuck on the results screen if the network is slow. Persisting to
    // the server happens right after and has its own timeout.
    _goals = newGoals;
    _userProfile = fullProfile;
    _onboardingComplete = true;
    notifyListeners();

    await _apiService.saveUserProfile(fullProfile);
    await recordTodayWeight(fullProfile.weight);
    unawaited(generateHealthGuidance(fullProfile));
  }

  /// Manually overrides daily macro targets (from Settings).
  /// [changed] drives auto-balancing: editing macros updates calories (4/4/9),
  /// editing calories scales protein/carbs/fat proportionally.
  Future<void> updateMacros({
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    MacroEditField changed = MacroEditField.protein,
  }) async {
    final current =
        _goals ??
        NutritionalGoals(calories: 2000, protein: 100, carbs: 200, fat: 60);

    final balanced = rebalanceMacroEdit(
      current: current,
      changed: changed,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );

    final newCalories = balanced.calories;
    final newProtein = balanced.protein;
    final newCarbs = balanced.carbs;
    final newFat = balanced.fat;

    _goals = NutritionalGoals(
      calories: newCalories,
      protein: newProtein,
      carbs: newCarbs,
      fat: newFat,
    );
    _userProfile = _userProfile?.copyWithMacros(
      dailyCalories: newCalories,
      dailyProtein: newProtein,
      dailyCarbs: newCarbs,
      dailyFat: newFat,
    );
    _persistDailyNutritionSnapshot();
    notifyListeners();

    if (_isMockUser) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('guest_calories', newCalories);
      await prefs.setInt('guest_protein', newProtein);
      await prefs.setInt('guest_carbs', newCarbs);
      await prefs.setInt('guest_fat', newFat);
      if (_userProfile != null) {
        await prefs.setString(
          'guest_profile_ext',
          jsonEncode(_userProfile!.toMap()),
        );
      }
      return;
    }

    if (_isLoggedIn) {
      await _apiService.updateProfileField({
        'daily_calories': newCalories,
        'daily_protein': newProtein,
        'daily_carbs': newCarbs,
        'daily_fat': newFat,
      });
    }
  }

  Future<void> recordTodayWeight([double? weightKg]) async {
    final w = weightKg ?? _userProfile?.weight;
    if (w == null || w <= 0) return;
    _weightHistory[_nutritionDateKey(DateTime.now())] = w;
    await _saveWeightHistory();
    if (_isLoggedIn && !_isMockUser) {
      unawaited(_apiService.recordWeight(w));
    }
    notifyListeners();
  }

  Future<NutritionalGoals?> generateAiGoals(
    Map<String, dynamic> profile,
  ) async {
    return computeNutritionalGoalsFromProfile(profile);
  }

  Future<int> generateAiWaterTarget(
    Map<String, dynamic> profile, {
    NutritionalGoals? goals,
  }) async {
    return _fallbackWaterTargetMl(profile);
  }

  Future<Map<String, double>> generateAiMicroGoals(
    Map<String, dynamic> profile,
  ) async {
    final age = profile['age'] as int;
    final gender = profile['gender'] as String;
    final pregnancyStatus = profile['pregnancyStatus'] as String? ?? 'none';
    final sicknesses = List<String>.from(profile['sicknesses'] ?? []);

    Map<String, double> fallback() => computeMicroGoals(
      age: age,
      gender: gender,
      pregnancyStatus: pregnancyStatus,
      sicknesses: sicknesses,
      activityLevel: profile['activity'] as String? ?? 'moderatelyActive',
      weightKg: (profile['weight'] as num?)?.toDouble() ?? 70,
    );

    return fallback();
  }

  /// Local water target (no network) — safe for web / offline onboarding.
  int fallbackWaterTargetMl(Map<String, dynamic> profile) =>
      _fallbackWaterTargetMl(profile);

  Future<void> _loadMicroGoals(SharedPreferences prefs) async {
    final raw = prefs.getString('micro_goals');
    if (raw != null) {
      try {
        final map = Map<String, dynamic>.from(
          (const JsonCodec()).decode(raw) as Map,
        );
        _microGoals = map.map((k, v) => MapEntry(k, (v as num).toDouble()));
      } catch (_) {}
    }
    if (_microGoals.isEmpty) {
      await _ensureMicroGoalsFromProfile();
    }
  }

  Future<void> _saveMicroGoals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('micro_goals', jsonEncode(_microGoals));
    _userProfile = _userProfile?.copyWithMicroGoals(_microGoals);
  }

  Future<void> _ensureMicroGoalsFromProfile() async {
    final p = _userProfile;
    if (p == null) return;
    if (p.dailyMicroGoals.isNotEmpty) {
      _microGoals = Map<String, double>.from(p.dailyMicroGoals);
    } else {
      _microGoals = computeMicroGoals(
        age: p.age,
        gender: p.gender,
        pregnancyStatus: p.pregnancyStatus,
        sicknesses: p.sicknesses,
        activityLevel: p.activityLevel,
        weightKg: p.weight,
      );
    }
    await _saveMicroGoals();
    notifyListeners();
  }

  int _fallbackWaterTargetMl(Map<String, dynamic> profile) {
    final weight = (profile['weight'] as num).toDouble();
    final activity = profile['activity'] as String;

    var ml = weight * 32.0;

    const activityBonus = {
      'sedentary': 0.0,
      'lightlyActive': 200.0,
      'moderatelyActive': 400.0,
      'veryActive': 600.0,
      'extraActive': 800.0,
    };
    ml += activityBonus[activity] ?? 300.0;

    return ml.round().clamp(1500, 4000);
  }

  Future<bool> updateWater(int newVal) async {
    if (_isMockUser) {
      _waterIntake = newVal;
      await _saveGuestWater();
      notifyListeners();
      return true;
    }
    if (!_isLoggedIn) return false;
    final owner = _apiService.userId;
    final saved = await _apiService.updateWater(newVal);
    if (!_apiService.hasToken || _apiService.userId != owner) return false;
    _saveFailed = !saved;
    if (saved) _waterIntake = newVal;
    if (saved) await _apiService.cacheCurrentData(waterMl: newVal);
    notifyListeners();
    return saved;
  }

  Future<bool> addLogEntry(LogEntry entry) async {
    if (_isMockUser) {
      _dailyLog = [..._dailyLog, entry];
      await _saveGuestDailyLog();
      _persistDailyNutritionSnapshot();
      notifyListeners();
      return true;
    }
    if (!_isLoggedIn) return false;
    final owner = _apiService.userId;
    final saved = await _apiService.addFoodLog(entry);
    if (!_apiService.hasToken || _apiService.userId != owner) return false;
    _saveFailed = saved == null;
    if (saved != null) _dailyLog = [..._dailyLog, saved];
    if (saved != null) await _apiService.cacheCurrentData(logs: _dailyLog);
    _persistDailyNutritionSnapshot();
    notifyListeners();
    return saved != null;
  }

  Future<bool> removeLogEntry(String id) async {
    if (_isMockUser) {
      _dailyLog = _dailyLog.where((e) => e.id != id).toList();
      await _saveGuestDailyLog();
      _persistDailyNutritionSnapshot();
      notifyListeners();
      return true;
    }
    if (!_isLoggedIn) return false;
    final owner = _apiService.userId;
    final saved = await _apiService.removeFoodLog(id);
    if (!_apiService.hasToken || _apiService.userId != owner) return false;
    _saveFailed = !saved;
    if (saved) _dailyLog = _dailyLog.where((e) => e.id != id).toList();
    if (saved) await _apiService.cacheCurrentData(logs: _dailyLog);
    _persistDailyNutritionSnapshot();
    notifyListeners();
    return saved;
  }

  Future<bool> saveMealPlan(MealPlanData plan) async {
    if (_isMockUser) {
      _currentMealPlan = plan;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('guest_meal_plan', jsonEncode(plan.toMap()));
      notifyListeners();
      return true;
    }
    if (!_isLoggedIn) return false;
    final owner = _apiService.userId;
    final saved = await _apiService.saveMealPlan(plan);
    if (!_apiService.hasToken || _apiService.userId != owner) return false;
    _saveFailed = !saved;
    if (saved) _currentMealPlan = plan;
    if (saved) await _apiService.cacheCurrentData(mealPlan: plan);
    notifyListeners();
    return saved;
  }

  Future<void> refreshNutritionHistoryFromCloud() async {
    if (_isMockUser || !_isLoggedIn || !isOnline) return;
    final owner = _apiService.userId;
    final dates = last7DateKeys();
    try {
      final byDate = await _apiService.fetchFoodLogsForDates(dates);
      if (!_apiService.hasToken || _apiService.userId != owner) return;
      for (final e in byDate.entries) {
        double cal = 0, pro = 0, car = 0, fa = 0;
        for (final log in e.value) {
          cal += log.calories;
          pro += log.protein;
          car += log.carbs;
          fa += log.fat;
        }
        _nutritionHistory[e.key] = {
          'calories': cal.round(),
          'protein': pro.round(),
          'carbs': car.round(),
          'fat': fa.round(),
        };
      }
      await _saveNutritionHistory();
      notifyListeners();
    } catch (err) {
      debugPrint('refreshNutritionHistoryFromCloud: $err');
    }
  }

  Future<void> addFavorite(FavoriteTemplate template) async {
    _favorites = [..._favorites.where((f) => f.id != template.id), template];
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> removeFavorite(String id) async {
    _favorites = _favorites.where((f) => f.id != id).toList();
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> logFromFavorite(FavoriteTemplate f) async {
    await addLogEntry(
      LogEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        foodId: f.foodId ?? 'favorite-${f.id}',
        name: f.name,
        amount: f.amount,
        calories: f.calories,
        protein: f.protein,
        carbs: f.carbs,
        fat: f.fat,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        micros: f.micros,
      ),
    );
  }

  Future<ShoppingItemAddOutcome> addShoppingItem(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return ShoppingItemAddOutcome.empty;
    final norm = normalizeShoppingName(trimmed);
    if (norm.isEmpty) return ShoppingItemAddOutcome.empty;
    final dup = _shoppingList.any(
      (s) => !s.checked && normalizeShoppingName(s.name) == norm,
    );
    if (dup) return ShoppingItemAddOutcome.duplicate;
    final id = '${DateTime.now().microsecondsSinceEpoch}_${trimmed.hashCode}';
    _shoppingList = [..._shoppingList, ShoppingItem(id: id, name: trimmed)];
    await _saveShoppingList();
    notifyListeners();
    return ShoppingItemAddOutcome.added;
  }

  Future<void> removeShoppingItem(String id) async {
    _shoppingList = _shoppingList.where((s) => s.id != id).toList();
    await _saveShoppingList();
    notifyListeners();
  }

  Future<void> toggleShoppingItem(String id) async {
    _shoppingList = _shoppingList
        .map((s) => s.id == id ? s.copyWith(checked: !s.checked) : s)
        .toList();
    await _saveShoppingList();
    notifyListeners();
  }

  Future<void> clearCheckedShoppingItems() async {
    _shoppingList = _shoppingList.where((s) => !s.checked).toList();
    await _saveShoppingList();
    notifyListeners();
  }

  Future<ShoppingBulkAddResult> addIngredientsToShoppingList(
    List<String> ingredients,
  ) async {
    final seenUnchecked = <String>{
      for (final s in _shoppingList)
        if (!s.checked) normalizeShoppingName(s.name),
    };
    var next = List<ShoppingItem>.from(_shoppingList);
    var added = 0, skippedDup = 0, skippedEmpty = 0;
    var i = 0;
    for (final raw in ingredients) {
      final name = raw.trim();
      if (name.isEmpty) {
        skippedEmpty++;
        continue;
      }
      final norm = normalizeShoppingName(name);
      if (norm.isEmpty) {
        skippedEmpty++;
        continue;
      }
      if (seenUnchecked.contains(norm)) {
        skippedDup++;
        continue;
      }
      seenUnchecked.add(norm);
      i++;
      added++;
      next.add(
        ShoppingItem(
          id: '${DateTime.now().microsecondsSinceEpoch}_${i}_${name.hashCode}',
          name: name,
        ),
      );
    }
    if (added > 0) {
      _shoppingList = next;
      await _saveShoppingList();
      notifyListeners();
    }
    return ShoppingBulkAddResult(
      addedCount: added,
      skippedDuplicateCount: skippedDup,
      skippedEmptyCount: skippedEmpty,
    );
  }

  Future<void> setWeeklyDigestEnabled(bool enabled) async {
    _weeklyDigestEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('weekly_digest_enabled', enabled);
    if (supportsOptionalDeviceServices) {
      if (enabled) {
        await _persistWeeklyDigestNotifStrings();
        final p = await SharedPreferences.getInstance();
        await NotificationService.instance.scheduleWeeklySummary(
          title:
              p.getString('weekly_digest_notif_title') ?? t.weeklyDigestTitle,
          body: p.getString('weekly_digest_notif_body') ?? t.weeklyDigestBody,
        );
      } else {
        await NotificationService.instance.cancelWeeklySummary();
      }
    }
    notifyListeners();
  }

  Future<void> setMealPlanCuisine(String cuisine) async {
    _mealPlanCuisine = sanitizeMealPlanCuisine(cuisine);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('meal_plan_cuisine', _mealPlanCuisine);
    notifyListeners();
  }

  // ─── Premium ────────────────────────────────────────

  void _loadPremium(SharedPreferences prefs) {
    _isPremium = prefs.getBool('is_premium') ?? false;
    final untilMs = prefs.getInt('premium_until_ms');
    _premiumUntil = untilMs != null
        ? DateTime.fromMillisecondsSinceEpoch(untilMs, isUtc: true)
        : null;
  }

  Future<void> setPremium(bool active, {DateTime? until}) async {
    _isPremium = active;
    _premiumUntil = active ? until?.toUtc() : null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', active);
    if (_premiumUntil != null) {
      await prefs.setInt(
        'premium_until_ms',
        _premiumUntil!.millisecondsSinceEpoch,
      );
    } else {
      await prefs.remove('premium_until_ms');
    }
    // Subscription changes never imply health onboarding is complete.
    notifyListeners();
  }

  Future<void> syncPremiumFromServer() async {
    if (_isMockUser || !_isLoggedIn) return;
    final sub = await _apiService.getSubscription();
    if (sub == null) return;
    if (sub['isPremium'] == true) {
      await setPremium(
        true,
        until: DateTime.tryParse(sub['expiresAt']?.toString() ?? ''),
      );
      return;
    }
    if (supportsOptionalDeviceServices) {
      try {
        if (await _applyStoreEntitlement(await Purchases.getCustomerInfo())) {
          return;
        }
      } catch (_) {
        return;
      }
    }
    await setPremium(false);
  }

  Future<bool> _applyStoreEntitlement(CustomerInfo info) async {
    final entitlement = info.entitlements.all['all_feature'];
    if (entitlement?.isActive != true) return false;
    final expiration = DateTime.tryParse(entitlement?.expirationDate ?? '');
    if (expiration != null && !expiration.isAfter(DateTime.now())) return false;
    await setPremium(true, until: expiration);
    if (_isLoggedIn && !_isMockUser) {
      unawaited(_apiService.postSubscription());
    }
    return true;
  }

  Future<void> syncPremiumFromRevenueCat() async {
    if (!supportsOptionalDeviceServices) return;
    try {
      final info = await Purchases.getCustomerInfo();
      if (!await _applyStoreEntitlement(info) && _isLoggedIn && !_isMockUser) {
        await syncPremiumFromServer();
      }
    } catch (_) {}
  }

  Future<bool> purchasePremium({String? productId}) async {
    if (!supportsOptionalDeviceServices || !isAuthenticated) return false;
    try {
      await Purchases.logIn(_apiService.userId!.toString());
      if (productId != null) {
        final products = await Purchases.getProducts([productId]);
        if (products.isEmpty) return false;
        final result = await Purchases.purchase(
          PurchaseParams.storeProduct(products.first),
        );
        return await _applyStoreEntitlement(result.customerInfo);
      }
      final offerings = await Purchases.getOfferings();
      final packages = offerings.current?.availablePackages ?? [];
      if (packages.isEmpty) return false;
      final result = await Purchases.purchase(
        PurchaseParams.package(packages.first),
      );
      return await _applyStoreEntitlement(result.customerInfo);
    } catch (_) {
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    if (!isAuthenticated) return false;
    if (!supportsOptionalDeviceServices) {
      await syncPremiumFromServer();
      return isPremium;
    }
    try {
      await Purchases.logIn(_apiService.userId!.toString());
      if (await _applyStoreEntitlement(await Purchases.restorePurchases())) {
        return true;
      }
      await syncPremiumFromServer();
    } catch (_) {}
    return isPremium;
  }

  // ─── Notifications inbox ─────────────────────────────

  Future<void> _loadNotifications(SharedPreferences prefs) async {
    _lastSeenNotificationId = prefs.getInt('notif_last_seen_id') ?? 0;
    final raw = prefs.getString('notif_inbox');
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _notifications = list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } catch (_) {
        _notifications = [];
      }
    }
  }

  Future<void> _saveNotifications(SharedPreferences prefs) async {
    // Keep at most the 100 most recent.
    final trimmed = _notifications.take(100).toList();
    await prefs.setString('notif_inbox', jsonEncode(trimmed));
  }

  /// Fetches new notifications from the server, stores them in the inbox, and
  /// fires a local notification for each new one.
  Future<void> syncNotifications() async {
    if (_isMockUser || !_isLoggedIn) return;
    try {
      final existingIds = _notifications
          .map((n) => n['id'] as int? ?? 0)
          .toSet();
      final fetched = await _apiService.getNotifications();
      if (fetched.isEmpty) return;

      final incoming = fetched
          .map(
            (n) => {
              'id': (n['id'] as num?)?.toInt() ?? 0,
              'title': n['title']?.toString() ?? '',
              'translations': n['translations'],
              'body': n['body']?.toString() ?? '',
              'createdAt': n['createdAt']?.toString() ?? '',
            },
          )
          .toList();

      final fresh = incoming
          .where((n) => !existingIds.contains(n['id']))
          .toList();
      if (fresh.isEmpty) return;

      // Newest first.
      _notifications = [...fresh, ..._notifications]
        ..sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));

      final prefs = await SharedPreferences.getInstance();
      await _saveNotifications(prefs);

      if (supportsOptionalDeviceServices) {
        for (final n in fresh) {
          try {
            await NotificationService.instance.showServerNotification(
              id: n['id'] as int,
              title: notificationText(n, 'title', _lang).isEmpty
                  ? 'BNYAD'
                  : notificationText(n, 'title', _lang),
              body: notificationText(n, 'body', _lang),
            );
          } catch (e) {
            debugPrint('show server notification error: $e');
          }
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('syncNotifications error: $e');
    }
  }

  /// Marks the inbox as read (clears the unread badge).
  Future<void> markNotificationsRead() async {
    if (_notifications.isEmpty) return;
    final topId = _notifications
        .map((n) => n['id'] as int? ?? 0)
        .fold<int>(0, (a, b) => a > b ? a : b);
    if (topId <= _lastSeenNotificationId) return;
    _lastSeenNotificationId = topId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notif_last_seen_id', topId);
    notifyListeners();
  }

  // ─── Meal Reminders ─────────────────────────────────

  Future<void> _loadReminders(SharedPreferences prefs) async {
    for (final meal in ['breakfast', 'lunch', 'dinner', 'snacks']) {
      _reminderEnabled[meal] =
          prefs.getBool('reminder_${meal}_enabled') ?? false;
      final h = prefs.getInt('reminder_${meal}_hour');
      final m = prefs.getInt('reminder_${meal}_minute');
      if (h != null && m != null) {
        _reminderTimes[meal] = TimeOfDay(hour: h, minute: m);
      }
    }
  }

  Future<void> _rescheduleAllReminders() async {
    for (final mealId in ['breakfast', 'lunch', 'dinner', 'snacks']) {
      if (_reminderEnabled[mealId] == true) {
        final time = _reminderTimes[mealId];
        if (time != null) {
          final label = _reminderLabel(mealId);
          await NotificationService.instance.scheduleMealReminder(
            mealId: mealId,
            hour: time.hour,
            minute: time.minute,
            title: label,
            body: t.timeToEat,
          );
        }
      }
    }
    debugPrint('All enabled reminders re-scheduled');
  }

  Future<void> setReminderEnabled(String mealId, bool enabled) async {
    _reminderEnabled[mealId] = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_${mealId}_enabled', enabled);

    if (supportsOptionalDeviceServices) {
      if (enabled) {
        final time = _reminderTimes[mealId]!;
        final label = _reminderLabel(mealId);
        await NotificationService.instance.scheduleMealReminder(
          mealId: mealId,
          hour: time.hour,
          minute: time.minute,
          title: label,
          body: t.timeToEat,
        );
      } else {
        await NotificationService.instance.cancelMealReminder(mealId);
      }
    }
    notifyListeners();
  }

  Future<void> setReminderTime(String mealId, TimeOfDay time) async {
    _reminderTimes[mealId] = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_${mealId}_hour', time.hour);
    await prefs.setInt('reminder_${mealId}_minute', time.minute);

    if (supportsOptionalDeviceServices && (_reminderEnabled[mealId] ?? false)) {
      final label = _reminderLabel(mealId);
      await NotificationService.instance.scheduleMealReminder(
        mealId: mealId,
        hour: time.hour,
        minute: time.minute,
        title: label,
        body: t.timeToEat,
      );
    }
    notifyListeners();
  }

  String _reminderLabel(String mealId) {
    switch (mealId) {
      case 'breakfast':
        return t.breakfastReminder;
      case 'lunch':
        return t.lunchReminder;
      case 'dinner':
        return t.dinnerReminder;
      case 'snacks':
        return t.snacksReminder;
      default:
        return mealId;
    }
  }

  // ─── Custom Recipe ──────────────────────────────────

  Future<void> saveCustomRecipe(Map<String, dynamic> recipe) async {
    _savedRecipe = recipe;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_recipe', const JsonCodec().encode(recipe));
    notifyListeners();
  }

  Future<void> clearCustomRecipe() async {
    _savedRecipe = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_recipe');
    notifyListeners();
  }

  Future<void> _loadSavedRecipe(SharedPreferences prefs) async {
    final raw = prefs.getString('saved_recipe');
    if (raw != null) {
      try {
        _savedRecipe = const JsonCodec().decode(raw) as Map<String, dynamic>;
      } catch (_) {}
    }
  }

  // ─── Vitamins / Pills ───────────────────────────────

  Future<void> _loadVitamins(SharedPreferences prefs) async {
    final raw = prefs.getStringList('vitamins') ?? [];
    _vitamins = raw
        .map((s) {
          try {
            final map = Map<String, dynamic>.from(
              (const JsonCodec()).decode(s) as Map,
            );
            return VitaminEntry.fromMap(map);
          } catch (_) {
            return null;
          }
        })
        .whereType<VitaminEntry>()
        .toList();
  }

  Future<void> _saveVitamins() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _vitamins
        .map((v) => const JsonCodec().encode(v.toMap()))
        .toList();
    await prefs.setStringList('vitamins', raw);
  }

  Future<void> addVitamin(VitaminEntry entry) async {
    _vitamins = [..._vitamins, entry];
    await _saveVitamins();
    if (supportsOptionalDeviceServices && entry.reminderEnabled) {
      await _scheduleVitaminReminder(entry);
    }
    notifyListeners();
  }

  Future<void> removeVitamin(String id) async {
    if (supportsOptionalDeviceServices) {
      await NotificationService.instance.cancelSupplementReminder(id);
    }
    _vitamins = _vitamins.where((v) => v.id != id).toList();
    await _saveVitamins();
    notifyListeners();
  }

  Future<void> setVitaminReminder(
    String id, {
    required bool enabled,
    TimeOfDay? time,
  }) async {
    _vitamins = _vitamins.map((v) {
      if (v.id != id) return v;
      final h = time?.hour ?? v.reminderHour ?? 8;
      final m = time?.minute ?? v.reminderMinute ?? 0;
      return v.copyWith(
        reminderEnabled: enabled,
        reminderHour: h,
        reminderMinute: m,
      );
    }).toList();
    await _saveVitamins();

    final updated = _vitamins.firstWhere((v) => v.id == id);
    if (supportsOptionalDeviceServices) {
      if (enabled) {
        await _scheduleVitaminReminder(updated);
      } else {
        await NotificationService.instance.cancelSupplementReminder(id);
      }
    }
    notifyListeners();
  }

  Future<void> _scheduleVitaminReminder(VitaminEntry v) async {
    if (!v.reminderEnabled) return;
    final hour = v.reminderHour ?? 8;
    final minute = v.reminderMinute ?? 0;
    await NotificationService.instance.scheduleSupplementReminder(
      vitaminId: v.id,
      hour: hour,
      minute: minute,
      title: t.supplementReminderTitle,
      body: '${t.takeYourSupplement}: ${v.name}',
    );
  }

  Future<void> _rescheduleAllSupplementReminders() async {
    if (!supportsOptionalDeviceServices) return;
    for (final v in _vitamins) {
      if (v.reminderEnabled) {
        await _scheduleVitaminReminder(v);
      }
    }
  }

  Future<void> toggleVitaminTaken(String id) async {
    _vitamins = _vitamins.map((v) {
      if (v.id == id) return v.copyWith(taken: !v.taken);
      return v;
    }).toList();
    await _saveVitamins();
    notifyListeners();
  }

  Future<void> resetVitaminsTaken() async {
    _vitamins = _vitamins.map((v) => v.copyWith(taken: false)).toList();
    await _saveVitamins();
    notifyListeners();
  }

  Future<void> generateHealthGuidance(UserProfile? profile) async {
    if (profile == null) return;
    if (!isPremium) return;
    if (await getAiConsent() != true) return;
    final g = _goals;
    _healthGuidanceByLang = await ai.generateHealthGuidance(
      disabilities: profile.disabilities,
      sicknesses: profile.sicknesses,
      allergies: profile.allergies,
      dailyCalories: g?.calories ?? profile.dailyCalories,
      dailyProtein: g?.protein ?? 90,
      dailyCarbs: g?.carbs ?? 250,
      dailyFat: g?.fat ?? 70,
      nutritionGoalLabel: localizedNutritionGoalLabel,
      dietaryPattern: profile.dietaryPattern,
      dislikedFoods: profile.dislikedFoods,
      cuisinePreference: profile.cuisinePreference,
      pace: profile.pace,
      pregnancyStatus: profile.pregnancyStatus,
      workoutDaysPerWeek: profile.workoutDaysPerWeek,
      workoutType: profile.workoutType,
      fastingWindow: profile.fastingWindow,
      mealsPerDay: profile.mealsPerDay,
      sleepHours: profile.sleepHours,
      stressLevel: profile.stressLevel,
      waterTargetMl: profile.waterTargetMl,
      targetWeight: profile.targetWeight,
      bodyFatPct: profile.bodyFatPct,
      medications: profile.medications,
    );
    notifyListeners();
  }

  Future<bool> checkConnectivity() async {
    if (!supportsOptionalDeviceServices) {
      _isOnline = true;
      return true;
    }
    try {
      final results = await Connectivity().checkConnectivity();
      bool online =
          results.isEmpty || results.any((r) => r != ConnectivityResult.none);
      if (!online) {
        try {
          final lookup = await InternetAddress.lookup(
            'google.com',
          ).timeout(const Duration(seconds: 3));
          if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
            online = true;
          }
        } catch (_) {}
      }
      if (_isOnline != online) {
        _isOnline = online;
        notifyListeners();
      }
      return online;
    } catch (e) {
      debugPrint('Connectivity check: $e');
      return _isOnline;
    }
  }

  void _startConnectivityListener() {
    if (!supportsOptionalDeviceServices) return;
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (results) async {
        bool online =
            results.isEmpty || results.any((r) => r != ConnectivityResult.none);
        if (!online) {
          try {
            final lookup = await InternetAddress.lookup(
              'google.com',
            ).timeout(const Duration(seconds: 3));
            if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
              online = true;
            }
          } catch (_) {}
        }
        if (_isOnline != online) {
          _isOnline = online;
          notifyListeners();
          if (online && _isLoggedIn && !_isMockUser) {
            unawaited(_fetchUserData());
          }
        }
      },
      onError: (_) {
        // Connectivity plugins can be unavailable temporarily or on tests.
        // This must not discard authentication or user data.
      },
    );
    unawaited(checkConnectivity());
  }

  Future<void> _persistWeeklyDigestNotifStrings() async {
    final loc = AppLocalizations(_lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('weekly_digest_notif_title', loc.weeklyDigestTitle);
    await prefs.setString('weekly_digest_notif_body', loc.weeklyDigestBody);
  }

  void _persistDailyNutritionSnapshot() {
    final key = _nutritionDateKey(DateTime.now());
    final s = consumedStats;
    _nutritionHistory[key] = Map<String, int>.from(s);
    unawaited(_saveNutritionHistory());
  }

  Future<void> _saveNutritionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_nutritionHistory.map((k, v) => MapEntry(k, v)));
    await prefs.setString('nutrition_history', encoded);
  }

  Future<void> _loadNutritionHistory(SharedPreferences prefs) async {
    final raw = prefs.getString('nutrition_history');
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _nutritionHistory.clear();
      for (final e in map.entries) {
        final inner = e.value as Map<String, dynamic>;
        _nutritionHistory[e.key] = inner.map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        );
      }
    } catch (_) {}
  }

  Future<void> _saveWeightHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_weightHistory.map((k, v) => MapEntry(k, v)));
    await prefs.setString('weight_history', encoded);
  }

  Future<void> _loadWeightHistory(SharedPreferences prefs) async {
    final raw = prefs.getString('weight_history');
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _weightHistory.clear();
      for (final e in map.entries) {
        _weightHistory[e.key] = (e.value as num).toDouble();
      }
    } catch (_) {}
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'favorites',
      _favorites.map((f) => f.toJsonString()).toList(),
    );
  }

  Future<void> _loadFavorites(SharedPreferences prefs) async {
    final raw = prefs.getStringList('favorites') ?? [];
    _favorites = raw
        .map(FavoriteTemplate.tryParse)
        .whereType<FavoriteTemplate>()
        .toList();
  }

  Future<void> _saveShoppingList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'shopping_list',
      _shoppingList.map((s) => s.toJsonString()).toList(),
    );
  }

  Future<void> _loadShoppingList(SharedPreferences prefs) async {
    final raw = prefs.getStringList('shopping_list') ?? [];
    _shoppingList = raw
        .map(ShoppingItem.tryParse)
        .whereType<ShoppingItem>()
        .toList();
  }

  Future<void> _saveGuestDailyLog() async {
    if (!_isMockUser) return;
    final prefs = await SharedPreferences.getInstance();
    final payload = {
      'date': _nutritionDateKey(DateTime.now()),
      'entries': _dailyLog.map(_logEntryToJson).toList(),
    };
    await prefs.setString('guest_daily_log', jsonEncode(payload));
  }

  Future<void> _loadGuestDailyLog(SharedPreferences prefs) async {
    final raw = prefs.getString('guest_daily_log');
    if (raw == null) return;
    final today = _nutritionDateKey(DateTime.now());
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final storedDate = decoded['date'] as String?;
        if (storedDate != today) {
          _dailyLog = [];
          await _saveGuestDailyLog();
          return;
        }
        final entries = decoded['entries'] as List<dynamic>? ?? [];
        _dailyLog = entries
            .map((e) => _logEntryFromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        return;
      }
      if (decoded is List) {
        _dailyLog = decoded
            .map((e) => _logEntryFromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _saveGuestWater() async {
    if (!_isMockUser) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('guest_water_ml', _waterIntake);
    await prefs.setString(
      'guest_water_date',
      _nutritionDateKey(DateTime.now()),
    );
  }

  Future<void> _loadGuestWater(SharedPreferences prefs) async {
    final storedDate = prefs.getString('guest_water_date');
    final today = _nutritionDateKey(DateTime.now());
    if (storedDate == today) {
      _waterIntake = prefs.getInt('guest_water_ml') ?? 0;
    } else {
      _waterIntake = 0;
    }
  }

  Future<void> _loadGuestMealPlan(SharedPreferences prefs) async {
    final raw = prefs.getString('guest_meal_plan');
    if (raw == null) return;
    try {
      _currentMealPlan = MealPlanData.fromMap(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    steps.removeListener(notifyListeners);
    steps.dispose();
    _connectivitySub?.cancel();
    _apiService.onSessionInvalidated = null;
    _apiService.dispose();
    super.dispose();
  }
}
