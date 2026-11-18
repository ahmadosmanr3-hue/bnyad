class ScanResultStrings {
  ScanResultStrings(this.lang);
  final String lang;
  String tr(String en, String ar, String ku) => lang == 'ar'
      ? ar
      : ['ku', 'ckb'].contains(lang)
      ? ku
      : en;
  String get title =>
      tr('Review your scan', 'راجع نتيجة المسح', 'ئەنجامی سکانەکە بپشکنە');
  String get mealName => tr('Meal name', 'اسم الوجبة', 'ناوی ژەم');
  String get review => tr(
    'Check identity and portions',
    'تحقق من الطعام والكميات',
    'خواردن و بڕەکان بپشکنە',
  );
  String get estimate => tr(
    'Nutrition is estimated. Confirm the preparation and edible portion. Hidden ingredients may be missing.',
    'القيم الغذائية تقديرية. أكد طريقة التحضير والكمية الصالحة للأكل؛ قد لا تظهر بعض المكونات.',
    'بەها خۆراکییەکان خەمڵاندنن. شێوازی ئامادەکردن و بڕی خواردنەوەکە پشتڕاست بکەوە؛ ڕەنگە هەندێک پێکهاتە دیار نەبێت.',
  );
  String get dish => tr('Whole dish', 'طبق كامل', 'خواردنی تەواو');
  String get components => tr('Components', 'مكونات', 'پێکهاتەکان');
  String get modeHint => tr(
    'Use a whole dish OR its individual components. No verified ingredient recipe is available for prepared dishes.',
    'استخدم الطبق الكامل أو مكوناته الفردية. لا تتوفر وصفة مكونات موثقة للأطباق الجاهزة.',
    'خواردنی تەواو یان پێکهاتەکانی بەکاربهێنە. ڕەچەتەی پێکهاتەی پشتڕاستکراوە بۆ خواردنە ئامادەکراوەکان بەردەست نییە.',
  );
  String get choose => tr('Choose food', 'اختر الطعام', 'خواردن هەڵبژێرە');
  String get add => tr('Add component', 'إضافة مكون', 'پێکهاتە زیاد بکە');
  String get change => tr('Change food', 'تغيير الطعام', 'خواردن بگۆڕە');
  String get remove => tr('Remove', 'إزالة', 'لابردن');
  String get portion => tr('Edit portion', 'تعديل الحصة', 'پشکەکە ڕێک بخە');
  String get apply => tr('Apply portion', 'تطبيق الحصة', 'پشکەکە جێبەجێ بکە');
  String get search =>
      tr('Search catalog', 'بحث في قائمة الأطعمة', 'گەڕان لە لیستی خواردن');
  String get possible => tr(
    'Possible matches · tap to choose',
    'مطابقات محتملة · اضغط للاختيار',
    'ئەگەری ناسینەوە · بۆ هەڵبژاردن پەنجە بنێ',
  );
  String get empty => tr(
    'Choose a catalog food to see nutrition. You can also build the meal from confirmed components.',
    'اختر طعاماً من القائمة لعرض التغذية، أو كوّن الوجبة من مكونات مؤكدة.',
    'بۆ بینینی بەها خۆراکییەکان خواردنێک لە لیست هەڵبژێرە؛ یان ژەمەکە لە پێکهاتە پشتڕاستکراوەکان دروست بکە.',
  );
  String get noMatches => tr(
    'No verified match. Try another name or preparation. Nothing has been logged.',
    'لا توجد مطابقة موثقة. جرّب اسماً أو تحضيراً آخر. لم يتم تسجيل شيء.',
    'هیچ هاوتایەکی پشتڕاستکراوە نەدۆزرایەوە. ناو یان شێوازێکی تر تاقی بکەوە. هیچ تۆمار نەکراوە.',
  );
  String get pending => tr(
    'Unresolved components · replace or remove',
    'مكونات غير مؤكدة · استبدلها أو أزلها',
    'پێکهاتە نادیارەکان · بگۆڕە یان لایببە',
  );
  String get confirm => tr(
    'I checked the food identities, ingredients and portions.',
    'راجعت الأطعمة والمكونات والكميات.',
    'خواردن، پێکهاتە و بڕەکانم پشکنیوە.',
  );
  String get log =>
      tr('Confirm and Log', 'تأكيد وتسجيل', 'پشتڕاستکردنەوە و تۆمارکردن');
  String get total => tr('Meal total', 'إجمالي الوجبة', 'کۆی ژەم');
  String get calories => tr('Calories', 'السعرات', 'کالۆری');
  String get protein => tr('Protein', 'بروتين', 'پرۆتین');
  String get carbs => tr('Carbs', 'كربوهيدرات', 'کاربۆهایدرات');
  String get fat => tr('Fat', 'دهون', 'چەوری');
  String get saved => tr('Meal saved', 'تم حفظ الوجبة', 'ژەمەکە تۆمارکرا');
  String get failed => tr(
    'Could not save. Check your connection and catalog, then review again. No automatic retry.',
    'تعذر الحفظ. تحقق من الاتصال والقائمة ثم راجع مجدداً. لا توجد إعادة محاولة تلقائية.',
    'تۆمار نەکرا. پەیوەندی و لیستەکە بپشکنە و دووبارە پێداچوونەوە بکە. دووبارەکردنەوەی خۆکار نییە.',
  );
  String get invalid => tr(
    'Review missing foods, duplicate components and portion limits (2500 g / 5000 mL per scan).',
    'راجع الأطعمة الناقصة والمكونات المكررة وحدود الكمية (2500 غ / 5000 مل للمسح).',
    'خواردنە نادیارەکان و پێکهاتە دووبارەکان و سنووری بڕ بپشکنە (٢٥٠٠ گرام / ٥٠٠٠ مل بۆ سکانێک).',
  );
  String get reset => tr(
    'Replace the current list?',
    'استبدال القائمة الحالية؟',
    'لیستی ئێستا بگۆڕدرێت؟',
  );
  String get cancel => tr('Cancel', 'إلغاء', 'پاشگەزبوونەوە');
  String get preview =>
      tr('Catalog estimate', 'تقدير القائمة', 'خەمڵاندنی لیست');
}
