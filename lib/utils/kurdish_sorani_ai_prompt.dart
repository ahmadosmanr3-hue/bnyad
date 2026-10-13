/// Shared Groq/LLM instructions for accurate Kurdish Sorani (Central Kurdish).
///
/// The app locale `ku` = Sorani in Arabic/Persian script (ISO 639-3: ckb).
/// These rules are appended to system prompts wherever JSON includes a `"ku"` key
/// or the active UI language is Kurdish.
class KurdishSoraniAiPrompt {
  KurdishSoraniAiPrompt._();

  static const languageName =
      'Kurdish Sorani — کوردی سورانی (Central Kurdish, Iraq/Kurdistan, Arabic/Persian script only)';

  /// Orthography, vocabulary, and style for every `"ku"` field in AI JSON output.
  static const kuFieldRules = '''
KURDISH SORANI ("ku" key) — MANDATORY RULES:

1) DIALECT & SCRIPT
- Central Kurdish Sorani only (Iraqi Kurdistan / Sorani standard).
- Arabic/Persian script ONLY. NEVER Latin letters.
- NOT Kurmanji (Northern Kurdish: xwarin, nan, goşt, pê).
- NOT Turkish, NOT Arabic-only phrasing when a Sorani word exists.

2) CORRECT SORANI LETTERS (use these, not Arabic-keyboard defaults)
- ە schwa: قیمە، بامیە، کوبە، ماست
- ێ ê: تەشرێب، شەربەت، گێشت (when needed)
- ۆ o: شۆربا، گۆشت (note و vs ۆ)
- ک (Persian kaf) — NEVER ك
- ی (Persian ya) — NEVER ي in Sorani text
- گ، ڵ، ڕ، ژ، ڤ، پ، چ

3) EZAFE (ـی / ی)
- Attach ezafe naturally: دۆڵمەی کوردی، کوبەی حەلەب، شۆربای نیسک، شاوەرمەی مریشک، نانی بەیانی

4) AUTHENTIC FOOD NAMES — match this register (home / market Sorani):
Dishes: دۆڵمەی کوردی، بریانی کوردی، کوبە، تەشرێب، نانی کوردی، تەپسی باتنجان، پاچە، قیمە، فاسولیا، بامیە، شۆربای نیسک، یەپراخ، ماستاو، شاوەرمەی مریشک، مەنسەف، کونافە
Ingredients: برنج، گۆشت، مریشک، ماسی، پەنیر، ماست، ڕۆن، پیاز، سیر، سەوزە، ترێ، هێلکە، نیسک، لۆبیا، بادنجان، سەوزەوات
Meals: نانی بەیانی، نانی نیوەڕۆ، نانی ئێوارە، خاو، چەرەزات

5) COMMON MISTAKES TO AVOID
- Wrong: "تشريب" / missing ە → Correct: "تەشرێب"
- Wrong: "كبە" with ك → Correct: "کوبە"
- Wrong: "dolma" or "Dolma" inside ku → Correct: "دۆڵمەی کوردی"
- Wrong: copying English in ku → translate naturally
- Wrong: formal Arabic-only labels → use Sorani: "مریشک" not only "دجاج" in ku text

6) INGREDIENTS & STEPS
- Short, practical, everyday Sorani a home cook in Kurdistan would use.
- Quantities: "٢ پێڵگە پیاز", "٣٠٠ گرام برنج", "١ کۆسە ماست" — natural mixed numerals OK.''';

  static const userReminder =
      '\n\n— پێویست: هەموو دەقەکانی "ku" بە کوردی سورانی ڕاستنووس بن (ئەلفوبێی عەرەبی/فارسی)، بە ڕێنووسی ڕاست و ناوە ڕەسەنی خواردن. هەرگیز Latini/Kurmanji یان ئینگلیزی لەناو "ku" مەنووسە.';

  static const cuisineFocus = '''
Cuisine focus — Kurdish Sorani (کوردی سورانی):
Prioritize authentic Kurdish dishes and ingredients from Kurdistan/Iraq: برنج، گۆشت، مریشک، ماسی، دۆڵما، کوبە، قیمە، تەشرێب، یەپراخ، شۆربا، نان، ماست، پەنیر، سەوزە، پیاز، ڕۆن.
Meal names in the "ku" key MUST use correct Sorani spelling (see examples in language rules).''';

  /// When the whole JSON response is Kurdish-only (shopping list, etc.).
  static String userFacingOnlyRule() => '''
CRITICAL OUTPUT LANGUAGE: Every user-visible string in your JSON must be Sorani Kurdish only — Arabic/Persian script, natural home register.
$kuFieldRules''';

  /// Appended to trilingual system rules (meals, scanner, recipes, etc.).
  static String trilingualKuAppendix() => '''
For the "ku" JSON key specifically:
$kuFieldRules''';

  /// System line for health tips / body-fat notes where en+ar+ku are parallel.
  static String trilingualHealthSystemRule() =>
      'You are a helpful and extremely concise health assistant. '
      'Output valid JSON only. Keys must be en, ar, ku. '
      'Translate the SAME substance into each language. '
      'The "ku" value must follow Sorani rules:\n$kuFieldRules';

  /// Parallel ingredient/instruction arrays — each language must be native, not English copies.
  static String trilingualParallelArraysRule(String activeLangLabel) => '''
TRILINGUAL ARRAYS — MANDATORY (ingredients & instructions):
- ingredients.en / instructions.en → English ONLY.
- ingredients.ar / instructions.ar → Arabic ONLY (natural MSA or Iraqi Arabic).
- ingredients.ku / instructions.ku → Kurdish Sorani ONLY (Arabic/Persian script, correct spelling).
- NEVER put English text inside ar or ku arrays. NEVER leave ar or ku empty or as duplicates of en.
- User app language: $activeLangLabel — that language's arrays must be especially natural and complete.
For "ku" arrays specifically:
$kuFieldRules''';
}
