import 'package:flutter_test/flutter_test.dart';
import 'package:nutrify/services/food_barcode_service.dart';

void main() {
  test('UPC-A 12 digits also tries EAN-13 with leading zero', () {
    final candidates = FoodBarcodeService.barcodeLookupCandidates('012345678905');
    expect(candidates, contains('012345678905'));
    expect(candidates, contains('0012345678905'));
  });

  test('strips non-digits from scanner output', () {
    final candidates = FoodBarcodeService.barcodeLookupCandidates('5449-0000-0996');
    expect(candidates.first, '544900000996');
  });

  test('parseGramsFromServingLabel extracts grams and ml', () {
    expect(FoodBarcodeService.parseGramsFromServingLabel('250 g'), 250);
    expect(FoodBarcodeService.parseGramsFromServingLabel('330ml'), 330);
    expect(FoodBarcodeService.parseGramsFromServingLabel('1 portion'), isNull);
  });

  test('bestLocalFoodMatch finds Kurdish foods by name fragment', () {
    final match = FoodBarcodeService.bestLocalFoodMatch('Kurdish Naan flatbread');
    expect(match, isNotNull);
    expect(match!.id, 'k5');
  });

  test('bestLocalFoodMatch returns null for unrelated text', () {
    expect(FoodBarcodeService.bestLocalFoodMatch('xy'), isNull);
    expect(FoodBarcodeService.bestLocalFoodMatch('random unknown product xyz'), isNull);
  });
}
