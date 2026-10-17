package com.bnyad.app

import android.app.Activity
import android.os.Bundle
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Button
import java.util.Locale

/** Available even when Flutter is not running: Health Connect's required rationale. */
class HealthPrivacyActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val language = getSharedPreferences("bnyad_localization", MODE_PRIVATE).getString("language", null) ?: Locale.getDefault().language
        val text = when (language) {
            "ar" -> "خصوصية النشاط في BNYAD\n\nنقرأ الخطوات والمسافة الاختيارية لعرض نشاطك واقتراح أهداف تدريجية وتقدير سعرات المشي على جهازك. لا نكتب في Health Connect. لا تُرفع بيانات الصحة إلى خوادم BNYAD أو خدمات الذكاء الاصطناعي أو الإعلانات. نحفظ الإعدادات فقط لكل حساب، وليس سجلات الصحة. المسافة قد تشمل نشاطاً غير المشي؛ لذلك نحدّ التقدير باستخدام الخطوات. لا يتغير هدف السعرات الغذائية. يمكنك إيقاف الاتصال في إعدادات BNYAD وإلغاء الأذونات في Health Connect ← أذونات التطبيقات ← BNYAD."
            "ku", "ckb" -> "تایبەتمەندی چالاکی لە BNYAD\n\nهەنگاو و دووریی هەڵبژاردەیی دەخوێنینەوە بۆ پیشاندانی چالاکی، پێشنیاری ئامانجی هێواش و خەمڵاندنی کالۆریی پیاسە لەسەر ئامێرەکەت. هیچ داتایەک لە Health Connect نانووسین. داتای تەندروستی بۆ سێرڤەر، زیرەکی دەستکرد یان ڕیکلام نانێردرێت. تەنیا ڕێکخستنەکان بۆ هەر هەژمارێک پاشەکەوت دەکرێن، نەک تۆمارە تەندروستییەکان. ئامانجی کالۆریی خواردن ناگۆڕێت. دەتوانیت پەیوەندی لە ڕێکخستنەکانی BNYAD بوەستێنیت و مۆڵەتەکان لە Health Connect ← مۆڵەتی ئەپەکان ← BNYAD هەڵبوەشێنیتەوە."
            else -> "BNYAD activity privacy\n\nWith your permission, we read steps and optional distance to show daily activity, suggest gentle goals, and estimate walking calories on your device. We never write to Health Connect. Health totals and records are never uploaded to BNYAD servers, AI services, or advertising systems. Only account-specific settings are persisted, not health records. Distance may include other activities, so estimates are capped using steps. Nutrition calorie targets never change. Disconnect in BNYAD Settings to stop reading; revoke OS access in Health Connect → App permissions → BNYAD.\n\nThis supplements the app's existing privacy policy available in BNYAD Settings."
        }
        val layout = LinearLayout(this).apply {
            layoutDirection = if (language in listOf("ar", "ku", "ckb")) android.view.View.LAYOUT_DIRECTION_RTL else android.view.View.LAYOUT_DIRECTION_LTR
            orientation = LinearLayout.VERTICAL
            setPadding(32, 48, 32, 32)
            addView(TextView(this@HealthPrivacyActivity).apply { this.text = text; textSize = 17f },
                LinearLayout.LayoutParams(-1, -2))
            addView(Button(this@HealthPrivacyActivity).apply {
                this.text = when (language) { "ar" -> "إغلاق"; "ku", "ckb" -> "داخستن"; else -> "Close" }
                setOnClickListener { finish() }
            })
        }
        setContentView(android.widget.ScrollView(this).apply {
            addView(layout, android.widget.FrameLayout.LayoutParams(-1, -2))
        })
    }
}
