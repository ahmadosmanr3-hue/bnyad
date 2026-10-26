/// Complete trilingual localization for BNYAD
/// Languages: English (en), Arabic (ar), Central Kurdish (ckb; legacy ku).
class AppLocalizations {
  static const Map<String, Map<String, dynamic>> _translations = {
    'en': _en,
    'ar': _ar,
    'ku': _ku,
    'ckb': _ku,
  };

  final String locale;
  late final Map<String, dynamic> _t;

  AppLocalizations(this.locale) {
    _t = _translations[locale] ?? _translations['en']!;
  }

  String get(String key) => _t[key]?.toString() ?? key;

  String getGoal(String key) =>
      (_t['goalList'] as Map<String, String>?)?[key] ?? key;
  String getSickness(String key) =>
      (_t['sicknessesList'] as Map<String, String>?)?[key] ?? key;
  String getAllergy(String key) =>
      (_t['allergiesList'] as Map<String, String>?)?[key] ?? key;
  String getDisability(String key) =>
      (_t['disabilitiesList'] as Map<String, String>?)?[key] ?? key;
  String getPace(String key) =>
      (_t['paceList'] as Map<String, String>?)?[key] ?? key;
  String getPregnancyStatus(String key) =>
      (_t['pregnancyStatusList'] as Map<String, String>?)?[key] ?? key;
  String getDietaryPattern(String key) =>
      (_t['dietaryPatternList'] as Map<String, String>?)?[key] ?? key;
  String getDislikedFood(String key) =>
      (_t['dislikedFoodsList'] as Map<String, String>?)?[key] ?? key;
  String getCuisinePreference(String key) =>
      (_t['cuisinePreferenceList'] as Map<String, String>?)?[key] ?? key;
  String getMealsPerDay(String key) =>
      (_t['mealsPerDayList'] as Map<String, String>?)?[key] ?? key;
  String getFastingWindow(String key) =>
      (_t['fastingWindowList'] as Map<String, String>?)?[key] ?? key;
  String getStressLevel(String key) =>
      (_t['stressLevelList'] as Map<String, String>?)?[key] ?? key;
  String getWorkoutType(String key) =>
      (_t['workoutTypeList'] as Map<String, String>?)?[key] ?? key;
  String getCookingSkill(String key) =>
      (_t['cookingSkillList'] as Map<String, String>?)?[key] ?? key;
  String getCookingTime(String key) =>
      (_t['cookingTimeList'] as Map<String, String>?)?[key] ?? key;
  List<String> get instructionsSteps =>
      List<String>.from(_t['instructionsSteps'] ?? []);

  bool get isRTL => locale == 'ar' || locale == 'ku' || locale == 'ckb';

  String get retry => locale == 'ar'
      ? 'إعادة المحاولة'
      : isRTL && locale != 'ar'
      ? 'دووبارە هەوڵبدەرەوە'
      : 'Try again';
  String get saveFailed => locale == 'ar'
      ? 'لم يتم حفظ التغيير. تحقق من الاتصال وحاول مرة أخرى.'
      : isRTL
      ? 'گۆڕانکارییەکە پاشەکەوت نەکرا. پەیوەندیی ئینتەرنێتەکەت بپشکنە و دووبارە هەوڵبدەرەوە.'
      : 'Your change was not saved. Check your connection and try again.';
  String get sessionUnavailable => locale == 'ar'
      ? 'تعذر استعادة جلستك الآن. تحقق من الاتصال وحاول مرة أخرى. لم يتم حذف بيانات تسجيل الدخول.'
      : isRTL
      ? 'ئێستا نەتوانرا چوونەژوورەوەکەت بگەڕێندرێتەوە. پەیوەندیی ئینتەرنێتەکەت بپشکنە و دووبارە هەوڵبدەرەوە. زانیارییەکانی چوونەژوورەوەت نەسڕاونەتەوە.'
      : 'Your session could not be restored yet. Check your connection and try again. Your saved sign-in has been kept.';
  String get purchaseFailed => locale == 'ar'
      ? 'لم تكتمل عملية الشراء أو تم إلغاؤها.'
      : isRTL
      ? 'کڕینەکە تەواو نەبوو یان هەڵوەشێندرایەوە.'
      : 'Purchase failed or cancelled.';
  String get purchaseVerificationPending => locale == 'ar'
      ? 'اكتملت خطوة المتجر، لكن التحقق من الاشتراك لم يكتمل بعد. لا تشترِ مرة أخرى. تحقق من الاتصال واستخدم استعادة المشتريات.'
      : isRTL
      ? 'هەنگاوی فرۆشگاکە تەواو بوو، بەڵام پشتڕاستکردنەوەی بەشداریکردنەکە هێشتا تەواو نەبووە. دووبارە مەیکڕەوە. پەیوەندییەکەت بپشکنە و گەڕاندنەوەی کڕینەکان بەکاربهێنە.'
      : 'The store step completed, but subscription verification is still pending. Do not purchase again. Check your connection and use Restore Purchases.';
  String get linkFailed => locale == 'ar'
      ? 'تعذر فتح الرابط. حاول مرة أخرى.'
      : isRTL
      ? 'نەتوانرا بەستەرەکە بکرێتەوە. دووبارە هەوڵبدەرەوە.'
      : 'Could not open the link. Try again.';
  String get monthlyPlan => locale == 'ar'
      ? 'خطة شهرية'
      : isRTL
      ? 'پلانی مانگانە'
      : 'Monthly plan';
  String get yearlyPlan => locale == 'ar'
      ? 'خطة سنوية'
      : isRTL
      ? 'پلانی ساڵانە'
      : 'Yearly plan';
  String get monthlyBilling => locale == 'ar'
      ? 'تُجدد شهرياً. يمكنك الإلغاء من المتجر.'
      : isRTL
      ? 'مانگانە نوێ دەکرێتەوە. دەتوانیت لە فرۆشگاکە هەڵیوەشێنیتەوە.'
      : 'Renews monthly. Cancel through your store.';
  String get yearlyBilling => locale == 'ar'
      ? 'تُجدد سنوياً. يمكنك الإلغاء من المتجر.'
      : isRTL
      ? 'ساڵانە نوێ دەکرێتەوە. دەتوانیت لە فرۆشگاکە هەڵیوەشێنیتەوە.'
      : 'Renews yearly. Cancel through your store.';
  String get storePrice => locale == 'ar'
      ? 'السعر في المتجر'
      : isRTL
      ? 'نرخ لە فرۆشگاکە'
      : 'Price shown by your store';
  String get restoreSuccess => locale == 'ar'
      ? 'تمت استعادة الاشتراك.'
      : isRTL
      ? 'بەشداریکردنەکەت گەڕێندرایەوە.'
      : 'Subscription restored.';
  String get restoreNotFound => locale == 'ar'
      ? 'لم يتم العثور على اشتراك فعال.'
      : isRTL
      ? 'هیچ بەشداریکردنێکی چالاک نەدۆزرایەوە.'
      : 'No active subscription found.';
  String get manageSubscription => locale == 'ar'
      ? 'إدارة الاشتراك في المتجر'
      : isRTL
      ? 'بەڕێوەبردنی بەشداریکردن لە فرۆشگاکە'
      : 'Manage subscription in your store';

  /// Do not display English server messages verbatim in Arabic/Sorani mode.
  String localizeError(String message) {
    if (!isRTL) return message;
    final lower = message.toLowerCase();
    final ar = locale == 'ar';
    if (lower.contains('network') ||
        lower.contains('temporarily') ||
        lower.contains('server')) {
      return ar
          ? 'تعذر الاتصال بالخادم. تحقق من اتصال الإنترنت وحاول مرة أخرى.'
          : 'نەتوانرا پەیوەندی بە سێرڤەرەوە بکرێت. پەیوەندیی ئینتەرنێتەکەت بپشکنە و دووبارە هەوڵبدەرەوە.';
    }
    if (lower.contains('too many') || lower.contains('rate')) {
      return ar
          ? 'محاولات كثيرة. انتظر قليلاً ثم حاول مجدداً.'
          : 'هەوڵدانەکان زۆرن. کەمێک چاوەڕێ بکە، پاشان دووبارە هەوڵبدەرەوە.';
    }
    if (lower.contains('password') &&
        (lower.contains('incorrect') || lower.contains('login'))) {
      return ar
          ? 'رقم الهاتف أو كلمة المرور غير صحيحة.'
          : 'ژمارەی مۆبایل یان وشەی نهێنی هەڵەیە.';
    }
    if (lower.contains('expired')) {
      return ar
          ? 'انتهت صلاحية الرمز. اطلب رمزاً جديداً.'
          : 'ماوەی کۆدەکە بەسەرچووە. داوای کۆدێکی نوێ بکە.';
    }
    if (lower.contains('code') || lower.contains('verification')) {
      return ar
          ? 'تعذر التحقق من الرمز. تحقق منه أو اطلب رمزاً جديداً.'
          : 'نەتوانرا کۆدەکە پشتڕاست بکرێتەوە. کۆدەکە بپشکنە یان داوای کۆدێکی نوێ بکە.';
    }
    if (lower.contains('password')) return invalidPassword;
    if (lower.contains('phone')) return invalidPhoneNumber;
    return ar
        ? 'لم تكتمل العملية. حاول مرة أخرى.'
        : 'کردارەکە تەواو نەبوو. دووبارە هەوڵبدەرەوە.';
  }

  /// Used by regression tests to audit complete key/nested-key coverage.
  static Map<String, dynamic> translationsFor(String locale) =>
      Map.unmodifiable(_translations[locale] ?? _en);

  // Convenience getters
  String get dashboard => get('dashboard');
  String get profile => get('profile');
  String get foodLog => get('foodLog');
  String get calories => get('calories');
  String get carbs => get('carbs');
  String get protein => get('protein');
  String get fat => get('fat');
  String get macronutrients => get('macronutrients');
  String get water => get('water');
  String get waterIntake => get('waterIntake');
  String get glasses => get('glasses');
  String get weight => get('weight');
  String get height => get('height');
  String get age => get('age');
  String get gender => get('gender');
  String get male => get('male');
  String get female => get('female');
  String get activityLevel => get('activityLevel');
  String get sedentary => get('sedentary');
  String get lightlyActive => get('lightlyActive');
  String get moderatelyActive => get('moderatelyActive');
  String get veryActive => get('veryActive');
  String get extraActive => get('extraActive');
  String get calculate => get('calculate');
  String get bmr => get('bmr');
  String get tdee => get('tdee');
  String get searchFood => get('searchFood');
  String get addMeal => get('addMeal');
  String get addFood => get('addFood');
  String get language => get('language');
  String get english => get('english');
  String get arabic => get('arabic');
  String get kurdish => get('kurdish');
  String get onboardingTitle => get('onboardingTitle');
  String get onboardingSubtitle => get('onboardingSubtitle');
  String get disabilities => get('disabilities');
  String get sicknesses => get('sicknesses');
  String get allergies => get('allergies');
  String get next => get('next');
  String get back => get('back');
  String get finish => get('finish');
  String get analyzing => get('analyzing');
  String get goalSet => get('goalSet');
  String get getStarted => get('getStarted');
  String get settings => get('settings');
  String get theme => get('theme');
  String get light => get('light');
  String get dark => get('dark');
  String get selectSicknesses => get('selectSicknesses');
  String get selectAllergies => get('selectAllergies');
  String get search => get('search');
  String get selected => get('selected');
  String get none => get('none');
  String get mealPlan => get('mealPlan');
  String get generateMealPlan => get('generateMealPlan');
  String get generatePlan => get('generatePlan');
  String get mealPlanSubtitle => get('mealPlanSubtitle');
  String get breakfast => get('breakfast');
  String get lunch => get('lunch');
  String get dinner => get('dinner');
  String get snacks => get('snacks');
  String get generating => get('generating');
  String get selectDisabilities => get('selectDisabilities');
  String get ingredients => get('ingredients');
  String get instructions => get('instructions');
  String get logAsEaten => get('logAsEaten');
  String get eaten => get('eaten');
  String get goals => get('goals');
  String get selectGoal => get('selectGoal');
  String get healthGuidance => get('healthGuidance');
  String get healthGuidanceSubtitle => get('healthGuidanceSubtitle');
  String get amount => get('amount');
  String get grams => get('grams');
  String get add => get('add');
  String get total => get('total');
  String get searchPlaceholder => get('searchPlaceholder');
  String get browseFoods => get('browseFoods');
  String get selectFood => get('selectFood');
  String get close => get('close');
  String get foodScanner => get('foodScanner');
  String get readyToScan => get('readyToScan');
  String get scanSubtitle => get('scanSubtitle');
  String get startCamera => get('startCamera');
  String get uploadPhoto => get('uploadPhoto');
  String get aiAnalyzed => get('aiAnalyzed');
  String get logAsEaten100g => get('logAsEaten100g');
  String get howToUse => get('howToUse');
  String get legalAndMedicalSources => get('legalAndMedicalSources');
  String get privacyPolicy => get('privacyPolicy');
  String get termsOfUseEula => get('termsOfUseEula');
  String get medicalSourcesCitations => get('medicalSourcesCitations');
  String get subscriptionAutoRenewTerms => get('subscriptionAutoRenewTerms');
  String get privacyMedicalSourcesTitle => get('privacyMedicalSourcesTitle');
  String get privacyMedicalSourcesSubtitle =>
      get('privacyMedicalSourcesSubtitle');
  String get privacyMedicalDisclaimerTitle =>
      get('privacyMedicalDisclaimerTitle');
  String get privacyMedicalDisclaimerBody =>
      get('privacyMedicalDisclaimerBody');
  String get privacyMedicalViewSourceLink =>
      get('privacyMedicalViewSourceLink');
  String get privacyMedicalSourcesBmrCategory =>
      get('privacyMedicalSourcesBmrCategory');
  String get privacyMedicalSourcesBmrDesc =>
      get('privacyMedicalSourcesBmrDesc');
  String get privacyMedicalSourcesBmiCategory =>
      get('privacyMedicalSourcesBmiCategory');
  String get privacyMedicalSourcesBmiDesc =>
      get('privacyMedicalSourcesBmiDesc');
  String get privacyMedicalSourcesBodyFatNavyCategory =>
      get('privacyMedicalSourcesBodyFatNavyCategory');
  String get privacyMedicalSourcesBodyFatNavyDesc =>
      get('privacyMedicalSourcesBodyFatNavyDesc');
  String get privacyMedicalSourcesBodyFatDeurenbergCategory =>
      get('privacyMedicalSourcesBodyFatDeurenbergCategory');
  String get privacyMedicalSourcesBodyFatDeurenbergDesc =>
      get('privacyMedicalSourcesBodyFatDeurenbergDesc');
  String get privacyMedicalSourcesMacrosCategory =>
      get('privacyMedicalSourcesMacrosCategory');
  String get privacyMedicalSourcesMacrosDesc =>
      get('privacyMedicalSourcesMacrosDesc');
  String get privacyMedicalSourcesWaterCategory =>
      get('privacyMedicalSourcesWaterCategory');
  String get privacyMedicalSourcesWaterDesc =>
      get('privacyMedicalSourcesWaterDesc');
  String get privacyMedicalSourcesFoodDbCategory =>
      get('privacyMedicalSourcesFoodDbCategory');
  String get privacyMedicalSourcesFoodDbDesc =>
      get('privacyMedicalSourcesFoodDbDesc');

  String get aiGuidance => get('aiGuidance');
  String get cameraError => get('cameraError');
  String get analysisError => get('analysisError');
  String get regenerate => get('regenerate');
  String get noMealPlan => get('noMealPlan');
  String get noMealPlanDesc => get('noMealPlanDesc');
  String get loggedAsEaten => get('loggedAsEaten');
  String get goalCalculatedDesc => get('goalCalculatedDesc');
  String get ml => get('ml');
  String get kcal => get('kcal');
  String get logout => get('logout');
  String get account => get('account');
  String get deleteAccount => get('deleteAccount');
  String get deleteAccountConfirmTitle => get('deleteAccountConfirmTitle');
  String get deleteAccountConfirmDesc => get('deleteAccountConfirmDesc');
  String get deleteAccountButton => get('deleteAccountButton');
  String get deleteAccountSuccess => get('deleteAccountSuccess');
  String get deleteAccountFailed => get('deleteAccountFailed');
  String get deletingAccount => get('deletingAccount');
  String get accountDeletionWeb => get('accountDeletionWeb');
  String get login => get('login');
  String get phoneNumber => get('phoneNumber');
  String get phoneNumberHint => get('phoneNumberHint');
  String get sendOtp => get('sendOtp');
  String get enterOtpCode => get('enterOtpCode');
  String get otpCodeHint => get('otpCodeHint');
  String get verifyOtp => get('verifyOtp');
  String get resendOtp => get('resendOtp');
  String get changePhoneNumber => get('changePhoneNumber');
  String get signInWithPhone => get('signInWithPhone');
  String get signInWithPassword => get('signInWithPassword');
  String get loginWithOtp => get('loginWithOtp');
  String get welcomeTitle => get('welcomeTitle');
  String get welcomeSubtitle => get('welcomeSubtitle');
  String get signUp => get('signUp');
  String get phoneNotRegistered => get('phoneNotRegistered');
  String get phoneAlreadyRegistered => get('phoneAlreadyRegistered');
  String get invalidPhoneNumber => get('invalidPhoneNumber');
  String get invalidOtpCode => get('invalidOtpCode');
  String get otpSentTo => get('otpSentTo');
  String get otpBackendPending => get('otpBackendPending');
  String get resendOtpIn => get('resendOtpIn');
  String get demoOtpHint => get('demoOtpHint');
  String get yourName => get('yourName');
  String get nameHint => get('nameHint');
  String get whatIsYourName => get('whatIsYourName');
  String get nameSubtitle => get('nameSubtitle');
  String get continueLabel => get('continueLabel');
  String get invalidName => get('invalidName');
  String get welcomeName => get('welcomeName');
  String get yourBmi => get('yourBmi');
  String get maintenanceCalories => get('maintenanceCalories');
  String get dailyCalorieTarget => get('dailyCalorieTarget');
  String get proteinPerKgBody => get('proteinPerKgBody');
  String get password => get('password');
  String get passwordHint => get('passwordHint');
  String get invalidPassword => get('invalidPassword');
  String get noEntries => get('noEntries');
  String get guestMode => get('guestMode');
  String get generateDetails => get('generateDetails');
  String get goalGenerationError => get('goalGenerationError');
  String get unknownFood => get('unknownFood');
  String get per100g => get('per100g');
  String get guestUser => get('guestUser');
  String get loginRequiredTitle => get('loginRequiredTitle');
  String get loginRequiredSubtitle => get('loginRequiredSubtitle');
  String get loginRequiredCta => get('loginRequiredCta');
  String get signInToContinue => get('signInToContinue');
  String get createAccount => get('createAccount');
  String get registerSubtitle => get('registerSubtitle');
  String get confirmPassword => get('confirmPassword');
  String get confirmPasswordHint => get('confirmPasswordHint');
  String get passwordsDoNotMatch => get('passwordsDoNotMatch');
  String get continueWithPhone => get('continueWithPhone');
  String get welcomeBack => get('welcomeBack');
  String get returningUserOtpHint => get('returningUserOtpHint');
  String get guestModeLimited => get('guestModeLimited');
  String get signInFromSettings => get('signInFromSettings');
  String get appLoading => get('appLoading');
  String get splashTagline => get('splashTagline');
  String get splashSubline => get('splashSubline');
  String get todaysMeals => get('todaysMeals');
  String get quickLog => get('quickLog');
  String get quickLogHint => get('quickLogHint');
  String get logForMealSlot => get('logForMealSlot');
  String get noMealPlanned => get('noMealPlanned');
  String get otherFoods => get('otherFoods');
  String get otherFoodsHint => get('otherFoodsHint');
  String get loggedToday => get('loggedToday');
  String get viewMealPlan => get('viewMealPlan');
  String get swapMeal => get('swapMeal');
  String get mealReminders => get('mealReminders');
  String get reminderTime => get('reminderTime');
  String get breakfastReminder => get('breakfastReminder');
  String get lunchReminder => get('lunchReminder');
  String get dinnerReminder => get('dinnerReminder');
  String get snacksReminder => get('snacksReminder');
  String get timeToEat => get('timeToEat');
  String get nutrientsAndSupplements => get('nutrientsAndSupplements');
  String get fromFood => get('fromFood');
  String get supplements => get('supplements');
  String get vitaminA => get('vitaminA');
  String get vitaminC => get('vitaminC');
  String get vitaminD => get('vitaminD');
  String get vitaminB12 => get('vitaminB12');
  String get iron => get('iron');
  String get calcium => get('calcium');
  String get potassium => get('potassium');
  String get zincMineral => get('zincMineral');
  String get vitaminE => get('vitaminE');
  String get vitaminK => get('vitaminK');
  String get vitaminB6 => get('vitaminB6');
  String get folate => get('folate');
  String get magnesium => get('magnesium');
  String get phosphorus => get('phosphorus');
  String get selenium => get('selenium');
  String get sodium => get('sodium');
  String get fiber => get('fiber');
  String get supplementReminders => get('supplementReminders');
  String get supplementReminderTitle => get('supplementReminderTitle');
  String get takeYourSupplement => get('takeYourSupplement');
  String get enableReminder => get('enableReminder');
  String get dailyNutrientGoals => get('dailyNutrientGoals');
  String get noSupplementsForReminders => get('noSupplementsForReminders');
  String get vitaminsAndPills => get('vitaminsAndPills');
  String get addVitamin => get('addVitamin');
  String get vitaminName => get('vitaminName');
  String get dosage => get('dosage');
  String get taken => get('taken');
  String get noVitamins => get('noVitamins');
  String get noVitaminsDesc => get('noVitaminsDesc');
  String get cookWithIngredients => get('cookWithIngredients');
  String get enterIngredients => get('enterIngredients');
  String get ingredientsHint => get('ingredientsHint');
  String get generateRecipe => get('generateRecipe');
  String get aiRecipe => get('aiRecipe');
  String get piece => get('piece');
  String get pieces => get('pieces');
  String get bowls => get('bowls');
  String get perPiece => get('perPiece');
  String get perBowl => get('perBowl');
  String get pieceWeight => get('pieceWeight');
  String get byGrams => get('byGrams');
  String get byPiece => get('byPiece');
  String get byBowl => get('byBowl');
  String get bowlWeight => get('bowlWeight');
  String get scanFridge => get('scanFridge');
  String get scanFridgeDesc => get('scanFridgeDesc');
  String get selectMealType => get('selectMealType');
  String get detectedIngredients => get('detectedIngredients');
  String get ingredientBreakdown => get('ingredientBreakdown');
  String get totalMacros => get('totalMacros');
  String get suggestedRecipe => get('suggestedRecipe');
  String get deleteRecipe => get('deleteRecipe');
  String get logFoodForNutrients => get('logFoodForNutrients');
  String getCategory(String key) =>
      (_t['categoryList'] as Map<String, String>?)?[key] ?? key;

  /// Localized label for meal slot ids: breakfast, lunch, dinner, snacks.
  String mealSlotLabel(String slot) {
    switch (slot) {
      case 'breakfast':
        return breakfast;
      case 'lunch':
        return lunch;
      case 'dinner':
        return dinner;
      case 'snacks':
        return snacks;
      default:
        return slot;
    }
  }

  // Error handling
  String get errorNetwork => get('errorNetwork');
  String get errorTimeout => get('errorTimeout');
  String get errorGeneric => get('errorGeneric');
  String get tryAgain => get('tryAgain');
  String get somethingWentWrong => get('somethingWentWrong');
  String get noInternet => get('noInternet');
  String get mealGenerationFailed => get('mealGenerationFailed');
  String get scanFailed => get('scanFailed');
  String get loadingFailed => get('loadingFailed');
  String get permissionDenied => get('permissionDenied');
  String get fridgeScanError => get('fridgeScanError');
  String get recipeGenerationFailed => get('recipeGenerationFailed');
  String get goalGenerationFailed => get('goalGenerationFailed');
  String get swapFailed => get('swapFailed');
  String get detailsFailed => get('detailsFailed');
  String get dailyTotal => get('dailyTotal');
  String get ofGoal => get('ofGoal');
  String get weeklySummary => get('weeklySummary');
  String get weeklySummarySubtitle => get('weeklySummarySubtitle');
  String get weeklyStreak => get('weeklyStreak');
  String get weeklyDaysLogged => get('weeklyDaysLogged');
  String get weeklyGoalDays => get('weeklyGoalDays');
  String get weeklyWeightChange => get('weeklyWeightChange');
  String get weeklyWeightLost => get('weeklyWeightLost');
  String get weeklyWeightGained => get('weeklyWeightGained');
  String get weeklyWeightStable => get('weeklyWeightStable');
  String get weeklyLogWeightHint => get('weeklyLogWeightHint');
  String get weeklyAvgCalories => get('weeklyAvgCalories');
  String get weeklyCalorieChart => get('weeklyCalorieChart');
  String get weeklyDailyBreakdown => get('weeklyDailyBreakdown');
  String get weeklyUpdateWeight => get('weeklyUpdateWeight');
  String get weeklyDayStreak => get('weeklyDayStreak');
  String get weeklyOnTarget => get('weeklyOnTarget');
  String get weeklyDaysLoggedHint => get('weeklyDaysLoggedHint');
  String get weeklyStreakStart => get('weeklyStreakStart');
  String get cancel => get('cancel');
  String get save => get('save');
  String get editMacros => get('editMacros');
  String get editMacrosDesc => get('editMacrosDesc');
  String get macrosUpdated => get('macrosUpdated');
  String get resetToAi => get('resetToAi');
  String get remove => get('remove');
  String get removeLoggedTitle => get('removeLoggedTitle');
  String get removeLoggedBody => get('removeLoggedBody');
  String get itemRemoved => get('itemRemoved');
  String get bodyFatShortcut => get('bodyFatShortcut');
  String get bodyFatScreenTitle => get('bodyFatScreenTitle');
  String get bodyFatScreenIntro => get('bodyFatScreenIntro');
  String get bodyFatStaticDisclaimer => get('bodyFatStaticDisclaimer');
  String get bodyFatAnalyzing => get('bodyFatAnalyzing');
  String get bodyFatEstimatedRange => get('bodyFatEstimatedRange');
  String get bodyFatConfidenceLabel => get('bodyFatConfidenceLabel');
  String get bodyFatConfidenceLow => get('bodyFatConfidenceLow');
  String get bodyFatConfidenceMedium => get('bodyFatConfidenceMedium');
  String get bodyFatConfidenceHigh => get('bodyFatConfidenceHigh');
  String get bodyFatMeasureTitle => get('bodyFatMeasureTitle');
  String get bodyFatMeasureHint => get('bodyFatMeasureHint');
  String get bodyFatMeasureRequired => get('bodyFatMeasureRequired');
  String get bodyFatWaistCm => get('bodyFatWaistCm');
  String get bodyFatNeckCm => get('bodyFatNeckCm');
  String get bodyFatHipCm => get('bodyFatHipCm');
  String get bodyFatCalculateMeasurements =>
      get('bodyFatCalculateMeasurements');
  String get bodyFatPhotoOptional => get('bodyFatPhotoOptional');
  String get bodyFatPhotoHint => get('bodyFatPhotoHint');
  String get bodyFatMethodLabel => get('bodyFatMethodLabel');
  String get bodyFatMethodNavy => get('bodyFatMethodNavy');
  String get bodyFatMethodDeurenberg => get('bodyFatMethodDeurenberg');
  String get bodyFatMethodBlended => get('bodyFatMethodBlended');
  String get bodyFatMethodPhoto => get('bodyFatMethodPhoto');
  String get bodyFatProfileContext => get('bodyFatProfileContext');
  String get bodyFatAiNotes => get('bodyFatAiNotes');
  String get bodyFatAiDisclaimer => get('bodyFatAiDisclaimer');
  String get bodyFatRetakePhoto => get('bodyFatRetakePhoto');
  String get bodyFatFailed => get('bodyFatFailed');
  String get weeklyDigestTitle => get('weeklyDigestTitle');
  String get weeklyDigestBody => get('weeklyDigestBody');
  String get weeklyDigestNotify => get('weeklyDigestNotify');
  String get shoppingList => get('shoppingList');
  String get shoppingListEmpty => get('shoppingListEmpty');
  String get addItem => get('addItem');
  String get itemName => get('itemName');
  String get clearDone => get('clearDone');
  String get favorites => get('favorites');
  String get noFavorites => get('noFavorites');
  String get saveAsFavorite => get('saveAsFavorite');
  String get savedFavorite => get('savedFavorite');
  String get useTemplate => get('useTemplate');
  String get addPlanIngredients => get('addPlanIngredients');
  String get saveMealTemplate => get('saveMealTemplate');
  String get offlineBanner => get('offlineBanner');
  String get testNotification => get('testNotification');
  String get notificationsWebInfo => get('notificationsWebInfo');
  String get notificationsWebHint => get('notificationsWebHint');
  String get shoppingListUpdated => get('shoppingListUpdated');
  String get insightsLists => get('insightsLists');
  String get mealCuisineStyle => get('mealCuisineStyle');
  String get cuisineKurdish => get('cuisineKurdish');
  String get cuisineArabic => get('cuisineArabic');
  String get cuisineAll => get('cuisineAll');
  String get aiShoppingListButton => get('aiShoppingListButton');
  String get aiShoppingListTitle => get('aiShoppingListTitle');
  String get aiShoppingLoading => get('aiShoppingLoading');
  String get aiShoppingFailed => get('aiShoppingFailed');
  String get addSuggestedToList => get('addSuggestedToList');
  String get needMealPlanForAiShopping => get('needMealPlanForAiShopping');
  String get aiShoppingDetailsHint => get('aiShoppingDetailsHint');
  String get aiShoppingAllMealsLogged => get('aiShoppingAllMealsLogged');
  String get generateAllDetailsButton => get('generateAllDetailsButton');
  String get generateAllDetailsBusy => get('generateAllDetailsBusy');
  String get generateAllDetailsHint => get('generateAllDetailsHint');
  String get allMealsAlreadyDetailed => get('allMealsAlreadyDetailed');
  String get allDetailsAllFailed => get('allDetailsAllFailed');
  String allDetailsGeneratedSuccess(int n) =>
      get('allDetailsGeneratedSuccess').replaceAll('{n}', '$n');
  String allDetailsPartialSuccess(int n) =>
      get('allDetailsPartialSuccess').replaceAll('{n}', '$n');
  String get shoppingDuplicate => get('shoppingDuplicate');
  String get shoppingItemAdded => get('shoppingItemAdded');

  // Extended onboarding
  String get onboardTargetsTitle => get('onboardTargetsTitle');
  String get onboardTargetsSubtitle => get('onboardTargetsSubtitle');
  String get targetWeight => get('targetWeight');
  String get pace => get('pace');
  String get bodyFatPct => get('bodyFatPct');
  String get pregnancyStatus => get('pregnancyStatus');
  String get onboardDietTitle => get('onboardDietTitle');
  String get onboardDietSubtitle => get('onboardDietSubtitle');
  String get dietaryPattern => get('dietaryPattern');
  String get dislikedFoods => get('dislikedFoods');
  String get cuisinePreference => get('cuisinePreference');
  String get onboardLifestyleTitle => get('onboardLifestyleTitle');
  String get onboardLifestyleSubtitle => get('onboardLifestyleSubtitle');
  String get mealsPerDay => get('mealsPerDay');
  String get fastingWindow => get('fastingWindow');
  String get sleepHours => get('sleepHours');
  String get stressLevel => get('stressLevel');
  String get waterTargetMl => get('waterTargetMl');
  String get waterTargetAiNote => get('waterTargetAiNote');
  String get dailyWaterGoal => get('dailyWaterGoal');
  String get scanBarcode => get('scanBarcode');
  String get barcodeScanHint => get('barcodeScanHint');
  String get barcodeLookingUp => get('barcodeLookingUp');
  String get barcodeNotFound => get('barcodeNotFound');
  String get barcodeLogQuestion => get('barcodeLogQuestion');
  String get barcodeLogYes => get('barcodeLogYes');
  String get barcodeLogNo => get('barcodeLogNo');
  String get barcodeLogged => get('barcodeLogged');
  String get barcodeAmountLabel => get('barcodeAmountLabel');
  String get barcodeNotOnWeb => get('barcodeNotOnWeb');
  String get barcodeCameraDenied => get('barcodeCameraDenied');
  String get barcodeCameraSettings => get('barcodeCameraSettings');
  String get barcodeNetworkError => get('barcodeNetworkError');
  String get barcodeInvalid => get('barcodeInvalid');
  String get barcodeManualEntry => get('barcodeManualEntry');
  String get barcodeManualHint => get('barcodeManualHint');
  String get barcodeLookupButton => get('barcodeLookupButton');
  String get barcodeNotFoundTitle => get('barcodeNotFoundTitle');
  String get barcodeNotFoundBody => get('barcodeNotFoundBody');
  String get barcodeAddManually => get('barcodeAddManually');
  String get barcodePickFromApp => get('barcodePickFromApp');
  String get barcodeProductName => get('barcodeProductName');
  String get barcodeSaveAndContinue => get('barcodeSaveAndContinue');
  String get barcodeSavedForNextTime => get('barcodeSavedForNextTime');
  String get choosePreparation => get('choosePreparation');
  String get choosePreparationHint => get('choosePreparationHint');
  String get chooseOilStep => get('chooseOilStep');
  String get bonePortionLabel => get('bonePortionLabel');
  String get bonelessPortion => get('bonelessPortion');
  String get withBonesPortion => get('withBonesPortion');
  String get bonePortionHint => get('bonePortionHint');
  String get medicationsLabel => get('medicationsLabel');
  String get medicationsHint => get('medicationsHint');
  String get onboardTrainingTitle => get('onboardTrainingTitle');
  String get onboardTrainingSubtitle => get('onboardTrainingSubtitle');
  String get workoutDaysPerWeek => get('workoutDaysPerWeek');
  String get workoutType => get('workoutType');
  String get cookingSkill => get('cookingSkill');
  String get cookingTime => get('cookingTime');
  String get optionalField => get('optionalField');
  String onboardStepOf(int current, int total) => get(
    'onboardStepOf',
  ).replaceAll('{c}', '$current').replaceAll('{t}', '$total');
  String get onboardActivityStepTitle => get('onboardActivityStepTitle');
  String get onboardActivityStepSubtitle => get('onboardActivityStepSubtitle');
  String get onboardHealthStepTitle => get('onboardHealthStepTitle');
  String get onboardHealthStepSubtitle => get('onboardHealthStepSubtitle');
  String get onboardHealthOptionalNote => get('onboardHealthOptionalNote');
  String get onboardGoalStepSubtitle => get('onboardGoalStepSubtitle');
  String getActivityHint(String level) {
    switch (level) {
      case 'sedentary':
        return get('activityHintSedentary');
      case 'lightlyActive':
        return get('activityHintLightlyActive');
      case 'moderatelyActive':
        return get('activityHintModeratelyActive');
      case 'veryActive':
        return get('activityHintVeryActive');
      case 'extraActive':
        return get('activityHintExtraActive');
      default:
        return '';
    }
  }

  // Premium
  String get premium => get('premium');
  String get premiumBadge => get('premiumBadge');
  String get premiumLocked => get('premiumLocked');
  String get premiumUnlockCta => get('premiumUnlockCta');
  String get premiumActive => get('premiumActive');
  String get premiumActiveUntil => get('premiumActiveUntil');
  String get premiumTitle => get('premiumTitle');
  String get premiumSubtitle => get('premiumSubtitle');
  String get premiumPerkMealPlan => get('premiumPerkMealPlan');
  String get premiumPerkScanner => get('premiumPerkScanner');
  String get premiumPerkAiTips => get('premiumPerkAiTips');
  String get premiumPerkNutrients => get('premiumPerkNutrients');
  String get premiumPerkSwapMeals => get('premiumPerkSwapMeals');
  String get premiumPerkRecipes => get('premiumPerkRecipes');
  String get premiumActivate => get('premiumActivate');
  String get premiumDeactivate => get('premiumDeactivate');
  String get premiumRestore => get('premiumRestore');
  String get premiumComingSoon => get('premiumComingSoon');
  String get premiumManage => get('premiumManage');
  String get premiumFooterNote => get('premiumFooterNote');

  String shoppingBulkFeedback(int added, int skippedDupes) {
    if (added == 0 && skippedDupes > 0) return get('shoppingBulkAllDupes');
    if (added > 0 && skippedDupes == 0) {
      return get('shoppingBulkAddedOnly').replaceAll('{n}', '$added');
    }
    if (added > 0 && skippedDupes > 0) {
      return get(
        'shoppingBulkMixed',
      ).replaceAll('{a}', '$added').replaceAll('{s}', '$skippedDupes');
    }
    return '';
  }

  // ─── English ────────────────────────────────────────
  static const Map<String, dynamic> _en = {
    'or': 'or',
    'notifications': 'Notifications',
    'ofTotal': 'of {total}',
    'versus': 'compared with',
    'daysRemaining': '{days} days remaining',
    'poweredByBnyad': 'Made for your wellbeing',
    'invalidNumber': 'Enter a valid positive number.',
    'mealChannel': 'Meal reminders',
    'mealChannelDescription': 'Daily meal reminder notifications',
    'weeklyChannel': 'Weekly summary',
    'weeklyChannelDescription': 'Weekly nutrition digest',
    'supplementChannel': 'Supplement reminders',
    'supplementChannelDescription': 'Daily pill and supplement reminders',
    'notificationTestBody': 'Notifications are working!',
    'androidRenewal':
        'Payment is charged to your Google Play account after confirmation. Subscriptions renew automatically unless canceled before renewal. Manage or cancel in Google Play subscriptions.',
    'webRenewal':
        'Your app store shows subscription and renewal terms before confirmation.',
    'dashboard': 'Dashboard',
    'profile': 'Health Profile',
    'foodLog': 'Food Log',
    'calories': 'Calories',
    'carbs': 'Carbs',
    'protein': 'Protein',
    'fat': 'Fat',
    'macronutrients': 'Macronutrients',
    'water': 'Water Intake',
    'waterIntake': 'Water Intake',
    'glasses': 'glasses',
    'weight': 'Weight (kg)',
    'height': 'Height (cm)',
    'age': 'Age',
    'gender': 'Gender',
    'male': 'Male',
    'female': 'Female',
    'activityLevel': 'Activity Level',
    'sedentary': 'Sedentary',
    'lightlyActive': 'Lightly Active',
    'moderatelyActive': 'Moderately Active',
    'veryActive': 'Very Active',
    'extraActive': 'Extra Active',
    'calculate': 'Calculate TDEE',
    'bmr': 'BMR',
    'tdee': 'TDEE',
    'searchFood': 'Search food...',
    'addMeal': 'Add Meal',
    'addFood': 'Add Food',
    'language': 'Language',
    'english': 'English',
    'arabic': 'العربية',
    'kurdish': 'کوردی (سۆرانی)',
    'onboardingTitle': 'Welcome to BNYAD',
    'onboardingSubtitle': 'Let\'s set up your personalized nutrition plan.',
    'disabilities': 'Physical Disabilities',
    'sicknesses': 'Sicknesses / Medical Conditions',
    'allergies': 'Allergies',
    'next': 'Next',
    'back': 'Back',
    'finish': 'Generate Plan',
    'analyzing': 'Calculating your daily targets...',
    'goalSet': 'Your personalized goal is ready!',
    'getStarted': 'Get Started',
    'settings': 'Settings',
    'theme': 'Theme',
    'light': 'Light',
    'dark': 'Dark',
    'selectSicknesses': 'Select Medical Conditions',
    'selectAllergies': 'Select Allergies',
    'search': 'Search...',
    'selected': 'Selected',
    'none': 'None',
    'mealPlan': 'Meal Plan',
    'generateMealPlan': 'Generate Meal Plan',
    'generatePlan': 'Generate Plan',
    'mealPlanSubtitle': 'AI-powered daily nutrition guide',
    'breakfast': 'Breakfast',
    'lunch': 'Lunch',
    'dinner': 'Dinner',
    'snacks': 'Snacks',
    'generating': 'Generating your plan...',
    'selectDisabilities': 'Select Physical Disabilities',
    'ingredients': 'Ingredients',
    'instructions': 'Instructions',
    'logAsEaten': 'Log as Eaten',
    'eaten': 'Eaten',
    'goals': 'Goals',
    'selectGoal': 'Select Your Goal',
    'goalList': {
      'loseWeight': 'Lose Weight',
      'gainWeight': 'Gain Weight',
      'gainMuscle': 'Gain Muscle',
      'stayHealthy': 'Stay Healthy',
      'athletic': 'Improve Athletic Performance',
      'manageCondition': 'Manage Medical Condition',
    },
    'healthGuidance': 'Health Guidance',
    'healthGuidanceSubtitle': 'Personalized tips for your conditions',
    'amount': 'Amount',
    'grams': 'grams',
    'add': 'Add',
    'total': 'Total',
    'searchPlaceholder': 'Search for foods (e.g. Dolma, Pizza...)',
    'browseFoods': 'Browse Foods',
    'selectFood': 'Select Food',
    'close': 'Close',
    'sicknessesList': {
      'diabetes1': 'Diabetes Type 1',
      'diabetes2': 'Diabetes Type 2',
      'hypertension': 'Hypertension',
      'celiac': 'Celiac Disease',
      'ibs': 'IBS',
      'kidney': 'Kidney Disease',
      'heart': 'Heart Disease',
      'obesity': 'Obesity',
      'anemia': 'Anemia',
      'hypo': 'Hypothyroidism',
      'hyper': 'Hyperthyroidism',
      'gout': 'Gout',
      'reflux': 'Acid Reflux',
    },
    'allergiesList': {
      'peanuts': 'Peanuts',
      'treeNuts': 'Tree Nuts',
      'milk': 'Milk',
      'egg': 'Egg',
      'wheat': 'Wheat',
      'soy': 'Soy',
      'fish': 'Fish',
      'shellfish': 'Shellfish',
      'sesame': 'Sesame',
      'gluten': 'Gluten',
      'lactose': 'Lactose',
      'corn': 'Corn',
      'mustard': 'Mustard',
    },
    'disabilitiesList': {
      'wheelchair': 'Wheelchair User',
      'mobility': 'Limited Mobility',
      'visual': 'Visual Impairment',
      'hearing': 'Hearing Impairment',
      'amputation': 'Amputation',
      'none': 'None',
    },
    'foodScanner': 'Food Scanner',
    'readyToScan': 'Ready to Scan?',
    'scanSubtitle':
        'Point your camera or upload a photo of your food to get instant nutritional info.',
    'startCamera': 'Start Camera',
    'uploadPhoto': 'Upload Photo',
    'aiAnalyzed': 'AI Analyzed',
    'logAsEaten100g': 'Log as Eaten (100g)',
    'howToUse': 'How to Use',
    'instructionsSteps': [
      'Set up your profile with your weight, height, and health conditions.',
      'Use the Scanner to identify food items and their nutritional values.',
      'Log your meals daily to track your calories and macros.',
      'Check your Dashboard for personalized health guidance.',
      'Generate a Meal Plan to get AI-powered daily nutrition guides.',
    ],
    'aiGuidance': 'AI Health Guidance',
    'cameraError':
        'Could not access camera. Please ensure permissions are granted.',
    'analysisError': 'Failed to analyze image. Please try again.',
    'regenerate': 'Regenerate',
    'noMealPlan': 'No Meal Plan Yet',
    'noMealPlanDesc':
        'Let AI create a personalized nutrition plan based on your goals and health profile.',
    'loggedAsEaten': 'Logged as Eaten',
    'goalCalculatedDesc':
        'Based on your weight, height, age, activity, goal, and training.',
    'ml': 'ml',
    'kcal': 'kcal',
    'logout': 'Logout',
    'account': 'Account',
    'deleteAccount': 'Delete Account',
    'deleteAccountConfirmTitle': 'Permanently Delete Account?',
    'deleteAccountConfirmDesc':
        'All your profile data, daily nutrition logs, water intake, weight history, and meal plans will be permanently removed from our servers. This action cannot be undone.',
    'deleteAccountButton': 'Delete My Account',
    'deleteAccountSuccess': 'Your account has been permanently deleted.',
    'deleteAccountFailed':
        'Failed to delete account. Please check your connection and try again.',
    'deletingAccount': 'Deleting account...',
    'accountDeletionWeb': 'Account Deletion Portal (Web)',
    'login': 'Login',
    'signInWithPhone': 'Sign in with phone',
    'welcomeTitle': 'Start Your Healthy Journey',
    'welcomeSubtitle':
        'Track your nutrition, plan your meals, and achieve your health goals with BNYAD.',
    'signUp': 'Create Account',
    'phoneNotRegistered':
        'This phone number is not registered. Please sign up.',
    'phoneAlreadyRegistered':
        'This phone number is already registered. Please sign in.',
    'signInWithPassword': 'Sign in with password',
    'loginWithOtp': 'Login with OTP',
    'phoneNumber': 'Phone number',
    'phoneNumberHint': '750 123 4567',
    'sendOtp': 'Send code',
    'enterOtpCode': 'Enter verification code',
    'otpCodeHint': '6-digit code',
    'verifyOtp': 'Verify',
    'resendOtp': 'Resend code',
    'changePhoneNumber': 'Change number',
    'invalidPhoneNumber': 'Enter a valid phone number',
    'invalidOtpCode': 'Enter the 6-digit code',
    'otpSentTo': 'Code sent to',
    'otpBackendPending': 'OTP verification is not connected yet.',
    'resendOtpIn': 'Resend in {seconds}s',
    'demoOtpHint': 'Demo code: 123456',
    'yourName': 'Your name',
    'nameHint': 'e.g. Sara',
    'whatIsYourName': 'What\'s your name?',
    'nameSubtitle': 'We\'ll greet you on your dashboard',
    'continueLabel': 'Continue',
    'invalidName': 'Please enter your name',
    'welcomeName': 'Hello, {name}',
    'yourBmi': 'Your BMI',
    'maintenanceCalories': 'Maintenance (TDEE)',
    'dailyCalorieTarget': 'Daily calorie target',
    'proteinPerKgBody': 'g protein per kg body weight',
    'password': 'Password',
    'passwordHint': 'At least 6 characters',
    'invalidPassword': 'Password must be at least 6 characters',
    'noEntries': 'No entries yet',
    'guestMode': 'Guest Mode',
    'generateDetails': 'Generate Details',
    'goalGenerationError': 'Could not generate goals. Please try again.',
    'unknownFood': 'Unknown Food',
    'per100g': 'per 100g',
    'guestUser': 'Guest User',
    'loginRequiredTitle': 'Sign in required',
    'loginRequiredSubtitle':
        'Create an account or sign in to use this feature. Your data will sync across devices.',
    'loginRequiredCta': 'Sign in / Register',
    'signInToContinue': 'Sign in to continue',
    'createAccount': 'Create account',
    'registerSubtitle': 'Set your name and password, then verify your phone.',
    'confirmPassword': 'Confirm password',
    'confirmPasswordHint': 'Re-enter password',
    'passwordsDoNotMatch': 'Passwords do not match',
    'continueWithPhone': 'Continue',
    'welcomeBack': 'Welcome back',
    'returningUserOtpHint': 'Enter the code we sent to your phone.',
    'guestModeLimited': 'Guest mode — limited features',
    'signInFromSettings': 'Sign in to unlock all features',
    'appLoading': 'BNYAD is loading...',
    'splashTagline': 'Your AI-Powered\nNutrition Partner',
    'splashSubline': 'Eat smarter. Live healthier.',
    'todaysMeals': 'Today\'s Meals',
    'quickLog': 'Quick log',
    'quickLogHint':
        'Add foods manually from your food log, or pick a meal below.',
    'logForMealSlot': 'Log for',
    'noMealPlanned': 'No meal planned yet',
    'otherFoods': 'Other foods',
    'otherFoodsHint': 'Logged without a meal slot (tap to open food log)',
    'loggedToday': 'Logged',
    'viewMealPlan': 'View Full Plan',
    'swapMeal': 'Swap Meal',
    'mealReminders': 'Meal Reminders',
    'reminderTime': 'Reminder Time',
    'breakfastReminder': 'Breakfast Reminder',
    'lunchReminder': 'Lunch Reminder',
    'dinnerReminder': 'Dinner Reminder',
    'snacksReminder': 'Snacks Reminder',
    'timeToEat': 'Time to eat!',
    'nutrientsAndSupplements': 'Nutrients & Supplements',
    'fromFood': 'From Food',
    'supplements': 'Supplements',
    'vitaminA': 'Vitamin A',
    'vitaminC': 'Vitamin C',
    'vitaminD': 'Vitamin D',
    'vitaminB12': 'Vitamin B12',
    'iron': 'Iron',
    'calcium': 'Calcium',
    'potassium': 'Potassium',
    'zincMineral': 'Zinc',
    'vitaminE': 'Vitamin E',
    'vitaminK': 'Vitamin K',
    'vitaminB6': 'Vitamin B6',
    'folate': 'Folate',
    'magnesium': 'Magnesium',
    'phosphorus': 'Phosphorus',
    'selenium': 'Selenium',
    'sodium': 'Sodium',
    'fiber': 'Fiber',
    'supplementReminders': 'Supplement Reminders',
    'supplementReminderTitle': 'Take your supplement',
    'takeYourSupplement': 'Time to take',
    'enableReminder': 'Daily reminder',
    'dailyNutrientGoals': 'Daily nutrient goals',
    'noSupplementsForReminders':
        'Add supplements in the Nutrients section to set reminders.',
    'vitaminsAndPills': 'Vitamins & Pills',
    'addVitamin': 'Add Vitamin',
    'vitaminName': 'Vitamin Name',
    'dosage': 'e.g. 1 pill, 500mg',
    'taken': 'Taken',
    'noVitamins': 'No Vitamins Yet',
    'noVitaminsDesc': 'Add your daily vitamins and supplements to track them.',
    'cookWithIngredients': 'Cook with My Ingredients',
    'enterIngredients': 'Enter Your Ingredients',
    'ingredientsHint': 'e.g. chicken, rice, tomatoes, onion...',
    'generateRecipe': 'Generate Recipe',
    'aiRecipe': 'AI Recipe',
    'piece': 'piece',
    'pieces': 'pieces',
    'bowls': 'bowls',
    'perPiece': 'per piece',
    'perBowl': 'per bowl',
    'pieceWeight': 'Weight per piece (g)',
    'byGrams': 'By Grams',
    'byPiece': 'By Piece',
    'byBowl': 'By Bowl',
    'bowlWeight': 'Weight per bowl (g)',
    'scanFridge': 'Scan My Fridge',
    'scanFridgeDesc':
        'Take a photo of your fridge and AI will suggest a meal based on what you have.',
    'selectMealType': 'This meal is for:',
    'detectedIngredients': 'Detected Ingredients',
    'ingredientBreakdown': 'Ingredient Breakdown',
    'totalMacros': 'Total macros',
    'suggestedRecipe': 'Suggested Recipe',
    'deleteRecipe': 'Delete Recipe',
    'logFoodForNutrients': 'Log food to see your daily nutrients',
    'errorNetwork':
        'Network error. Please check your connection and try again.',
    'errorTimeout': 'Request timed out. Please try again.',
    'errorGeneric': 'Something went wrong. Please try again.',
    'tryAgain': 'Try Again',
    'somethingWentWrong': 'Something went wrong',
    'noInternet': 'No internet connection',
    'mealGenerationFailed': 'Failed to generate meal plan. Please try again.',
    'scanFailed':
        'Failed to analyze food. Please try again with a clearer image.',
    'loadingFailed': 'Failed to load data. Please try again.',
    'permissionDenied': 'Permission denied. Please enable it in Settings.',
    'fridgeScanError': 'Failed to analyze fridge contents. Please try again.',
    'recipeGenerationFailed': 'Failed to generate recipe. Please try again.',
    'goalGenerationFailed': 'Failed to generate goals. Please try again.',
    'swapFailed': 'Failed to swap meal. Please try again.',
    'detailsFailed': 'Failed to generate meal details. Please try again.',
    'dailyTotal': 'Daily Total',
    'ofGoal': 'of goal',
    'weeklySummary': 'Weekly summary',
    'weeklySummarySubtitle': 'Your progress over the last 7 days',
    'weeklyStreak': 'Logging streak',
    'weeklyDaysLogged': 'Days logged',
    'weeklyGoalDays': 'On target',
    'weeklyWeightChange': 'Weight change',
    'weeklyWeightLost': 'lost this week',
    'weeklyWeightGained': 'gained this week',
    'weeklyWeightStable': 'No change this week',
    'weeklyLogWeightHint':
        'Update your weight below to track kg lost or gained.',
    'weeklyAvgCalories': 'Avg calories (logged days)',
    'weeklyCalorieChart': 'Daily calories vs goal',
    'weeklyDailyBreakdown': 'Day by day',
    'weeklyUpdateWeight': 'Update today\'s weight',
    'weeklyDayStreak': 'day streak',
    'weeklyOnTarget': 'On target',
    'weeklyDaysLoggedHint': 'of 7 days',
    'weeklyStreakStart': 'Log meals to start a streak',
    'cancel': 'Cancel',
    'save': 'Save',
    'editMacros': 'Edit Macros',
    'editMacrosDesc':
        'Manually set your daily calories, protein, carbs and fat targets.',
    'macrosUpdated': 'Macro targets updated',
    'resetToAi': 'Reset to AI values',
    'remove': 'Remove',
    'removeLoggedTitle': 'Remove item?',
    'removeLoggedBody': 'Remove "{name}" from today\'s log?',
    'itemRemoved': 'Item removed',
    'bodyFatShortcut': 'Body fat (AI)',
    'bodyFatScreenTitle': 'Body fat estimate',
    'bodyFatScreenIntro':
        'For better accuracy, use a soft tape measure first (waist + neck). A photo can refine the result but is never as accurate as measurements.',
    'bodyFatStaticDisclaimer':
        'This feature is for general wellness information only. It is not a diagnosis or medical device. For accurate body composition, ask a healthcare professional about DEXA, hydrostatic weighing, or professional skinfold testing.',
    'bodyFatAnalyzing': 'Analyzing photo…',
    'bodyFatEstimatedRange': 'Estimated range',
    'bodyFatConfidenceLabel': 'Confidence',
    'bodyFatConfidenceLow': 'Low (photo only)',
    'bodyFatConfidenceMedium': 'Medium (BMI formula or blended)',
    'bodyFatConfidenceHigh': 'High (tape measure method)',
    'bodyFatMeasureTitle': 'Step 1 — Tape measurements (recommended)',
    'bodyFatMeasureHint':
        'Measure in the morning, relaxed stomach. Waist: narrowest point above navel or at navel. Neck: below the larynx. Women also need hip at the widest point.',
    'bodyFatMeasureRequired':
        'Enter waist and neck (and hip for women) in centimeters.',
    'bodyFatWaistCm': 'Waist',
    'bodyFatNeckCm': 'Neck',
    'bodyFatHipCm': 'Hip (women)',
    'bodyFatCalculateMeasurements': 'Calculate from measurements',
    'bodyFatPhotoOptional': 'Step 2 — Photo (optional)',
    'bodyFatPhotoHint':
        'Front or side photo, fitted clothing, good lighting. Used only to adjust the measurement estimate slightly.',
    'bodyFatMethodLabel': 'Method',
    'bodyFatMethodNavy': 'US Navy tape formula',
    'bodyFatMethodDeurenberg': 'BMI + age formula',
    'bodyFatMethodBlended': 'Measurements + photo',
    'bodyFatMethodPhoto': 'Photo estimate',
    'bodyFatProfileContext': 'Your profile',
    'bodyFatAiNotes': 'Notes',
    'bodyFatAiDisclaimer': 'AI disclaimer',
    'bodyFatRetakePhoto': 'New photo',
    'bodyFatFailed':
        'Could not estimate from this photo. Try another image or check your connection.',
    'weeklyDigestTitle': 'Weekly summary',
    'weeklyDigestBody': 'Open BNYAD to review your week.',
    'weeklyDigestNotify': 'Weekly summary reminder (Sunday)',
    'shoppingList': 'Shopping list',
    'shoppingListEmpty': 'Nothing on your list yet',
    'addItem': 'Add item',
    'itemName': 'Item name',
    'clearDone': 'Clear checked',
    'favorites': 'Favorites',
    'noFavorites': 'No favorites yet — save foods or meals for quick logging.',
    'saveAsFavorite': 'Save as favorite',
    'savedFavorite': 'Saved to favorites',
    'useTemplate': 'Log from favorites',
    'addPlanIngredients': 'Add ingredients to shopping list',
    'saveMealTemplate': 'Save meal as template',
    'offlineBanner': 'Offline — food log and saved plans still work.',
    'testNotification': 'Test notification',
    'notificationsWebInfo':
        'Meal reminders and scheduled alerts run on the BNYAD mobile app. The web version cannot show system notifications.',
    'notificationsWebHint':
        'Use the Android or iOS app to set reminder times for breakfast, lunch, dinner, snacks, and optional weekly summaries.',
    'shoppingListUpdated': 'Ingredients added to your shopping list',
    'insightsLists': 'Insights & lists',
    'mealCuisineStyle': 'Meal style',
    'cuisineKurdish': 'Kurdish',
    'cuisineArabic': 'Arabic',
    'cuisineAll': 'All / mixed',
    'aiShoppingListButton': 'What should I buy? (AI)',
    'aiShoppingListTitle': 'Suggested shopping list',
    'aiShoppingLoading': 'Planning your shopping list…',
    'aiShoppingFailed': 'Could not build a shopping list. Try again.',
    'addSuggestedToList': 'Add all to shopping list',
    'needMealPlanForAiShopping':
        'Create a meal plan first, then open this again.',
    'aiShoppingDetailsHint':
        'Tip: tap “Generate details” on each meal for a more accurate list.',
    'aiShoppingAllMealsLogged':
        'You\'ve already logged every meal from today\'s plan as eaten — there\'s nothing left to buy for those dishes.',
    'generateAllDetailsButton': 'Generate all meal details',
    'generateAllDetailsBusy': 'Generating all meals…',
    'generateAllDetailsHint':
        'Skips meals that already have ingredients and steps. Regenerate one meal from its card.',
    'allMealsAlreadyDetailed': 'Every meal already has ingredients and steps.',
    'allDetailsGeneratedSuccess': 'Added ingredients & steps for {n} meal(s).',
    'allDetailsPartialSuccess':
        'Updated {n} meal(s). Check any cards marked with an error.',
    'allDetailsAllFailed':
        'Could not generate details. Try again or use each meal’s button.',
    'shoppingDuplicate': 'Already on your list — we skipped the duplicate.',
    'shoppingItemAdded': 'Added to your list.',
    'shoppingBulkAllDupes':
        'Nothing new — those items were already on your list.',
    'shoppingBulkAddedOnly': 'Added {n} new item(s) to your list.',
    'shoppingBulkMixed':
        'Added {a} new item(s). Skipped {s} duplicate(s) already on your list.',
    'categoryList': {
      'Kurdish': 'Kurdish',
      'Bread': 'Breads & flatbreads',
      'RiceDishes': 'Rice dishes',
      'Soup': 'Soups & stews',
      'Arabic': 'Arabic / Middle Eastern',
      'Protein': 'Protein',
      'Dairy': 'Dairy',
      'Grains': 'Grains & Carbs',
      'Fruit': 'Fruits',
      'Vegetable': 'Vegetables',
      'Nuts': 'Nuts & Seeds',
      'Legumes': 'Legumes',
      'International': 'International',
      'FastFood': 'Fast food',
      'Supplement': 'Supplements',
      'Beverage': 'Beverages',
      'Snacks': 'Snacks & Sweets',
      'Oil': 'Oils & Fats',
    },
    'premium': 'Premium',
    'premiumBadge': 'PREMIUM',
    'premiumLocked': 'Premium feature',
    'premiumUnlockCta': 'Unlock Premium',
    'premiumActive': 'Premium active',
    'premiumActiveUntil': 'Active until {date}',
    'premiumTitle': 'Go Premium',
    'premiumSubtitle': 'Unlock the full power of BNYAD\'s AI.',
    'premiumPerkMealPlan': 'AI-generated daily meal plans',
    'premiumPerkScanner': 'AI food & fridge scanner',
    'premiumPerkAiTips': 'Personalized AI health guidance',
    'premiumPerkNutrients': 'Nutrient & supplement tracking',
    'premiumPerkSwapMeals': 'Swap meals & smart shopping list',
    'premiumPerkRecipes': 'Custom AI recipes from your ingredients',
    'premiumActivate': 'Start Premium',
    'premiumDeactivate': 'Cancel Premium',
    'premiumRestore': 'Restore purchase',
    'premiumComingSoon': 'Real payments coming soon. Tap activate to preview.',
    'premiumManage': 'Manage subscription',
    'premiumFooterNote': 'Body fat estimator and macro calculator remain free.',
    'optionalField': 'Optional',
    'onboardStepOf': 'Step {c} of {t}',
    'onboardActivityStepTitle': 'Daily Activity',
    'onboardActivityStepSubtitle':
        'How active are you on a typical week? This sets your calorie baseline.',
    'onboardHealthStepTitle': 'Health & Allergies',
    'onboardHealthStepSubtitle':
        'Helps us personalize meal ideas and micronutrient targets safely.',
    'onboardHealthOptionalNote':
        'Optional — skip if none apply. You can update these anytime in Settings.',
    'onboardGoalStepSubtitle':
        'Pick your main focus. Calories are adjusted with a safe, moderate deficit or surplus.',
    'activityHintSedentary': 'Little or no exercise (desk job)',
    'activityHintLightlyActive': 'Exercise 1–3 times per week',
    'activityHintModeratelyActive': 'Exercise 4–5 times per week',
    'activityHintVeryActive': 'Daily exercise or intense 3–4×/week',
    'activityHintExtraActive': 'Very intense exercise daily, or physical job',
    'onboardTargetsTitle': 'Your Targets',
    'onboardTargetsSubtitle':
        'These help the AI plan your calorie and macro path.',
    'targetWeight': 'Target weight (kg)',
    'pace': 'Pace',
    'bodyFatPct': 'Body fat % (optional)',
    'pregnancyStatus': 'Pregnancy / breastfeeding',
    'onboardDietTitle': 'Diet Preferences',
    'onboardDietSubtitle': 'Food the AI should favor or avoid for you.',
    'dietaryPattern': 'Dietary pattern',
    'dislikedFoods': 'Foods to avoid (taste / preference)',
    'cuisinePreference': 'Cuisine preference',
    'onboardLifestyleTitle': 'Lifestyle',
    'onboardLifestyleSubtitle': 'Meal timing, sleep, stress, hydration.',
    'mealsPerDay': 'Meals per day',
    'fastingWindow': 'Intermittent fasting window',
    'sleepHours': 'Average sleep (hours)',
    'stressLevel': 'Stress level',
    'waterTargetMl': 'Water target (ml)',
    'waterTargetAiNote':
        'Your daily water goal will be calculated by AI from your body stats, activity, training, and health info when you finish onboarding.',
    'dailyWaterGoal': 'Daily water',
    'scanBarcode': 'Scan barcode',
    'barcodeScanHint': 'Point your camera at the product barcode',
    'barcodeLookingUp': 'Looking up nutrition…',
    'barcodeNotFound':
        'Product not found online. You can add it from the package label or pick a similar food.',
    'barcodeLogQuestion': 'Add this food to today\'s log?',
    'barcodeLogYes': 'Yes, log it',
    'barcodeLogNo': 'Not now',
    'barcodeLogged': 'Food added to your daily log',
    'barcodeAmountLabel': 'How much did you eat?',
    'barcodeNotOnWeb':
        'Use the BNYAD app on iPhone or Android to scan barcodes.',
    'barcodeCameraDenied':
        'Camera access is needed to scan barcodes. Allow camera permission and try again.',
    'barcodeCameraSettings':
        'Camera permission is blocked. Open Settings → BNYAD → Permissions and allow Camera.',
    'barcodeNetworkError':
        'Could not reach the food database. Check your internet and try again.',
    'barcodeInvalid': 'That barcode number is not valid. Enter 8–14 digits.',
    'barcodeManualEntry': 'Or type the barcode number',
    'barcodeManualHint': 'EAN / UPC number',
    'barcodeLookupButton': 'Look up',
    'barcodeNotFoundTitle': 'Product not in global database',
    'barcodeNotFoundBody':
        'Many local Iraqi and Kurdish products are not listed online yet. Add the nutrition once and the next scan will work automatically.',
    'barcodeAddManually': 'Enter nutrition from the label',
    'barcodePickFromApp': 'Pick a similar food from BNYAD',
    'barcodeProductName': 'Product name',
    'barcodeSaveAndContinue': 'Save and continue',
    'barcodeSavedForNextTime':
        'Saved. This barcode will work next time you scan it.',
    'choosePreparation': 'How was it prepared?',
    'choosePreparationHint': 'Tap to choose type (grilled, boiled, with oil…)',
    'chooseOilStep': 'With or without added oil?',
    'bonePortionLabel': 'Bones in your portion?',
    'bonelessPortion': 'Boneless (edible meat)',
    'withBonesPortion': 'With bones',
    'bonePortionHint':
        'If you weighed the piece with bones, we count only the edible meat so macros are not too high.',
    'medicationsLabel': 'Medications (optional)',
    'medicationsHint': 'Comma-separated, e.g. Metformin, Lisinopril',
    'onboardTrainingTitle': 'Training & Cooking',
    'onboardTrainingSubtitle':
        'Workout load and how much time you spend in the kitchen.',
    'workoutDaysPerWeek': 'Workout days / week',
    'workoutType': 'Workout type',
    'cookingSkill': 'Cooking skill',
    'cookingTime': 'Time per meal',
    'paceList': {
      'relaxed': 'Relaxed (gentle change)',
      'moderate': 'Moderate (recommended)',
      'aggressive': 'Aggressive (faster, harder)',
    },
    'pregnancyStatusList': {
      'none': 'None',
      'pregnant': 'Pregnant',
      'breastfeeding': 'Breastfeeding',
      'planning': 'Planning pregnancy',
    },
    'dietaryPatternList': {
      'omnivore': 'Omnivore',
      'vegetarian': 'Vegetarian',
      'vegan': 'Vegan',
      'pescatarian': 'Pescatarian',
      'keto': 'Keto',
      'lowCarb': 'Low-carb',
      'mediterranean': 'Mediterranean',
      'halal': 'Halal',
      'kosher': 'Kosher',
    },
    'dislikedFoodsList': {
      'pork': 'Pork',
      'beef': 'Beef',
      'redMeat': 'Red meat',
      'lamb': 'Lamb',
      'chicken': 'Chicken',
      'fishDislike': 'Fish',
      'shellfishDislike': 'Shellfish',
      'dairyDislike': 'Dairy',
      'eggsDislike': 'Eggs',
      'mushrooms': 'Mushrooms',
      'olives': 'Olives',
      'onions': 'Onions',
      'spicy': 'Spicy food',
      'cilantro': 'Cilantro',
      'sweets': 'Sweets',
      'processed': 'Processed food',
      'fried': 'Fried food',
    },
    'cuisinePreferenceList': {
      'mixed': 'Mixed / International',
      'kurdish': 'Kurdish',
      'arabic': 'Arabic / Middle Eastern',
      'mediterranean': 'Mediterranean',
      'asian': 'Asian',
      'western': 'Western',
    },
    'mealsPerDayList': {
      'two': '2 meals',
      'three': '3 meals',
      'four': '4 meals',
      'five': '5 meals',
    },
    'fastingWindowList': {
      'fastingNone': 'No fasting',
      'fasting12': '12-hour fast',
      'fasting14': '14-hour fast',
      'fasting16': '16:8',
      'fasting18': '18:6',
      'fasting20': '20:4 (OMAD-ish)',
    },
    'stressLevelList': {
      'stressLow': 'Low',
      'stressMedium': 'Medium',
      'stressHigh': 'High',
    },
    'workoutTypeList': {
      'workoutNone': 'None',
      'workoutCardio': 'Cardio',
      'workoutStrength': 'Strength',
      'workoutBoth': 'Cardio + strength',
      'workoutSport': 'Sport-specific',
    },
    'cookingSkillList': {
      'cookingBeginner': 'Beginner',
      'cookingIntermediate': 'Intermediate',
      'cookingAdvanced': 'Advanced',
    },
    'cookingTimeList': {
      'cookingTimeUnder15': 'Under 15 min',
      'cookingTimeUnder30': 'Under 30 min',
      'cookingTimeUnder60': 'Under 1 hour',
      'cookingTimeAny': 'Any',
    },
    'legalAndMedicalSources': 'Legal & Medical Citations',
    'privacyPolicy': 'Privacy Policy',
    'termsOfUseEula': 'Terms of Use (EULA)',
    'medicalSourcesCitations': 'Medical Sources & Citations',
    'subscriptionAutoRenewTerms':
        'Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless canceled at least 24 hours before the end of the current period. Account will be charged for renewal within 24 hours prior to the end of the current period. You can manage or cancel subscriptions in your App Store Account Settings after purchase.',
    'privacyMedicalSourcesTitle': 'Medical Sources & Citations',
    'privacyMedicalSourcesSubtitle':
        'Peer-reviewed research and clinical guidelines supporting BNYAD calculations',
    'privacyMedicalDisclaimerTitle': 'Important Medical Disclaimer',
    'privacyMedicalDisclaimerBody':
        'BNYAD (Nutrify) provides health, fitness, and nutrition calculations for educational and informational purposes only. It is not a substitute for clinical diagnosis or medical advice. Always consult a qualified physician or dietitian before starting a new diet program.',
    'privacyMedicalViewSourceLink': 'View Scientific Source Article',
    'privacyMedicalSourcesBmrCategory': 'BMR & Calorie Formula',
    'privacyMedicalSourcesBmrDesc':
        'Validates predictive equations for resting energy expenditure in healthy individuals across various BMI ranges.',
    'privacyMedicalSourcesBmiCategory': 'Body Mass Index (BMI)',
    'privacyMedicalSourcesBmiDesc':
        'International standard categories for adult body mass index derived from body weight and height.',
    'privacyMedicalSourcesBodyFatNavyCategory': 'Body Fat - US Navy Method',
    'privacyMedicalSourcesBodyFatNavyDesc':
        'Standardized tape measurement technique using waist, neck, and hip circumferences to estimate percent body fat.',
    'privacyMedicalSourcesBodyFatDeurenbergCategory':
        'Body Fat - Deurenberg Formula',
    'privacyMedicalSourcesBodyFatDeurenbergDesc':
        'Age- and sex-specific prediction model for adult body fat percentage derived from BMI.',
    'privacyMedicalSourcesMacrosCategory': 'Macronutrient Targets',
    'privacyMedicalSourcesMacrosDesc':
        'International Society of Sports Nutrition (ISSN) evidence-based recommendations for daily protein (1.6-2.0 g/kg) and macro splits.',
    'privacyMedicalSourcesWaterCategory': 'Daily Water Hydration',
    'privacyMedicalSourcesWaterDesc':
        'EFSA scientific opinion establishing adequate daily fluid intake guidelines for adult men and women.',
    'privacyMedicalSourcesFoodDbCategory': 'Nutritional Food Databases',
    'privacyMedicalSourcesFoodDbDesc':
        'Global open food database verified against USDA FoodData Central standards for energy and macronutrient profiles.',
  };

  // ─── Arabic ─────────────────────────────────────────
  static const Map<String, dynamic> _ar = {
    'or': 'أو',
    'notifications': 'الإشعارات',
    'ofTotal': 'من {total}',
    'versus': 'مقارنةً بـ',
    'daysRemaining': 'الأيام المتبقية: {days}',
    'poweredByBnyad': 'من أجل صحتك',
    'invalidNumber': 'أدخل رقماً موجباً صالحاً.',
    'mealChannel': 'تذكيرات الوجبات',
    'mealChannelDescription': 'إشعارات تذكير يومية بالوجبات',
    'weeklyChannel': 'الملخص الأسبوعي',
    'weeklyChannelDescription': 'ملخص التغذية الأسبوعي',
    'supplementChannel': 'تذكيرات المكملات',
    'supplementChannelDescription': 'تذكيرات الأدوية والمكملات اليومية',
    'notificationTestBody': 'الإشعارات تعمل!',
    'androidRenewal':
        'يُخصم الدفع من حساب Google Play بعد التأكيد. تتجدد الاشتراكات تلقائياً ما لم تُلغَ قبل موعد التجديد. يمكنك إدارة الاشتراك أو إلغاؤه في اشتراكات Google Play.',
    'webRenewal': 'يعرض متجر التطبيقات شروط الاشتراك والتجديد قبل التأكيد.',
    'generateAllDetailsHint':
        'سيتم تخطي الوجبات التي تحتوي بالفعل على المكونات والخطوات. لتحديث وجبة واحدة، استخدم الزر الموجود في بطاقتها.',
    'dashboard': 'لوحة القيادة',
    'profile': 'الملف الصحي',
    'foodLog': 'سجل الطعام',
    'calories': 'السعرات الحرارية',
    'carbs': 'الكربوهيدرات',
    'protein': 'البروتين',
    'fat': 'الدهون',
    'macronutrients': 'المغذيات الكبرى',
    'water': 'استهلاك الماء',
    'waterIntake': 'استهلاك الماء',
    'glasses': 'أكواب',
    'weight': 'الوزن (كجم)',
    'height': 'الطول (سم)',
    'age': 'العمر',
    'gender': 'الجنس',
    'male': 'ذكر',
    'female': 'أنثى',
    'activityLevel': 'مستوى النشاط',
    'sedentary': 'خامل',
    'lightlyActive': 'نشيط قليلاً',
    'moderatelyActive': 'نشيط باعتدال',
    'veryActive': 'نشيط جداً',
    'extraActive': 'نشيط للغاية',
    'calculate': 'حساب TDEE',
    'bmr': 'معدل الأيض الأساسي',
    'tdee': 'إجمالي استهلاك الطاقة',
    'searchFood': 'ابحث عن طعام...',
    'addMeal': 'إضافة وجبة',
    'addFood': 'إضافة طعام',
    'language': 'اللغة',
    'english': 'English',
    'arabic': 'العربية',
    'kurdish': 'کوردی (سۆرانی)',
    'onboardingTitle': 'مرحباً بك في BNYAD',
    'onboardingSubtitle': 'لنقم بإعداد خطة التغذية المخصصة لك.',
    'disabilities': 'الإعاقات الجسدية',
    'sicknesses': 'الأمراض / الحالات الطبية',
    'allergies': 'الحساسية',
    'next': 'التالي',
    'back': 'السابق',
    'finish': 'إنشاء الخطة',
    'analyzing': 'جاري الحساب...',
    'goalSet': 'هدفك المخصص جاهز!',
    'getStarted': 'ابدأ الآن',
    'settings': 'الإعدادات',
    'theme': 'المظهر',
    'light': 'فاتح',
    'dark': 'داكن',
    'selectSicknesses': 'اختر الحالات الطبية',
    'selectAllergies': 'اختر الحساسية',
    'search': 'بحث...',
    'selected': 'تم الاختيار',
    'none': 'لا يوجد',
    'mealPlan': 'خطة الوجبات',
    'generateMealPlan': 'إنشاء خطة الوجبات',
    'generatePlan': 'إنشاء الخطة',
    'mealPlanSubtitle': 'دليل التغذية اليومي المدعوم بالذكاء الاصطناعي',
    'breakfast': 'الإفطار',
    'lunch': 'الغداء',
    'dinner': 'العشاء',
    'snacks': 'وجبات خفيفة',
    'generating': 'جاري إنشاء خطتك...',
    'selectDisabilities': 'اختر الإعاقات الجسدية',
    'ingredients': 'المكونات',
    'instructions': 'التعليمات',
    'logAsEaten': 'تسجيل كوجبة مأكولة',
    'eaten': 'تم الأكل',
    'goals': 'الأهداف',
    'selectGoal': 'اختر هدفك',
    'goalList': {
      'loseWeight': 'إنقاص الوزن',
      'gainWeight': 'زيادة الوزن',
      'gainMuscle': 'بناء العضلات',
      'stayHealthy': 'البقاء بصحة جيدة',
      'athletic': 'تحسين الأداء الرياضي',
      'manageCondition': 'إدارة الحالة الطبية',
    },
    'healthGuidance': 'نصائح صحية',
    'healthGuidanceSubtitle': 'نصائح مخصصة لحالتك الصحية',
    'amount': 'الكمية',
    'grams': 'جرام',
    'add': 'إضافة',
    'total': 'المجموع',
    'searchPlaceholder': 'ابحث عن طعام (مثلاً دولمة، بيتزا...)',
    'browseFoods': 'تصفح الأطعمة',
    'selectFood': 'اختر الطعام',
    'close': 'إغلاق',
    'sicknessesList': {
      'diabetes1': 'السكري النوع الأول',
      'diabetes2': 'السكري النوع الثاني',
      'hypertension': 'ارتفاع ضغط الدم',
      'celiac': 'مرض السيلياك',
      'ibs': 'القولون العصبي',
      'kidney': 'أمراض الكلى',
      'heart': 'أمراض القلب',
      'obesity': 'السمنة',
      'anemia': 'فقر الدم',
      'hypo': 'قصور الغدة الدرقية',
      'hyper': 'فرط نشاط الغدة الدرقية',
      'gout': 'النقرس',
      'reflux': 'ارتجاع المريء',
    },
    'allergiesList': {
      'peanuts': 'الفول السوداني',
      'treeNuts': 'المكسرات',
      'milk': 'الحليب',
      'egg': 'البيض',
      'wheat': 'القمح',
      'soy': 'الصويا',
      'fish': 'السمك',
      'shellfish': 'المحار',
      'sesame': 'السمسم',
      'gluten': 'الغلوتين',
      'lactose': 'اللاكتوز',
      'corn': 'الذرة',
      'mustard': 'الخردل',
    },
    'disabilitiesList': {
      'wheelchair': 'مستخدم كرسي متحرك',
      'mobility': 'حركة محدودة',
      'visual': 'ضعف البصر',
      'hearing': 'ضعف السمع',
      'amputation': 'بتر',
      'none': 'لا يوجد',
    },
    'foodScanner': 'ماسح الطعام',
    'readyToScan': 'جاهز للمسح؟',
    'scanSubtitle':
        'وجه الكاميرا أو ارفع صورة لطعامك للحصول على معلومات غذائية فورية.',
    'startCamera': 'بدء الكاميرا',
    'uploadPhoto': 'رفع صورة',
    'aiAnalyzed': 'تحليل الذكاء الاصطناعي',
    'logAsEaten100g': 'تسجيل كوجبة (100 جرام)',
    'howToUse': 'كيفية الاستخدام',
    'instructionsSteps': [
      'قم بإعداد ملفك الشخصي بوزنك وطولك وحالتك الصحية.',
      'استخدم الماسح الضوئي للتعرف على الأطعمة وقيمها الغذائية.',
      'سجل وجباتك يومياً لتتبع السعرات الحرارية والماكروز.',
      'تحقق من لوحة القيادة للحصول على نصائح صحية مخصصة.',
      'قم بإنشاء خطة وجبات للحصول على أدلة تغذية يومية مدعومة بالذكاء الاصطناعي.',
    ],
    'aiGuidance': 'نصائح صحية بالذكاء الاصطناعي',
    'cameraError': 'تعذر الوصول إلى الكاميرا. يرجى التأكد من منح الأذونات.',
    'analysisError': 'فشل تحليل الصورة. يرجى المحاولة مرة أخرى.',
    'regenerate': 'إعادة إنشاء',
    'noMealPlan': 'لا توجد خطة وجبات بعد',
    'noMealPlanDesc':
        'دع الذكاء الاصطناعي ينشئ خطة تغذية مخصصة بناءً على أهدافك وملفك الصحي.',
    'loggedAsEaten': 'تم التسجيل كوجبة مأكولة',
    'goalCalculatedDesc': 'بناءً على وزنك وطولك وعمرك ونشاطك وهدفك وتمرينك.',
    'ml': 'مل',
    'kcal': 'سعرة',
    'logout': 'تسجيل الخروج',
    'account': 'الحساب',
    'deleteAccount': 'حذف الحساب',
    'deleteAccountConfirmTitle': 'حذف الحساب نهائياً؟',
    'deleteAccountConfirmDesc':
        'سيتم حذف جميع بيانات ملفك الشخصي وسجلات التغذية اليومية وتتبع المياه وسجل الوزن وخطط الوجبات نهائياً من خوادمنا. لا يمكن التراجع عن هذا الإجراء.',
    'deleteAccountButton': 'حذف حسابي',
    'deleteAccountSuccess': 'تم حذف حسابك وبياناتك نهائياً.',
    'deleteAccountFailed':
        'فشل حذف الحساب. يرجى التحقق من اتصالك والمحاولة مرة أخرى.',
    'deletingAccount': 'جاري حذف الحساب...',
    'accountDeletionWeb': 'بوابة حذف الحساب (الويب)',
    'login': 'تسجيل الدخول',
    'signInWithPhone': 'تسجيل الدخول بالهاتف',
    'welcomeTitle': 'ابدأ رحلتك الصحية',
    'welcomeSubtitle':
        'تتبع تغذيتك، وخطط لوجباتك، وحقق أهدافك الصحية مع بنياد.',
    'signUp': 'إنشاء حساب',
    'phoneNotRegistered': 'رقم الهاتف هذا غير مسجل. يرجى إنشاء حساب.',
    'phoneAlreadyRegistered': 'رقم الهاتف هذا مسجل بالفعل. يرجى تسجيل الدخول.',
    'signInWithPassword': 'تسجيل الدخول بكلمة المرور',
    'loginWithOtp': 'تسجيل الدخول برمز OTP',
    'phoneNumber': 'رقم الهاتف',
    'phoneNumberHint': '750 123 4567',
    'sendOtp': 'إرسال الرمز',
    'enterOtpCode': 'أدخل رمز التحقق',
    'otpCodeHint': 'رمز من 6 أرقام',
    'verifyOtp': 'تحقق',
    'resendOtp': 'إعادة إرسال الرمز',
    'changePhoneNumber': 'تغيير الرقم',
    'invalidPhoneNumber': 'أدخل رقم هاتف صالح',
    'invalidOtpCode': 'أدخل الرمز المكون من 6 أرقام',
    'otpSentTo': 'تم إرسال الرمز إلى',
    'otpBackendPending': 'التحقق برمز OTP غير متصل بعد.',
    'resendOtpIn': 'إعادة الإرسال خلال {seconds} ث',
    'demoOtpHint': 'رمز تجريبي: 123456',
    'yourName': 'اسمك',
    'nameHint': 'مثال: سارة',
    'whatIsYourName': 'ما اسمك؟',
    'nameSubtitle': 'سنرحّب بك في لوحة القيادة',
    'continueLabel': 'متابعة',
    'invalidName': 'يرجى إدخال اسمك',
    'welcomeName': 'مرحباً، {name}',
    'yourBmi': 'مؤشر كتلة الجسم',
    'maintenanceCalories': 'السعرات للحفاظ (TDEE)',
    'dailyCalorieTarget': 'هدف السعرات اليومي',
    'proteinPerKgBody': 'غرام بروتين لكل كغ من وزن الجسم',
    'password': 'كلمة المرور',
    'passwordHint': '6 أحرف على الأقل',
    'invalidPassword': 'يجب أن تكون كلمة المرور 6 أحرف على الأقل',
    'noEntries': 'لا توجد إدخالات بعد',
    'guestMode': 'وضع الضيف',
    'generateDetails': 'إنشاء التفاصيل',
    'goalGenerationError': 'تعذر إنشاء الأهداف. يرجى المحاولة مرة أخرى.',
    'unknownFood': 'طعام غير معروف',
    'per100g': 'لكل ١٠٠ جرام',
    'guestUser': 'مستخدم ضيف',
    'loginRequiredTitle': 'يلزم تسجيل الدخول',
    'loginRequiredSubtitle':
        'أنشئ حساباً أو سجّل الدخول لاستخدام هذه الميزة. ستُزامَن بياناتك بين الأجهزة.',
    'loginRequiredCta': 'تسجيل الدخول / إنشاء حساب',
    'signInToContinue': 'سجّل الدخول للمتابعة',
    'createAccount': 'إنشاء حساب',
    'registerSubtitle': 'أدخل اسمك وكلمة المرور، ثم تحقق من رقم هاتفك.',
    'confirmPassword': 'تأكيد كلمة المرور',
    'confirmPasswordHint': 'أعد إدخال كلمة المرور',
    'passwordsDoNotMatch': 'كلمتا المرور غير متطابقتين',
    'continueWithPhone': 'متابعة',
    'welcomeBack': 'مرحباً بعودتك',
    'returningUserOtpHint': 'أدخل الرمز الذي أرسلناه إلى هاتفك.',
    'guestModeLimited': 'وضع الضيف — ميزات محدودة',
    'signInFromSettings': 'سجّل الدخول لفتح كل الميزات',
    'appLoading': '...جاري التحميل BNYAD',
    'splashTagline': 'شريكك الذكي\nفي التغذية',
    'splashSubline': 'كُل بذكاء. عِش بصحة.',
    'todaysMeals': 'وجبات اليوم',
    'quickLog': 'تسجيل سريع',
    'quickLogHint': 'أضف الأطعمة يدوياً من سجل الطعام، أو اختر وجبة أدناه.',
    'logForMealSlot': 'تسجيل لـ',
    'noMealPlanned': 'لا وجبة مخططة بعد',
    'otherFoods': 'أطعمة أخرى',
    'otherFoodsHint': 'مسجّلة بدون فترة وجبة (اضغط لفتح سجل الطعام)',
    'loggedToday': 'مسجّل',
    'viewMealPlan': 'عرض الخطة الكاملة',
    'swapMeal': 'تبديل الوجبة',
    'mealReminders': 'تذكيرات الوجبات',
    'reminderTime': 'وقت التذكير',
    'breakfastReminder': 'تذكير الإفطار',
    'lunchReminder': 'تذكير الغداء',
    'dinnerReminder': 'تذكير العشاء',
    'snacksReminder': 'تذكير الوجبات الخفيفة',
    'timeToEat': 'حان وقت الأكل!',
    'nutrientsAndSupplements': 'العناصر الغذائية والمكملات',
    'fromFood': 'من الطعام',
    'supplements': 'المكملات',
    'vitaminA': 'فيتامين أ',
    'vitaminC': 'فيتامين سي',
    'vitaminD': 'فيتامين د',
    'vitaminB12': 'فيتامين ب١٢',
    'iron': 'الحديد',
    'calcium': 'الكالسيوم',
    'potassium': 'البوتاسيوم',
    'zincMineral': 'الزنك',
    'vitaminE': 'فيتامين E',
    'vitaminK': 'فيتامين K',
    'vitaminB6': 'فيتامين B6',
    'folate': 'حمض الفوليك',
    'magnesium': 'المغنيسيوم',
    'phosphorus': 'الفوسفور',
    'selenium': 'السيلينيوم',
    'sodium': 'الصوديوم',
    'fiber': 'الألياف',
    'supplementReminders': 'تذكير المكملات',
    'supplementReminderTitle': 'حان وقت المكمل',
    'takeYourSupplement': 'وقت تناول',
    'enableReminder': 'تذكير يومي',
    'dailyNutrientGoals': 'أهداف العناصر اليومية',
    'noSupplementsForReminders':
        'أضف مكملات من قسم العناصر الغذائية لتعيين التذكيرات.',
    'vitaminsAndPills': 'الفيتامينات والحبوب',
    'addVitamin': 'إضافة فيتامين',
    'vitaminName': 'اسم الفيتامين',
    'dosage': 'مثلاً: ١ حبة، ٥٠٠ ملغ',
    'taken': 'تم تناوله',
    'noVitamins': 'لا توجد فيتامينات بعد',
    'noVitaminsDesc': 'أضف فيتاميناتك ومكملاتك اليومية لتتبعها.',
    'cookWithIngredients': 'اطبخ بمكوناتي',
    'enterIngredients': 'أدخل مكوناتك',
    'ingredientsHint': 'مثلاً: دجاج، أرز، طماطم، بصل...',
    'generateRecipe': 'إنشاء وصفة',
    'aiRecipe': 'وصفة الذكاء الاصطناعي',
    'piece': 'قطعة',
    'pieces': 'قطع',
    'bowls': 'أوعية',
    'perPiece': 'لكل قطعة',
    'perBowl': 'لكل وعاء',
    'pieceWeight': 'وزن القطعة (جرام)',
    'byGrams': 'بالجرام',
    'byPiece': 'بالقطعة',
    'byBowl': 'بالوعاء',
    'bowlWeight': 'وزن الوعاء (جرام)',
    'scanFridge': 'مسح ثلاجتي',
    'scanFridgeDesc':
        'التقط صورة لثلاجتك وسيقترح الذكاء الاصطناعي وجبة بناءً على ما لديك.',
    'selectMealType': 'هذه الوجبة لـ:',
    'detectedIngredients': 'المكونات المكتشفة',
    'ingredientBreakdown': 'تفصيل المكونات',
    'totalMacros': 'إجمالي الماكروز',
    'suggestedRecipe': 'الوصفة المقترحة',
    'deleteRecipe': 'حذف الوصفة',
    'logFoodForNutrients': 'سجّل طعامك لمعرفة العناصر الغذائية اليومية',
    'errorNetwork': 'خطأ في الشبكة. يرجى التحقق من الاتصال والمحاولة مرة أخرى.',
    'errorTimeout': 'انتهت مهلة الطلب. يرجى المحاولة مرة أخرى.',
    'errorGeneric': 'حدث خطأ ما. يرجى المحاولة مرة أخرى.',
    'tryAgain': 'حاول مرة أخرى',
    'somethingWentWrong': 'حدث خطأ ما',
    'noInternet': 'لا يوجد اتصال بالإنترنت',
    'mealGenerationFailed': 'فشل في إنشاء خطة الوجبات. يرجى المحاولة مرة أخرى.',
    'scanFailed': 'فشل في تحليل الطعام. يرجى المحاولة مع صورة أوضح.',
    'loadingFailed': 'فشل في تحميل البيانات. يرجى المحاولة مرة أخرى.',
    'permissionDenied': 'تم رفض الإذن. يرجى تفعيله من الإعدادات.',
    'fridgeScanError': 'فشل في تحليل محتويات الثلاجة. يرجى المحاولة مرة أخرى.',
    'recipeGenerationFailed': 'فشل في إنشاء الوصفة. يرجى المحاولة مرة أخرى.',
    'goalGenerationFailed': 'فشل في تحديد الأهداف. يرجى المحاولة مرة أخرى.',
    'swapFailed': 'فشل في تبديل الوجبة. يرجى المحاولة مرة أخرى.',
    'detailsFailed': 'فشل في إنشاء تفاصيل الوجبة. يرجى المحاولة مرة أخرى.',
    'dailyTotal': 'المجموع اليومي',
    'ofGoal': 'من الهدف',
    'weeklySummary': 'ملخص أسبوعي',
    'weeklySummarySubtitle': 'تقدمك خلال آخر ٧ أيام',
    'weeklyStreak': 'سلسلة التسجيل',
    'weeklyDaysLogged': 'أيام مسجّلة',
    'weeklyGoalDays': 'ضمن الهدف',
    'weeklyWeightChange': 'تغيّر الوزن',
    'weeklyWeightLost': 'فقدت هذا الأسبوع',
    'weeklyWeightGained': 'اكتسبت هذا الأسبوع',
    'weeklyWeightStable': 'لا تغيّر هذا الأسبوع',
    'weeklyLogWeightHint':
        'حدّث وزنك أدناه لمتابعة فقدان أو زيادة الوزن بالكيلوغرام.',
    'weeklyAvgCalories': 'متوسط السعرات (أيام مسجّلة)',
    'weeklyCalorieChart': 'السعرات اليومية مقابل الهدف',
    'weeklyDailyBreakdown': 'يوم بيوم',
    'weeklyUpdateWeight': 'تحديث وزن اليوم',
    'weeklyDayStreak': 'يوم متتالي',
    'weeklyOnTarget': 'ضمن الهدف',
    'weeklyDaysLoggedHint': 'من ٧ أيام',
    'weeklyStreakStart': 'سجّل وجباتك لبدء سلسلة',
    'cancel': 'إلغاء',
    'save': 'حفظ',
    'editMacros': 'تعديل الماكروز',
    'editMacrosDesc':
        'حدّد يدويًا أهداف السعرات والبروتين والكربوهيدرات والدهون اليومية.',
    'macrosUpdated': 'تم تحديث أهداف الماكروز',
    'resetToAi': 'إعادة إلى قيم الذكاء الاصطناعي',
    'remove': 'إزالة',
    'removeLoggedTitle': 'إزالة العنصر؟',
    'removeLoggedBody': 'إزالة "{name}" من سجل اليوم؟',
    'itemRemoved': 'تمت إزالة العنصر',
    'bodyFatShortcut': 'دهون الجسم (ذكاء اصطناعي)',
    'bodyFatScreenTitle': 'تقدير دهون الجسم',
    'bodyFatScreenIntro':
        'للدقة الأفضل، استخدم شريط قياس ناعم أولاً (الخصر + الرقبة). الصورة يمكن أن تعدّل النتيجة قليلاً لكنها ليست أدق من القياسات.',
    'bodyFatStaticDisclaimer':
        'هذه الميزة للمعلومات العامة فقط وليست تشخيصاً أو جهازاً طبياً. لقياس دقيق للتكوين، استشر مختصاً عن فحص DEXA أو غيره.',
    'bodyFatAnalyzing': 'جارٍ تحليل الصورة…',
    'bodyFatEstimatedRange': 'النطاق التقديري',
    'bodyFatConfidenceLabel': 'الثقة',
    'bodyFatConfidenceLow': 'منخفضة (صورة فقط)',
    'bodyFatConfidenceMedium': 'متوسطة (معادلة BMI أو مزيج)',
    'bodyFatConfidenceHigh': 'عالية (طريقة الشريط)',
    'bodyFatMeasureTitle': 'الخطوة ١ — قياسات الشريط (موصى بها)',
    'bodyFatMeasureHint':
        'قِس في الصباح، بطن مرتاح. الخصر: أضيق نقطة فوق السرة أو عندها. الرقبة: أسفل الحنجرة. النساء: الورك عند أعرض نقطة.',
    'bodyFatMeasureRequired': 'أدخل الخصر والرقبة (والورك للنساء) بالسنتيمتر.',
    'bodyFatWaistCm': 'الخصر',
    'bodyFatNeckCm': 'الرقبة',
    'bodyFatHipCm': 'الورك (نساء)',
    'bodyFatCalculateMeasurements': 'احسب من القياسات',
    'bodyFatPhotoOptional': 'الخطوة ٢ — صورة (اختياري)',
    'bodyFatPhotoHint':
        'صورة أمامية أو جانبية، ملابس ضيقة، إضاءة جيدة. تُستخدم لتعديل تقدير القياسات قليلاً فقط.',
    'bodyFatMethodLabel': 'الطريقة',
    'bodyFatMethodNavy': 'معادلة الشريط (US Navy)',
    'bodyFatMethodDeurenberg': 'معادلة BMI + العمر',
    'bodyFatMethodBlended': 'قياسات + صورة',
    'bodyFatMethodPhoto': 'تقدير من الصورة',
    'bodyFatProfileContext': 'ملفك',
    'bodyFatAiNotes': 'ملاحظات',
    'bodyFatAiDisclaimer': 'تنبيه الذكاء الاصطناعي',
    'bodyFatRetakePhoto': 'صورة جديدة',
    'bodyFatFailed': 'تعذّر التقدير. جرّب صورة أخرى أو تحقق من الاتصال.',
    'weeklyDigestTitle': 'ملخص أسبوعي',
    'weeklyDigestBody': 'افتح BNYAD لمراجعة أسبوعك.',
    'weeklyDigestNotify': 'تذكير بالملخص الأسبوعي (الأحد)',
    'shoppingList': 'قائمة التسوق',
    'shoppingListEmpty': 'القائمة فارغة',
    'addItem': 'إضافة عنصر',
    'itemName': 'اسم العنصر',
    'clearDone': 'مسح المُنجَز',
    'favorites': 'المفضلة',
    'noFavorites': 'لا توجد مفضلات — احفظ أطعمة أو وجبات للتسجيل السريع.',
    'saveAsFavorite': 'حفظ كمفضل',
    'savedFavorite': 'تم الحفظ في المفضلة',
    'useTemplate': 'تسجيل من المفضلة',
    'addPlanIngredients': 'إضافة المكونات لقائمة التسوق',
    'saveMealTemplate': 'حفظ الوجبة كقالب',
    'offlineBanner': 'وضع عدم الاتصال — سجل الطعام والخطط المحفوظة تعمل.',
    'testNotification': 'اختبار الإشعار',
    'notificationsWebInfo':
        'تذكيرات الوجبات والتنبيهات المجدولة تعمل في تطبيق BNYAD للهاتف. نسخة الويب لا تستطيع عرض إشعارات النظام.',
    'notificationsWebHint':
        'استخدم تطبيق أندرويد أو آي أو إس لتعيين أوقات التذكير للإفطار والغداء والعشاء والوجبات الخفيفة والملخص الأسبوعي.',
    'shoppingListUpdated': 'تمت إضافة المكونات إلى قائمة التسوق',
    'insightsLists': 'رؤى وقوائم',
    'mealCuisineStyle': 'نوع الأطباق',
    'cuisineKurdish': 'كوردي',
    'cuisineArabic': 'عربي / شرق أوسطي',
    'cuisineAll': 'متنوع / الكل',
    'aiShoppingListButton': 'ماذا أشتري؟ (ذكاء اصطناعي)',
    'aiShoppingListTitle': 'قائمة تسوق مقترحة',
    'aiShoppingLoading': 'جاري إعداد قائمة التسوق…',
    'aiShoppingFailed': 'تعذر إنشاء القائمة. حاول مرة أخرى.',
    'addSuggestedToList': 'إضافة الكل لقائمة التسوق',
    'needMealPlanForAiShopping': 'أنشئ خطة وجبات أولاً ثم أعد المحاولة.',
    'aiShoppingDetailsHint':
        'نصيحة: اضغط «إنشاء التفاصيل» لكل وجبة لقائمة أدق.',
    'aiShoppingAllMealsLogged':
        'لقد سجّلت كل وجبات خطة اليوم كمأكولة — لا يوجد شيء متبقٍ للشراء لهذه الأطباق.',
    'generateAllDetailsButton': 'إنشاء تفاصيل كل الوجبات',
    'generateAllDetailsBusy': 'جاري إنشاء التفاصيل…',
    'allMealsAlreadyDetailed': 'كل الوجبات تحتوي بالفعل على المكونات والخطوات.',
    'allDetailsGeneratedSuccess': 'تمت إضافة المكونات والخطوات لـ {n} وجبة.',
    'allDetailsPartialSuccess':
        'تم تحديث {n} وجبة. راجع البطاقات التي تظهر خطأ.',
    'allDetailsAllFailed':
        'تعذر إنشاء التفاصيل. حاول مرة أخرى أو استخدم زر كل وجبة.',
    'shoppingDuplicate': 'موجود مسبقاً في القائمة — تم تخطي التكرار.',
    'shoppingItemAdded': 'تمت الإضافة إلى القائمة.',
    'shoppingBulkAllDupes': 'لا جديد — كل العناصر كانت موجودة مسبقاً.',
    'shoppingBulkAddedOnly': 'تمت إضافة {n} عنصراً جديداً إلى القائمة.',
    'shoppingBulkMixed':
        'تمت إضافة {a} عنصراً جديداً. تم تخطي {s} مكرراً موجود مسبقاً.',
    'categoryList': {
      'Kurdish': 'أكلات كوردية',
      'Bread': 'خبز ومعجنات',
      'RiceDishes': 'أطباق أرز',
      'Soup': 'شوربات وأطباق سائلة',
      'Arabic': 'عربي / شرق أوسطي',
      'Protein': 'بروتينات',
      'Dairy': 'منتجات الألبان',
      'Grains': 'حبوب ونشويات',
      'Fruit': 'فواكه',
      'Vegetable': 'خضروات',
      'Nuts': 'مكسرات وبذور',
      'Legumes': 'بقوليات',
      'International': 'أطباق عالمية',
      'FastFood': 'وجبات سريعة',
      'Supplement': 'مكملات غذائية',
      'Beverage': 'مشروبات',
      'Snacks': 'وجبات خفيفة وحلويات',
      'Oil': 'زيوت ودهون',
    },
    'premium': 'بريميوم',
    'premiumBadge': 'بريميوم',
    'premiumLocked': 'ميزة بريميوم',
    'premiumUnlockCta': 'افتح بريميوم',
    'premiumActive': 'بريميوم مفعّل',
    'premiumActiveUntil': 'مفعّل حتى {date}',
    'premiumTitle': 'اشترك في بريميوم',
    'premiumSubtitle': 'افتح كامل قدرات الذكاء الاصطناعي في BNYAD.',
    'premiumPerkMealPlan': 'خطط وجبات يومية بالذكاء الاصطناعي',
    'premiumPerkScanner': 'ماسح الطعام والثلاجة بالذكاء الاصطناعي',
    'premiumPerkAiTips': 'نصائح صحية شخصية بالذكاء الاصطناعي',
    'premiumPerkNutrients': 'تتبّع المغذيات والمكمّلات',
    'premiumPerkSwapMeals': 'تبديل الوجبات وقائمة تسوق ذكية',
    'premiumPerkRecipes': 'وصفات مخصصة من مكوناتك',
    'premiumActivate': 'ابدأ بريميوم',
    'premiumDeactivate': 'إلغاء بريميوم',
    'premiumRestore': 'استعادة الشراء',
    'premiumComingSoon': 'المدفوعات الحقيقية قريباً. اضغط للتفعيل التجريبي.',
    'premiumManage': 'إدارة الاشتراك',
    'premiumFooterNote': 'مقدر دهون الجسم وحاسبة الماكروز يبقيان مجانيين.',
    'optionalField': 'اختياري',
    'onboardStepOf': 'الخطوة {c} من {t}',
    'onboardActivityStepTitle': 'النشاط اليومي',
    'onboardActivityStepSubtitle':
        'ما مدى نشاطك في الأسبوع المعتاد؟ يحدد هذا سعراتك الأساسية.',
    'onboardHealthStepTitle': 'الصحة والحساسية',
    'onboardHealthStepSubtitle':
        'يساعدنا على تخصيص الوجبات وأهداف المغذيات الدقيقة بأمان.',
    'onboardHealthOptionalNote':
        'اختياري — تخطَّ إن لم ينطبق. يمكنك التعديل لاحقاً من الإعدادات.',
    'onboardGoalStepSubtitle':
        'اختر تركيزك الرئيسي. تُعدَّل السعرات بعجز أو فائض معتدل وآمن.',
    'activityHintSedentary': 'قليل أو بدون تمارين (عمل مكتبي)',
    'activityHintLightlyActive': 'تمارين 1–3 مرات في الأسبوع',
    'activityHintModeratelyActive': 'تمارين 4–5 مرات في الأسبوع',
    'activityHintVeryActive': 'تمارين يومية أو مكثفة 3–4 مرات/أسبوع',
    'activityHintExtraActive': 'تمارين مكثفة جداً يومياً أو عمل بدني',
    'onboardTargetsTitle': 'أهدافك',
    'onboardTargetsSubtitle':
        'تساعد الذكاء الاصطناعي على رسم خطة السعرات والماكروز.',
    'targetWeight': 'الوزن المستهدف (كغ)',
    'pace': 'السرعة',
    'bodyFatPct': 'نسبة دهون الجسم % (اختياري)',
    'pregnancyStatus': 'الحمل / الرضاعة',
    'onboardDietTitle': 'تفضيلات الغذاء',
    'onboardDietSubtitle': 'الطعام الذي يُفضَّل أو يُتجنَّب.',
    'dietaryPattern': 'النمط الغذائي',
    'dislikedFoods': 'طعام تفضل تجنبه',
    'cuisinePreference': 'المطبخ المفضل',
    'onboardLifestyleTitle': 'نمط الحياة',
    'onboardLifestyleSubtitle': 'توقيت الوجبات والنوم والإجهاد والترطيب.',
    'mealsPerDay': 'عدد الوجبات في اليوم',
    'fastingWindow': 'الصيام المتقطع',
    'sleepHours': 'معدل النوم (ساعات)',
    'stressLevel': 'مستوى الإجهاد',
    'waterTargetMl': 'هدف الماء (مل)',
    'waterTargetAiNote':
        'سيتم حساب هدف الماء اليومي بالذكاء الاصطناعي من بياناتك (الجسم، النشاط، التمرين، والصحة) عند إنهاء الإعداد.',
    'dailyWaterGoal': 'الماء اليومي',
    'scanBarcode': 'مسح الباركود',
    'barcodeScanHint': 'وجّه الكاميرا نحو باركود المنتج',
    'barcodeLookingUp': 'جاري جلب القيم الغذائية…',
    'barcodeNotFound': 'المنتج غير موجود. جرّب باركوداً آخر أو ابحث يدوياً.',
    'barcodeLogQuestion': 'هل تريد إضافة هذا الطعام لسجل اليوم؟',
    'barcodeLogYes': 'نعم، أضفه',
    'barcodeLogNo': 'ليس الآن',
    'barcodeLogged': 'تمت إضافة الطعام لسجل اليوم',
    'barcodeAmountLabel': 'كم أكلت؟',
    'barcodeNotOnWeb':
        'استخدم تطبيق BNYAD على آي أو إس أو أندرويد لمسح الباركود.',
    'barcodeCameraDenied':
        'يلزم الوصول إلى الكاميرا لمسح الباركود. اسمح بالإذن وحاول مرة أخرى.',
    'barcodeCameraSettings':
        'تم حظر إذن الكاميرا. افتح الإعدادات → BNYAD → الأذونات واسمح بالكاميرا.',
    'barcodeNetworkError':
        'تعذر الاتصال بقاعدة بيانات الطعام. تحقق من الإنترنت وحاول مرة أخرى.',
    'barcodeInvalid': 'رقم الباركود غير صالح. أدخل 8–14 رقمًا.',
    'barcodeManualEntry': 'أو اكتب رقم الباركود',
    'barcodeManualHint': 'رقم EAN / UPC',
    'barcodeLookupButton': 'بحث',
    'barcodeNotFoundTitle': 'المنتج غير موجود في قاعدة البيانات العالمية',
    'barcodeNotFoundBody':
        'كثير من المنتجات المحلية العراقية والكردية غير مسجلة على الإنترنت. أضف القيم الغذائية مرة واحدة وسيعمل الباركود تلقائياً لاحقاً.',
    'barcodeAddManually': 'أدخل القيم من الملصق',
    'barcodePickFromApp': 'اختر طعاماً مشابهاً من BNYAD',
    'barcodeProductName': 'اسم المنتج',
    'barcodeSaveAndContinue': 'حفظ ومتابعة',
    'barcodeSavedForNextTime': 'تم الحفظ. سيعمل هذا الباركود في المرة القادمة.',
    'choosePreparation': 'كيف تم تحضيره؟',
    'choosePreparationHint': 'اضغط لاختيار النوع (مشوي، مسلوق، بالزيت…)',
    'chooseOilStep': 'بدون زيت أم بالزيت؟',
    'bonePortionLabel': 'هل يوجد عظم في الحصة؟',
    'bonelessPortion': 'بدون عظم (لحم صالح)',
    'withBonesPortion': 'مع عظم',
    'bonePortionHint':
        'إذا وزنت القطعة مع العظم، نحسب اللحم الصالح فقط حتى لا تكون السعرات أعلى من الواقع.',
    'medicationsLabel': 'الأدوية (اختياري)',
    'medicationsHint': 'مفصولة بفواصل، مثل: ميتفورمين، ليزينوبريل',
    'onboardTrainingTitle': 'التمرين والطبخ',
    'onboardTrainingSubtitle': 'حجم التمارين والوقت في المطبخ.',
    'workoutDaysPerWeek': 'أيام التمرين في الأسبوع',
    'workoutType': 'نوع التمرين',
    'cookingSkill': 'مهارة الطبخ',
    'cookingTime': 'الوقت لكل وجبة',
    'paceList': {
      'relaxed': 'هادئة (تغيير لطيف)',
      'moderate': 'معتدلة (مُوصى بها)',
      'aggressive': 'سريعة (أصعب)',
    },
    'pregnancyStatusList': {
      'none': 'لا شيء',
      'pregnant': 'حامل',
      'breastfeeding': 'مرضعة',
      'planning': 'أخطط للحمل',
    },
    'dietaryPatternList': {
      'omnivore': 'كل شيء',
      'vegetarian': 'نباتي',
      'vegan': 'نباتي صرف',
      'pescatarian': 'سمكي',
      'keto': 'كيتو',
      'lowCarb': 'منخفض الكربوهيدرات',
      'mediterranean': 'متوسطي',
      'halal': 'حلال',
      'kosher': 'كوشير',
    },
    'dislikedFoodsList': {
      'pork': 'خنزير',
      'beef': 'لحم بقري',
      'redMeat': 'لحم أحمر',
      'lamb': 'لحم خروف',
      'chicken': 'دجاج',
      'fishDislike': 'سمك',
      'shellfishDislike': 'محار',
      'dairyDislike': 'ألبان',
      'eggsDislike': 'بيض',
      'mushrooms': 'فطر',
      'olives': 'زيتون',
      'onions': 'بصل',
      'spicy': 'حار',
      'cilantro': 'كزبرة',
      'sweets': 'حلويات',
      'processed': 'أطعمة مُصنّعة',
      'fried': 'مقلي',
    },
    'cuisinePreferenceList': {
      'mixed': 'مختلط / عالمي',
      'kurdish': 'كردي',
      'arabic': 'عربي / شرق أوسطي',
      'mediterranean': 'متوسطي',
      'asian': 'آسيوي',
      'western': 'غربي',
    },
    'mealsPerDayList': {
      'two': 'وجبتان',
      'three': '٣ وجبات',
      'four': '٤ وجبات',
      'five': '٥ وجبات',
    },
    'fastingWindowList': {
      'fastingNone': 'بدون صيام',
      'fasting12': 'صيام ١٢ ساعة',
      'fasting14': 'صيام ١٤ ساعة',
      'fasting16': '٨:١٦',
      'fasting18': '٦:١٨',
      'fasting20': '٤:٢٠',
    },
    'stressLevelList': {
      'stressLow': 'منخفض',
      'stressMedium': 'متوسط',
      'stressHigh': 'مرتفع',
    },
    'workoutTypeList': {
      'workoutNone': 'بدون',
      'workoutCardio': 'تمارين هوائية',
      'workoutStrength': 'قوة',
      'workoutBoth': 'هوائي + قوة',
      'workoutSport': 'رياضة محددة',
    },
    'cookingSkillList': {
      'cookingBeginner': 'مبتدئ',
      'cookingIntermediate': 'متوسط',
      'cookingAdvanced': 'متقدم',
    },
    'cookingTimeList': {
      'cookingTimeUnder15': 'أقل من ١٥ دقيقة',
      'cookingTimeUnder30': 'أقل من ٣٠ دقيقة',
      'cookingTimeUnder60': 'أقل من ساعة',
      'cookingTimeAny': 'أي مدة',
    },
    'legalAndMedicalSources': 'المعلومات القانونية والمصادر الطبية',
    'privacyPolicy': 'سياسة الخصوصية',
    'termsOfUseEula': 'شروط الاستخدام (EULA)',
    'medicalSourcesCitations': 'المصادر المرجعية والأبحاث الطبية',
    'subscriptionAutoRenewTerms':
        'سيتم خصم الرسوم من حساب Apple ID الخاص بك عند تأكيد الشراء. يتجدد الاشتراك تلقائيًا ما لم يتم إلغاؤه قبل 24 ساعة على الأقل من نهاية الفترة الحالية. يتم تحصيل رسوم التجديد خلال 24 ساعة قبل نهاية الفترة الحالية. يمكنك إدارة أو إلغاء الاشتراكات في إعدادات حساب App Store بعد الشراء.',
    'privacyMedicalSourcesTitle': 'المصادر الطبية والأبحاث العلمية',
    'privacyMedicalSourcesSubtitle':
        'الدراسات المحكّمة والإرشادات السريرية المعتمدة لحسابات تطبيق بنياد',
    'privacyMedicalDisclaimerTitle': 'إخلاء مسؤولية طبي هام',
    'privacyMedicalDisclaimerBody':
        'تطبيق بنياد يوفر حسابات التغذية والتندروست لأغراض تعليمية وإرشادية فقط. ولا يُعد بديلًا عن الاستشارة أو التشخيص الطبي السريري. يُنصح دائمًا باستشارة طبيب أو أخصائي تغذية قبل البدء بأي نظام غذائي.',
    'privacyMedicalViewSourceLink': 'عرض رابط البحث العلمي المصدر',
    'privacyMedicalSourcesBmrCategory': 'معادلة السعرات والأيض الأساسي (BMR)',
    'privacyMedicalSourcesBmrDesc':
        'تعتمد معادلة ميفلين-سانت جيور المعتمدة عالمياً لحساب معدل الأيض الأساسي والسعرات الحرارية.',
    'privacyMedicalSourcesBmiCategory': 'مؤشر كتلة الجسم (BMI)',
    'privacyMedicalSourcesBmiDesc':
        'التصنيفات المعيارية الدولية لمنظمة الصحة العالمية لمؤشر كتلة الجسم بناءً على الطول والوزن.',
    'privacyMedicalSourcesBodyFatNavyCategory':
        'نسبة الدهون - طريقة البحرية الأمريكية',
    'privacyMedicalSourcesBodyFatNavyDesc':
        'طريقة قياس المحيطات (الخصر والرقبة الورك) المعتمدة لتقدير نسبة الدهون في الجسم.',
    'privacyMedicalSourcesBodyFatDeurenbergCategory':
        'نسبة الدهون - معادلة ديورنبرغ',
    'privacyMedicalSourcesBodyFatDeurenbergDesc':
        'نموذج التنبؤ بنسبة الدهون في الجسم المعتمد على العمر والجنس ومؤشر كتلة الجسم.',
    'privacyMedicalSourcesMacrosCategory':
        'توزيع المغذيات الكبرى (البروتين والماكروز)',
    'privacyMedicalSourcesMacrosDesc':
        'التوصيات العلمية للجمعية الدولية لتغذية الرياضيين (ISSN) لنسب البروتين والسعرات اليومية.',
    'privacyMedicalSourcesWaterCategory': 'الاحتياج اليومي من الماء',
    'privacyMedicalSourcesWaterDesc':
        'الرأي العلمي للهيئة الأوروبية لسلامة الأغذية (EFSA) لتحديد المعدلات الصحية لشرب الماء.',
    'privacyMedicalSourcesFoodDbCategory': 'قواعد بيانات الأغذية',
    'privacyMedicalSourcesFoodDbDesc':
        'قاعدة بيانات Open Food Facts وقاعدة البيانات الزراعية الأمريكية USDA للقيم الغذائية.',
  };

  // ─── Kurdish Sorani ────────────────────────────────
  static const Map<String, dynamic> _ku = {
    'or': 'یان',
    'notifications': 'ئاگادارکردنەوەکان',
    'ofTotal': 'لە {total}',
    'versus': 'بە بەراورد بە',
    'daysRemaining': '{days} ڕۆژ ماوە',
    'poweredByBnyad': 'بۆ تەندروستیی تۆ',
    'invalidNumber': 'ژمارەیەکی دروستی گەورەتر لە سفر بنووسە.',
    'mealChannel': 'بیرهێنانەوەی ژەمەکان',
    'mealChannelDescription': 'ئاگادارکردنەوەی ڕۆژانە بۆ ژەمەکان',
    'weeklyChannel': 'پوختەی هەفتانە',
    'weeklyChannelDescription': 'پوختەی خۆراکی هەفتانە',
    'supplementChannel': 'بیرهێنانەوەی تەواوکەرەکان',
    'supplementChannelDescription':
        'بیرهێنانەوەی ڕۆژانەی دەرمان و تەواوکەرەکان',
    'notificationTestBody': 'ئاگادارکردنەوەکان کار دەکەن!',
    'androidRenewal':
        'دوای پشتڕاستکردنەوە، پارەکە لە هەژماری Google Play دەبڕدرێت. بەشدارییەکە خۆکارانە نوێ دەبێتەوە، مەگەر پێش بەرواری نوێکردنەوە هەڵیبوەشێنیتەوە. دەتوانیت لە بەشی بەشدارییەکانی Google Play بەڕێوەی ببەیت یان هەڵیبوەشێنیتەوە.',
    'webRenewal':
        'فرۆشگای ئەپ پێش پشتڕاستکردنەوە مەرجی بەشداری و نوێکردنەوە پیشان دەدات.',
    'dashboard': 'داشبۆرد',
    'profile': 'پڕۆفایلی تەندروستی',
    'foodLog': 'تۆماری خۆراک',
    'calories': 'کالۆری',
    'carbs': 'کاربۆهیدرات',
    'protein': 'پرۆتین',
    'fat': 'چەوری',
    'macronutrients': 'ماددە خۆراکییە سەرەکییەکان',
    'water': 'خواردنەوەی ئاو',
    'waterIntake': 'خواردنەوەی ئاو',
    'glasses': 'پەرداخ',
    'weight': 'کێش (کیلۆگرام)',
    'height': 'باڵا (سانتیمەتر)',
    'age': 'تەمەن',
    'gender': 'ڕەگەز',
    'male': 'نێر',
    'female': 'مێ',
    'activityLevel': 'ئاستی چالاکی',
    'sedentary': 'کەمجووڵە',
    'lightlyActive': 'کەمێک چالاک',
    'moderatelyActive': 'چالاکیی مامناوەند',
    'veryActive': 'زۆر چالاک',
    'extraActive': 'یەکجار چالاک',
    'calculate': 'هەژمارکردن',
    'bmr': 'BMR',
    'tdee': 'TDEE',
    'searchFood': 'گەڕان بۆ خۆراک...',
    'addMeal': 'زیادکردنی ژەم',
    'addFood': 'زیادکردنی خواردن',
    'language': 'زمان',
    'english': 'English',
    'arabic': 'العربية',
    'kurdish': 'کوردی (سۆرانی)',
    'onboardingTitle': 'بەخێربێیت بۆ BNYAD',
    'onboardingSubtitle': 'با پلانی خۆراکی تایبەت بە خۆت دابنێین.',
    'disabilities': 'کەمئەندامی جەستەیی',
    'sicknesses': 'نەخۆشییەکان / بارودۆخی پزیشکی',
    'allergies': 'حەساسیەت',
    'next': 'دواتر',
    'back': 'گەڕانەوە',
    'finish': 'دروستکردنی پلان',
    'analyzing': 'خەریکی هەژمارکردنە...',
    'goalSet': 'ئامانجە تایبەتەکەت ئامادەیە!',
    'getStarted': 'دەستپێبکە',
    'settings': 'ڕێکخستنەکان',
    'theme': 'ڕووکار',
    'light': 'ڕووناک',
    'dark': 'تاریک',
    'selectSicknesses': 'نەخۆشییەکان هەڵبژێرە',
    'selectAllergies': 'حەساسیەتەکان هەڵبژێرە',
    'search': 'گەڕان...',
    'selected': 'هەڵبژێردراو',
    'none': 'هیچ',
    'mealPlan': 'پلانی ژەمەکان',
    'generateMealPlan': 'دروستکردنی پلانی ژەمەکان',
    'generatePlan': 'دروستکردنی پلان',
    'mealPlanSubtitle': 'ڕێبەری خۆراکی ڕۆژانە بە ژیری دەستکرد',
    'breakfast': 'ژەمی بەیانی',
    'lunch': 'ژەمی نیوەڕۆ',
    'dinner': 'ژەمی ئێوارە',
    'snacks': 'سووکە ژەمەکان',
    'generating': 'خەریکی دروستکردنی پلانەکەتە...',
    'selectDisabilities': 'کەمئەندامی جەستەیی هەڵبژێرە',
    'ingredients': 'پێکهاتەکان',
    'instructions': 'ڕێنمایییەکان',
    'logAsEaten': 'تۆمارکردن وەک خوراو',
    'eaten': 'خوراوە',
    'goals': 'ئامانجەکان',
    'selectGoal': 'ئامانجەکەت هەڵبژێرە',
    'goalList': {
      'loseWeight': 'دابەزاندنی کێش',
      'gainWeight': 'زیادکردنی کێش',
      'gainMuscle': 'دروستکردنی ماسولکە',
      'stayHealthy': 'مانەوە بە تەندروستی',
      'athletic': 'باشترکردنی توانای وەرزشی',
      'manageCondition': 'کۆنترۆڵکردنی نەخۆشی',
    },
    'healthGuidance': 'ڕێنمایی تەندروستی',
    'healthGuidanceSubtitle': 'ئامۆژگاری تایبەت بۆ بارودۆخی تۆ',
    'amount': 'بڕ',
    'grams': 'گرام',
    'add': 'زیادکردن',
    'total': 'کۆ',
    'searchPlaceholder': 'بگەڕێ بۆ خواردن (بۆ نموونە دۆڵمە، پیتزا...)',
    'browseFoods': 'گەڕان لەناو خواردنەکان',
    'selectFood': 'خواردن هەڵبژێرە',
    'close': 'داخستن',
    'sicknessesList': {
      'diabetes1': 'شەکرەی جۆری ١',
      'diabetes2': 'شەکرەی جۆری ٢',
      'hypertension': 'بەرزیی پەستانی خوێن',
      'celiac': 'نەخۆشی سیلیاک',
      'ibs': 'کۆڵۆنی دەمارگیر',
      'kidney': 'نەخۆشی گورچیلە',
      'heart': 'نەخۆشی دڵ',
      'obesity': 'قەڵەوی',
      'anemia': 'کەمخوێنی',
      'hypo': 'کەمکاریی ڕژێنی دەرەقی',
      'hyper': 'زۆرکاریی ڕژێنی دەرەقی',
      'gout': 'نەقرەس',
      'reflux': 'گەڕانەوەی ترشەڵۆکی گەدە',
    },
    'allergiesList': {
      'peanuts': 'فستقی زەمینی',
      'treeNuts': 'گوێز و بادەم',
      'milk': 'شیر',
      'egg': 'هێلکە',
      'wheat': 'گەنم',
      'soy': 'سۆیا',
      'fish': 'ماسی',
      'shellfish': 'سەدەف',
      'sesame': 'کونجی',
      'gluten': 'گلۆتێن',
      'lactose': 'لاکتۆز',
      'corn': 'گەمەشامی',
      'mustard': 'خەردەل',
    },
    'disabilitiesList': {
      'wheelchair': 'بەکارهێنەری کورسی کەمئەندامی',
      'mobility': 'جووڵەی سنووردار',
      'visual': 'کێشەی بینین',
      'hearing': 'کێشەی بیستن',
      'amputation': 'بڕینەوەی ئەندام',
      'none': 'هیچ',
    },
    'foodScanner': 'سکانەری خواردن',
    'readyToScan': 'ئامادەی بۆ سکان؟',
    'scanSubtitle':
        'کامێراکەت ڕوو بکە لە خواردنەکە یان وێنەیەک دابنێ بۆ زانینی زانیارییە تەندروستییەکان.',
    'startCamera': 'دەستپێکردنی کامێرا',
    'uploadPhoto': 'دانانی وێنە',
    'aiAnalyzed': 'شیکردنەوەی AI',
    'logAsEaten100g': 'تۆمارکردن وەک خوراو (١٠٠گم)',
    'howToUse': 'چۆنییەتی بەکارهێنان',
    'instructionsSteps': [
      'پڕۆفایلەکەت ڕێکبخە بە کێش و باڵا و بارودۆخی تەندروستیت.',
      'سکانەرەکە بەکاربهێنە بۆ ناسینەوەی خواردنەکان و بەها خۆراکییەکانیان.',
      'ژەمەکانت ڕۆژانە تۆمار بکە بۆ تێگەیشتن لە کالۆری و ماکرۆکان.',
      'سەیری داشبۆرد بکە بۆ وەرگرتنی ڕێنمایی تەندروستی تایبەت.',
      'پلانی ژەمەکان دروست بکە بۆ وەرگرتنی ڕێبەری خۆراکی ڕۆژانە.',
    ],
    'aiGuidance': 'ڕێنمایی تەندروستی AI',
    'cameraError':
        'دەستڕاگەیشتن بە کامێرا سەرکەوتوو نەبوو. تکایە دڵنیابەرەوە لە پێدانی مۆڵەت.',
    'analysisError':
        'شیکردنەوەی وێنەکە سەرکەوتوو نەبوو. تکایە دووبارە هەوڵ بدەرەوە.',
    'regenerate': 'دووبارە دروستکردنەوە',
    'noMealPlan': 'هێشتا پلانی ژەمەکان نییە',
    'noMealPlanDesc':
        'با ژیری دەستکرد پلانێکی خۆراکی تایبەتت بۆ دروست بکات بەپێی ئامانج و پڕۆفایلە تەندروستییەکەت.',
    'loggedAsEaten': 'وەک خوراو تۆمارکرا',
    'goalCalculatedDesc':
        'بەپێی کێش، باڵا، تەمەن، چالاکی، ئامانج و ڕاهێنانەکەت.',
    'ml': 'میلیلیتر',
    'kcal': 'کالۆری',
    'logout': 'چوونەدەرەوە',
    'account': 'هەژمار',
    'deleteAccount': 'سڕینەوەی هەژمار',
    'deleteAccountConfirmTitle': 'سڕینەوەی هەمیشەیی هەژمار؟',
    'deleteAccountConfirmDesc':
        'هەموو زانیارییەکانی پرۆفایل، تۆمارەکانی خۆراکی ڕۆژانە، کێش و پلانەکانی ژەمت بە شێوەیەکی هەمیشەیی لە سێرڤەرەکانمان دەسڕێنەوە. ناتوانرێت ئەم کردارە پاشگەز بکرێتەوە.',
    'deleteAccountButton': 'هەژمارەکەم بسڕەوە',
    'deleteAccountSuccess':
        'هەژمارەکەت بە سەرکەوتوویی و بە شێوەیەکی هەمیشەیی سڕایەوە.',
    'deleteAccountFailed':
        'سڕینەوەی هەژمار سەرکەوتوو نەبوو. تکایە پەیوەندیی ئینتەرنێتەکەت بپشکنە و دووبارە هەوڵبدەرەوە.',
    'deletingAccount': 'سڕینەوەی هەژمار...',
    'accountDeletionWeb': 'دەروازەی سڕینەوەی هەژمار (وێب)',
    'login': 'چوونەژوورەوە',
    'signInWithPhone': 'چوونەژوورەوە بە مۆبایل',
    'welcomeTitle': 'دەست بە گەشتە تەندروستەکەت بکە',
    'welcomeSubtitle':
        'چاودێری خۆراکت بکە، ژەمەکانت پلان بکە، و بگە بە ئامانجە تەندروستییەکانت لەگەڵ بنیاد.',
    'signUp': 'دروستکردنی هەژمار',
    'phoneNotRegistered':
        'ئەم ژمارە مۆبایلە تۆمار نەکراوە. تکایە ئەکاونت دروست بکە.',
    'phoneAlreadyRegistered':
        'ئەم ژمارە مۆبایلە پێشتر تۆمار کراوە. تکایە بچۆ ژوورەوە.',
    'signInWithPassword': 'چوونەژوورەوە بە وشەی نهێنی',
    'loginWithOtp': 'چوونەژوورەوە بە کۆدی OTP',
    'phoneNumber': 'ژمارەی مۆبایل',
    'phoneNumberHint': '750 123 4567',
    'sendOtp': 'ناردنی کۆد',
    'enterOtpCode': 'کۆدی پشتڕاستکردنەوە بنووسە',
    'otpCodeHint': 'کۆدی ٦ ژمارەیی',
    'verifyOtp': 'پشتڕاستکردنەوە',
    'resendOtp': 'دووبارە ناردنی کۆد',
    'changePhoneNumber': 'گۆڕینی ژمارە',
    'invalidPhoneNumber': 'ژمارەی مۆبایلێکی دروست بنووسە',
    'invalidOtpCode': 'کۆدی ٦ ژمارەیی بنووسە',
    'otpSentTo': 'کۆد نێردرا بۆ',
    'otpBackendPending':
        'نەتوانرا داوای کۆد بنێردرێت. پەیوەندیی ئینتەرنێتەکەت بپشکنە و دووبارە هەوڵبدەرەوە.',
    'resendOtpIn': 'دووبارە ناردن دوای {seconds} چرکە',
    'demoOtpHint': 'کۆدی تاقیکردنەوە: 123456',
    'yourName': 'ناوت',
    'nameHint': 'وەک: سارا',
    'whatIsYourName': 'ناوت چییە؟',
    'nameSubtitle': 'لە داشبۆرددا پێشوازی لێت دەکەین',
    'continueLabel': 'بەردەوامبوون',
    'invalidName': 'تکایە ناوت بنووسە',
    'welcomeName': 'سڵاو، {name}',
    'yourBmi': 'BMI ـەکەت',
    'maintenanceCalories': 'کالۆری پاراستن (TDEE)',
    'dailyCalorieTarget': 'ئامانجی کالۆری ڕۆژانە',
    'proteinPerKgBody': 'گرام پرۆتین بۆ هەر کیلۆ گرام لە کێش',
    'password': 'وشەی نهێنی',
    'passwordHint': 'لانیکەم 6 پیت',
    'invalidPassword': 'وشەی نهێنی دەبێت لانیکەم 6 پیت بێت',
    'noEntries': 'هێشتا هیچ تۆمارێک نییە',
    'guestMode': 'دۆخی میوان',
    'generateDetails': 'دروستکردنی وردەکاری',
    'goalGenerationError':
        'نەتوانرا ئامانجەکان دروست بکرێن. تکایە دووبارە هەوڵ بدەرەوە.',
    'unknownFood': 'خواردنی نەناسراو',
    'per100g': 'بۆ هەر ١٠٠ گرام',
    'guestUser': 'میوانی بەکارهێنەر',
    'loginRequiredTitle': 'پێویستە بچیتە ژوورەوە',
    'loginRequiredSubtitle':
        'هەژمار دروست بکە یان بچۆ ژوورەوە بۆ ئەم تایبەتمەندییە. زانیارییەکانت لە نێوان ئامێرەکان هاوکات دەبن.',
    'loginRequiredCta': 'چوونەژوورەوە / هەژمار',
    'signInToContinue': 'بچۆ ژوورەوە بۆ بەردەوامبوون',
    'createAccount': 'دروستکردنی هەژمار',
    'registerSubtitle':
        'ناو و وشەی نهێنی دابنێ، پاشان ژمارەی مۆبایل پشتڕاست بکەرەوە.',
    'confirmPassword': 'دووبارەکردنەوەی وشەی نهێنی',
    'confirmPasswordHint': 'وشەی نهێنی دووبارە بنووسە',
    'passwordsDoNotMatch': 'وشەی نهێنی یەکناگرنەوە',
    'continueWithPhone': 'بەردەوامبوون',
    'welcomeBack': 'بەخێربێیتەوە',
    'returningUserOtpHint': 'کۆدی نێردراو بۆ مۆبایلەکەت بنووسە.',
    'guestModeLimited': 'دۆخی میوان — تایبەتمەندی سنووردار',
    'signInFromSettings': 'بچۆ ژوورەوە بۆ کردنەوەی هەموو تایبەتمەندییەکان',
    'appLoading': '...BNYAD خەریکی بارکردنە',
    'splashTagline': 'هاوکاری زیرەکی\nخۆراکی تۆ',
    'splashSubline': 'زیرەکانە بخۆ. تەندروست بژی.',
    'todaysMeals': 'ژەمەکانی ئەمڕۆ',
    'quickLog': 'تۆماری خێرا',
    'quickLogHint':
        'خواردن بە دەست لە تۆماری خواردن زیاد بکە، یان ژەمێک هەڵبژێرە.',
    'logForMealSlot': 'تۆمار بۆ',
    'noMealPlanned': 'هێشتا ژەم پلان نەکراوە',
    'otherFoods': 'خواردنی تر',
    'otherFoodsHint':
        'بەبێ هەڵبژاردنی ژەم (پەنجە بدە بۆ کردنەوەی تۆماری خواردن)',
    'loggedToday': 'تۆمارکراو',
    'viewMealPlan': 'پلانی تەواو ببینە',
    'swapMeal': 'گۆڕینەوەی ژەم',
    'mealReminders': 'بیرهێنەرەوەی ژەمەکان',
    'reminderTime': 'کاتی بیرهێنەرەوە',
    'breakfastReminder': 'بیرهێنەرەوەی بەیانیان',
    'lunchReminder': 'بیرهێنەرەوەی نیوەڕۆیان',
    'dinnerReminder': 'بیرهێنەرەوەی شەوان',
    'snacksReminder': 'بیرهێنەرەوەی سووکە ژەم',
    'timeToEat': 'کاتی خواردنە!',
    'nutrientsAndSupplements': 'خۆراکەکان و تەواوکەرەکان',
    'fromFood': 'لە خواردن',
    'supplements': 'تەواوکەرەکان',
    'vitaminA': 'ڤیتامین A',
    'vitaminC': 'ڤیتامین C',
    'vitaminD': 'ڤیتامین D',
    'vitaminB12': 'ڤیتامین B12',
    'iron': 'ئاسن',
    'calcium': 'کالسیۆم',
    'potassium': 'پۆتاسیۆم',
    'zincMineral': 'زینک',
    'vitaminE': 'ڤیتامین E',
    'vitaminK': 'ڤیتامین K',
    'vitaminB6': 'ڤیتامین B6',
    'folate': 'فۆلات',
    'magnesium': 'مەگنیسیۆم',
    'phosphorus': 'فۆسفۆر',
    'selenium': 'سیلینیۆم',
    'sodium': 'سۆدیۆم',
    'fiber': 'ڕیشاڵ',
    'supplementReminders': 'بیرخستنەوەی تەواوکەر',
    'supplementReminderTitle': 'کاتی حەبەکەت',
    'takeYourSupplement': 'کاتی خواردن',
    'enableReminder': 'بیرخستنەوەی ڕۆژانە',
    'dailyNutrientGoals': 'ئامانجی ڕۆژانەی خۆراک',
    'noSupplementsForReminders':
        'تەواوکەر لە بەشی خۆراکەکان زیاد بکە بۆ دانانی بیرخستنەوە.',
    'vitaminsAndPills': 'ڤیتامین و حەبەکان',
    'addVitamin': 'زیادکردنی ڤیتامین',
    'vitaminName': 'ناوی ڤیتامین',
    'dosage': 'بۆ نم: ١ حەب، ٥٠٠ ملغ',
    'taken': 'خوراوە',
    'noVitamins': 'هێشتا ڤیتامینت نییە',
    'noVitaminsDesc':
        'ڤیتامین و تەواوکەرەکانی ڕۆژانەت زیاد بکە بۆ بەدواداچوونیان.',
    'cookWithIngredients': 'لێنان بە پێکهاتەکانم',
    'enterIngredients': 'پێکهاتەکانت بنووسە',
    'ingredientsHint': 'بۆ نموونە: مریشک، برنج، تەماتە، پیاز...',
    'generateRecipe': 'دروستکردنی ڕێچەتە',
    'aiRecipe': 'ڕێچەتەی AI',
    'piece': 'پارچە',
    'pieces': 'پارچە',
    'bowls': 'قاپ',
    'perPiece': 'بۆ هەر پارچەیەک',
    'perBowl': 'بۆ هەر قاپێک',
    'pieceWeight': 'کێشی پارچەیەک (گرام)',
    'byGrams': 'بە گرام',
    'byPiece': 'بە پارچە',
    'byBowl': 'بە قاپ',
    'bowlWeight': 'کێشی هەر قاپێک (گرام)',
    'scanFridge': 'سکانی سەلاجەکەم',
    'scanFridgeDesc':
        'وێنەیەک لە سەلاجەکەت بگرە و AI ژەمێکت بۆ پێشنیار دەکات بەپێی ئەوەی هەتە.',
    'selectMealType': 'ئەم ژەمە بۆ:',
    'detectedIngredients': 'پێکهاتە دۆزراوەکان',
    'ingredientBreakdown': 'وردەکاری پێکهاتەکان',
    'totalMacros': 'کۆی ماکرۆ',
    'suggestedRecipe': 'ڕێچەتەی پێشنیارکراو',
    'deleteRecipe': 'سڕینەوەی ڕێچەتە',
    'logFoodForNutrients': 'خواردن تۆمار بکە بۆ بینینی خۆراکە ڕۆژانەکانت',
    'errorNetwork':
        'هەڵەی تۆڕ. تکایە پەیوەندییەکەت بپشکنە و دووبارە هەوڵ بدەرەوە.',
    'errorTimeout': 'کاتی داواکارییەکە تەواو بوو. تکایە دووبارە هەوڵ بدەرەوە.',
    'errorGeneric': 'شتێک هەڵە بوو. تکایە دووبارە هەوڵ بدەرەوە.',
    'tryAgain': 'دووبارە هەوڵ بدەرەوە',
    'somethingWentWrong': 'شتێک هەڵە بوو',
    'noInternet': 'پەیوەندییەکی ئینتەرنێت نییە',
    'mealGenerationFailed':
        'دروستکردنی پلانی خواردن سەرنەکەوت. تکایە دووبارە هەوڵ بدەرەوە.',
    'scanFailed':
        'شیکردنەوەی خواردن سەرنەکەوت. تکایە وێنەیەکی ڕوونتر بەکاربهێنە.',
    'loadingFailed': 'بارکردنی داتا سەرنەکەوت. تکایە دووبارە هەوڵ بدەرەوە.',
    'permissionDenied':
        'ڕێگەپێدان ڕەتکرایەوە. تکایە لە ڕێکخستنەکان چالاکی بکەرەوە.',
    'fridgeScanError':
        'شیکردنەوەی ناوەڕۆکی ساردخانە سەرنەکەوت. تکایە دووبارە هەوڵ بدەرەوە.',
    'recipeGenerationFailed':
        'دروستکردنی ڕێچەتە سەرنەکەوت. تکایە دووبارە هەوڵ بدەرەوە.',
    'goalGenerationFailed':
        'دروستکردنی ئامانجەکان سەرنەکەوت. تکایە دووبارە هەوڵ بدەرەوە.',
    'swapFailed': 'گۆڕینەوەی خواردن سەرنەکەوت. تکایە دووبارە هەوڵ بدەرەوە.',
    'detailsFailed':
        'دروستکردنی وردەکاری خواردن سەرنەکەوت. تکایە دووبارە هەوڵ بدەرەوە.',
    'dailyTotal': 'کۆی ڕۆژانە',
    'ofGoal': 'لە ئامانج',
    'weeklySummary': 'پوختەی هەفتانە',
    'weeklySummarySubtitle': 'پێشکەوتنت لە ٧ ڕۆژی ڕابردوو',
    'weeklyStreak': 'زنجیرەی تۆمارکردن',
    'weeklyDaysLogged': 'ڕۆژە تۆمارکراوەکان',
    'weeklyGoalDays': 'لە ئامانجدا',
    'weeklyWeightChange': 'گۆڕانی کێش',
    'weeklyWeightLost': 'کەمبوونەوە لەم هەفتەیە',
    'weeklyWeightGained': 'زیادبوون لەم هەفتەیە',
    'weeklyWeightStable': 'گۆڕان نییە لەم هەفتەیە',
    'weeklyLogWeightHint': 'کێشەکەت نوێ بکەرەوە بۆ بینینی kg کەم/زیاد.',
    'weeklyAvgCalories': 'ناوەندی کالۆری (ڕۆژە تۆمارکراوەکان)',
    'weeklyCalorieChart': 'کالۆری ڕۆژانە بەرامبەر ئامانج',
    'weeklyDailyBreakdown': 'ڕۆژ بە ڕۆژ',
    'weeklyUpdateWeight': 'نوێکردنەوەی کێشی ئەمڕۆ',
    'weeklyDayStreak': 'ڕۆژ زنجیرە',
    'weeklyOnTarget': 'لە ئامانجدا',
    'weeklyDaysLoggedHint': 'لە ٧ ڕۆژ',
    'weeklyStreakStart': 'ژەم تۆمار بکە بۆ دەستپێکردنی زنجیرە',
    'cancel': 'هەڵوەشاندنەوە',
    'save': 'پاشەکەوت',
    'editMacros': 'دەستکاری ماکڕۆ',
    'editMacrosDesc':
        'ئامانجی ڕۆژانەی کالۆری، پرۆتین، کاربۆهیدرات و چەوری بە دەستی دیاری بکە.',
    'macrosUpdated': 'ئامانجی ماکڕۆ نوێکرایەوە',
    'resetToAi': 'گەڕانەوە بۆ بەهای AI',
    'remove': 'لابردن',
    'removeLoggedTitle': 'ئایتم لاببرێت؟',
    'removeLoggedBody': '"{name}" لە تۆماری ئەمڕۆ لاببرێت؟',
    'itemRemoved': 'ئایتم لابرا',
    'bodyFatShortcut': 'ڕێژەی چەوری (AI)',
    'bodyFatScreenTitle': 'خەمڵاندنی ڕێژەی چەوری',
    'bodyFatScreenIntro':
        'بۆ وردتر، یەکەم پێوانەی نەرم بەکاربهێنە (کەمەر + مل). وێنە دەتوانێت ئەنجامەکە کەمێک ڕێک بخات، بەڵام هەرگیز وردتر نییە لە پێوانە.',
    'bodyFatStaticDisclaimer':
        'ئەم تایبەتمەندییە تەنها بۆ زانیاری گشتییە؛ نە دەستنیشانکردنی نەخۆشییە و نە ئامێری پزیشکی. بۆ ڕێنمایی تایبەت بە خۆت، ڕاوێژ بە پزیشک بکە.',
    'bodyFatAnalyzing': 'وێنە شیکار دەکرێت…',
    'bodyFatEstimatedRange': 'مەودای خەمڵێنراو',
    'bodyFatConfidenceLabel': 'متمانە',
    'bodyFatConfidenceLow': 'کەم (تەنها وێنە)',
    'bodyFatConfidenceMedium': 'مامناوەند (فۆرمولی BMI یان تێکەڵ)',
    'bodyFatConfidenceHigh': 'بەرز (پێوانەی نوار)',
    'bodyFatMeasureTitle': 'هەنگاوی ١ — پێوانە بە نوار (پێشنیار)',
    'bodyFatMeasureHint':
        'بەیانیان پێوانە بکە، سک بە ئاسودەیی. کەمەر: تەنگترین شوێن سەرەوە یان لە ناوەڕاستی سک. مل: خوارەوە لە قورگ. ژنان: کولە لە پانترین شوێن.',
    'bodyFatMeasureRequired':
        'کەمەر و مل (و کولە بۆ ژنان) بە سانتیمەتر بنووسە.',
    'bodyFatWaistCm': 'کەمەر',
    'bodyFatNeckCm': 'مل',
    'bodyFatHipCm': 'کولە (ژنان)',
    'bodyFatCalculateMeasurements': 'ژماردن لە پێوانەکان',
    'bodyFatPhotoOptional': 'هەنگاوی ٢ — وێنە (هەڵبژاردە)',
    'bodyFatPhotoHint':
        'وێنەی پێشەوە یان لا، جلوبەرگی داور، ڕووناکی باش. تەنها بۆ کەمێک ڕێکخستنی خەمڵاندنی پێوانە.',
    'bodyFatMethodLabel': 'شێواز',
    'bodyFatMethodNavy': 'فۆرمولی نواری US Navy',
    'bodyFatMethodDeurenberg': 'فۆرمولی BMI + تەمەن',
    'bodyFatMethodBlended': 'پێوانە + وێنە',
    'bodyFatMethodPhoto': 'خەمڵاندن لە وێنە',
    'bodyFatProfileContext': 'پرۆفایلەکەت',
    'bodyFatAiNotes': 'تێبینی',
    'bodyFatAiDisclaimer': 'ئاگاداری AI',
    'bodyFatRetakePhoto': 'وێنەی نوێ',
    'bodyFatFailed':
        'نەتوانرا خەمڵێنرێت. وێنەیەکی تر تاقی بکەرەوە یان پەیوەندی بپشکنە.',
    'weeklyDigestTitle': 'پوختەی هەفتانە',
    'weeklyDigestBody': 'BNYAD بکەرەوە بۆ بینینی هەفتەکەت.',
    'weeklyDigestNotify': 'بیرهێنەرەوەی پوختەی هەفتانە (یەکشەممە)',
    'shoppingList': 'لیستی کڕین',
    'shoppingListEmpty': 'لیستەکە بەتاڵە',
    'addItem': 'زیادکردنی بابەت',
    'itemName': 'ناوی بابەت',
    'clearDone': 'سڕینەوەی تیکدراوەکان',
    'favorites': 'دڵخوازەکان',
    'noFavorites':
        'هێشتا دڵخواز نییە — خواردن یان ژەم پاشەکەوت بکە بۆ تۆمارکردنی خێرا.',
    'saveAsFavorite': 'پاشەکەوت وەک دڵخواز',
    'savedFavorite': 'پاشەکەوت کرا بۆ دڵخوازەکان',
    'useTemplate': 'تۆمار لە دڵخوازەکان',
    'addPlanIngredients': 'پێکهاتەکان زیاد بکە بۆ لیستی کڕین',
    'saveMealTemplate': 'ژەم پاشەکەوت بکە وەک قاڵب',
    'offlineBanner':
        'دەرهێڵ — تۆماری خواردن و پلانە پاشەکەوتکراوەکان کاردەکەن.',
    'testNotification': 'تاقیکردنەوەی ئاگادارکردنەوە',
    'notificationsWebInfo':
        'بیرهێنەرەوەی ژەم و ئاگادارکردنەوەی کاتی دیاریکراو لە ئەپی مۆبایلی BNYAD کاردەکەن. وەشانی وێب ناتوانێت ئاگادارکردنەوەی سیستەم پیشان بدات.',
    'notificationsWebHint':
        'ئەپی ئەندرۆید یان iOS بەکاربهێنە بۆ دانانی کات بۆ بەیانیان و نیوەڕۆ و شەو و سووکە ژەم و پوختەی هەفتانە.',
    'shoppingListUpdated': 'پێکهاتەکان زیادکران بۆ لیستی کڕین',
    'insightsLists': 'تێڕوانین و لیستەکان',
    'mealCuisineStyle': 'جۆری خواردن',
    'cuisineKurdish': 'کوردی',
    'cuisineArabic': 'عەرەبی / ڕۆژهەڵات',
    'cuisineAll': 'هەموو / تێکەڵ',
    'aiShoppingListButton': 'چ بکڕم؟ (AI)',
    'aiShoppingListTitle': 'لیستی کڕینی پێشنیارکراو',
    'aiShoppingLoading': 'خەریکی ئامادەکردنی لیستی کڕین…',
    'aiShoppingFailed': 'نەتوانرا لیست دروست بکرێت. دووبارە هەوڵ بدەرەوە.',
    'addSuggestedToList': 'هەموو زیاد بکە بۆ لیستی کڕین',
    'needMealPlanForAiShopping':
        'سەرەتا پلانی ژەمەکان دروست بکە، پاشان دووبارە بیکەرەوە.',
    'aiShoppingDetailsHint':
        'ئامۆژگاری: «دروستکردنی وردەکاری» بۆ هەر ژەمێک بگرە بۆ لیستێکی وردتر.',
    'aiShoppingAllMealsLogged':
        'هەموو ژەمەکانی پلانی ئەمڕۆت وەک خواردوو تۆمار کردووە — هیچ شتێکی ماوە نییە بۆ کڕین بۆ ئەو خواردنانە.',
    'generateAllDetailsButton': 'دروستکردنی وردەکاری هەموو ژەمەکان',
    'generateAllDetailsBusy': 'خەریکی دروستکردنی وردەکاری…',
    'generateAllDetailsHint':
        'ئەو ژەمانە تێپەڕێنرێت کە پێشتر پێکهاتە و هەنگاو هەیە. بۆ نوێکردنەوەی یەک ژەم دوگمەی هەمان کارت بەکاربهێنە.',
    'allMealsAlreadyDetailed':
        'هەموو ژەمەکان پێشتر پێکهاتە و هەنگاوەکانیان هەیە.',
    'allDetailsGeneratedSuccess': 'پێکهاتە و هەنگاوەکان زیادکران بۆ {n} ژەم.',
    'allDetailsPartialSuccess':
        '{n} ژەم نوێکرایەوە. سەیری ئەو کارتیانە بکە کە هەڵەیان هەیە.',
    'allDetailsAllFailed':
        'نەتوانرا وردەکاری دروست بکرێت. دووبارە هەوڵ بدەرەوە یان دوگمەی هەر ژەمێک بەکاربهێنە.',
    'shoppingDuplicate': 'پێشتر لە لیستەکەتدایە — دووبارەکە تێپەڕێنرا.',
    'shoppingItemAdded': 'زیادکرا بۆ لیستەکەت.',
    'shoppingBulkAllDupes': 'شتێکی نوێ نییە — هەموو بابەتەکان پێشتر بوون.',
    'shoppingBulkAddedOnly': '{n} بابەتی نوێ زیادکرا بۆ لیستەکەت.',
    'shoppingBulkMixed':
        '{a} بابەتی نوێ زیادکرا. {s} دووبارە تێپەڕێنرا چونکە پێشتر بوون.',
    'categoryList': {
      'Kurdish': 'خواردنی کوردی',
      'Bread': 'نان و نانەوێڵە',
      'RiceDishes': 'خواردنەکانی برنج',
      'Soup': 'شۆربا و خورش',
      'Arabic': 'عەرەبی / ڕۆژهەڵاتی ناوەڕاست',
      'Protein': 'پرۆتین',
      'Dairy': 'بەرهەمی شیر',
      'Grains': 'دانەوێڵە و کاربۆهایدرات',
      'Fruit': 'میوەکان',
      'Vegetable': 'سەوزەکان',
      'Nuts': 'گوێز و تۆو',
      'Legumes': 'بەقوولات',
      'International': 'خواردنی نێودەوڵەتی',
      'FastFood': 'خواردنی خێرا',
      'Supplement': 'تەواوکەرەکان',
      'Beverage': 'خواردنەوەکان',
      'Snacks': 'سووکە ژەم و شیرینی',
      'Oil': 'ڕۆن و چەوری',
    },
    'premium': 'پرێمیەم',
    'premiumBadge': 'پرێمیەم',
    'premiumLocked': 'تایبەتمەندی پرێمیەم',
    'premiumUnlockCta': 'پرێمیەم بکەرەوە',
    'premiumActive': 'پرێمیەم چالاکە',
    'premiumActiveUntil': 'چالاکە تا {date}',
    'premiumTitle': 'پرێمیەم وەربگرە',
    'premiumSubtitle': 'هەموو توانای زیرەکی دەستکردی BNYAD بکەرەوە.',
    'premiumPerkMealPlan': 'پلانی ڕۆژانەی خۆراک بە زیرەکیی دەستکرد',
    'premiumPerkScanner': 'سکانەری خۆراک و سەلاجە بە زیرەکی دەستکرد',
    'premiumPerkAiTips': 'ڕێنمایی تەندروستی تایبەتکراو',
    'premiumPerkNutrients': 'شوێنپێیی پێکهاتە و سوپلیمێنت',
    'premiumPerkSwapMeals': 'گۆڕینەوەی ژەم و لیستی کڕینی زیرەک',
    'premiumPerkRecipes': 'ڕێسپی تایبەت لە پێکهاتەکانت',
    'premiumActivate': 'پرێمیەم دەستپێبکە',
    'premiumDeactivate': 'هەڵبوەشێنە',
    'premiumRestore': 'گەڕانەوەی کڕین',
    'premiumComingSoon':
        'پارەدان بە ڕاستی بەم زووانە. بۆ تاقیکردنەوە چالاک بکە.',
    'premiumManage': 'بەڕێوەبردنی بەشداری',
    'premiumFooterNote':
        'پێوەری چەوریی لەش و ژمێرکاری ماکرۆ بەخۆڕایی دەمێننەوە.',
    'optionalField': 'هەڵبژاردەیی',
    'onboardStepOf': 'هەنگاو {c} لە {t}',
    'onboardActivityStepTitle': 'چالاکی ڕۆژانە',
    'onboardActivityStepSubtitle':
        'لە هەفتەیەکی ئاسایی چەند چالاکیت؟ ئەمە بنەمای کالۆری دادەنێت.',
    'onboardHealthStepTitle': 'تەندروستی و حەساسیەت',
    'onboardHealthStepSubtitle':
        'یارمەتی دەدات ژەم و ئامانجی مایکرۆ بە سەلامەتی تایبەت بکرێت.',
    'onboardHealthOptionalNote':
        'هەڵبژاردەیی — تێپەڕێ ئەگەر هیچ نییە. دواتر لە ڕێکخستن دەتوانیت بگۆڕیت.',
    'onboardGoalStepSubtitle':
        'ئامانجی سەرەکی هەڵبژێرە. کالۆری بە کەمبوون یان زیادبوونی سەلامەت ڕێکدەخرێت.',
    'activityHintSedentary': 'کەم یان بێ وەرزش (کارێکی مێز)',
    'activityHintLightlyActive': 'وەرزش ١–٣ جار لە هەفتە',
    'activityHintModeratelyActive': 'وەرزش ٤–٥ جار لە هەفتە',
    'activityHintVeryActive': 'وەرزشی ڕۆژانە یان قورس ٣–٤ جار/هەفتە',
    'activityHintExtraActive': 'وەرزشی زۆر قورس ڕۆژانە، یان کارێکی جەستەیی',
    'onboardTargetsTitle': 'ئامانجەکانت',
    'onboardTargetsSubtitle':
        'یارمەتی AI دەدات ڕێگەی کالۆری و ماکرۆکانت دیاری بکات.',
    'targetWeight': 'کێشی ئامانج (کگ)',
    'pace': 'خێرایی',
    'bodyFatPct': 'ڕێژەی چەوری % (هەڵبژاردەیی)',
    'pregnancyStatus': 'دووگیانی / شیردان',
    'onboardDietTitle': 'هەڵبژاردنی خۆراک',
    'onboardDietSubtitle': 'خۆراک کە دەتەوێت پێشخستی ببێت یان دوور بکرێتەوە.',
    'dietaryPattern': 'شێوازی خۆراکخواردن',
    'dislikedFoods': 'خۆراکی دوورکراوە لە تامەکانت',
    'cuisinePreference': 'چێشتی دڵخواز',
    'onboardLifestyleTitle': 'شێوازی ژیان',
    'onboardLifestyleSubtitle': 'کاتی ژەم و خەو و فشار و ئاوخواردنەوە.',
    'mealsPerDay': 'ژەم لە ڕۆژدا',
    'fastingWindow': 'ڕۆژووی بەردەوامی',
    'sleepHours': 'تێکڕای خەو (کاژێر)',
    'stressLevel': 'ئاستی فشار',
    'waterTargetMl': 'ئامانجی ئاو (ملل)',
    'waterTargetAiNote':
        'ئامانجی ئاوی ڕۆژانەت بە AI لە زانیاری جەستە، چالاکی، ڕاهێنان و تەندروستیت دەهێنرێتەوە کاتێک ڕێکخستن تەواو دەکەیت.',
    'dailyWaterGoal': 'ئاوی ڕۆژانە',
    'scanBarcode': 'بارکۆد بخوێنەوە',
    'barcodeScanHint': 'کامێراکە بەرەو بارکۆدی بەرهەمەکە بگرە',
    'barcodeLookingUp': 'زانیاری خۆراک دەهێنرێت…',
    'barcodeNotFound':
        'بەرهەم نەدۆزرایەوە. بارکۆدێکی تر تاقی بکە یان دەستی بگەڕێ.',
    'barcodeLogQuestion': 'ئەم خواردنە بۆ تۆمارەی ئەمڕۆ زیاد بکرێت؟',
    'barcodeLogYes': 'بەڵێ، تۆمار بکە',
    'barcodeLogNo': 'ئێستا نا',
    'barcodeLogged': 'خواردنەکە بۆ تۆمارەی ئەمڕۆ زیاد کرا',
    'barcodeAmountLabel': 'چەندت خوارد؟',
    'barcodeNotOnWeb':
        'بۆ خوێندنەوەی بارکۆد، ئەپی BNYAD لە iPhone یان Android بەکاربهێنە.',
    'barcodeCameraDenied':
        'پێویستە مۆڵەتی کامێرا بدەیت بۆ خوێندنەوەی بارکۆد. دووبارە هەوڵ بدەرەوە.',
    'barcodeCameraSettings':
        'مۆڵەتی کامێرا ڕەتکراوە. بچۆ ڕێکخستنەکان → BNYAD → مۆڵەتەکان و کامێرا چالاک بکە.',
    'barcodeNetworkError':
        'پەیوەندی بە بنکەی خواردنەوە نەکرا. ئینتەرنێت بپشکنە و دووبارە هەوڵ بدەرەوە.',
    'barcodeInvalid': 'ژمارەی بارکۆد دروست نییە. ٨–١٤ ژمارە بنووسە.',
    'barcodeManualEntry': 'یان ژمارەی بارکۆد بنووسە',
    'barcodeManualHint': 'ژمارەی EAN / UPC',
    'barcodeLookupButton': 'گەڕان',
    'barcodeNotFoundTitle': 'بەرهەم لە بنکەی جیهانیدا نییە',
    'barcodeNotFoundBody':
        'زۆر بەرهەمی ناوخۆیی عێراق و کوردستان لە ئینتەرنێتدا تۆمار نەکراون. یەک جار خواردنەکان بنووسە، جار داهاتوو بارکۆدەکە خۆکار کار دەکات.',
    'barcodeAddManually': 'زانیاری لەسەر لیبل بنووسە',
    'barcodePickFromApp': 'خواردنێکی نزیک لە BNYAD هەڵبژێرە',
    'barcodeProductName': 'ناوی بەرهەم',
    'barcodeSaveAndContinue': 'پاشەکەوت و بەردەوامبوون',
    'barcodeSavedForNextTime':
        'پاشەکەوت کرا. جار داهاتوو ئەم بارکۆدە کار دەکات.',
    'choosePreparation': 'چۆن ئامادە کراوە؟',
    'choosePreparationHint': 'دەست لێبدە بۆ جۆر (برژاو، کوڵاو، بە ڕۆن…)',
    'chooseOilStep': 'بە ڕۆن یان بێ ڕۆن؟',
    'bonePortionLabel': 'ئێسک لە بەشەکەتدا هەیە؟',
    'bonelessPortion': 'بێ ئێسک (تەنها گۆشتی خواردن)',
    'withBonesPortion': 'بە ئێسک',
    'bonePortionHint':
        'ئەگەر بە ئێسکەوە کێشت، تەنها گۆشتی خواردن دەژمێردرێت بۆ ئەوەی کالۆریەکان زیادە نەبن.',
    'medicationsLabel': 'دەرمانەکان (هەڵبژاردەیی)',
    'medicationsHint': 'بە کۆما جیا بکەرەوە، نموونە: Metformin، Lisinopril',
    'onboardTrainingTitle': 'وەرزش و چێشتلێنان',
    'onboardTrainingSubtitle': 'قەبارەی وەرزش و کاتی چێشتلێنان.',
    'workoutDaysPerWeek': 'ڕۆژانی وەرزش لە هەفتە',
    'workoutType': 'جۆری وەرزش',
    'cookingSkill': 'لێهاتوویی چێشتلێنان',
    'cookingTime': 'کات بۆ هەر ژەمێک',
    'paceList': {
      'relaxed': 'هێمن (گۆڕانێکی نەرم)',
      'moderate': 'مامناوەند (پێشنیار کراو)',
      'aggressive': 'بەرز (خێراتر، سەختتر)',
    },
    'pregnancyStatusList': {
      'none': 'هیچ',
      'pregnant': 'دووگیانی',
      'breastfeeding': 'شیردان',
      'planning': 'پلانی دووگیانی',
    },
    'dietaryPatternList': {
      'omnivore': 'هەموو شت',
      'vegetarian': 'سەوزەخۆر',
      'vegan': 'ڤێگان',
      'pescatarian': 'ماسی + سەوزە',
      'keto': 'کیتۆ',
      'lowCarb': 'کاربۆهایدراتی کەم',
      'mediterranean': 'دەریای ناوەڕاست',
      'halal': 'حەڵاڵ',
      'kosher': 'کۆشێر',
    },
    'dislikedFoodsList': {
      'pork': 'گۆشتی بەراز',
      'beef': 'گۆشتی گا',
      'redMeat': 'گۆشتی سوور',
      'lamb': 'گۆشتی بەرخ',
      'chicken': 'مریشک',
      'fishDislike': 'ماسی',
      'shellfishDislike': 'ماسی توێکڵدار',
      'dairyDislike': 'بەرهەمی شیر',
      'eggsDislike': 'هێلکە',
      'mushrooms': 'قارچک',
      'olives': 'زەیتوون',
      'onions': 'پیاز',
      'spicy': 'تەند',
      'cilantro': 'گژنیج',
      'sweets': 'شیرینی',
      'processed': 'خۆراکی پرۆسێسکراو',
      'fried': 'برژاو',
    },
    'cuisinePreferenceList': {
      'mixed': 'تێکەڵ / نێودەوڵەتی',
      'kurdish': 'کوردی',
      'arabic': 'عەرەبی / ڕۆژهەڵاتی ناوەڕاست',
      'mediterranean': 'دەریای ناوەڕاست',
      'asian': 'ئاسیایی',
      'western': 'ڕۆژاوایی',
    },
    'mealsPerDayList': {
      'two': '٢ ژەم',
      'three': '٣ ژەم',
      'four': '٤ ژەم',
      'five': '٥ ژەم',
    },
    'fastingWindowList': {
      'fastingNone': 'بێ ڕۆژوو',
      'fasting12': 'ڕۆژووی ١٢ کاژێر',
      'fasting14': 'ڕۆژووی ١٤ کاژێر',
      'fasting16': '٨:١٦',
      'fasting18': '٦:١٨',
      'fasting20': '٤:٢٠',
    },
    'stressLevelList': {
      'stressLow': 'نزم',
      'stressMedium': 'مامناوەند',
      'stressHigh': 'بەرز',
    },
    'workoutTypeList': {
      'workoutNone': 'هیچ',
      'workoutCardio': 'کاردیۆ',
      'workoutStrength': 'هێز',
      'workoutBoth': 'کاردیۆ + هێز',
      'workoutSport': 'وەرزشی تایبەت',
    },
    'cookingSkillList': {
      'cookingBeginner': 'دەستپێکەر',
      'cookingIntermediate': 'مامناوەند',
      'cookingAdvanced': 'پێشکەوتوو',
    },
    'cookingTimeList': {
      'cookingTimeUnder15': 'کەمتر لە ١٥ خولەک',
      'cookingTimeUnder30': 'کەمتر لە ٣٠ خولەک',
      'cookingTimeUnder60': 'کەمتر لە کاژێرێک',
      'cookingTimeAny': 'هەر کاتێک',
    },
    'legalAndMedicalSources': 'سەرچاوە یاسایی و پزیشکییەکان',
    'privacyPolicy': 'سیاسەتی تایبەتمەندی',
    'termsOfUseEula': 'مەرجەکانی بەکارهێنان (EULA)',
    'medicalSourcesCitations': 'سەرچاوە پزیشکی و توێژینەوەکان',
    'subscriptionAutoRenewTerms':
        'پارەدان لە هەژماری Apple ID ەکەت وەردەگیرێت لە کاتی پشتڕاستکردنەوەی کڕیندا. بەشداریکردنەکە بە شێوەیەکی خۆکارانە نوێ دەبێتەوە مەگەر لانی کەم ٢٤ کاژێر پێش کۆتایی هاتنی ماوەی ئێستا هەڵبوەشێنرێتەوە. کرێی نوێکردنەوە لە ماوەی ٢٤ کاژێر پێش کۆتایی هاتنی ماوەی ئێستا وەردەگیرێت. دەتوانیت بەشداریکردنەکانت بەڕێوەببەیت یان هەڵیانبوەشێنیتەوە لە ڕێکخستنەکانی App Store.',
    'privacyMedicalSourcesTitle': 'سەرچاوە پزیشکی و زانستییەکان',
    'privacyMedicalSourcesSubtitle':
        'توێژینەوە زانستییە باوەڕپێکراوەکان بۆ ژمێرکارییەکانی ئەپڵیکەیشنی بنیاد',
    'privacyMedicalDisclaimerTitle': 'ئاگاداری پزیشکی گرنگ',
    'privacyMedicalDisclaimerBody':
        'ئەپڵیکەیشنی بنیاد ژمێرکارییەکانی خۆراک و تەندروستی تەنها بۆ مەبەستی زانیاری و ڕێنمایی دابین دەکات. شوێنی ڕاوێژی پزیشکی یان دەستنیشانکردنی نەخۆشی ناگرێتەوە. هەمیشە ڕاوێژ بە پزیشک یان شارەزای خۆراک بکە.',
    'privacyMedicalViewSourceLink': 'بینینی بەستەری توێژینەوەی سەرچاوە',
    'privacyMedicalSourcesBmrCategory': 'هاوکێشەی کالۆری و BMR',
    'privacyMedicalSourcesBmrDesc':
        'هاوکێشەی میفلین-سەنت جیۆر بۆ ژماردنی ڕێژەی سووتاندنی کالۆری بنەڕەتی جەستە.',
    'privacyMedicalSourcesBmiCategory': 'نیشاندەری بارستەی جەستە (BMI)',
    'privacyMedicalSourcesBmiDesc':
        'پێوەرە جیهانییەکانی ڕێکخراوی تەندروستی جیهانی (WHO) بۆ کێش و بەژن.',
    'privacyMedicalSourcesBodyFatNavyCategory':
        'ڕێژەی بەز - ڕێگەی هێزی دەریایی ئەمریکی',
    'privacyMedicalSourcesBodyFatNavyDesc':
        'ڕێگەی پێوانی کەمەر و مل بۆ دیاریکردنی ڕێژەی بەزی جەستە.',
    'privacyMedicalSourcesBodyFatDeurenbergCategory':
        'ڕێژەی بەز - هاوکێشەی دیورنبێرگ',
    'privacyMedicalSourcesBodyFatDeurenbergDesc':
        'هاوکێشەی دیاریکردنی بەزی جەستە بەپێی تەمەن و ڕەگەز و BMI.',
    'privacyMedicalSourcesMacrosCategory': 'دابەشکردنی پرۆتین و ماکرۆس',
    'privacyMedicalSourcesMacrosDesc':
        'ڕێنماییە دەستنیشانکراوەکانی کۆمەڵەی جیهانی تغذیەی وەرزشی (ISSN) بۆ ڕێژەی پرۆتینی ڕۆژانە.',
    'privacyMedicalSourcesWaterCategory': 'پێویستی ڕۆژانەی ئاو',
    'privacyMedicalSourcesWaterDesc':
        'ڕێنماییە زانستییەکانی دەستەی سەلامەتی خۆراکی ئەوروپا (EFSA) بۆ خواردنەوەی ئاو.',
    'privacyMedicalSourcesFoodDbCategory': 'داتابەیزی خۆراک',
    'privacyMedicalSourcesFoodDbDesc':
        'داتابەیزی جیهانی Open Food Facts و داتابەیزی کشتوکاڵی ئەمریکا USDA.',
  };
}
