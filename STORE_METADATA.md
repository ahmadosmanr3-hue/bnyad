# BNYAD store metadata — release draft, 26 October 2026

These are prepared values, not evidence of a saved or published store listing.
Preserve the existing Apple bundle `com.nutrify.bnyad`, Android package
`com.bnyad.app`, app records, signing identities and short launcher name `BNYAD`.

## Both stores

Name: **BNYAD: Calorie & Macro Tracker** (30 characters).

Recommended category: Health & Fitness. Keep existing privacy/support URLs only
after checking that they are reachable and accurate. The owner approved this release with AI disabled for everyone. Do not advertise
working AI, food-photo recognition or AI meal generation in this release.

## English

Apple subtitle: `Food, nutrition & daily steps`

Apple keywords:
`calories,macros,nutrition,food diary,protein,steps,water,weight,meal tracker,Kurdish,Arabic`

Google Play short description:
`Track calories, macros, meals, water, weight and daily steps with BNYAD.`

Description:

BNYAD helps you keep track of your daily nutrition and activity in English,
Arabic and Kurdish Sorani.

- Log meals and follow your daily calorie, protein, carbohydrate and fat targets.
- Search the food database and scan supported product barcodes.
- Track water intake, weight and your daily nutrition history.
- Connect Apple Health on iPhone or Health Connect on Android to read steps,
  review a personal step goal and see estimated walking calories.
- Keep your preferred language and settings across app restarts.

Health access is optional. Android steps require a source that writes steps to
Health Connect. Walking calories are estimates and do not increase your food
calorie allowance. Some features require an account or Premium subscription.
AI features are currently disabled for everyone; Premium does not activate them
while the service is paused. BNYAD is a nutrition tracking tool and does not
provide medical advice.

## Arabic — owner wording review before saving

Keep the same requested store name.

Apple subtitle: `تتبّع الغذاء والماء والخطوات`

Google Play short description:
`تابع السعرات والمغذيات والوجبات والماء والوزن والخطوات اليومية مع BNYAD.`

Description:

يساعدك BNYAD على متابعة غذائك ونشاطك اليومي بالإنجليزية والعربية والكردية السورانية.

- سجّل وجباتك وتابع أهداف السعرات والبروتين والكربوهيدرات والدهون اليومية.
- ابحث في قاعدة بيانات الأطعمة وامسح الرموز الشريطية للمنتجات المدعومة.
- تابع شرب الماء والوزن وسجل التغذية اليومي.
- اربط Apple Health على iPhone أو Health Connect على Android لقراءة الخطوات،
  ومتابعة هدفك الشخصي وتقدير السعرات المحروقة بالمشي.
- احتفظ باللغة والإعدادات المفضلة عند إعادة فتح التطبيق.

الوصول إلى البيانات الصحية اختياري. تتطلب الخطوات على Android مصدراً يكتب
البيانات في Health Connect. السعرات المحروقة تقديرية ولا تزيد الحد اليومي
لسعرات الطعام. تتطلب بعض الميزات حساباً أو اشتراك Premium. التطبيق أداة
لمتابعة التغذية ولا يقدم نصائح طبية. ميزات الذكاء الاصطناعي معطلة للجميع حالياً،
ولا يؤدي اشتراك Premium إلى تفعيلها أثناء إيقاف الخدمة.

## Release notes

Improved barcode scanning, iPhone camera permissions, gram/mL quantity logging,
version display, notifications and Kurdish/Arabic layouts. Existing nutrition
calculations and real health step tracking are preserved. AI features are
currently disabled for everyone, including Premium subscribers.

Do not promise background notification delivery as verified until physical
device checks pass. Use screenshots from the actual release candidate, with
fictional data. Check AI/health privacy declarations against the final enabled
features. Sorani app support does not imply that App Store Connect offers a
Sorani store-localization option.

## App review notes — draft

This version intentionally keeps server-side AI disabled for every account.
Attempting an AI feature shows a localized unavailable notice; Premium does not
activate it. Do not use the local simulated-AI build as an app-review binary.
The production app contains no Gemini API key. Later AI activation is controlled
by the authenticated backend and will require suitable provider configuration,
consent and separately approved testing. Account, tracking, barcode, settings and
optional read-only health features are available independently of AI.

Use only the existing private review account credentials in the store consoles;
never place them in this file. Verify camera access, health declarations,
subscription restoration and privacy answers against the submitted signed build.
