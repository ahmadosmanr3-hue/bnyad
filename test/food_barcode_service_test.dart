import 'package:flutter_test/flutter_test.dart';
import 'package:nutrify/services/food_barcode_service.dart';

void main() {
  test('UPC-A 12 digits also tries EAN-13 with leading zero', () {
    final candidates = FoodBarcodeService.barcodeLookupCandidates(
      '012345678905',
    );
    expect(candidates, contains('012345678905'));
    expect(candidates, contains('0012345678905'));
  });

  test(
    'accepts printed separators without inventing or stripping barcode digits',
    () {
      final candidates = FoodBarcodeService.barcodeLookupCandidates(
        '5449-00000-0996',
      );
      expect(candidates.first, '5449000000996');
      expect(
        FoodBarcodeService.barcodeLookupCandidates('text5449000000996'),
        isEmpty,
      );
      expect(
        FoodBarcodeService.barcodeLookupCandidates('5449000000997'),
        isEmpty,
      );
    },
  );

  test('serving volume is never parsed as grams', () {
    expect(FoodBarcodeService.parseGramsFromServingLabel('250 g'), 250);
    expect(FoodBarcodeService.parseGramsFromServingLabel('330ml'), isNull);
    expect(FoodBarcodeService.parseGramsFromServingLabel('1 portion'), isNull);
  });

  test('UPC-E is explicitly expanded and its UPC-A check digit verified', () {
    expect(FoodBarcodeService.expandUpce('04252614'), '042100005264');
    expect(
      FoodBarcodeService.barcodeLookupCandidates('04252614', format: 'upcE'),
      contains('042100005264'),
    );
    expect(FoodBarcodeService.expandUpce('04252615'), isNull);
  });

  test('bestLocalFoodMatch finds Kurdish foods by name fragment', () {
    final match = FoodBarcodeService.bestLocalFoodMatch(
      'Kurdish Naan flatbread',
    );
    expect(match, isNotNull);
    expect(match!.id, 'k5');
  });

  test('bestLocalFoodMatch returns null for unrelated text', () {
    expect(FoodBarcodeService.bestLocalFoodMatch('xy'), isNull);
    expect(
      FoodBarcodeService.bestLocalFoodMatch('random unknown product xyz'),
      isNull,
    );
  });
}
