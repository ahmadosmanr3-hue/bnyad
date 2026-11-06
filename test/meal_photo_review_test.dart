import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nutrify/widgets/meal_photo_review.dart';

final photo = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aV34AAAAASUVORK5CYII=',
);

class FixturePicker extends ImagePicker {
  int calls = 0;
  bool fail = false;
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    calls++;
    if (fail) throw StateError('fixture camera unavailable');
    return XFile.fromData(
      Uint8List.fromList(photo),
      mimeType: 'image/png',
      name: 'fictional.png',
    );
  }
}

void main() {
  for (final twoPhotos in [false, true]) {
    testWidgets(
      'review ${twoPhotos ? "two" : "one"} photo, retake, remove and measured submission',
      (tester) async {
        tester.view.physicalSize = const Size(390, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final picker = FixturePicker();
        MealPhotoReview? result;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    result = await showMealPhotoReview(
                      context,
                      initial: photo,
                      source: ImageSource.gallery,
                      picker: picker,
                      lang: 'en',
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.byType(Image), findsOneWidget);
        await tester.tap(find.text('Retake top photo'));
        await tester.pumpAndSettle();
        expect(picker.calls, 1);
        if (twoPhotos) {
          await tester.tap(find.text('Optional side photo'));
          await tester.pumpAndSettle();
          expect(find.byType(Image), findsNWidgets(2));
          await tester.tap(find.text('Retake side photo'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Remove'));
          await tester.pumpAndSettle();
          expect(find.byType(Image), findsOneWidget);
          await tester.tap(find.text('Optional side photo'));
          await tester.pumpAndSettle();
        }
        final fields = find.byType(TextField);
        await tester.ensureVisible(fields.last);
        await tester.enterText(fields.last, '٢٥٠');
        await tester.ensureVisible(find.text('Analyze meal'));
        await tester.tap(find.text('Analyze meal'));
        await tester.pumpAndSettle();
        expect(result, isNotNull);
        expect(result!.$2 != null, twoPhotos);
        expect(result!.$3, {'foodGrams': 250.0});
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('photo picker failure stays reviewable without submitting', (
    tester,
  ) async {
    final picker = FixturePicker()..fail = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showMealPhotoReview(
                context,
                initial: photo,
                source: ImageSource.gallery,
                picker: picker,
                lang: 'en',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retake top photo'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not load the photo. Please try again.'),
      findsOneWidget,
    );
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
