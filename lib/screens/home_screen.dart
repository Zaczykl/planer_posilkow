import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meal.dart';
import '../providers/meal_provider.dart';
import '../app_theme.dart';
import 'ingredients_screen.dart';
import 'meals_screen.dart';
import 'recipes_screen.dart';
import 'shopping_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _titles = ['🛒 Lodówka', '🥗 Śniadania / Kolacje', '🍲 Obiady', '📖 Przepisy'];

  void _navigateToMeals(FilterMode filter) {
    context.read<MealProvider>().setFilterMode(filter);
    setState(() => _currentIndex = 1); // Śniadania tab
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MealProvider>();

    final screens = [
      IngredientsScreen(onStatTap: _navigateToMeals),
      const MealsScreen(category: MealCategory.sniadanie),
      const MealsScreen(category: MealCategory.obiad),
      const RecipesScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          if (_currentIndex != 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
                ),
                icon: const Icon(Icons.shopping_cart_outlined, size: 20),
                label: const Text('Plan'),
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              ),
            ),
        ],
      ),

      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),

      // ── Bottom navigation ─────────────────────────
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.kitchen_outlined), label: 'Lodówka'),
          NavigationDestination(icon: Icon(Icons.breakfast_dining_outlined), label: 'Śniadania'),
          NavigationDestination(icon: Icon(Icons.restaurant_outlined), label: 'Obiady'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Przepisy'),
        ],
      ),

      // ── FAB: open plan / shopping list ───────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
        ),
        backgroundColor: provider.planCount > 0 ? AppColors.green : AppColors.accent,
        icon: const Icon(Icons.list_alt, color: Colors.white),
        label: Text(
          provider.planCount > 0
              ? 'Plan (${provider.planCount}/3)'
              : 'Plan zakupów',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
