/// Consent/error strings are deliberately local, never provider-controlled.
class AiStrings {
  static const translations = {
    'en': {
      'availabilityChecking': 'Checking AI service availability…',
      'premiumAiPaused':
          'AI features are currently disabled for everyone. A Premium subscription does not enable AI while the service is paused. Other available features remain unchanged.',
      'availabilityUnknown':
          'AI availability could not be checked. A Premium subscription does not guarantee that AI services are available.',
      'disabled':
          'AI features are currently paused by BNYAD. Basic tracking remains available.',
      'configuration':
          'BNYAD AI needs a service configuration update. Please contact support.',
      'serviceUpdate':
          'The AI service needs an update. Please contact BNYAD support.',
      'providerQuota':
          'The AI provider has reached its current request allowance. Please try later.',
      'rateLimit': 'Too many AI requests. Wait a minute before trying again.',
      'dailyLimit':
          'Your daily AI allowance is used up. It resets at midnight UTC.',
      'budgetLimit':
          'AI is paused because the monthly spending safeguard was reached. Please contact support.',
      'bodyNotice':
          'Optional body-photo analysis also sends the measurement-derived body-fat estimate, but not your raw measurements. Photo location metadata is removed on the server before Google receives it.',
      'title': 'Optional Google AI features',
      'notice':
          'With your permission, BNYAD sends your selected photo or ingredient/meal text, nutrition targets and cooking preferences to Google Gemini to estimate food or suggest recipes. Your name, phone, account ID, medications and detailed medical history are not sent. Photos are not stored by BNYAD; validated recipe results may be cached privately for up to 24 hours. Google handles the data under the configured service terms. AI can misidentify food and allergens; results are estimates, not medical advice. Check ingredients, labels, cooking safety and portions before use. You can revoke permission in Settings. Basic tracking works without AI.',
      'allow': 'Allow optional AI sharing',
      'decline': 'Not now',
      'revoke': 'Revoke Google AI permission',
      'revoked': 'AI permission revoked. Cached AI results were removed.',
      'confirm': 'Confirm estimated ingredients and portions',
      'estimate':
          'AI estimate — review ingredient identity, allergens and portions before saving. Not medical advice.',
      'review': 'I checked the ingredients and portions',
      'failed': 'AI could not complete this request. Please try again.',
      'signIn': 'Sign in to use AI.',
      'consentRequired': 'Allow optional Google AI sharing before continuing.',
      'notAuthorized':
          'AI requires current permission and an active premium subscription.',
      'quota':
          'AI usage, rate or spending limit reached. Please try later; daily allowances reset at midnight UTC.',
      'tooLarge': 'Choose a smaller JPEG or PNG image (maximum 1 MB).',
      'invalidResult':
          'AI could not produce a safe, valid result for these ingredients and preferences. Try simple ingredient names or review your profile.',
      'unavailable':
          'AI is not enabled or is temporarily unavailable. Your saved data is unchanged.',
    },
    'ar': {
      'availabilityChecking': 'جارٍ التحقق من توفر خدمة الذكاء الاصطناعي…',
      'premiumAiPaused':
          'ميزات الذكاء الاصطناعي معطلة للجميع حالياً. لا يؤدي اشتراك Premium إلى تفعيلها أثناء إيقاف الخدمة. تبقى الميزات الأخرى المتاحة دون تغيير.',
      'availabilityUnknown':
          'تعذر التحقق من توفر الذكاء الاصطناعي. لا يضمن اشتراك Premium توفر خدمات الذكاء الاصطناعي.',
      'disabled':
          'أوقف بنياد ميزات الذكاء الاصطناعي مؤقتاً. يبقى التتبع الأساسي متاحاً.',
      'configuration':
          'تحتاج خدمة الذكاء الاصطناعي في بنياد إلى تحديث إعداداتها. يرجى التواصل مع الدعم.',
      'serviceUpdate':
          'تحتاج خدمة الذكاء الاصطناعي إلى تحديث. يرجى التواصل مع دعم بنياد.',
      'providerQuota':
          'بلغ مزود الذكاء الاصطناعي الحد المتاح للطلبات حالياً. حاول لاحقاً.',
      'rateLimit': 'طلبات الذكاء الاصطناعي كثيرة. انتظر دقيقة ثم حاول مجدداً.',
      'dailyLimit':
          'استهلكت الحد اليومي للذكاء الاصطناعي. يتجدد عند منتصف الليل بتوقيت UTC.',
      'budgetLimit':
          'توقف الذكاء الاصطناعي لبلوغ حد الإنفاق الشهري. تواصل مع الدعم.',
      'bodyNotice':
          'يرسل تحليل صورة الجسم الاختياري تقدير نسبة الدهون المستند إلى القياسات، لا القياسات الخام. يحذف الخادم بيانات موقع الصورة قبل إرسالها إلى Google.',
      'title': 'ميزات Google AI الاختيارية',
      'notice':
          'بموافقتك، يرسل بنياد الصورة التي تختارها أو نص المكونات والوجبة وأهداف التغذية وتفضيلات الطبخ إلى Google Gemini لتقدير الطعام واقتراح وصفات. لا نرسل اسمك أو هاتفك أو رقم حسابك أو أدويتك أو تاريخك الطبي المفصل. لا يحتفظ بنياد بالصور؛ قد تُحفظ نتائج الوصفات مؤقتاً وبشكل خاص لمدة تصل إلى ٢٤ ساعة. تعالج Google البيانات وفق شروط الخدمة المهيأة. قد يخطئ الذكاء الاصطناعي في تحديد الطعام ومسببات الحساسية؛ النتائج تقديرية وليست نصيحة طبية. تحقق من المكونات والملصقات وسلامة الطبخ والكميات قبل الاستخدام. يمكنك سحب الموافقة من الإعدادات. التتبع الأساسي لا يحتاج إلى الذكاء الاصطناعي.',
      'allow': 'أوافق على المشاركة الاختيارية',
      'decline': 'ليس الآن',
      'revoke': 'سحب موافقة Google AI',
      'revoked': 'تم سحب الموافقة وحذف نتائج الذكاء الاصطناعي المؤقتة.',
      'confirm': 'تأكيد المكونات والكميات التقديرية',
      'estimate':
          'تقدير بالذكاء الاصطناعي — راجع المكونات والحساسية والكميات قبل الحفظ. ليس نصيحة طبية.',
      'review': 'راجعت المكونات والكميات',
      'failed': 'تعذر إكمال الطلب. حاول مرة أخرى.',
      'signIn': 'سجّل الدخول لاستخدام الذكاء الاصطناعي.',
      'consentRequired':
          'وافق على مشاركة البيانات الاختيارية مع Google AI أولاً.',
      'notAuthorized':
          'يتطلب الذكاء الاصطناعي موافقة سارية واشتراكاً مميزاً نشطاً.',
      'quota':
          'تم بلوغ حد الاستخدام أو الطلبات أو الإنفاق. حاول لاحقاً؛ يتجدد الحد اليومي عند منتصف الليل بتوقيت UTC.',
      'tooLarge': 'اختر صورة JPEG أو PNG أصغر من ١ ميغابايت.',
      'invalidResult':
          'تعذر إنشاء نتيجة آمنة وصحيحة لهذه المكونات والتفضيلات. استخدم أسماء مكونات بسيطة أو راجع ملفك.',
      'unavailable':
          'الذكاء الاصطناعي غير مفعل أو غير متاح مؤقتاً. لم تتغير بياناتك المحفوظة.',
    },
    'ku': {
      'availabilityChecking':
          'بەردەستبوونی خزمەتگوزاریی زیرەکی دەستکرد دەپشکنرێت…',
      'premiumAiPaused':
          'تایبەتمەندییەکانی زیرەکی دەستکرد ئێستا بۆ هەمووان ناچالاکن. بەشداریی Premium لە کاتی ڕاگرتنی خزمەتگوزارییەکەدا چالاکیان ناکات. تایبەتمەندییە بەردەستەکانی تر وەک خۆیان دەمێننەوە.',
      'availabilityUnknown':
          'بەردەستبوونی زیرەکی دەستکرد نەپشکنرا. بەشداریی Premium بەڵێنی بەردەستبوونی خزمەتگوزارییەکانی زیرەکی دەستکرد نادات.',
      'disabled':
          'بنیاد تایبەتمەندییەکانی زیرەکیی دەستکردی کاتی ڕاگرتووە. تۆمارکردنی ئاسایی بەردەستە.',
      'configuration':
          'خزمەتگوزاریی زیرەکیی دەستکردی بنیاد پێویستی بە نوێکردنەوەی ڕێکخستنەکانە. پەیوەندی بە پشتگیرییەوە بکە.',
      'serviceUpdate':
          'خزمەتگوزاریی زیرەکیی دەستکرد پێویستی بە نوێکردنەوەیە. پەیوەندی بە پشتگیریی بنیادەوە بکە.',
      'providerQuota':
          'دابینکەری زیرەکیی دەستکرد گەیشتووەتە سنووری ئێستای داواکارییەکان. دواتر هەوڵ بدەوە.',
      'rateLimit':
          'داواکارییەکانی زیرەکیی دەستکرد زۆرن. خولەکێک چاوەڕێ بکە و دووبارە هەوڵ بدەوە.',
      'dailyLimit':
          'سنووری ڕۆژانەی زیرەکیی دەستکردت بەکارهێناوە. لە نیوەشەوی UTC نوێ دەبێتەوە.',
      'budgetLimit':
          'زیرەکیی دەستکرد بەهۆی گەیشتن بە سنووری خەرجیی مانگانە ڕاگیراوە. پەیوەندی بە پشتگیرییەوە بکە.',
      'bodyNotice':
          'شیکردنەوەی هەڵبژاردەیی وێنەی لەش، خەملاندنی ڕێژەی چەوریی لەش دەنێرێت، نە پێوانە خامەکان. سێرڤەر زانیاریی شوێنی وێنەکە پێش ناردن بۆ Google دەسڕێتەوە.',
      'title': 'تایبەتمەندییە هەڵبژاردەییەکانی Google AI',
      'notice':
          'بە ڕەزامەندیی تۆ، بنیاد وێنەی هەڵبژێردراو یان دەقی پێکهاتە و ژەم، ئامانجە خۆراکییەکان و حەزەکانی چێشتلێنان دەنێرێت بۆ Google Gemini بۆ خەملاندنی خواردن و پێشنیاری ڕێچکە. ناو، ژمارەی تەلەفۆن، ناسنامەی هەژمار، دەرمان و وردەکاریی مێژووی پزیشکیت نانێردرێن. بنیاد وێنەکان هەڵناگرێت؛ ئەنجامی ڕێچکەکان لەوانەیە بە تایبەتی تا ٢٤ کاتژمێر کاتی هەڵبگیرێن. Google بەپێی مەرجەکانی خزمەتگوزاریی ڕێکخراو مامەڵە لەگەڵ داتاکان دەکات. زیرەکیی دەستکرد لەوانەیە خواردن و ماددە هەستیاری‌هێنەرەکان بە هەڵە بناسێتەوە؛ ئەنجامەکان خەملاندنن، نە ئامۆژگاریی پزیشکی. پێکهاتە، لیبڵ، سەلامەتیی چێشتلێنان و بڕەکان بپشکنە. دەتوانیت لە ڕێکخستنەکان ڕەزامەندییەکەت بکشێنیتەوە. تۆمارکردنی ئاسایی پێویستی بە زیرەکیی دەستکرد نییە.',
      'allow': 'ڕازیم بە ناردنی هەڵبژاردەیی',
      'decline': 'ئێستا نا',
      'revoke': 'کشاندنەوەی ڕەزامەندیی Google AI',
      'revoked': 'ڕەزامەندی کشایەوە و ئەنجامە کاتییەکان سڕانەوە.',
      'confirm': 'پشتڕاستکردنەوەی پێکهاتە و بڕە خەمڵێنراوەکان',
      'estimate':
          'خەملاندنی زیرەکیی دەستکرد — پێکهاتە، هەستیاری و بڕەکان پێش هەڵگرتن بپشکنە. ئامۆژگاریی پزیشکی نییە.',
      'review': 'پێکهاتە و بڕەکانم پشکنیوە',
      'failed': 'داواکارییەکە تەواو نەکرا. تکایە دووبارە هەوڵ بدەوە.',
      'signIn': 'بۆ بەکارهێنانی زیرەکیی دەستکرد بچۆ ژوورەوە.',
      'consentRequired':
          'سەرەتا ڕەزامەندی بۆ ناردنی هەڵبژاردەیی بۆ Google AI بدە.',
      'notAuthorized': 'ڕەزامەندیی کارا و بەشداریی پریمیەمی کارا پێویستن.',
      'quota':
          'گەیشتوویتەتە سنووری بەکارهێنان، داواکاری یان خەرجی. دواتر هەوڵ بدەوە؛ سنووری ڕۆژانە لە نیوەشەوی UTC نوێ دەبێتەوە.',
      'tooLarge': 'وێنەیەکی JPEG یان PNG بچووکتر لە ١ مێگابایت هەڵبژێرە.',
      'invalidResult':
          'ئەنجامێکی سەلامەت و دروست بۆ ئەم پێکهاتانە و حەزانە بەدەست نەهات. ناوی سادەی پێکهاتەکان بنووسە یان پرۆفایلەکەت بپشکنە.',
      'unavailable':
          'زیرەکیی دەستکرد کارا نییە یان کاتێکی کەم بەردەست نییە. داتای هەڵگیراوت نەگۆڕاوە.',
    },
  };
  static String get(String lang, String key) =>
      (translations[lang == 'ckb' ? 'ku' : lang] ?? translations['en']!)[key] ??
      translations['en']!['failed']!;
}
