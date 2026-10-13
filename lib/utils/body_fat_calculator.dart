import 'dart:math' as math;

import 'package:nutrify/models/user_profile.dart';
import 'package:nutrify/utils/nutrition_calculator.dart';

/// Result of a body-fat estimate (always a range, never a single clinical value).
class BodyFatEstimate {
  final double minPercent;
  final double maxPercent;
  final double centerPercent;
  /// `navy`, `deurenberg`, `blended`, or `photo`.
  final String method;
  /// `high` (Navy measurements), `medium` (Deurenberg / blended), `low` (photo only).
  final String confidence;

  const BodyFatEstimate({
    required this.minPercent,
    required this.maxPercent,
    required this.centerPercent,
    required this.method,
    required this.confidence,
  });

  BodyFatEstimate clamped() {
    var minP = minPercent.clamp(3.0, 55.0);
    var maxP = maxPercent.clamp(3.0, 55.0);
    if (minP > maxP) {
      final t = minP;
      minP = maxP;
      maxP = t;
    }
    final center = centerPercent.clamp(minP, maxP);
    return BodyFatEstimate(
      minPercent: minP,
      maxPercent: maxP,
      centerPercent: center,
      method: method,
      confidence: confidence,
    );
  }
}

double _log10(double value) => math.log(value) / math.ln10;

bool _isFemaleGender(String gender) {
  final g = gender.toLowerCase();
  return g == 'female' || g == 'f' || g == 'woman';
}

/// Deurenberg et al. (1991) — BMI + age estimate. Useful when tape measurements are missing.
double deurenbergBodyFatPercent({
  required double weightKg,
  required double heightCm,
  required int age,
  required bool isFemale,
}) {
  if (heightCm <= 0 || weightKg <= 0) return 0;
  final bmi = computeBmi(weightKg: weightKg, heightCm: heightCm);
  final sexFactor = isFemale ? 0.0 : 1.0;
  return (1.20 * bmi) + (0.23 * age) - (10.8 * sexFactor) - 5.4;
}

/// US Navy circumference method (tape measure). Much more reliable than a single photo.
double? navyBodyFatPercent({
  required bool isFemale,
  required double heightCm,
  required double waistCm,
  required double neckCm,
  double? hipCm,
}) {
  if (heightCm <= 0 || waistCm <= 0 || neckCm <= 0) return null;

  final heightIn = heightCm / 2.54;
  final waistIn = waistCm / 2.54;
  final neckIn = neckCm / 2.54;

  if (heightIn <= 0) return null;

  double? raw;
  if (isFemale) {
    final hipIn = (hipCm ?? 0) / 2.54;
    if (hipIn <= 0) return null;
    final sum = waistIn + hipIn - neckIn;
    if (sum <= 0.5) return null;
    raw = 163.205 * _log10(sum) - 97.684 * _log10(heightIn) - 78.387;
  } else {
    final diff = waistIn - neckIn;
    if (diff <= 0.5) return null;
    raw = 86.010 * _log10(diff) - 70.041 * _log10(heightIn) + 36.76;
  }

  if (!raw.isFinite) return null;
  return raw.clamp(3.0, 55.0);
}

BodyFatEstimate estimateFromMeasurements({
  required UserProfile profile,
  required double waistCm,
  required double neckCm,
  double? hipCm,
}) {
  final isFemale = _isFemaleGender(profile.gender);
  final navy = navyBodyFatPercent(
    isFemale: isFemale,
    heightCm: profile.height,
    waistCm: waistCm,
    neckCm: neckCm,
    hipCm: hipCm,
  );

  if (navy != null) {
    return BodyFatEstimate(
      minPercent: navy - 2.0,
      maxPercent: navy + 2.0,
      centerPercent: navy,
      method: 'navy',
      confidence: 'high',
    ).clamped();
  }

  final deu = deurenbergBodyFatPercent(
    weightKg: profile.weight,
    heightCm: profile.height,
    age: profile.age,
    isFemale: isFemale,
  ).clamp(3.0, 55.0);

  return BodyFatEstimate(
    minPercent: deu - 4.0,
    maxPercent: deu + 4.0,
    centerPercent: deu,
    method: 'deurenberg',
    confidence: 'medium',
  ).clamped();
}

BodyFatEstimate estimateFromProfile(UserProfile profile) {
  final isFemale = _isFemaleGender(profile.gender);
  final deu = deurenbergBodyFatPercent(
    weightKg: profile.weight,
    heightCm: profile.height,
    age: profile.age,
    isFemale: isFemale,
  ).clamp(3.0, 55.0);

  return BodyFatEstimate(
    minPercent: deu - 5.0,
    maxPercent: deu + 5.0,
    centerPercent: deu,
    method: 'deurenberg',
    confidence: 'medium',
  ).clamped();
}

/// Keeps AI photo output near a measurement anchor so wild guesses are reduced.
BodyFatEstimate blendPhotoWithAnchor({
  required BodyFatEstimate anchor,
  required double aiMin,
  required double aiMax,
}) {
  final slack = anchor.method == 'navy' ? 5.0 : 7.0;
  var minP = aiMin.clamp(anchor.centerPercent - slack, anchor.centerPercent + slack);
  var maxP = aiMax.clamp(anchor.centerPercent - slack, anchor.centerPercent + slack);
  if (minP > maxP) {
    minP = anchor.centerPercent - 3;
    maxP = anchor.centerPercent + 3;
  }
  if (maxP - minP < 3) {
    minP = anchor.centerPercent - 2;
    maxP = anchor.centerPercent + 2;
  }

  return BodyFatEstimate(
    minPercent: minP,
    maxPercent: maxP,
    centerPercent: (minP + maxP) / 2,
    method: 'blended',
    confidence: anchor.confidence == 'high' ? 'medium' : 'low',
  ).clamped();
}

BodyFatEstimate estimateFromPhotoOnly({
  required double aiMin,
  required double aiMax,
}) {
  var minP = aiMin;
  var maxP = aiMax;
  if (minP > maxP) {
    final t = minP;
    minP = maxP;
    maxP = t;
  }
  if (maxP - minP < 4) {
    final mid = (minP + maxP) / 2;
    minP = mid - 2;
    maxP = mid + 2;
  }
  return BodyFatEstimate(
    minPercent: minP,
    maxPercent: maxP,
    centerPercent: (minP + maxP) / 2,
    method: 'photo',
    confidence: 'low',
  ).clamped();
}
