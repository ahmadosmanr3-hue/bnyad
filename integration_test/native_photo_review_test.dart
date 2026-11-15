import 'dart:io';
import 'fixtures/dolma_image.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutrify/widgets/meal_photo_review.dart';
import 'package:nutrify/theme/app_theme.dart';

/// Injected, openly licensed food image. Tests the real review UI on the native
/// runtime, not native picker permissions, camera hardware or Gemini accuracy.
class LocalFixturePicker extends ImagePicker {
  LocalFixturePicker(this.bytes);
  final Uint8List bytes;
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => XFile.fromData(
    bytes,
    mimeType: 'image/jpeg',
    name: 'licensed-food-qa.jpg',
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'native photo review single/side/retake/remove/cancel in three locales and themes',
    (tester) async {
      final bytes = licensedDolmaPhoto;
      expect(bytes.length, lessThan(524288));
      for (final lang in ['en', 'ar', 'ku']) {
        for (final dark in [false, true]) {
          MealPhotoReview? result;
          final add = {
            'en': 'Optional side photo',
            'ar': 'صورة جانبية اختيارية',
            'ku': 'وێنەی تەنیشت بە ئارەزوو',
          }[lang]!;
          final retake = {
            'en': 'Retake side photo',
            'ar': 'إعادة الصورة الجانبية',
            'ku': 'وێنەی تەنیشت دووبارە بگرە',
          }[lang]!;
          final remove = {'en': 'Remove', 'ar': 'إزالة', 'ku': 'لابردن'}[lang]!;
          final analyze = {
            'en': 'Analyze meal',
            'ar': 'تحليل الوجبة',
            'ku': 'شیکردنەوەی ژەم',
          }[lang]!;
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => Directionality(
                textDirection: lang == 'en'
                    ? TextDirection.ltr
                    : TextDirection.rtl,
                child: child!,
              ),
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              home: Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: FilledButton(
                      onPressed: () async {
                        result = await showMealPhotoReview(
                          context,
                          initial: bytes,
                          source: ImageSource.gallery,
                          picker: LocalFixturePicker(bytes),
                          lang: lang,
                        );
                      },
                      child: const Text('Open simulated photo review'),
                    ),
                  ),
                ),
              ),
            ),
          );
          tester.testTextInput.register();
          await tester.tap(find.text('Open simulated photo review'));
          await tester.pumpAndSettle();
          if (Platform.isAndroid && lang == 'en' && !dark) {
            await binding.convertFlutterSurfaceToImage();
            await tester.pump();
          }
          await binding.takeScreenshot(
            '${Platform.operatingSystem}_$lang-photo-single-${dark ? 'dark' : 'light'}',
          );
          await tester.ensureVisible(find.text(analyze));
          await tester.tap(find.text(analyze));
          await tester.pumpAndSettle();
          expect(result!.$2, isNull);
          await tester.tap(find.text('Open simulated photo review'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text(add));
          await tester.tap(find.text(add));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text(retake));
          await tester.tap(find.text(retake));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text(remove));
          await tester.tap(find.text(remove));
          await tester.pumpAndSettle();
          expect(find.text(add), findsOneWidget);
          await tester.tap(find.text(add));
          await tester.pumpAndSettle();
          await binding.takeScreenshot(
            '${Platform.operatingSystem}_$lang-photo-side-${dark ? 'dark' : 'light'}',
          );
          await tester.ensureVisible(find.text(analyze));
          await tester.tap(find.text(analyze));
          await tester.pumpAndSettle();
          expect(result, isNotNull);
          expect(result!.$2, isNotNull);
          expect(result!.$1, bytes);
          expect(tester.takeException(), isNull);
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      tester.testTextInput.unregister();
    },
  );
}
