import 'package:flutter_test/flutter_test.dart';
import 'package:nutrify/models/user_profile.dart';
import 'package:nutrify/utils/body_fat_calculator.dart';

void main() {
  final profile = UserProfile(
    uid: 'test',
    weight: 80,
    height: 178,
    age: 30,
    gender: 'male',
    activityLevel: 'moderatelyActive',
    goal: 'stayHealthy',
    sicknesses: const [],
    allergies: const [],
    disabilities: const [],
    dailyCalories: 2200,
    dailyCarbs: 250,
    dailyProtein: 120,
    dailyFat: 70,
    language: 'en',
    theme: 'light',
    onboarded: true,
  );

  test('navy formula returns plausible range for typical male', () {
    final est = estimateFromMeasurements(
      profile: profile,
      waistCm: 88,
      neckCm: 38,
    );
    expect(est.method, 'navy');
    expect(est.confidence, 'high');
    expect(est.centerPercent, inInclusiveRange(10, 35));
  });

  test('photo blend stays near measurement anchor', () {
    final anchor = BodyFatEstimate(
      minPercent: 16,
      maxPercent: 20,
      centerPercent: 18,
      method: 'navy',
      confidence: 'high',
    );
    final blended = blendPhotoWithAnchor(anchor: anchor, aiMin: 8, aiMax: 30);
    expect(blended.centerPercent, inInclusiveRange(13, 23));
    expect(blended.method, 'blended');
  });
}
