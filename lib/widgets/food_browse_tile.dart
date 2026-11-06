import 'package:flutter/material.dart';

/// Text-only food result. Actions wrap independently of the food name on phones.
class FoodBrowseTile extends StatelessWidget {
  const FoodBrowseTile({
    super.key,
    required this.name,
    required this.category,
    required this.nutrition,
    required this.actionLabel,
    required this.onOpen,
    required this.favorite,
    this.hint,
  });
  final String name, category, nutrition, actionLabel;
  final String? hint;
  final VoidCallback onOpen;
  final Widget favorite;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  favorite,
                ],
              ),
              Text(
                category,
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(hint!),
                ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text(
                    nutrition,
                    textDirection: TextDirection.ltr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpen,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(48, 48),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(actionLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
