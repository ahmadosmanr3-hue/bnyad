import 'package:flutter/material.dart';

/// Compact phone detection (typical ≤360 logical px width).
bool isCompactWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 360;

/// Soften OS/accessibility text scale so layouts don't explode on phones.
TextScaler clampedTextScaler(BuildContext context, {double max = 1.15}) {
  return MediaQuery.textScalerOf(context).clamp(minScaleFactor: 0.85, maxScaleFactor: max);
}

/// Number / short label that shrinks instead of overflowing.
Widget scaleDownText(
  String text, {
  TextStyle? style,
  TextAlign textAlign = TextAlign.center,
  int maxLines = 1,
}) {
  return FittedBox(
    fit: BoxFit.scaleDown,
    alignment: textAlign == TextAlign.center
        ? Alignment.center
        : (textAlign == TextAlign.end ? Alignment.centerRight : Alignment.centerLeft),
    child: Text(
      text,
      maxLines: maxLines,
      softWrap: false,
      overflow: TextOverflow.visible,
      textAlign: textAlign,
      style: style,
    ),
  );
}
