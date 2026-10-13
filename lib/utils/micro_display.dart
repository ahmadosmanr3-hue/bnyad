import 'package:flutter/material.dart';
import 'package:nutrify/l10n/app_localizations.dart';
import 'package:nutrify/theme/app_theme.dart';

String microLabel(AppLocalizations t, String key) {
  switch (key) {
    case 'vitA':
      return t.vitaminA;
    case 'vitC':
      return t.vitaminC;
    case 'vitD':
      return t.vitaminD;
    case 'vitE':
      return t.vitaminE;
    case 'vitK':
      return t.vitaminK;
    case 'vitB6':
      return t.vitaminB6;
    case 'vitB12':
      return t.vitaminB12;
    case 'folate':
      return t.folate;
    case 'iron':
      return t.iron;
    case 'calcium':
      return t.calcium;
    case 'potassium':
      return t.potassium;
    case 'magnesium':
      return t.magnesium;
    case 'phosphorus':
      return t.phosphorus;
    case 'zinc':
      return t.zincMineral;
    case 'selenium':
      return t.selenium;
    case 'sodium':
      return t.sodium;
    case 'fiber':
      return t.fiber;
    default:
      return key;
  }
}

Color microColor(String key) {
  switch (key) {
    case 'vitA':
      return const Color(0xFFFF9800);
    case 'vitC':
      return const Color(0xFFFFC107);
    case 'vitD':
      return const Color(0xFF03A9F4);
    case 'vitE':
      return const Color(0xFF8BC34A);
    case 'vitK':
      return const Color(0xFF009688);
    case 'vitB6':
      return const Color(0xFF673AB7);
    case 'vitB12':
      return const Color(0xFFE91E63);
    case 'folate':
      return const Color(0xFF4CAF50);
    case 'iron':
      return const Color(0xFF795548);
    case 'calcium':
      return const Color(0xFF9E9E9E);
    case 'potassium':
      return const Color(0xFF8BC34A);
    case 'magnesium':
      return const Color(0xFF00BCD4);
    case 'phosphorus':
      return const Color(0xFF607D8B);
    case 'zinc':
      return const Color(0xFF78909C);
    case 'selenium':
      return const Color(0xFFFF5722);
    case 'sodium':
      return const Color(0xFF3F51B5);
    case 'fiber':
      return const Color(0xFF795548);
    default:
      return AppTheme.indigo;
  }
}
