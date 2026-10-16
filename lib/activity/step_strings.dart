import 'step_tracker.dart';

/// Separate feature vocabulary; existing app translations are unchanged.
class StepStrings {
  final String locale;
  const StepStrings(this.locale);
  bool get rtl => ['ar', 'ku', 'ckb'].contains(locale);
  String text(String key) =>
      (locale == 'ar'
          ? ar
          : rtl
          ? ku
          : en)[key] ??
      en[key] ??
      key;
  String status(StepStatus status) => text(switch (status) {
    StepStatus.disconnected => 'disconnected',
    StepStatus.loading => 'loading',
    StepStatus.waitingForForeground => 'waitingForeground',
    StepStatus.ready => 'ready',
    StepStatus.emptyOrPrivate => 'empty',
    StepStatus.denied => 'denied',
    StepStatus.unavailable => 'unavailable',
    StepStatus.installRequired => 'install',
    StepStatus.error => 'error',
  });
  static const en = {
    'waitingForeground':
        'Connection saved. Bring BNYAD to the foreground and tap Refresh to read Health data.',
    'readingDay': 'Local date being read',
    'connectionSaved':
        'Connection saved for this account. Empty or private readings do not mean you are disconnected. Refresh after Health syncs; review access in Apple Health / Health Connect if needed.',
    'burned': 'kcal burned',
    'calorieInfoTitle': 'About walking calories',
    'calorieInfo':
        'Calories burned are estimates, not measurements. They depend on your steps, available profile weight and height, and optional walking distance. Missing profile data means no estimate. Burned calories do not increase your food allowance or change nutrition targets.',
    'unit': 'kcal',
    'activity': 'Daily activity',
    'steps': 'steps',
    'goal': 'Daily step goal',
    'estimated': 'Estimated walking calories burned',
    'details': 'Step tracking',
    'demo': 'SIMULATED STEPS · DEMO ONLY',
    'connect': 'Connect Apple Health / Health Connect',
    'privacyTitle': 'Connect your own health data?',
    'privacy':
        'BNYAD reads steps and optional distance from Apple Health (iOS) or Health Connect (Android) only after your permission. Distance access is optional; steps still work without it. Daily totals and calculations stay in memory on this device, never on our backend, Gemini, AI services or advertising systems. Only settings are saved separately for this account. No health data is written and no location or background tracking is used. Connect only your own health data, especially on a shared device.',
    'allow': 'Continue to permissions',
    'cancel': 'Cancel',
    'close': 'Close',
    'disconnected': 'Not connected. Tap to set up step tracking.',
    'loading': 'Refreshing health data…',
    'ready': 'Daily aggregates from your health platform',
    'empty':
        'No readable steps. There may be no data, limited history access, or read permission may be off. Check your health app; missing data is not zero.',
    'denied':
        'Step permission is off or revoked. Review health permissions to reconnect.',
    'unavailable':
        'Health tracking is unavailable here. Use a compatible iPhone or Android device. Web previews cannot read device health data.',
    'install':
        'Health Connect needs to be installed or updated. Open health settings to continue.',
    'error':
        'Could not read health data or save settings. Try again. No previous health totals are shown as current.',
    'refresh': 'Refresh',
    'manage': 'Open health settings',
    'disconnect': 'Disconnect on this account',
    'revoke':
        'Disconnect stops BNYAD reading data for this account; it does not revoke OS permission. iOS: Health → profile → Apps and Services → BNYAD → turn off Steps and Walking + Running Distance. Android: Health Connect → App permissions → BNYAD → remove access. OS permission applies to this app on this device, not just one BNYAD account.',
    'automatic': 'Personalized goal recommendations',
    'automaticHint':
        'Suggestions only. Your goal never changes without your acceptance. Manual edits pause recommendations.',
    'manual': 'Change goal manually',
    'restore': 'Restore automatic recommendations',
    'save': 'Save',
    'range': 'Enter a whole number from 1 to 20,000.',
    'review': 'Review completed tracking days',
    'reviewHint':
        'Select only completed days when you carried your phone or wore your tracker normally and all sources have synced. Exclude partial days, travel/timezone-change days, and unusual days. At least 7 of the last 14 days are needed; today and missing days never count. A positive step total alone does not prove complete tracking.',
    'confirmDays': 'Use selected complete days',
    'noHistory': 'No readable completed days yet.',
    'historyCount': 'Confirmed complete days',
    'suggested': 'Suggested daily goal',
    'accept': 'Accept suggested goal',
    'initial': 'Conservative starting recommendation',
    'algorithm':
        'Starting goals use your activity level: 3,000 / 4,000 / 5,000 / 6,000 / 6,500 steps. After 7–14 confirmed complete days, we use their median plus 5%, limited to a 5% or 500-step change (whichever is smaller), at most once per 7 days. Recommendations stay between 1,000 and 10,000. These are optional product defaults, not medical advice.',
    'gentle':
        'A standard walking target may not fit your circumstances. Automatic increases are paused for limited mobility, under-18s, older adults or pregnancy/breastfeeding profiles. Choose any comfortable manual goal, including a low goal; ask a qualified professional if unsure.',
    'calorieNote':
        'Illustrative estimate, not a measurement: steps × estimated stride (40% of height, capped at 0.75 m), then 0.45 kcal/kg/km. Optional health distance can only reduce this conservative estimate because it may include running or other activity. Missing weight/height means no estimate. Walking calories never increase your food allowance or change TDEE, calorie or macro targets.',
    'demoNote':
        'These fictional totals are simulated for browser UI testing. This does not test HealthKit, Health Connect, device permissions, sensors or watch syncing.',
    'notAdded': 'Not added to your calorie allowance',
    'updated': 'Last refreshed',
    'enable': 'Enable recommendations',
    'settings': 'Step settings',
  };
  static const ar = {
    'waitingForeground':
        'الاتصال محفوظ. افتح BNYAD في المقدمة واضغط تحديث لقراءة بيانات الصحة.',
    'readingDay': 'التاريخ المحلي للقراءة',
    'connectionSaved':
        'الاتصال محفوظ لهذا الحساب. القراءات الفارغة أو الخاصة لا تعني انقطاع الاتصال. حدّث بعد مزامنة تطبيق الصحة، وراجع الأذونات فيه عند الحاجة.',
    'burned': 'سعرة محروقة',
    'calorieInfoTitle': 'حول سعرات المشي',
    'calorieInfo':
        'السعرات المحروقة تقديرية وليست قياساً. تعتمد على خطواتك والوزن والطول المتاحين في ملفك والمسافة الاختيارية. عند نقص بيانات الملف لا نعرض تقديراً. السعرات المحروقة لا تزيد حصتك الغذائية ولا تغيّر أهداف التغذية.',
    'unit': 'سعرة',
    'activity': 'النشاط اليومي',
    'steps': 'خطوة',
    'goal': 'هدف الخطوات اليومي',
    'estimated': 'السعرات المحروقة بالمشي — تقديرية',
    'details': 'تتبّع الخطوات',
    'demo': 'خطوات محاكاة · للعرض التجريبي فقط',
    'connect': 'ربط Apple Health / Health Connect',
    'privacyTitle': 'هل تريد ربط بياناتك الصحية؟',
    'privacy':
        'يقرأ BNYAD الخطوات والمسافة الاختيارية من Apple Health على iOS أو Health Connect على Android بعد إذنك فقط. إذن المسافة اختياري ولا يمنع عرض الخطوات. تبقى المجاميع والحسابات في ذاكرة جهازك ولا تُرسل إلى خوادمنا أو Gemini أو الذكاء الاصطناعي أو الإعلانات. تُحفظ الإعدادات فقط وبشكل منفصل لكل حساب. لا نكتب بيانات صحية ولا نتتبّع الموقع أو النشاط في الخلفية. اربط بياناتك أنت فقط، خصوصاً على جهاز مشترك.',
    'allow': 'المتابعة إلى الأذونات',
    'cancel': 'إلغاء',
    'close': 'إغلاق',
    'disconnected': 'غير متصل. اضغط لإعداد تتبّع الخطوات.',
    'loading': 'جارٍ تحديث البيانات الصحية…',
    'ready': 'مجاميع يومية من منصة الصحة على جهازك',
    'empty':
        'لا توجد خطوات قابلة للقراءة. قد لا تتوفر بيانات أو قد تكون صلاحية القراءة أو فترة السجل محدودة. تحقق من تطبيق الصحة؛ البيانات المفقودة ليست صفراً.',
    'denied': 'إذن الخطوات غير مفعّل أو أُلغي. راجع الأذونات لإعادة الاتصال.',
    'unavailable':
        'تتبّع الصحة غير متاح هنا. استخدم iPhone أو Android متوافقاً. المتصفح لا يقرأ بيانات الصحة من الجهاز.',
    'install':
        'يحتاج Health Connect إلى التثبيت أو التحديث. افتح إعدادات الصحة للمتابعة.',
    'error':
        'تعذرت قراءة بيانات الصحة أو حفظ الإعدادات. حاول مجدداً. لن نعرض المجاميع السابقة على أنها حديثة.',
    'refresh': 'تحديث',
    'manage': 'فتح إعدادات الصحة',
    'disconnect': 'فصل الاتصال لهذا الحساب',
    'revoke':
        'الفصل يوقف قراءة BNYAD لهذا الحساب ولا يلغي إذن النظام. على iOS: الصحة ← الملف الشخصي ← التطبيقات والخدمات ← BNYAD، وأوقف الخطوات ومسافة المشي والجري. على Android: Health Connect ← أذونات التطبيقات ← BNYAD ← إزالة الوصول. إذن النظام يخص التطبيق على هذا الجهاز وليس حساباً واحداً فقط.',
    'automatic': 'اقتراحات هدف خطوات مخصّص',
    'automaticHint':
        'اقتراحات فقط. لن يتغير هدفك دون قبولك. التعديل اليدوي يوقف الاقتراحات.',
    'manual': 'تعديل الهدف يدوياً',
    'restore': 'استعادة الاقتراحات التلقائية',
    'save': 'حفظ',
    'range': 'أدخل عدداً صحيحاً من 1 إلى 20,000.',
    'review': 'مراجعة أيام التتبّع المكتملة',
    'reviewHint':
        'اختر فقط الأيام المكتملة التي حملت فيها هاتفك أو ارتديت جهاز التتبّع كالمعتاد واكتملت مزامنة المصادر. استبعد الأيام الجزئية وأيام السفر أو تغيير المنطقة الزمنية والأيام غير المعتادة. نحتاج 7 أيام على الأقل من آخر 14 يوماً؛ لا يُحسب اليوم الحالي أو البيانات المفقودة. وجود خطوات لا يثبت اكتمال التتبّع.',
    'confirmDays': 'استخدام الأيام المكتملة المحددة',
    'noHistory': 'لا توجد أيام مكتملة قابلة للقراءة بعد.',
    'historyCount': 'أيام مكتملة مؤكدة',
    'suggested': 'الهدف اليومي المقترح',
    'accept': 'قبول الهدف المقترح',
    'initial': 'اقتراح بداية معتدل',
    'algorithm':
        'أهداف البداية حسب النشاط: 3,000 / 4,000 / 5,000 / 6,000 / 6,500 خطوة. بعد 7–14 يوماً مكتملاً ومؤكداً نستخدم الوسيط مع 5%، ونحدّ التغيير إلى 5% أو 500 خطوة أيهما أقل، مرة كل 7 أيام كحد أقصى. الاقتراحات بين 1,000 و10,000. هذه إعدادات اختيارية وليست نصيحة طبية.',
    'gentle':
        'قد لا يناسبك هدف مشي عام. نوقف الزيادات التلقائية عند محدودية الحركة أو لمن هم دون 18 عاماً أو كبار السن أو أثناء الحمل والرضاعة. اختر هدفاً يدوياً مريحاً ولو كان منخفضاً، واستشر مختصاً عند الحاجة.',
    'calorieNote':
        'تقدير توضيحي وليس قياساً: الخطوات × طول خطوة مقدّر (40% من الطول وبحد أقصى 0.75 متر)، ثم 0.45 سعرة/كغ/كم. المسافة الصحية الاختيارية لا تزيد التقدير لأنها قد تشمل الجري أو أنشطة أخرى. بدون وزن وطول لا نقدّر السعرات. لا تُضاف سعرات المشي إلى المسموح الغذائي ولا تغيّر TDEE أو أهداف السعرات والمغذيات.',
    'demoNote':
        'هذه أرقام وهمية لمحاكاة واجهة المتصفح فقط. لا تختبر HealthKit أو Health Connect أو أذونات الجهاز أو المستشعرات أو مزامنة الساعة.',
    'notAdded': 'لا تُضاف إلى السعرات الغذائية المسموحة',
    'updated': 'آخر تحديث',
    'enable': 'تفعيل الاقتراحات',
    'settings': 'إعدادات الخطوات',
  };
  static const ku = {
    'waitingForeground':
        'پەیوەندی پاشەکەوت کراوە. BNYAD بکەرەوە لە پێشەوە و نوێکردنەوە دابگرە بۆ خوێندنەوەی داتای تەندروستی.',
    'readingDay': 'بەرواری ناوخۆیی بۆ خوێندنەوە',
    'connectionSaved':
        'پەیوەندی بۆ ئەم هەژمارە پاشەکەوت کراوە. خوێندنەوەی بەتاڵ یان تایبەت واتای پچڕانی پەیوەندی نییە. دوای هاوکاتکردنی تەندروستی نوێی بکەرەوە؛ ئەگەر پێویست بوو مۆڵەتەکان لەوێ بپشکنە.',
    'burned': 'کالۆری سووتاو',
    'calorieInfoTitle': 'دەربارەی کالۆریی پیاسە',
    'calorieInfo':
        'کالۆریی سووتاو خەمڵاندنە، نەک پێوانە. پشت بە هەنگاوەکانت، کێش و باڵای بەردەست لە پڕۆفایلەکەت و دووریی هەڵبژاردە دەبەستێت. ئەگەر داتای پڕۆفایل نەبێت خەمڵاندن نیشان نادرێت. کالۆریی سووتاو ڕێگەپێدراوی خواردنت زیاد ناکات و ئامانجی خۆراک ناگۆڕێت.',
    'unit': 'کالۆری',
    'activity': 'چالاکی ڕۆژانە',
    'steps': 'هەنگاو',
    'goal': 'ئامانجی هەنگاوی ڕۆژانە',
    'estimated': 'کالۆری سووتاو بە پیاسە — خەمڵێنراو',
    'details': 'بەدواداچوونی هەنگاو',
    'demo': 'هەنگاوی ساختە · تەنیا بۆ دیمۆ',
    'connect': 'پەیوەستکردنی Apple Health / Health Connect',
    'privacyTitle': 'داتای تەندروستی خۆت پەیوەست دەکەیت؟',
    'privacy':
        'BNYAD تەنیا بە مۆڵەتی تۆ هەنگاو و دووریی هەڵبژاردەیی لە Apple Health بۆ iOS یان Health Connect بۆ Android دەخوێنێتەوە. مۆڵەتی دووری هەڵبژاردەییە و هەنگاو بێ ئەویش کار دەکات. کۆی ڕۆژانە و ژماردنەکان لە بیرگەی ئامێرەکەت دەمێننەوە؛ بۆ سێرڤەر، Gemini، زیرەکی دەستکرد یان ڕیکلام نانێردرێن. تەنیا ڕێکخستنەکان بۆ هەر هەژمارێک جیا پاشەکەوت دەکرێن. هیچ داتایەکی تەندروستی نانووسین و شوێن یان چالاکی لە پاشبنەما ناپشکنین. تەنیا داتای خۆت پەیوەست بکە، بە تایبەتی لە ئامێری هاوبەشدا.',
    'allow': 'بەردەوامبە بۆ مۆڵەتەکان',
    'cancel': 'هەڵوەشاندنەوە',
    'close': 'داخستن',
    'disconnected': 'پەیوەست نییە. بۆ ڕێکخستنی هەنگاو دایبگرە.',
    'loading': 'نوێکردنەوەی داتای تەندروستی…',
    'ready': 'کۆی ڕۆژانە لە پلاتفۆرمی تەندروستیی ئامێرەکەت',
    'empty':
        'هەنگاوی خوێندنەوە نییە. ڕەنگە داتا نەبێت، مێژوو سنووردار بێت یان مۆڵەتی خوێندنەوە داخراو بێت. ئەپی تەندروستی بپشکنە؛ داتای نەبوو بە سفر دانانرێت.',
    'denied': 'مۆڵەتی هەنگاو داخراوە یان هەڵوەشاوەتەوە. مۆڵەتەکان بپشکنە.',
    'unavailable':
        'بەدواداچوونی تەندروستی لێرە بەردەست نییە. iPhone یان Android ـێکی گونجاو بەکاربهێنە. وێب ناتوانێت داتای تەندروستیی ئامێر بخوێنێتەوە.',
    'install':
        'Health Connect پێویستی بە دامەزراندن یان نوێکردنەوە هەیە. ڕێکخستنی تەندروستی بکەرەوە.',
    'error':
        'نەتوانرا داتای تەندروستی بخوێندرێتەوە یان ڕێکخستن پاشەکەوت بکرێت. دووبارە هەوڵبدەرەوە. کۆی کۆن وەک داتای نوێ پیشان نادرێت.',
    'refresh': 'نوێکردنەوە',
    'manage': 'کردنەوەی ڕێکخستنی تەندروستی',
    'disconnect': 'پچڕاندنی پەیوەندی بۆ ئەم هەژمارە',
    'revoke':
        'پچڕاندن خوێندنەوە بۆ ئەم هەژمارە دەوەستێنێت، بەڵام مۆڵەتی سیستەم هەڵناوەشێنێتەوە. لە iOS: Health ← پرۆفایل ← Apps and Services ← BNYAD، هەنگاو و دووریی پیاسە و ڕاکردن دابخە. لە Android: Health Connect ← مۆڵەتی ئەپەکان ← BNYAD ← لابردنی دەستگەیشتن. مۆڵەتی سیستەم بۆ ئەپەکەیە لەم ئامێرە، نەک تەنیا یەک هەژمار.',
    'automatic': 'پێشنیاری ئامانجی هەنگاوی تایبەت',
    'automaticHint':
        'تەنیا پێشنیارە. ئامانجەکەت بێ ڕەزامەندی تۆ ناگۆڕێت. دەستکاریکردنی دەستی پێشنیارەکان دەوەستێنێت.',
    'manual': 'گۆڕینی دەستیی ئامانج',
    'restore': 'گەڕاندنەوەی پێشنیارە خۆکارەکان',
    'save': 'پاشەکەوتکردن',
    'range': 'ژمارەیەکی تەواو لە 1 تا 20,000 بنووسە.',
    'review': 'پێداچوونەوە بە ڕۆژە تەواوەکان',
    'reviewHint':
        'تەنیا ئەو ڕۆژە تەواوانە هەڵبژێرە کە بە ئاسایی مۆبایل یان ئامێری بەدواداچوونت پێ بووە و هەموو سەرچاوەکان هاوکات کراون. ڕۆژی ناتەواو، گەشت، گۆڕینی کاتی ناوچە و ڕۆژی نائاسایی هەڵمەبژێرە. لانیکەم 7 ڕۆژ لە کۆتا 14 ڕۆژ پێویستە؛ ئەمڕۆ و داتای نەبوو هەژمار ناکرێن. بوونی هەنگاو بەڵگەی تەواوی بەدواداچوون نییە.',
    'confirmDays': 'بەکارهێنانی ڕۆژە تەواوە هەڵبژێردراوەکان',
    'noHistory': 'هێشتا ڕۆژی تەواوی خوێندنەوە نییە.',
    'historyCount': 'ڕۆژە تەواوە پشتڕاستکراوەکان',
    'suggested': 'ئامانجی ڕۆژانەی پێشنیارکراو',
    'accept': 'پەسەندکردنی ئامانجی پێشنیارکراو',
    'initial': 'پێشنیاری هێواش بۆ دەستپێک',
    'algorithm':
        'ئامانجی دەستپێک بە ئاستی چالاکی: 3,000 / 4,000 / 5,000 / 6,000 / 6,500 هەنگاو. دوای 7–14 ڕۆژی تەواوی پشتڕاستکراوە، ناوەڕاستی ژمارەکان لەگەڵ 5% بەکاردەهێنین. گۆڕانکاری زیاتر لە 5% یان 500 هەنگاو نابێت، هەرکامیان کەمتر بێت، و زۆرترین جارێک لە 7 ڕۆژدا. پێشنیارەکان لە 1,000 تا 10,000 ـن. ئەمانە هەڵبژاردەی ئەپن، نەک ڕێنمایی پزیشکی.',
    'gentle':
        'ڕەنگە ئامانجی گشتیی پیاسە بۆ تۆ گونجاو نەبێت. زیادکردنی خۆکار بۆ سنوورداری جووڵە، تەمەنی خوار 18، بەساڵاچووان یان دووگیانی و شیردان ڕاوەستاوە. ئامانجێکی دەستی و ئاسوودە هەڵبژێرە، تەنانەت ئەگەر کەم بێت. ئەگەر دڵنیا نیت پرسیار لە پسپۆڕ بکە.',
    'calorieNote':
        'خەمڵاندنێکی نموونەییە، نەک پێوانە: هەنگاو × درێژی هەنگاوی خەمڵێنراو (40%ی باڵا، زۆرترین 0.75 مەتر)، پاشان 0.45 کالۆری/کگ/کم. دووریی تەندروستی تەنیا دەتوانێت خەمڵاندن کەم بکات چونکە ڕەنگە ڕاکردن یان چالاکی تر لەخۆبگرێت. بێ کێش و باڵا کالۆری خەمڵێنراو نییە. کالۆریی پیاسە ئاستی ڕێگەپێدراوی خواردن زیاد ناکات و TDEE، ئامانجی کالۆری یان ماکرۆ ناگۆڕێت.',
    'demoNote':
        'ئەم ژمارە ساختانە تەنیا بۆ تاقیکردنەوەی ڕووکار لە وێبن. HealthKit، Health Connect، مۆڵەتی ئامێر، هەستەوەر یان هاوکاتکردنی کاتژمێر تاقی ناکەنەوە.',
    'notAdded': 'بۆ کالۆریی ڕێگەپێدراوی خواردن زیاد ناکرێت',
    'updated': 'کۆتا نوێکردنەوە',
    'enable': 'چالاککردنی پێشنیارەکان',
    'settings': 'ڕێکخستنەکانی هەنگاو',
  };
}
