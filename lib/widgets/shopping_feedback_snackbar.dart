import 'package:flutter/material.dart';
import 'package:nutrify/l10n/app_localizations.dart';
import 'package:nutrify/theme/app_theme.dart';
import 'package:nutrify/utils/shopping_list_utils.dart';

void showShoppingItemSnackBar(
  BuildContext context, {
  required AppLocalizations t,
  required bool isDark,
  required ShoppingItemAddOutcome outcome,
}) {
  if (outcome == ShoppingItemAddOutcome.empty) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();

  if (outcome == ShoppingItemAddOutcome.duplicate) {
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF422006) : const Color(0xFFFFFBEB),
        content: Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.shoppingDuplicate,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFFEF3C7) : const Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return;
  }

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? AppTheme.indigo.withValues(alpha: 0.35) : AppTheme.lightSurfaceTint,
      content: Row(
        children: [
          Icon(Icons.check_circle_outline, color: isDark ? AppTheme.indigoLight : AppTheme.indigo),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.shoppingItemAdded,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

void showShoppingBulkSnackBar(
  BuildContext context, {
  required AppLocalizations t,
  required bool isDark,
  required ShoppingBulkAddResult result,
}) {
  final text = t.shoppingBulkFeedback(result.addedCount, result.skippedDuplicateCount);
  if (text.isEmpty) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();

  final isDupOnly = result.addedCount == 0 && result.skippedDuplicateCount > 0;
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDupOnly
          ? (isDark ? const Color(0xFF422006) : const Color(0xFFFFFBEB))
          : (isDark ? AppTheme.indigo.withValues(alpha: 0.35) : AppTheme.lightSurfaceTint),
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isDupOnly ? Icons.info_outline : Icons.playlist_add_check,
            color: isDupOnly
                ? (isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309))
                : (isDark ? AppTheme.indigoLight : AppTheme.indigo),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: isDupOnly
                    ? (isDark ? const Color(0xFFFEF3C7) : const Color(0xFF92400E))
                    : (isDark ? Colors.white : const Color(0xFF1E293B)),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
