import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/models/food_item.dart';
import 'package:nutrify/models/favorite_template.dart';

String foodText(String lang, String en, String ar, String ku) => lang == 'ar'
    ? ar
    : (lang == 'ku' || lang == 'ckb')
    ? ku
    : en;

class FoodFavoriteButton extends StatelessWidget {
  const FoodFavoriteButton({super.key, required this.food, this.template});
  final FoodItem food;
  final FavoriteTemplate? template;
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>(),
        selected = state.isFavorite(food.canonicalKey);
    return IconButton(
      key: ValueKey('favorite-${food.canonicalKey}'),
      tooltip: selected
          ? foodText(
              state.lang,
              'Remove favorite',
              'إزالة من المفضلة',
              'لابردن لە دڵخوازەکان',
            )
          : state.t.saveAsFavorite,
      isSelected: selected,
      icon: Icon(
        selected ? Icons.star : Icons.star_outline,
        color: selected
            ? const Color(0xFFF59E0B)
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onPressed: () async {
        final f =
            template ??
            FavoriteTemplate(
              id: food.canonicalKey,
              foodId: food.canonicalKey,
              name: food.getLocalizedName(state.lang),
              amount: food.nutritionReferenceG,
              amountUnit: food.nutritionUnit,
              calories: food.calories,
              protein: food.protein,
              carbs: food.carbs,
              fat: food.fat,
              micros: food.micros,
            );
        final saved = await state.toggleFavorite(f);
        if (!context.mounted || saved) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                foodText(
                  state.lang,
                  'Favorites could not sync. Refreshed the saved state; please try again.',
                  'تعذرت مزامنة المفضلة. تم تحديث الحالة المحفوظة؛ حاول مجددًا.',
                  'دڵخوازەکان هاوکات نەکران. دۆخی پاشەکەوتکراو نوێ کرایەوە؛ تکایە دووبارە هەوڵ بدەوە.',
                ),
              ),
            ),
          );
      },
    );
  }
}
