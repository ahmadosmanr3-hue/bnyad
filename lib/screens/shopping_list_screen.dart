import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/theme/app_theme.dart';
import 'package:nutrify/widgets/ai_meal_plan_shopping_sheet.dart';
import 'package:nutrify/widgets/shopping_feedback_snackbar.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitNewItem(BuildContext context, String raw) async {
    final state = context.read<AppState>();
    final outcome = await state.addShoppingItem(raw);
    if (!context.mounted) return;
    _controller.clear();
    showShoppingItemSnackBar(
      context,
      t: state.t,
      isDark: state.isDark,
      outcome: outcome,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    final isDark = state.isDark;
    final items = state.shoppingList;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.shoppingList),
        actions: [
          IconButton(
            tooltip: t.aiShoppingListButton,
            onPressed: () => showAiMealPlanShoppingSheet(context),
            icon: Icon(Icons.smart_toy_outlined, color: isDark ? AppTheme.indigoLight : AppTheme.indigo),
          ),
          if (items.any((s) => s.checked))
            TextButton(
              onPressed: () => state.clearCheckedShoppingItems(),
              child: Text(t.clearDone, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: t.itemName,
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (v) => _submitNewItem(context, v),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _submitNewItem(context, _controller.text),
                  child: Text(t.addItem),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      t.shoppingListEmpty,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final s = items[i];
                      return Dismissible(
                        key: Key(s.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => state.removeShoppingItem(s.id),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsetsDirectional.only(end: 20),
                          color: AppTheme.rose.withValues(alpha: 0.15),
                          child: const Icon(Icons.delete_outline, color: AppTheme.rose),
                        ),
                        child: CheckboxListTile(
                          value: s.checked,
                          onChanged: (_) => state.toggleShoppingItem(s.id),
                          title: Text(
                            s.name,
                            style: TextStyle(
                              decoration: s.checked ? TextDecoration.lineThrough : null,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          secondary: Icon(
                            Icons.shopping_bag_outlined,
                            color: isDark ? AppTheme.indigoLight : AppTheme.indigo,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
