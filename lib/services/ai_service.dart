import 'dart:typed_data';
import 'dart:convert';
import 'package:nutrify/services/api_service.dart';

/// Existing feature facade. No Google credentials or provider access on-device.
class AiService {
  final ApiService api;
  AiService({required this.api});
  Map<String, String> _image(Uint8List bytes) => {
    'mimeType': bytes.length > 3 && bytes[0] == 137 && bytes[1] == 80
        ? 'image/png'
        : 'image/jpeg',
    'data': base64Encode(bytes),
  };

  Future<Map<String, String>?> generateHealthGuidance({
    required List<String> disabilities,
    required List<String> sicknesses,
    required List<String> allergies,
    required int dailyCalories,
    required int dailyProtein,
    required int dailyCarbs,
    required int dailyFat,
    required String nutritionGoalLabel,
    String dietaryPattern = 'omnivore',
    List<String> dislikedFoods = const [],
    String cuisinePreference = 'mixed',
    String pace = 'moderate',
    String pregnancyStatus = 'none',
    int? workoutDaysPerWeek,
    String workoutType = 'none',
    String fastingWindow = 'none',
    int mealsPerDay = 3,
    double? sleepHours,
    String stressLevel = 'medium',
    int? waterTargetMl,
    double? targetWeight,
    double? bodyFatPct,
    String medications = '',
  }) async {
    final result = await api.generateAi('guidance', {});
    return result?.map((key, value) => MapEntry(key, value.toString()));
  }

  Future<Map<String, dynamic>?> generateMealPlan({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    required String goal,
    required String healthConditionsSummary,
    required String allergiesSummary,
    required String lang,
    String mealCuisine = 'all',
    String dietaryPattern = 'omnivore',
    List<String> dislikedFoods = const [],
    String cuisinePreference = 'mixed',
    int mealsPerDay = 4,
    String fastingWindow = 'none',
    String cookingSkill = 'intermediate',
    String cookingTime = 'under30',
    String pregnancyStatus = 'none',
  }) async {
    final result = await api.generateAi('meal-plan', {'cuisine': mealCuisine});
    return result;
  }

  Future<Map<String, dynamic>?> generateMealDetails({
    required String mealName,
    String? slot,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    required String goal,
    required String healthConditionsSummary,
    required String allergiesSummary,
    required String lang,
    String mealCuisine = 'all',
  }) async {
    final result = await api.generateAi('details', {
      'mealName': mealName,
      'slot': ?slot,
      'cuisine': mealCuisine,
    });
    return result;
  }

  Future<Map<String, dynamic>?> generateSingleMeal({
    required String mealSlotLabel,
    required String currentName,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    required String goal,
    required String allergiesSummary,
    required String lang,
    String mealCuisine = 'all',
  }) async {
    final result = await api.generateAi('meal', {
      'mealName': currentName,
      'cuisine': mealCuisine,
      'slot': mealSlotLabel,
    });
    return result;
  }

  Future<Map<String, dynamic>?> generateMealPlanShoppingList({
    required List<
      ({String slotLabel, String dishName, List<String> ingredients})
    >
    pendingMeals,
    required String lang,
  }) async {
    final result = await api.generateAi('shopping', {
      'pendingMeals': pendingMeals.map((m) => m.dishName).toList(),
    });
    return result;
  }

  Future<Map<String, dynamic>?> generateRecipeFromIngredients({
    required List<String> ingredients,
    required int targetCalories,
    required String goal,
    required String allergiesSummary,
    required int dailyCalories,
    required int dailyProtein,
    required int dailyCarbs,
    required int dailyFat,
    required String lang,
  }) async {
    final result = await api.generateAi('recipe', {'ingredients': ingredients});
    return result;
  }

  Future<Map<String, dynamic>?> analyzeFridge({
    required Uint8List imageBytes,
    required String mealPeriodLabel,
    required int targetCalories,
    required String goal,
    required String allergiesSummary,
    required int dailyCalories,
    required int dailyProtein,
    required int dailyCarbs,
    required int dailyFat,
  }) async {
    final result = await api.generateAi('fridge', {
      'image': _image(imageBytes),
      'slot': mealPeriodLabel,
    });
    return result;
  }

  Future<Map<String, dynamic>?> analyzeFood({
    required Uint8List imageBytes,
    required int dailyCalories,
    required int dailyProtein,
    required int dailyCarbs,
    required int dailyFat,
    required String lang,
  }) async {
    final result = await api.generateAi('food', {'image': _image(imageBytes)});
    return result;
  }

  Future<Map<String, dynamic>?> estimateBodyFatFromPhoto({
    required Uint8List imageBytes,
    String gender = 'male',
    int age = 30,
    double heightCm = 175,
    double weightKg = 75,
    double? waistCm,
    double? neckCm,
    double? hipCm,
    double? anchorPercent,
    String? anchorMethod,
  }) async {
    final result = await api.generateAi('body-fat', {
      'image': _image(imageBytes),
      'anchorPercent': ?anchorPercent,
    });
    return result;
  }
}
