import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meal.dart';
import '../providers/meal_provider.dart';
import '../widgets/meal_card.dart';
import '../app_theme.dart';

class MealsScreen extends StatelessWidget {
  final MealCategory category;
  const MealsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _ControlBar(),
        Expanded(child: _MealList(category: category)),
      ],
    );
  }
}

// ── Sort & Filter controls ────────────────────────────
class _ControlBar extends StatelessWidget {
  const _ControlBar();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MealProvider>();

    return Container(
      color: AppColors.card,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        children: [
          // Sort row
          Row(
            children: [
              const Text('Sortuj:', style: TextStyle(fontSize: 13, color: AppColors.muted)),
              const SizedBox(width: 8),
              _SortChip(label: 'Dopasowanie', mode: SortMode.match),
              const SizedBox(width: 6),
              _SortChip(label: 'Nazwa', mode: SortMode.alpha),
              const SizedBox(width: 6),
              _SortChip(label: 'Kalorie', mode: SortMode.kcal),
            ],
          ),
          const SizedBox(height: 8),
          // Filter row
          Row(
            children: [
              const Text('Filtr:', style: TextStyle(fontSize: 13, color: AppColors.muted)),
              const SizedBox(width: 8),
              _FilterChip(label: 'Wszystkie', mode: FilterMode.all),
              const SizedBox(width: 6),
              _FilterChip(label: '✅ Gotowe', mode: FilterMode.full),
              const SizedBox(width: 6),
              _FilterChip(label: '🔶 Częściowe', mode: FilterMode.partial),
            ],
          ),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final SortMode mode;
  const _SortChip({required this.label, required this.mode});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MealProvider>();
    final active = provider.sortMode == mode;
    return GestureDetector(
      onTap: () => provider.setSortMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.accent : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final FilterMode mode;
  const _FilterChip({required this.label, required this.mode});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MealProvider>();
    final active = provider.filterMode == mode;
    return GestureDetector(
      onTap: () => provider.setFilterMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.green : AppColors.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.green : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

// ── Urgency bracket display config (UI-only constants) ───────────────────────
const _brackets = [
  (emoji: '🔴', label: 'Użyj dziś',      color: Color(0xFFD32F2F)),
  (emoji: '🟠', label: 'Użyj jutro',     color: Color(0xFFE07A3A)),
  (emoji: '🟡', label: 'Użyj w 2–3 dni', color: Color(0xFFD4A017)),
  (emoji: '🟢', label: 'Dłużej',         color: Color(0xFF5A9E6F)),
];

// ── Meal list ─────────────────────────────────────────
class _MealList extends StatelessWidget {
  final MealCategory category;
  const _MealList({required this.category});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MealProvider>();
    final meals    = provider.getFilteredMeals(category);

    if (meals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔍', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('Brak dań spełniających kryteria',
                style: TextStyle(color: AppColors.muted, fontSize: 15)),
          ],
        ),
      );
    }

    // Group meals into 4 urgency buckets (logic lives in provider)
    final groups = List.generate(4, (_) => <Meal>[]);
    for (final m in meals) {
      groups[provider.urgencyBracketOf(m)].add(m);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      children: [
        for (int b = 0; b < 4; b++)
          if (groups[b].isNotEmpty) ...[
            // Section header (skip "Dłużej" header if it's the only section)
            if (!(b == 3 && groups[0].isEmpty && groups[1].isEmpty && groups[2].isEmpty))
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Row(
                  children: [
                    Text(_brackets[b].emoji,
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(_brackets[b].label,
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700,
                          color: _brackets[b].color,
                        )),
                    const SizedBox(width: 6),
                    Text('(${groups[b].length})',
                        style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
            ...groups[b].map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: MealCard(meal: m),
            )),
            if (b < 3 && groups.sublist(b + 1).any((g) => g.isNotEmpty))
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Divider(height: 1),
              ),
          ],
      ],
    );
  }
}
