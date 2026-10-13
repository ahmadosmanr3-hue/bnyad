/// Bottom shell tab indices — keep in sync with `screens` / `AppBottomNav` in [main.dart].
/// Dashboard is the center tab (index 2 of 5). Meal plan + scanner are adjacent on the right (LTR).
abstract final class MainShellTab {
  static const int settings = 0;
  static const int foodLog = 1;
  static const int dashboard = 2;
  static const int mealPlan = 3;
  static const int scanner = 4;
}
