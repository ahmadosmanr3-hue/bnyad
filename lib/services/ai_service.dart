import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nutrify/utils/kurdish_sorani_ai_prompt.dart';
import 'package:nutrify/constants/food_database.dart';

class AiService {
  final String apiKey;



  static dynamic _parseJsonResponse(String rawContent) {
    String text = rawContent.trim();
    if (text.contains('</think>')) {
      text = text.split('</think>').last.trim();
    }
    if (text.startsWith('```json')) {
      text = text.substring(7);
    } else if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    text = text.trim();
    final firstBrace = text.indexOf('{');
    final lastBrace = text.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      text = text.substring(firstBrace, lastBrace + 1);
    }
    return jsonDecode(text);
  }

  AiService({required this.apiKey});

  bool get _hasKey => apiKey.trim().isNotEmpty;

  void _ensureApiKey() {
    if (!_hasKey) {
      throw StateError(
        'GEMINI_API_KEY is not configured. Provide it via --dart-define=GEMINI_API_KEY=... or in private_keys.dart.',
      );
    }
  }

  static const List<String> _geminiModels = [
    'gemini-1.5-flash',
    'gemini-1.5-flash-8b',
    'gemini-1.5-pro',
  ];


  Future<Map<String, dynamic>?> _postGeminiVision({
    required String prompt,
    required Uint8List imageBytes,
    String? systemInstruction,
  }) async {
    _ensureApiKey();
    final key = apiKey.trim();

    final mimeType = imageBytes.length >= 4 &&
            imageBytes[0] == 0x89 &&
            imageBytes[1] == 0x50 &&
            imageBytes[2] == 0x4E &&
            imageBytes[3] == 0x47
        ? 'image/png'
        : 'image/jpeg';

    final base64Image = base64Encode(imageBytes);

    for (final model in _geminiModels) {
      for (final apiVersion in ['v1beta', 'v1']) {
        try {
          final uri = Uri.parse(
            'https://generativelanguage.googleapis.com/$apiVersion/models/$model:generateContent?key=$key',
          );

          final parts = <Map<String, dynamic>>[];

          if (systemInstruction != null && systemInstruction.isNotEmpty) {
            parts.add({'text': 'SYSTEM INSTRUCTION: $systemInstruction\n\n$prompt'});
          } else {
            parts.add({'text': prompt});
          }

          parts.add({
            'inline_data': {
              'mime_type': mimeType,
              'data': base64Image,
            }
          });

          final payload = {
            'contents': [
              {'parts': parts}
            ],
            'generationConfig': {
              'temperature': 0.2,
              'responseMimeType': 'application/json',
            }
          };

          final response = await http
              .post(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'x-goog-api-key': key,
                },
                body: jsonEncode(payload),
              )
              .timeout(const Duration(seconds: 40));

          if (response.statusCode == 200) {
            final data = jsonDecode(utf8.decode(response.bodyBytes));
            final candidates = data['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final resParts = candidates.first['content']?['parts'] as List?;
              if (resParts != null && resParts.isNotEmpty) {
                final text = resParts.first['text'] as String? ?? '';
                final parsed = _parseJsonResponse(text);
                if (parsed is Map<String, dynamic>) return parsed;
                if (parsed is List && parsed.isNotEmpty && parsed.first is Map) {
                  return Map<String, dynamic>.from(parsed.first);
                }
              }
            }
          } else {
            debugPrint('AI request could not be completed.');
            if (response.statusCode == 400 || response.statusCode == 403 || response.statusCode == 404) {
              debugPrint('AI request could not be completed.');
            }
          }
        } catch (e) {
          debugPrint('AI request could not be completed.');
        }
      }
    }
    return null;
  }

  Future<http.Response> _postJson(
    Map<String, dynamic> body, {
    Duration? timeout,
  }) async {
    _ensureApiKey();
    final key = apiKey.trim();
    final messages = body['messages'] as List?;
    String systemText = '';
    String userText = '';
    if (messages != null) {
      for (final m in messages) {
        if (m is Map) {
          final role = m['role']?.toString();
          final content = m['content'];
          if (role == 'system' && content is String) {
            systemText = content;
          } else if (role == 'user') {
            if (content is String) {
              userText = content;
            } else if (content is List) {
              for (final item in content) {
                if (item is Map && item['type'] == 'text') {
                  userText += item['text']?.toString() ?? '';
                }
              }
            }
          }
        }
      }
    }

    final promptText = systemText.isNotEmpty
        ? 'SYSTEM INSTRUCTION: $systemText\n\n$userText'
        : userText;

    final temp = (body['temperature'] as num?)?.toDouble() ?? 0.3;

    for (final model in _geminiModels) {
      for (final apiVersion in ['v1beta', 'v1']) {
        try {
          final uri = Uri.parse(
            'https://generativelanguage.googleapis.com/$apiVersion/models/$model:generateContent?key=$key',
          );

          final payload = {
            'contents': [
              {
                'parts': [
                  {'text': promptText}
                ]
              }
            ],
            'generationConfig': {
              'temperature': temp,
              'responseMimeType': 'application/json',
            }
          };

          final res = await http
              .post(
                uri,
                headers: {
                  'Content-Type': 'application/json',
                  'x-goog-api-key': key,
                },
                body: jsonEncode(payload),
              )
              .timeout(timeout ?? const Duration(seconds: 40));


          if (res.statusCode == 200) {
            final data = jsonDecode(utf8.decode(res.bodyBytes));
            final candidates = data['candidates'] as List?;
            if (candidates != null && candidates.isNotEmpty) {
              final parts = candidates.first['content']?['parts'] as List?;
              if (parts != null && parts.isNotEmpty) {
                final text = parts.first['text'] as String? ?? '';
                final mockOpenAiResponse = {
                  'choices': [
                    {
                      'message': {'content': text}
                    }
                  ]
                };
                return http.Response(jsonEncode(mockOpenAiResponse), 200);
              }
            }
          } else {
            debugPrint('AI request could not be completed.');
          }
        } catch (e) {
          debugPrint('AI request could not be completed.');
        }
      }
    }
    return http.Response('{"error":"Gemini request failed"}', 500);
  }



  /// Human-readable name for prompts (matches app locales: en, ar, ku).
  String _languageName(String lang) {
    switch (lang) {
      case 'ar':
        return 'Modern Standard Arabic';
      case 'ku':
        return KurdishSoraniAiPrompt.languageName;
      default:
        return 'English';
    }
  }

  /// System message: all user-visible strings in JSON must follow the app language.
  String _systemRuleJsonUserFacingStrings(String lang) {
    switch (lang) {
      case 'ar':
        return 'CRITICAL OUTPUT LANGUAGE: Every user-visible string in your JSON (names, titles, intros, reasons, descriptions, ingredients, instructions, steps) must be in Arabic only — clear Modern Standard Arabic or widely understood Arabic. Never use English for those strings. JSON keys and numeric values stay as required.';
      case 'ku':
        return KurdishSoraniAiPrompt.userFacingOnlyRule();
      default:
        return 'CRITICAL OUTPUT LANGUAGE: Every user-visible string in your JSON must be in English only. JSON keys and numeric values stay as required.';
    }
  }

  /// Meal plans & meal details: same content in English, Arabic, and Kurdish Sorani (script).
  String get _systemRuleTrilingualMeals =>
      'CRITICAL: The app is used in English, Arabic, and Kurdish Sorani. For every meal you MUST output '
      '"names": {"en":"...","ar":"...","ku":"..."} — the SAME dish described naturally in all three languages '
      '(not English repeated three times). JSON keys stay in English. Numbers must match the user\'s macro targets exactly. '
      '${KurdishSoraniAiPrompt.trilingualKuAppendix()}';

  /// JSON blobs (scanner, fridge, custom recipe): parallel en / ar / ku for all user-visible strings.
  String get _systemRuleTrilingualJson =>
      'CRITICAL: The app is used in English, Arabic, and Kurdish Sorani. Every user-visible string set MUST use '
      'parallel keys "en", "ar", and "ku" with the SAME meaning in each language (natural in each; not English copied three times). '
      'Numeric fields and JSON key names stay as specified. '
      '${KurdishSoraniAiPrompt.trilingualKuAppendix()}';

  String _macroGoalsUserNarrative(
    int calories,
    int protein,
    int carbs,
    int fat,
  ) =>
      '''The user's saved daily nutrition targets (you MUST honor these in totals and in any advice you give):
- Calories: $calories kcal/day
- Protein: ${protein}g/day
- Carbs: ${carbs}g/day
- Fat: ${fat}g/day
When you mention nutrition, stay consistent with these targets.''';

  /// Repeated at end of user prompts so the model aligns with the active app locale.
  String _userReminderOutputLanguage(String lang) {
    switch (lang) {
      case 'ar':
        return '\n\n— إلزامي: واجهة التطبيق بالعربية. كل النصوص الطبيعية التي يقرأها المستخدم يجب أن تكون بالعربية فقط، لا الإنجليزية.';
      case 'ku':
        return KurdishSoraniAiPrompt.userReminder;
      default:
        return '\n\n— MANDATORY: The app UI is English. All natural-language text for the user must be English only.';
    }
  }

  String _trilingualArraysRule(String lang) =>
      KurdishSoraniAiPrompt.trilingualParallelArraysRule(_languageName(lang));

  static const _mealPlanSpecificityRules = '''
SPECIFICITY RULES (mandatory — no vague meals):
- Each dish name must name the actual food: main protein/carb, cooking method, and at least one side or garnish.
  BAD: "Healthy lunch", "Chicken meal", "Light snack", "Balanced dinner"
  GOOD en: "Grilled chicken thigh with saffron rice, cucumber yogurt, and fresh herbs"
  GOOD ku: "مریشکی برژاو لەگەڵ برنجی زعفران و ماستی ئەنجمۆر و گیا"
- ingredients: 4–6 lines per language WITH quantities (e.g. "200g chicken breast", "1 cup basmati rice", "150g yogurt").
- instructions: 2–3 concrete cooking steps per language (prep → cook → serve).
- Pick real regional dishes when cuisine focus applies — not generic placeholders.''';

  String _shoppingScaleHint(int n, String lang) {
    if (lang == 'ar') {
      if (n <= 1) {
        return 'تبقّى وجبة واحدة — قائمة تسوق أقصر (حوالي 3–12 بنداً) مناسبة.';
      }
      if (n == 2) {
        return 'تبقّى وجبتان — حوالي 5–16 سطراً بعد الدمج وتجنب التكرار.';
      }
      return 'تبقّى عدة وجبات — حوالي 8–22 سطراً نموذجياً.';
    }
    if (lang == 'ku') {
      if (n <= 1) {
        return 'تەنها یەک ژەم ماوە — لیستێکی کورتتر (نزیکەی 3–12 بابەت) گونجاوە.';
      }
      if (n == 2) {
        return 'دوو ژەم ماوە — نزیکەی 5–16 هێڵ دوای تێکەڵکردن.';
      }
      return 'چەند ژەمێک ماوە — نزیکەی 8–22 هێڵ ئاساییە.';
    }
    if (n <= 1) {
      return 'Only one meal remains — a shorter list (about 3–12 items) is appropriate.';
    }
    if (n == 2) {
      return 'Two meals remain — aim for roughly 5–16 shopping lines, merged and deduplicated.';
    }
    return 'Several meals remain — about 8–22 lines is typical.';
  }

  /// `kurdish` | `arabic` | `all` — steers dish choice for meal plans.
  String _mealCuisineInstruction(String mealCuisine) {
    switch (mealCuisine) {
      case 'kurdish':
        return KurdishSoraniAiPrompt.cuisineFocus;
      case 'arabic':
        return 'Cuisine focus: Prioritize Arabic and Middle Eastern dishes (e.g. grains, legumes, grilled meats, stews, mezze-style foods, regional vegetables and spices typical of the Levant, Gulf, and Iraq).';
      default:
        return 'Cuisine focus: Offer varied dishes — international and regional; do not restrict to one cuisine.';
    }
  }
  // ─── Nutritional Goals ──────────────────────────────

  Future<Map<String, int>?> generateNutritionalGoals({
    required double weight,
    required double height,
    required int age,
    required String gender,
    required String activityLevel,
    required String goal,
    required List<String> sicknesses,
    required List<String> allergies,
    required List<String> disabilities,
    double? targetWeight,
    String pace = 'moderate',
    double? bodyFatPct,
    String pregnancyStatus = 'none',
    String dietaryPattern = 'omnivore',
    int workoutDaysPerWeek = 0,
    String workoutType = 'none',
    String fastingWindow = 'none',
  }) async {
    try {
      _ensureApiKey();
      final prompt =
          '''Calculate daily nutritional goals for a person with:
- Weight: $weight kg
- Height: $height cm
- Age: $age years
- Gender: $gender
- Activity Level: $activityLevel
- Goal: $goal (pace: $pace)
- Sicknesses: ${sicknesses.isNotEmpty ? sicknesses.join(', ') : 'None'}
- Allergies: ${allergies.isNotEmpty ? allergies.join(', ') : 'None'}
- Disabilities: ${disabilities.isNotEmpty ? disabilities.join(', ') : 'None'}
- Dietary pattern: $dietaryPattern${dietaryPattern == 'keto' ? ' (very low carb)' : dietaryPattern == 'lowCarb' ? ' (low carb)' : ''}
- Training: ${workoutDaysPerWeek > 0 ? '$workoutDaysPerWeek days/week ($workoutType)' : 'none'}
- Fasting window: $fastingWindow${targetWeight != null ? '\n- Target weight: ${targetWeight}kg' : ''}${bodyFatPct != null ? '\n- Body fat: $bodyFatPct%' : ''}${pregnancyStatus != 'none' ? '\n- Pregnancy/lactation: $pregnancyStatus' : ''}

Provide the daily target for:
1. Calories (kcal)
2. Protein (grams)
3. Carbohydrates (grams)
4. Fat (grams)

Respond ONLY in valid JSON: {"calories": 0, "protein": 0, "carbs": 0, "fat": 0}''';

      final response = await _postJson({
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a precise nutritional calculator. Always output valid JSON.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.3,
        'response_format': {'type': 'json_object'},
        'max_tokens': 300,
      }, timeout: const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        final parsed = _parseJsonResponse(content);
        final map = parsed is Map<String, dynamic>
            ? parsed
            : (parsed is List && parsed.isNotEmpty && parsed.first is Map)
            ? Map<String, dynamic>.from(parsed.first)
            : null;
        if (map == null) return null;
        return {
          'calories': (map['calories'] as num).toInt(),
          'protein': (map['protein'] as num).toInt(),
          'carbs': (map['carbs'] as num).toInt(),
          'fat': (map['fat'] as num).toInt(),
        };
      }

      debugPrint('AI request could not be completed.');
      return null;
    } catch (e) {
      debugPrint('AI request could not be completed.');
      return null;
    }
  }

  /// Personalized daily vitamin & mineral targets (same keys as food micros).
  Future<Map<String, double>?> generateMicronutrientGoals({
    required double weight,
    required double height,
    required int age,
    required String gender,
    required String activityLevel,
    required String goal,
    required List<String> sicknesses,
    required List<String> allergies,
    required List<String> disabilities,
    double? targetWeight,
    String pace = 'moderate',
    double? bodyFatPct,
    String pregnancyStatus = 'none',
    String dietaryPattern = 'omnivore',
    int workoutDaysPerWeek = 0,
    String workoutType = 'none',
    String fastingWindow = 'none',
  }) async {
    try {
      _ensureApiKey();
      final prompt =
          '''Calculate personalized DAILY micronutrient targets for one person.

Profile:
- Weight: $weight kg, Height: $height cm, Age: $age, Gender: $gender
- Activity: $activityLevel
- Nutrition goal: $goal (pace: $pace)
- Sicknesses: ${sicknesses.isNotEmpty ? sicknesses.join(', ') : 'None'}
- Allergies: ${allergies.isNotEmpty ? allergies.join(', ') : 'None'}
- Disabilities: ${disabilities.isNotEmpty ? disabilities.join(', ') : 'None'}
- Diet: $dietaryPattern
- Training: ${workoutDaysPerWeek > 0 ? '$workoutDaysPerWeek days/week ($workoutType)' : 'none'}
- Fasting: $fastingWindow${targetWeight != null ? '\n- Target weight: ${targetWeight}kg' : ''}${bodyFatPct != null ? '\n- Body fat: $bodyFatPct%' : ''}${pregnancyStatus != 'none' ? '\n- Pregnancy/lactation: $pregnancyStatus' : ''}

Provide realistic daily targets for ALL nutrients (use these exact keys and units): $microKeysForAiPrompt

Adjust for gender, age, pregnancy, anemia, kidney disease, and activity. Use evidence-based RDAs/DRIs.

Respond ONLY in valid JSON: $microJsonTemplate''';

      final response = await _postJson({
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a precise clinical nutrition calculator. Always output valid JSON with numeric micronutrient targets.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.25,
        'response_format': {'type': 'json_object'},
        'max_tokens': 500,
      }, timeout: const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        final parsed = _parseJsonResponse(content);
        final map = parsed is Map<String, dynamic>
            ? parsed
            : (parsed is List && parsed.isNotEmpty && parsed.first is Map)
            ? Map<String, dynamic>.from(parsed.first)
            : null;
        if (map == null) return null;

        final out = <String, double>{};
        for (final k in kTrackedMicroKeys) {
          final v = map[k];
          if (v is num && v.toDouble() >= 0 && v.isFinite) {
            out[k] = v.toDouble();
          }
        }
        if (out.length >= kTrackedMicroKeys.length ~/ 2) return out;
      }

      debugPrint('AI request could not be completed.');
      return null;
    } catch (e) {
      debugPrint('AI request could not be completed.');
      return null;
    }
  }


  /// Daily hydration target in milliliters from full onboarding context.
  Future<int?> generateDailyWaterTargetMl({
    required double weight,
    required double height,
    required int age,
    required String gender,
    required String activityLevel,
    required String goal,
    required List<String> sicknesses,
    required List<String> allergies,
    required List<String> disabilities,
    double? targetWeight,
    String pace = 'moderate',
    double? bodyFatPct,
    String pregnancyStatus = 'none',
    String dietaryPattern = 'omnivore',
    int mealsPerDay = 3,
    String fastingWindow = 'none',
    double? sleepHours,
    String stressLevel = 'medium',
    String medications = '',
    int workoutDaysPerWeek = 0,
    String workoutType = 'none',
    int? dailyCalories,
  }) async {
    try {
      _ensureApiKey();
      final prompt =
          '''Calculate a safe, personalized DAILY water intake target in milliliters (ml) for one person.

Profile:
- Weight: $weight kg, Height: $height cm, Age: $age, Gender: $gender
- Activity: $activityLevel
- Nutrition goal: $goal (pace: $pace)
- Sicknesses: ${sicknesses.isNotEmpty ? sicknesses.join(', ') : 'None'}
- Allergies: ${allergies.isNotEmpty ? allergies.join(', ') : 'None'}
- Disabilities: ${disabilities.isNotEmpty ? disabilities.join(', ') : 'None'}
- Diet: $dietaryPattern
- Meals/day: $mealsPerDay, Fasting: $fastingWindow
- Sleep: ${sleepHours ?? 'unknown'} h/night, Stress: $stressLevel
- Training: ${workoutDaysPerWeek > 0 ? '$workoutDaysPerWeek days/week ($workoutType)' : 'none'}
${targetWeight != null ? '- Target weight: ${targetWeight}kg' : ''}${bodyFatPct != null ? '\n- Body fat: $bodyFatPct%' : ''}${pregnancyStatus != 'none' ? '\n- Pregnancy/lactation: $pregnancyStatus' : ''}${medications.trim().isNotEmpty ? '\n- Medications: $medications' : ''}${dailyCalories != null ? '\n- Daily calories: $dailyCalories kcal' : ''}

Rules:
- Use evidence-based hydration (body size, activity, climate-neutral baseline, pregnancy/lactation, illness where relevant).
- Typical adult range roughly 1500–4000 ml/day; athletes or breastfeeding may be higher; do not exceed 5000 ml unless clearly justified.
- Round to a practical number (nearest 50 or 100 ml).

Respond ONLY with valid JSON: {"waterTargetMl": 0, "reasonEn": "one short sentence in English explaining the main factor"}''';

      final response = await _postJson({
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a clinical nutrition assistant. Output only valid JSON with integer waterTargetMl.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.3,
        'response_format': {'type': 'json_object'},
        'max_tokens': 200,
      }, timeout: const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        final parsed = _parseJsonResponse(content);
        final map = parsed is Map<String, dynamic>
            ? parsed
            : (parsed is List && parsed.isNotEmpty && parsed.first is Map)
                ? Map<String, dynamic>.from(parsed.first)
                : null;
        if (map == null) return null;
        final ml = (map['waterTargetMl'] as num?)?.toInt();
        if (ml == null || ml < 1000 || ml > 6000) return null;
        return ml;
      }

      debugPrint('AI request could not be completed.');
      return null;
    } catch (e) {
      debugPrint('AI request could not be completed.');
      return null;
    }
  }

  // ─── Health Guidance ────────────────────────────────

  /// Returns localized tips for en, ar, ku so the UI can switch language without regenerating.
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
    try {
      _ensureApiKey();
      final macroBlock = _macroGoalsUserNarrative(
        dailyCalories,
        dailyProtein,
        dailyCarbs,
        dailyFat,
      );
      final extras = <String>[
        'Dietary pattern: $dietaryPattern',
        'Cuisine preference: $cuisinePreference',
        if (dislikedFoods.isNotEmpty)
          'Foods to avoid (preference): ${dislikedFoods.join(', ')}',
        'Pace: $pace',
        if (pregnancyStatus != 'none')
          'Pregnancy/lactation: $pregnancyStatus',
        if (workoutDaysPerWeek != null && workoutDaysPerWeek > 0)
          'Training: $workoutDaysPerWeek days/week ($workoutType)',
        if (fastingWindow != 'none') 'Intermittent fasting: $fastingWindow',
        'Meals per day: $mealsPerDay',
        if (sleepHours != null) 'Average sleep: ${sleepHours.toStringAsFixed(1)}h',
        'Stress: $stressLevel',
        if (waterTargetMl != null) 'Water target: ${waterTargetMl}ml',
        if (targetWeight != null)
          'Target weight: ${targetWeight.toStringAsFixed(1)}kg',
        if (bodyFatPct != null)
          'Body fat: ${bodyFatPct.toStringAsFixed(1)}%',
        if (medications.trim().isNotEmpty) 'Medications: ${medications.trim()}',
      ].join('\n- ');
      final prompt =
          '''Provide 3-5 concise, high-impact health tips for a user with these conditions:
- Disabilities: ${disabilities.isNotEmpty ? disabilities.join(', ') : 'None'}
- Sicknesses: ${sicknesses.isNotEmpty ? sicknesses.join(', ') : 'None'}
- Allergies: ${allergies.isNotEmpty ? allergies.join(', ') : 'None'}
- Primary nutrition goal: $nutritionGoalLabel
- $extras

$macroBlock

Focus on safety, nutrition, and lifestyle. Tips must align with the macro targets above.

Return ONLY valid JSON with the SAME advice in three languages (not three different sets of tips):
{"en":"paragraph in English","ar":"نفس النصائح بالعربية","ku":"هەمان ئامۆژگاری بە کوردی سورانی — ڕێنووسی ڕاست، نموونە: ماست، برنج، گۆشت، مریشک"}

Each value is one short paragraph (line breaks ok). The "ku" paragraph MUST use correct Sorani Arabic-script spelling (ک not ك، ە where needed).''';

      final response = await _postJson({
        'messages': [
          {
            'role': 'system',
            'content': KurdishSoraniAiPrompt.trilingualHealthSystemRule(),
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.55,
        'max_tokens': 900,
        'response_format': {'type': 'json_object'},
      }, timeout: const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        final parsed = _parseJsonResponse(content);
        if (parsed is! Map<String, dynamic>) return null;
        final en = parsed['en']?.toString().trim() ?? '';
        final ar = parsed['ar']?.toString().trim() ?? '';
        final ku = parsed['ku']?.toString().trim() ?? '';
        if (en.isEmpty && ar.isEmpty && ku.isEmpty) return null;
        return {'en': en, 'ar': ar, 'ku': ku};
      }

      debugPrint('AI request could not be completed.');
      return null;
    } catch (e) {
      debugPrint('AI request could not be completed.');
      return null;
    }
  }

  // ─── Meal Plan ──────────────────────────────────────

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
    try {
      _ensureApiKey();
      // Pre-calculate per-meal targets for the AI
      final bfCal = (calories * 0.25).round();
      final luCal = (calories * 0.35).round();
      final diCal = (calories * 0.30).round();
      final snCal = calories - bfCal - luCal - diCal;

      final cuisineBlock = _mealCuisineInstruction(mealCuisine);
      final macroNarrative = _macroGoalsUserNarrative(
        calories,
        protein,
        carbs,
        fat,
      );

      final prompt =
          '''Create a COMPLETE daily meal plan that MUST add up to EXACTLY these daily totals:
- Total Calories: $calories kcal
- Total Protein: ${protein}g
- Total Carbs: ${carbs}g
- Total Fat: ${fat}g

$macroNarrative

Distribute across 4 meals approximately:
- Breakfast: ~$bfCal kcal
- Lunch: ~$luCal kcal
- Dinner: ~$diCal kcal
- Snacks: ~$snCal kcal

$cuisineBlock

CRITICAL: The SUM of calories/protein/carbs/fat across breakfast+lunch+dinner+snacks MUST equal the daily targets above exactly (no rounding drift >2%).
Goal: $goal.${healthConditionsSummary.isNotEmpty ? ' Health conditions: $healthConditionsSummary.' : ''}${allergiesSummary.isNotEmpty ? ' Allergies / avoid: $allergiesSummary.' : ''}
User context:
- Dietary pattern: $dietaryPattern (respect strictly — e.g. vegan = no animal products; halal/kosher rules apply; keto = very low carbs).
- Cuisine preference: $cuisinePreference.
${dislikedFoods.isNotEmpty ? '- Foods the user dislikes (avoid in every meal): ${dislikedFoods.join(', ')}.\n' : ''}- Meals per day preference: $mealsPerDay (still produce breakfast+lunch+dinner+snacks JSON shape; if mealsPerDay <= 3, set snacks to a tiny optional item).
${fastingWindow != 'none' ? '- Intermittent fasting window: $fastingWindow — push breakfast later or compress meals accordingly.\n' : ''}- Cooking skill: $cookingSkill, time per meal: $cookingTime — suggest dishes the user can realistically prepare.
${pregnancyStatus != 'none' ? '- Pregnancy/lactation status: $pregnancyStatus — favor nutrient-dense, safe foods; avoid raw fish/unpasteurized dairy/high-mercury fish.\n' : ''}

Each meal MUST include:
- "names": {"en":"specific dish name in English","ar":"اسم محدد بالعربية","ku":"ناوی تایبەت بە کوردی سورانی"} — same dish, three natural translations (see SPECIFICITY RULES).
- "calories", "protein", "carbs", "fat" (integers for this meal)
- "ingredients": {"en":["qty + item",...],"ar":[...],"ku":[...]} — 4–6 lines per language with amounts
- "instructions": {"en":["step1","step2",...],"ar":[...],"ku":[...]} — 2–3 steps per language
- "micros" for that ENTIRE meal (not per 100g): $microKeysForAiPrompt

$_mealPlanSpecificityRules
${_trilingualArraysRule(lang)}

Do not use a single "name" field; use "names" only.

Return ONLY one JSON object with keys breakfast, lunch, dinner, snacks. Example shape for each meal:
{"names":{"en":"...","ar":"...","ku":"..."},"ingredients":{"en":["..."],"ar":["..."],"ku":["..."]},"instructions":{"en":["..."],"ar":["..."],"ku":["..."]},"calories":0,"protein":0,"carbs":0,"fat":0,"micros":{...}}${_userReminderOutputLanguage(lang)}''';

      final response = await _postJson({
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a professional nutritionist. $_systemRuleTrilingualMeals $_mealPlanSpecificityRules The four meals MUST sum to the user\'s exact daily calorie and macro targets. Each meal must include specific dish names, full ingredient lists with quantities, cooking steps, and realistic total micros in all three languages. Follow cuisine focus when choosing dishes. Always respond with a single flat JSON object with keys: breakfast, lunch, dinner, snacks.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.35,
        'response_format': {'type': 'json_object'},
        'max_tokens': 2800,
      }, timeout: const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        final parsed = _parseJsonResponse(content);
        if (parsed is Map<String, dynamic>) {
          if (parsed.containsKey('breakfast')) return parsed;
          final inner = parsed.values.firstWhere(
            (v) => v is Map && v.containsKey('breakfast'),
            orElse: () => null,
          );
          if (inner is Map<String, dynamic>) return inner;
          return parsed;
        }
        if (parsed is List && parsed.isNotEmpty) {
          final first = parsed.first;
          if (first is Map<String, dynamic>) return first;
        }
        return null;
      }

      debugPrint('AI request could not be completed.');
      return null;
    } catch (e) {
      debugPrint('AI request could not be completed.');
      return null;
    }
  }

  Future<Map<String, dynamic>?> generateMealDetails({
    required String mealName,
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
    try {
      _ensureApiKey();
      final cuisineBlock = _mealCuisineInstruction(mealCuisine);
      final dishLabel = mealName.trim().isNotEmpty ? mealName : 'meal';
      final ctx = StringBuffer(
        'Ingredients & instructions for "$dishLabel" (${calories}kcal, P${protein}g, C${carbs}g, F${fat}g).',
      );
      if (goal.isNotEmpty) ctx.write(' Nutrition goal: $goal.');
      if (healthConditionsSummary.isNotEmpty) {
        ctx.write(' Health conditions: $healthConditionsSummary.');
      }
      if (allergiesSummary.isNotEmpty) {
        ctx.write(' Avoid / allergies: $allergiesSummary.');
      }
      final prompt =
          '''$ctx
$cuisineBlock
Provide 4–6 specific ingredients WITH quantities (grams, cups, pieces) and 2–3 concrete cooking steps in ALL three languages (same recipe, fully translated — not English copied into ar/ku).

${_trilingualArraysRule(lang)}

Also estimate TOTAL micronutrients for this full meal (same units as USDA-style totals): $microKeysForAiPrompt — based on those ingredients and portion size implied by the calories.

Return ONLY valid JSON:
{"ingredients":{"en":["200g ...","..."],"ar":["..."],"ku":["..."]},"instructions":{"en":["step1","step2"],"ar":["..."],"ku":["..."]},"micros":$microJsonTemplate}${_userReminderOutputLanguage(lang)}''';

      final response = await _postJson({
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a professional nutritionist. Always output valid JSON. $_systemRuleTrilingualMeals $_trilingualArraysRule(lang) Micros must be numeric totals for the whole meal. Every en/ar/ku array must be written in its own language only.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.35,
        'response_format': {'type': 'json_object'},
        'max_tokens': 1200,
      }, timeout: const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        final parsed = _parseJsonResponse(content);
        if (parsed is Map<String, dynamic>) return parsed;
        if (parsed is List && parsed.isNotEmpty && parsed.first is Map) {
          return Map<String, dynamic>.from(parsed.first);
        }
        return null;
      }

      debugPrint('AI request could not be completed.');
      return null;
    } catch (e) {
      debugPrint('AI request could not be completed.');
      return null;
    }
  }

  // ─── Single Meal Swap ─────────────────────────────

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
    try {
      _ensureApiKey();
      final cuisineBlock = _mealCuisineInstruction(mealCuisine);
      final prompt =
          '''Generate ONE meal for this slot: "$mealSlotLabel". NOT "$currentName" (pick something different).
The meal MUST have EXACTLY these macros: ${calories}kcal, ${protein}g protein, ${carbs}g carbs, ${fat}g fat.
Include realistic TOTAL micros for this whole meal: $microKeysForAiPrompt (match typical foods for this dish).
$cuisineBlock
Goal: $goal.${allergiesSummary.isNotEmpty ? ' Allergies / avoid: $allergiesSummary.' : ''}

Return JSON only:
{"names":{"en":"...","ar":"...","ku":"..."},"calories":$calories,"protein":$protein,"carbs":$carbs,"fat":$fat,"micros":$microJsonTemplate}
Use "names" (not "name"). Same dish in three languages.''';

      final response = await _postJson({
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a professional nutritionist. $_systemRuleTrilingualMeals The meal macros MUST match the requested targets exactly. Include realistic meal-total micros. Honor the cuisine focus. Always output valid JSON.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.75,
        'response_format': {'type': 'json_object'},
        'max_tokens': 380,
      }, timeout: const Duration(seconds: 16));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        final parsed = _parseJsonResponse(content);
        if (parsed is Map<String, dynamic>) return parsed;
        if (parsed is List && parsed.isNotEmpty && parsed.first is Map) {
          return Map<String, dynamic>.from(parsed.first);
        }
        return null;
      }

      return null;
    } catch (e) {
      debugPrint('AI request could not be completed.');
      return null;
    }
  }

  /// Suggests what to buy for [pendingMeals] only (e.g. meals not yet logged as eaten).
  /// Each entry: localized slot label, dish name, and optional ingredient lines for that dish.
  Future<Map<String, dynamic>?> generateMealPlanShoppingList({
    required List<
      ({String slotLabel, String dishName, List<String> ingredients})
    >
    pendingMeals,
    required String lang,
  }) async {
    try {
      _ensureApiKey();
      if (pendingMeals.isEmpty) return null;
      final langName = _languageName(lang);
      final dishLines = pendingMeals
          .map((m) => '- ${m.slotLabel}: ${m.dishName}')
          .join('\n');
      final unique = pendingMeals
          .expand((m) => m.ingredients)
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      final ingBlock = unique.isEmpty
          ? 'No detailed ingredient lists are available yet for these dishes — infer realistic ingredients from each dish name and cuisine, then list what to buy. ONLY for the meals listed above.'
          : 'Ingredient lines from those recipes only (may be incomplete or overlapping):\n${unique.join('\n')}';

      final n = pendingMeals.length;
      final scaleHint = _shoppingScaleHint(n, lang);

      final prompt =
          '''You help a home cook shop for what they still need TODAY.

CRITICAL: The user has ALREADY eaten or finished some meals today. You MUST ONLY plan shopping for the meals listed below. Do NOT suggest ingredients for breakfast, lunch, dinner, or snacks that are NOT in this list. Ignore any concept of a "full day" beyond these dishes.

Meals still to cook / eat (ONLY these):
$dishLines

$ingBlock

$scaleHint
Assume the kitchen may not have everything. Produce a practical STORE shopping list: what they likely need to buy for ONLY these remaining meals (produce, proteins, dairy, grains, legumes, spices/oils only if central to these dishes). Merge duplicates. Skip obvious things everyone has unless essential.

The JSON keys stay: intro, items. Every string VALUE (intro, each name, each reason) must be written entirely in $langName — the same language as the app UI.

Return ONLY valid JSON:
{"intro":"1–2 friendly sentences mentioning only the remaining meals","items":[{"name":"what to buy","reason":"brief: which meal or why"}]}${_userReminderOutputLanguage(lang)}''';

      final response = await _postJson({
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a practical meal-prep and shopping assistant. ${_systemRuleJsonUserFacingStrings(lang)} Output strictly valid JSON with keys intro (string) and items (array of objects with name and reason). Be concise.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.4,
        'response_format': {'type': 'json_object'},
        'max_tokens': 900,
      }, timeout: const Duration(seconds: 28));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        final parsed = _parseJsonResponse(content);
        if (parsed is Map<String, dynamic>) return parsed;
        if (parsed is List && parsed.isNotEmpty && parsed.first is Map) {
          return Map<String, dynamic>.from(parsed.first as Map);
        }
        return null;
      }

      debugPrint('AI request could not be completed.');
      return null;
    } catch (e) {
      debugPrint('AI request could not be completed.');
      return null;
    }
  }

  // ─── Recipe from Ingredients ─────────────────────────

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
    try {
      _ensureApiKey();
      final langName = _languageName(lang);
      final macro = _macroGoalsUserNarrative(
        dailyCalories,
        dailyProtein,
        dailyCarbs,
        dailyFat,
      );
      final prompt =
          '''Create a healthy recipe using ONLY these ingredients (user typed them — may be in any language): ${ingredients.join(", ")}.
Target about $targetCalories kcal for this dish (one meal). User goal: $goal.${allergiesSummary.isNotEmpty ? ' Avoid / allergies: $allergiesSummary.' : ''}

$macro
Keep recipe totals coherent with the meal-sized calorie target and the user's daily macro picture.

User app language: $langName — they will read ingredients and instructions in that language first.

${_trilingualArraysRule(lang)}

Return ONLY valid JSON:
{"names":{"en":"...","ar":"...","ku":"..."},"calories":0,"protein":0,"carbs":0,"fat":0,"micros":$microJsonTemplate,"ingredients":{"en":["qty ingredient",...],"ar":["..."],"ku":["..."]},"instructions":{"en":["step1",...],"ar":[...],"ku":[...]}}
Micros units: $microKeysForAiPrompt.
- ingredients.ku and instructions.ku MUST be full Sorani Kurdish (Arabic script), not English.
- ingredients.ar and instructions.ar MUST be full Arabic, not English.
- Same recipe in all three languages; each array native and complete.${_userReminderOutputLanguage(lang)}''';

      final response = await _postJson({
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a professional chef and nutritionist. Always output valid JSON. $_systemRuleTrilingualJson ${_trilingualArraysRule(lang)} Never put English inside ar or ku arrays.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.5,
        'response_format': {'type': 'json_object'},
        'max_tokens': 1200,
      }, timeout: const Duration(seconds: 35));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];
        final parsed = _parseJsonResponse(content);
        if (parsed is Map<String, dynamic>) return parsed;
        if (parsed is List && parsed.isNotEmpty && parsed.first is Map) {
          return Map<String, dynamic>.from(parsed.first);
        }
        return null;
      }

      return null;
    } catch (e) {
      debugPrint('AI request could not be completed.');
      return null;
    }
  }


  // ─── Fridge Scanner ────────────────────────────────

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
    try {
      _ensureApiKey();
      final macro = _macroGoalsUserNarrative(
        dailyCalories,
        dailyProtein,
        dailyCarbs,
        dailyFat,
      );
      final prompt =
          '''Look at this fridge/pantry photo. Identify the visible ingredients.
Then suggest ONE recipe appropriate for this meal period: "$mealPeriodLabel". Target about $targetCalories kcal for this dish. User goal: $goal.${allergiesSummary.isNotEmpty ? ' Avoid / allergies: $allergiesSummary.' : ''}

$macro
Align the suggested recipe with these daily targets and the meal calorie target.

Return ONLY valid JSON:
{"detected_ingredients":{"en":["item",...],"ar":[...],"ku":[...]},"recipe":{"calories":0,"protein":0,"carbs":0,"fat":0,"micros":$microJsonTemplate,"names":{"en":"...","ar":"...","ku":"..."},"ingredients":{"en":["qty item",...],"ar":[...],"ku":[...]},"instructions":{"en":["step1",...],"ar":[...],"ku":[...]}}}
Use the same items in the same order in each language array. Micros units: $microKeysForAiPrompt.''';

      return await _postGeminiVision(
        prompt: prompt,
        imageBytes: imageBytes,
        systemInstruction:
            'You are a professional chef and nutritionist. Always output valid JSON. $_systemRuleTrilingualJson',
      );
    } catch (e) {
      debugPrint('AI request could not be completed.');
      return null;
    }
  }

  // ─── Food Scanner ──────────────────────────────────

  Future<Map<String, dynamic>?> analyzeFood({
    required Uint8List imageBytes,
    required int dailyCalories,
    required int dailyProtein,
    required int dailyCarbs,
    required int dailyFat,
    required String lang,
  }) async {
    try {
      _ensureApiKey();
      final macro = _macroGoalsUserNarrative(
        dailyCalories,
        dailyProtein,
        dailyCarbs,
        dailyFat,
      );
      final langName = _languageName(lang);
      final prompt =
          '''Identify the food in the image. The app UI language is $langName — keep every user-visible string natural in that language inside the en/ar/ku maps (correct script for each key).

Provide estimated nutritional values per 100g for the whole dish (calories, protein, carbs, fat) AND micronutrients per 100g.

$macro
Descriptions must be 1–2 short sentences only (never a list, never multiple languages in one string).

If the food is a mixed/composite dish (salad, sandwich, plate, stew, bowl with several visible parts), set "is_composite": true and list EVERY distinct component in "components" with its estimated portion in grams and absolute macros for that portion (not per 100g). Sum of component macros should approximate the visible portion. For a single food (one apple, one protein bar, plain rice), set "is_composite": false and "components": [].

Respond ONLY in valid JSON:
{"names":{"en":"...","ar":"...","ku":"..."},"descriptions":{"en":"1-2 sentences","ar":"...","ku":"..."},"is_composite":false,"calories":0,"protein":0,"carbs":0,"fat":0,"micros":$microJsonTemplate,"components":[{"names":{"en":"...","ar":"...","ku":"..."},"grams":0,"calories":0,"protein":0,"carbs":0,"fat":0}]}
Units: $microKeysForAiPrompt. Use 0 if unknown.${_userReminderOutputLanguage(lang)}''';

      return await _postGeminiVision(
        prompt: prompt,
        imageBytes: imageBytes,
        systemInstruction:
            'You are a food recognition expert. Output valid JSON ONLY. $_systemRuleTrilingualJson ${_systemRuleJsonUserFacingStrings(lang)}',
      );
    } catch (e) {
      debugPrint('AI request could not be completed.');
      return null;
    }
  }

  // ─── Body fat (visual estimate — not clinical) ─────



  /// Visual refinement from a photo — anchored to measurements when provided.
  /// Returns JSON: `min_percent`, `max_percent`, `confidence` ("low"|"medium"),
  /// `notes` {en,ar,ku}, `disclaimer` {en,ar,ku}.
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
    try {
      _ensureApiKey();
      final anchorBlock = anchorPercent != null
          ? '''
REFERENCE (from tape measurements / profile — treat as primary anchor):
- Estimated body fat anchor: ${anchorPercent.toStringAsFixed(1)}% (${anchorMethod ?? 'formula'})
- Your min_percent / max_percent should stay within about ±4 percentage points of this anchor unless the photo clearly contradicts it (e.g. very muscular with low visible fat).
'''
          : '''
No tape measurements were provided. Use the profile only as weak context:
- Sex: $gender, age: $age, height: ${heightCm.round()} cm, weight: ${weightKg.round()} kg
''';

      final measureBlock = (waistCm != null && neckCm != null)
          ? '- Waist: ${waistCm.toStringAsFixed(1)} cm, neck: ${neckCm.toStringAsFixed(1)} cm${hipCm != null ? ', hip: ${hipCm.toStringAsFixed(1)} cm' : ''}\n'
          : '';

      final prompt = '''
The user uploaded a photo for a casual, non-clinical visual check of approximate body fat percentage.

$anchorBlock$measureBlock
PHOTO RULES:
- Output only a RANGE (min_percent to max_percent), not one exact number.
- Prefer a 4–8 point range when the photo is clear; wider if clothing hides shape or lighting is poor.
- If unsuitable (face-only, heavy clothes, no torso), explain in notes and keep the range near the anchor if one was given.
- Never claim clinical accuracy. confidence must be only "low" or "medium".
- min_percent and max_percent: numbers between 3 and 55, min <= max.
- notes: one short supportive paragraph per language (en, ar, ku).
- disclaimer: one sentence per language — not medical advice; DEXA/caliper/tape methods are more accurate.

Return ONLY valid JSON:
{"min_percent":0,"max_percent":0,"confidence":"low","notes":{"en":"","ar":"","ku":""},"disclaimer":{"en":"","ar":"","ku":""}}
''';

      final geminiResult = await _postGeminiVision(
        prompt: prompt,
        imageBytes: imageBytes,
        systemInstruction:
            'You follow instructions exactly and output valid JSON only. $_systemRuleTrilingualJson '
            'The notes and disclaimer objects must each have keys en, ar, and ku with appropriate text.',
      );
      if (geminiResult != null) {
        return _sanitizeBodyFatJson(geminiResult);
      }
      return null;
    } catch (e) {
      debugPrint('AI request could not be completed.');
      return null;
    }
  }


  static Map<String, dynamic> _sanitizeBodyFatJson(Map<String, dynamic> raw) {
    double? g(String k) {
      final v = raw[k];
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString() ?? '');
    }

    var minP = g('min_percent');
    var maxP = g('max_percent');
    if (minP == null || maxP == null) return raw;
    minP = minP.clamp(3.0, 55.0);
    maxP = maxP.clamp(3.0, 55.0);
    if (minP > maxP) {
      final t = minP;
      minP = maxP;
      maxP = t;
    }
    raw['min_percent'] = minP;
    raw['max_percent'] = maxP;
    final c = raw['confidence']?.toString().toLowerCase();
    if (c != 'medium') {
      raw['confidence'] = 'low';
    } else {
      raw['confidence'] = 'medium';
    }
    return raw;
  }
}
