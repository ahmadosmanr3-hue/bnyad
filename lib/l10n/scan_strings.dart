/// Camera and verified label units, shared by all three scanner flows.
class ScanStrings {
  String get chooseBasis => _pick(
    'Choose the unit printed on the label',
    'اختر الوحدة المكتوبة على الملصق',
    'ئەو یەکەیە هەڵبژێرە کە لە لیبڵەکە نووسراوە',
  );
  String get torch => _pick('Flashlight', 'المصباح', 'فلاش');
  final String lang;
  const ScanStrings(this.lang);
  String _pick(String en, String ar, String ku) => lang == 'ar'
      ? ar
      : (lang == 'ku' || lang == 'ckb')
      ? ku
      : en;
  String get cameraDenied => _pick(
    'Camera access is off. Allow access in Settings to take food photos or scan barcodes.',
    'الوصول إلى الكاميرا متوقف. اسمح به في الإعدادات لتصوير الطعام أو مسح الباركود.',
    'دەستگەیشتن بە کامێرا ناچالاکە. لە ڕێکخستنەکان ڕێگەی پێ بدە بۆ وێنەگرتنی خواردن یان سکانکردنی بارکۆد.',
  );
  String get cameraRestricted => _pick(
    'Camera access is restricted by this device. Check Screen Time or device-management restrictions.',
    'الوصول إلى الكاميرا مقيّد على هذا الجهاز. تحقق من قيود مدة استخدام الجهاز أو إدارة الجهاز.',
    'دەستگەیشتن بە کامێرا لەم ئامێرەدا سنووردارە. سنوورەکانی کاتی بەکارهێنان یان بەڕێوەبردنی ئامێر بپشکنە.',
  );
  String get settings =>
      _pick('Open Settings', 'فتح الإعدادات', 'کردنەوەی ڕێکخستنەکان');
  String get quantity => _pick('Quantity', 'الكمية', 'بڕ');
  String get basis => _pick(
    'Nutrition label basis',
    'أساس القيم الغذائية على الملصق',
    'بنەمای بەها خۆراکییەکانی لیبڵ',
  );
  String get per100g => _pick('Per 100 g', 'لكل ١٠٠ غ', 'بۆ هەر ١٠٠ گرام');
  String get per100ml =>
      _pick('Per 100 mL', 'لكل ١٠٠ مل', 'بۆ هەر ١٠٠ میلیلیتر');
  String get grams => _pick('g', 'غ', 'گرام');
  String get ml => _pick('mL', 'مل', 'میلیلیتر');
  String get liters => _pick('L', 'لتر', 'لیتر');
  String get checkLabel => _pick(
    'Check the product name, label basis and nutrition before logging. Database information may be incomplete or incorrect.',
    'تحقق من اسم المنتج وأساس الملصق والقيم الغذائية قبل التسجيل. قد تكون بيانات قاعدة الأطعمة ناقصة أو غير دقيقة.',
    'پێش تۆمارکردن ناوی بەرهەم و بنەمای لیبڵ و بەها خۆراکییەکان بپشکنە. زانیارییەکانی بنکەکە لەوانەیە ناتەواو یان هەڵە بن.',
  );
  String get editLabel =>
      _pick('Edit label values', 'تعديل قيم الملصق', 'دەستکاری بەهاکانی لیبڵ');
  String get productName => _pick('Product name', 'اسم المنتج', 'ناوی بەرهەم');
  String get invalidNutrition => _pick(
    'Enter a name and valid non-negative label values. Check the units and portion size.',
    'أدخل اسماً وقيماً صحيحة غير سالبة. تحقق من الوحدات وحجم الحصة.',
    'ناوێک و بەهای دروستی نەنەرێنی بنووسە. یەکەکان و قەبارەی پۆرشنەکە بپشکنە.',
  );
  String get volumeNeedsLabel => _pick(
    'Volume and weight are different. Select the basis printed on this product’s label; no density conversion is assumed.',
    'الحجم والوزن مختلفان. اختر الأساس المكتوب على ملصق المنتج؛ لا نفترض تحويلاً حسب الكثافة.',
    'قەبارە و کێش جیاوازن. ئەو بنەمایە هەڵبژێرە کە لە لیبڵی بەرهەمەکە نووسراوە؛ هیچ گۆڕینێک بە چڕی بە خۆکار ناکرێت.',
  );
}
