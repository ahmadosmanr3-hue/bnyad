/// Core onboarding profile.
///
/// New extended fields (target weight, dietary pattern, fasting window, etc.)
/// are nullable / have safe defaults so existing Firestore docs from before
/// the expanded onboarding keep deserializing cleanly.
class UserProfile {
  final String uid;

  // ── Core body / activity ─────────────────────────────
  final double weight;
  final double height;
  final int age;
  final String gender;
  final String activityLevel;
  final String goal;
  final List<String> sicknesses;
  final List<String> allergies;
  final List<String> disabilities;

  // ── Macro targets (computed) ─────────────────────────
  final int dailyCalories;
  final int dailyCarbs;
  final int dailyProtein;
  final int dailyFat;

  // ── App preferences ──────────────────────────────────
  final String language;
  final String theme;
  final bool onboarded;
  final String displayName;

  // ── Targets & body composition ───────────────────────
  final double? targetWeight;
  final String pace; // relaxed | moderate | aggressive
  final double? bodyFatPct;
  final String pregnancyStatus; // none | pregnant | breastfeeding | planning

  // ── Diet preferences ─────────────────────────────────
  final String dietaryPattern; // omnivore | vegetarian | vegan | pescatarian | keto | lowCarb | mediterranean | halal | kosher
  final List<String> dislikedFoods;
  final String cuisinePreference; // mixed | kurdish | arabic | mediterranean | asian | western

  // ── Lifestyle ────────────────────────────────────────
  final int mealsPerDay;
  final String fastingWindow; // none | 12h | 14h | 16h | 18h | 20h
  final double? sleepHours;
  final String stressLevel; // low | medium | high
  final int? waterTargetMl;
  final String medications; // free text

  // ── Training & cooking ───────────────────────────────
  final int workoutDaysPerWeek;
  final String workoutType; // none | cardio | strength | both | sport
  final String cookingSkill; // beginner | intermediate | advanced
  final String cookingTime; // under15 | under30 | under60 | any

  /// Personalized daily micronutrient targets (key → amount in [microUnits]).
  final Map<String, double> dailyMicroGoals;

  UserProfile({
    required this.uid,
    required this.weight,
    required this.height,
    required this.age,
    required this.gender,
    required this.activityLevel,
    required this.goal,
    required this.sicknesses,
    required this.allergies,
    required this.disabilities,
    required this.dailyCalories,
    required this.dailyCarbs,
    required this.dailyProtein,
    required this.dailyFat,
    required this.language,
    required this.theme,
    required this.onboarded,
    this.displayName = '',
    this.targetWeight,
    this.pace = 'moderate',
    this.bodyFatPct,
    this.pregnancyStatus = 'none',
    this.dietaryPattern = 'omnivore',
    this.dislikedFoods = const [],
    this.cuisinePreference = 'mixed',
    this.mealsPerDay = 3,
    this.fastingWindow = 'none',
    this.sleepHours,
    this.stressLevel = 'medium',
    this.waterTargetMl,
    this.medications = '',
    this.workoutDaysPerWeek = 0,
    this.workoutType = 'none',
    this.cookingSkill = 'intermediate',
    this.cookingTime = 'under30',
    this.dailyMicroGoals = const {},
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      weight: (map['weight'] as num?)?.toDouble() ?? 70,
      height: (map['height'] as num?)?.toDouble() ?? 175,
      age: (map['age'] as num?)?.toInt() ?? 25,
      gender: map['gender'] ?? 'male',
      activityLevel: map['activityLevel'] ?? 'moderatelyActive',
      goal: map['goal'] ?? 'stayHealthy',
      sicknesses: List<String>.from(map['sicknesses'] ?? []),
      allergies: List<String>.from(map['allergies'] ?? []),
      disabilities: List<String>.from(map['disabilities'] ?? []),
      dailyCalories: (map['dailyCalories'] as num?)?.toInt() ?? 2200,
      dailyCarbs: (map['dailyCarbs'] as num?)?.toInt() ?? 250,
      dailyProtein: (map['dailyProtein'] as num?)?.toInt() ?? 120,
      dailyFat: (map['dailyFat'] as num?)?.toInt() ?? 70,
      language: map['language'] ?? 'en',
      theme: map['theme'] ?? 'light',
      onboarded: map['onboarded'] ?? false,
      displayName: map['displayName']?.toString() ?? '',
      targetWeight: (map['targetWeight'] as num?)?.toDouble(),
      pace: map['pace'] ?? 'moderate',
      bodyFatPct: (map['bodyFatPct'] as num?)?.toDouble(),
      pregnancyStatus: map['pregnancyStatus'] ?? 'none',
      dietaryPattern: map['dietaryPattern'] ?? 'omnivore',
      dislikedFoods: List<String>.from(map['dislikedFoods'] ?? []),
      cuisinePreference: map['cuisinePreference'] ?? 'mixed',
      mealsPerDay: (map['mealsPerDay'] as num?)?.toInt() ?? 3,
      fastingWindow: map['fastingWindow'] ?? 'none',
      sleepHours: (map['sleepHours'] as num?)?.toDouble(),
      stressLevel: map['stressLevel'] ?? 'medium',
      waterTargetMl: (map['waterTargetMl'] as num?)?.toInt(),
      medications: map['medications'] ?? '',
      workoutDaysPerWeek: (map['workoutDaysPerWeek'] as num?)?.toInt() ?? 0,
      workoutType: map['workoutType'] ?? 'none',
      cookingSkill: map['cookingSkill'] ?? 'intermediate',
      cookingTime: map['cookingTime'] ?? 'under30',
      dailyMicroGoals: _microGoalsFromMap(map['dailyMicroGoals']),
    );
  }

  static Map<String, double> _microGoalsFromMap(dynamic raw) {
    if (raw is! Map) return {};
    final out = <String, double>{};
    for (final e in raw.entries) {
      final v = e.value;
      if (v is num && v.toDouble() >= 0) {
        out[e.key.toString()] = v.toDouble();
      }
    }
    return out;
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'weight': weight,
        'height': height,
        'age': age,
        'gender': gender,
        'activityLevel': activityLevel,
        'goal': goal,
        'sicknesses': sicknesses,
        'allergies': allergies,
        'disabilities': disabilities,
        'dailyCalories': dailyCalories,
        'dailyCarbs': dailyCarbs,
        'dailyProtein': dailyProtein,
        'dailyFat': dailyFat,
        'language': language,
        'theme': theme,
        'onboarded': onboarded,
        if (displayName.isNotEmpty) 'displayName': displayName,
        if (targetWeight != null) 'targetWeight': targetWeight,
        'pace': pace,
        if (bodyFatPct != null) 'bodyFatPct': bodyFatPct,
        'pregnancyStatus': pregnancyStatus,
        'dietaryPattern': dietaryPattern,
        'dislikedFoods': dislikedFoods,
        'cuisinePreference': cuisinePreference,
        'mealsPerDay': mealsPerDay,
        'fastingWindow': fastingWindow,
        if (sleepHours != null) 'sleepHours': sleepHours,
        'stressLevel': stressLevel,
        if (waterTargetMl != null) 'waterTargetMl': waterTargetMl,
        'medications': medications,
        'workoutDaysPerWeek': workoutDaysPerWeek,
        'workoutType': workoutType,
        'cookingSkill': cookingSkill,
        'cookingTime': cookingTime,
        if (dailyMicroGoals.isNotEmpty) 'dailyMicroGoals': dailyMicroGoals,
      };

  /// Returns a copy with the daily macro targets overridden.
  UserProfile copyWithMacros({
    int? dailyCalories,
    int? dailyProtein,
    int? dailyCarbs,
    int? dailyFat,
  }) {
    return UserProfile(
      uid: uid,
      weight: weight,
      height: height,
      age: age,
      gender: gender,
      activityLevel: activityLevel,
      goal: goal,
      sicknesses: sicknesses,
      allergies: allergies,
      disabilities: disabilities,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      dailyCarbs: dailyCarbs ?? this.dailyCarbs,
      dailyProtein: dailyProtein ?? this.dailyProtein,
      dailyFat: dailyFat ?? this.dailyFat,
      language: language,
      theme: theme,
      onboarded: onboarded,
      displayName: displayName,
      targetWeight: targetWeight,
      pace: pace,
      bodyFatPct: bodyFatPct,
      pregnancyStatus: pregnancyStatus,
      dietaryPattern: dietaryPattern,
      dislikedFoods: dislikedFoods,
      cuisinePreference: cuisinePreference,
      mealsPerDay: mealsPerDay,
      fastingWindow: fastingWindow,
      sleepHours: sleepHours,
      stressLevel: stressLevel,
      waterTargetMl: waterTargetMl,
      medications: medications,
      workoutDaysPerWeek: workoutDaysPerWeek,
      workoutType: workoutType,
      cookingSkill: cookingSkill,
      cookingTime: cookingTime,
      dailyMicroGoals: dailyMicroGoals,
    );
  }

  UserProfile copyWithMicroGoals(Map<String, double> microGoals) {
    return UserProfile(
      uid: uid,
      weight: weight,
      height: height,
      age: age,
      gender: gender,
      activityLevel: activityLevel,
      goal: goal,
      sicknesses: sicknesses,
      allergies: allergies,
      disabilities: disabilities,
      dailyCalories: dailyCalories,
      dailyCarbs: dailyCarbs,
      dailyProtein: dailyProtein,
      dailyFat: dailyFat,
      language: language,
      theme: theme,
      onboarded: onboarded,
      displayName: displayName,
      targetWeight: targetWeight,
      pace: pace,
      bodyFatPct: bodyFatPct,
      pregnancyStatus: pregnancyStatus,
      dietaryPattern: dietaryPattern,
      dislikedFoods: dislikedFoods,
      cuisinePreference: cuisinePreference,
      mealsPerDay: mealsPerDay,
      fastingWindow: fastingWindow,
      sleepHours: sleepHours,
      stressLevel: stressLevel,
      waterTargetMl: waterTargetMl,
      medications: medications,
      workoutDaysPerWeek: workoutDaysPerWeek,
      workoutType: workoutType,
      cookingSkill: cookingSkill,
      cookingTime: cookingTime,
      dailyMicroGoals: microGoals,
    );
  }
}
