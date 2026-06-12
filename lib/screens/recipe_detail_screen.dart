import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/meal.dart';
import '../providers/meal_provider.dart';
import '../app_theme.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Meal meal;
  const RecipeDetailScreen({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MealProvider>();
    final match    = provider.matchOf(meal);
    final inPlan   = provider.isMealInPlan(meal.id);
    final isSn     = meal.category == MealCategory.sniadanie;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSn ? 'Śniadanie / Kolacja' : 'Obiad',
            style: const TextStyle(fontSize: 16)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () {
                final ok = provider.toggleMeal(meal);
                if (!ok) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Plan jest pełny — usuń jedno danie.'),
                    duration: Duration(seconds: 2),
                  ));
                }
              },
              icon: Icon(inPlan ? Icons.check_circle : Icons.add_circle_outline, size: 18),
              label: Text(inPlan ? 'W planie' : 'Dodaj do planu'),
              style: TextButton.styleFrom(
                foregroundColor: inPlan ? AppColors.green : AppColors.accent,
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Hero header ──────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: inPlan ? AppColors.green : AppColors.border,
                  width: inPlan ? 2 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.3)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _pill('${meal.kcal} kcal', AppColors.accent),
                    const SizedBox(width: 8),
                    _pill(isSn ? 'Śniadanie/Kolacja' : 'Obiad',
                        isSn ? const Color(0xFF5B8DD9) : AppColors.green),
                    const SizedBox(width: 8),
                    _pill('${match.pct}% gotowe', match.barColor),
                  ],
                ),
                const SizedBox(height: 10),
                // Match bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: match.pct / 100,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation(match.barColor),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Masz ${match.have.length + match.substituted.length} z ${meal.ingredients.length} składników'
                    '${match.substituted.isNotEmpty ? ' (w tym ${match.substituted.length} przez wymiennik)' : ''}',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Ingredients ──────────────────────────
          _sectionTitle('🧂 Składniki'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: meal.ingredients.asMap().entries.map((e) {
                final i     = e.value;
                final isLast = e.key == meal.ingredients.length - 1;
                final have  = provider.checked.contains(i.name);
                final subs  = have ? const <String>[] : provider.availableSubstitutes(i.name);
                final hasSub = subs.isNotEmpty;
                return Container(
                  decoration: BoxDecoration(
                    border: isLast ? null : const Border(
                      bottom: BorderSide(color: AppColors.border),
                    ),
                    color: have
                        ? AppColors.hitBg
                        : (hasSub ? const Color(0xFFEAF2FB) : null),
                    borderRadius: isLast
                        ? const BorderRadius.vertical(bottom: Radius.circular(12))
                        : (e.key == 0 ? const BorderRadius.vertical(top: Radius.circular(12)) : null),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(
                    children: [
                      Icon(
                        have
                            ? Icons.check_circle
                            : (hasSub ? Icons.swap_horiz : Icons.radio_button_unchecked),
                        size: 18,
                        color: have
                            ? AppColors.green
                            : (hasSub ? const Color(0xFF2C6FAF) : AppColors.border),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(i.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: (have || hasSub) ? FontWeight.w600 : FontWeight.normal,
                                  color: (have || hasSub) ? const Color(0xFF2C2C2C) : AppColors.muted,
                                )),
                            if (hasSub)
                              Text('🔄 masz wymiennik: ${subs.take(2).join(', ')}',
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFF2C6FAF))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: have ? AppColors.green.withOpacity(0.15) : AppColors.tagBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(i.amount,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: have ? AppColors.green : AppColors.muted,
                            )),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // ── Preparation ──────────────────────────
          _sectionTitle('👨‍🍳 Sposób przygotowania'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildSteps(meal.preparation),
            ),
          ),
          const SizedBox(height: 20),

          // ── Copy button ──────────────────────────
          OutlinedButton.icon(
            onPressed: () => _copyRecipe(context),
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Kopiuj przepis'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: AppColors.border),
              foregroundColor: AppColors.muted,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800));

  Widget _pill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
  );

  List<Widget> _buildSteps(String prep) {
    final steps = prep
        .split('\n')
        .map((s) => s.replaceFirst(RegExp(r'^\d+\.\s*'), ''))
        .where((s) => s.isNotEmpty)
        .toList();
    if (steps.length <= 1) {
      return [Text(steps.isEmpty ? prep : steps.first, style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF444444)))];
    }
    return steps.asMap().entries.map((e) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text('${e.key + 1}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.accent)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(e.value,
                style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF444444))),
          ),
        ],
      ),
    )).toList();
  }

  void _copyRecipe(BuildContext context) {
    final sb = StringBuffer();
    sb.writeln('=== ${meal.name} (${meal.kcal} kcal) ===\n');
    sb.writeln('SKŁADNIKI:');
    for (final i in meal.ingredients) {
      sb.writeln('• ${i.name} — ${i.amount}');
    }
    sb.writeln('\nSPOSÓB PRZYGOTOWANIA:');
    sb.writeln(meal.preparation);
    Clipboard.setData(ClipboardData(text: sb.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Przepis skopiowany!'), duration: Duration(seconds: 2)),
    );
  }
}
