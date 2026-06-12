import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meal.dart';
import '../providers/meal_provider.dart';
import '../app_theme.dart';
import 'recipe_detail_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search bar ────────────────────────────
        Container(
          color: AppColors.card,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Szukaj przepisu lub składnika…',
              prefixIcon: Icon(Icons.search, size: 20),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),

        // ── Category tabs ─────────────────────────
        Container(
          color: AppColors.card,
          child: TabBar(
            controller: _tabs,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.accent,
            tabs: const [
              Tab(text: 'Wszystkie'),
              Tab(text: 'Śniadania'),
              Tab(text: 'Obiady'),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Recipe lists ──────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _RecipeList(query: _query, category: null),
              _RecipeList(query: _query, category: MealCategory.sniadanie),
              _RecipeList(query: _query, category: MealCategory.obiad),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecipeList extends StatelessWidget {
  final String query;
  final MealCategory? category;
  const _RecipeList({required this.query, required this.category});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MealProvider>();
    final meals = provider.searchRecipes(query, category: category);

    if (meals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔍', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('Brak przepisów', style: TextStyle(color: AppColors.muted)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: meals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _RecipeTile(meal: meals[i]),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  final Meal meal;
  const _RecipeTile({required this.meal});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MealProvider>();
    final match    = provider.matchOf(meal);
    final inPlan   = provider.isMealInPlan(meal.id);
    final isSn     = meal.category == MealCategory.sniadanie;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RecipeDetailScreen(meal: meal)),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: inPlan ? AppColors.green : AppColors.border,
            width: inPlan ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meal.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, height: 1.3)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _pill(isSn ? '🥗 Śniadanie' : '🍲 Obiad',
                              isSn ? const Color(0xFF5B8DD9) : AppColors.green),
                          const SizedBox(width: 6),
                          _pill('${meal.kcal} kcal', AppColors.accent),
                          const SizedBox(width: 6),
                          _pill('${meal.ingredients.length} skł.', AppColors.muted),
                        ],
                      ),
                    ],
                  ),
                ),
                if (inPlan)
                  const Icon(Icons.check_circle, color: AppColors.green, size: 22),
              ],
            ),

            if (provider.checked.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: match.pct / 100,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation(match.barColor),
                        minHeight: 5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${match.pct}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: match.barColor,
                      )),
                ],
              ),
            ],

            const SizedBox(height: 8),
            // First 3 ingredients preview
            Text(
              meal.ingredients.take(4).map((i) => '${i.name} ${i.amount}').join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
  );
}
