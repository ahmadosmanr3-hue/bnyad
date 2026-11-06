import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutrify/l10n/localized_numbers.dart';

typedef MealPhotoReview = (Uint8List, Uint8List?, Map<String, double>);
Future<MealPhotoReview?> showMealPhotoReview(
  BuildContext context, {
  required Uint8List initial,
  required ImageSource source,
  required ImagePicker picker,
  required String lang,
}) => showModalBottomSheet<MealPhotoReview>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _MealPhotoReview(
    initial: initial,
    source: source,
    picker: picker,
    lang: lang,
  ),
);

class _MealPhotoReview extends StatefulWidget {
  const _MealPhotoReview({
    required this.initial,
    required this.source,
    required this.picker,
    required this.lang,
  });
  final Uint8List initial;
  final ImageSource source;
  final ImagePicker picker;
  final String lang;
  @override
  State<_MealPhotoReview> createState() => _MealPhotoReviewState();
}

class _MealPhotoReviewState extends State<_MealPhotoReview> {
  late Uint8List top = widget.initial;
  Uint8List? side;
  bool picking = false, photoError = false;
  String? measureError;
  final measurements = {
    for (final key in ['capacityMl', 'depthCm', 'foodGrams'])
      key: TextEditingController(),
  };
  String tr(String en, String ar, String ku) => widget.lang == 'ar'
      ? ar
      : widget.lang == 'ku'
      ? ku
      : en;
  @override
  void dispose() {
    for (final controller in measurements.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext sheetContext) {
    Future<void> pick(bool second) async {
      setState(() {
        picking = true;
        photoError = false;
      });
      try {
        final photo = await widget.picker.pickImage(
          source: widget.source,
          maxWidth: 800,
          maxHeight: 1200,
          requestFullMetadata: false,
          imageQuality: 70,
        );
        if (photo != null) {
          final bytes = await photo.readAsBytes();
          if (sheetContext.mounted) {
            setState(() {
              if (second) {
                side = bytes;
              } else {
                top = bytes;
              }
            });
          }
        }
      } catch (_) {
        if (sheetContext.mounted) setState(() => photoError = true);
      } finally {
        if (sheetContext.mounted) setState(() => picking = false);
      }
    }

    final tooLarge = top.length + (side?.length ?? 0) > 1048576;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * .85,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr(
                  'Review the same meal',
                  'مراجعة الوجبة نفسها',
                  'پێداچوونەوەی هەمان ژەم',
                ),
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Image.memory(
                top,
                height: 160,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
              ),
              TextButton(
                onPressed: picking ? null : () => pick(false),
                child: Text(
                  tr(
                    'Retake top photo',
                    'إعادة صورة الأعلى',
                    'وێنەی سەرەوە دووبارە بگرە',
                  ),
                ),
              ),
              if (side != null) ...[
                Image.memory(
                  side!,
                  height: 160,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
                Wrap(
                  children: [
                    TextButton(
                      onPressed: picking ? null : () => pick(true),
                      child: Text(
                        tr(
                          'Retake side photo',
                          'إعادة الصورة الجانبية',
                          'وێنەی تەنیشت دووبارە بگرە',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: picking
                          ? null
                          : () => setState(() => side = null),
                      child: Text(tr('Remove', 'إزالة', 'لابردن')),
                    ),
                  ],
                ),
              ] else
                OutlinedButton.icon(
                  onPressed: picking ? null : () => pick(true),
                  icon: const Icon(Icons.add_a_photo),
                  label: Text(
                    tr(
                      'Optional side photo',
                      'صورة جانبية اختيارية',
                      'وێنەی تەنیشت بە ئارەزوو',
                    ),
                  ),
                ),
              Text(
                tr(
                  'One or both chosen photos are sent through BNYAD to Google Gemini for the same meal. Photos cannot establish exact weight or volume. Confirm ingredients and measured portions before saving.',
                  'ترسل الصورة أو الصورتان المختارتان عبر بنياد إلى Google Gemini لتحليل الوجبة نفسها. لا تحدد الصور الوزن أو الحجم بدقة. أكد المكونات والكميات المقاسة قبل الحفظ.',
                  'یەک یان هەردوو وێنەی هەڵبژێردراو لە ڕێگەی BNYAD بۆ Google Gemini دەنێردرێن بۆ هەمان ژەم. وێنە کێش و قەبارە بە وردی دیاری ناکات. پێش پاشەکەوتکردن پێکهاتە و پشکی پێوانەکراو پشتڕاست بکەرەوە.',
                ),
              ),
              Text(
                tr(
                  'Optional measurements shared with Google',
                  'قياسات اختيارية ترسل إلى Google',
                  'پێوانەی ئارەزوومەندانە کە بۆ Google دەنێردرێت',
                ),
              ),
              ...measurements.entries.map(
                (entry) => TextField(
                  controller: entry.value,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: switch (entry.key) {
                      'capacityMl' => tr(
                        'Container capacity (mL), not food volume',
                        'سعة الوعاء (مل)، وليست حجم الطعام',
                        'گنجایشی دەفر (مل)، نە قەبارەی خواردن',
                      ),
                      'depthCm' => tr(
                        'Container depth (cm)',
                        'عمق الوعاء (سم)',
                        'قووڵایی دەفر (سم)',
                      ),
                      _ => tr(
                        'Weighed food mass (g)',
                        'وزن الطعام المقاس (غ)',
                        'کێشی پێوانەکراوی خواردن (گ)',
                      ),
                    },
                  ),
                ),
              ),
              if (measureError != null) Text(measureError!),
              if (photoError)
                Text(
                  tr(
                    'Could not load the photo. Please try again.',
                    'تعذر تحميل الصورة. حاول مجددًا.',
                    'وێنەکە بار نەکرا. تکایە دووبارە هەوڵ بدەوە.',
                  ),
                ),
              if (picking) const LinearProgressIndicator(),
              if (tooLarge)
                Text(
                  tr(
                    'Photos together must be smaller than 1 MB. Retake smaller photos.',
                    'يجب أن يقل مجموع الصورتين عن 1 ميغابايت. أعد التقاط صور أصغر.',
                    'کۆی وێنەکان دەبێت لە ١ مێگابایت کەمتر بێت. وێنەی بچووکتر بگرە.',
                  ),
                ),
              FilledButton(
                onPressed: picking || tooLarge
                    ? null
                    : () {
                        final values = <String, double>{};
                        for (final entry in measurements.entries) {
                          if (entry.value.text.trim().isEmpty) continue;
                          final value = parseLocalizedDouble(entry.value.text);
                          final max = entry.key == 'capacityMl'
                              ? 20000
                              : entry.key == 'depthCm'
                              ? 100
                              : 10000;
                          if (value == null || value < .1 || value > max) {
                            setState(
                              () => measureError = tr(
                                'Check the measured values.',
                                'تحقق من القياسات.',
                                'پێوانەکان بپشکنە.',
                              ),
                            );
                            return;
                          }
                          values[entry.key] = value;
                        }
                        Navigator.pop(sheetContext, (top, side, values));
                      },
                child: Text(
                  tr('Analyze meal', 'تحليل الوجبة', 'شیکردنەوەی ژەم'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
