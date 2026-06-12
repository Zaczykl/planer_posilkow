import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meal.dart';
import '../providers/meal_provider.dart';
import '../app_theme.dart';

class MealCard extends StatelessWidget {
  final Meal meal;
  const MealCard({super.key, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Consumer<MealProvider>(
      builder: (_, provider, __) {
        final match  = provider.matchOf(meal);
        final inPlan = provider.isMealInPlan(meal.id);
        final slot   = provider.planSlotOf(meal.id);

        Color topColor;
        Color cardBg;
        if (match.pct == 100) {
          topColor = AppColors.green;
          cardBg   = AppColors.hitBg;
        } else if (match.pct > 0) {
          topColor = AppColors.accent;
          cardBg   = AppColors.partialBg;
        } else {
          topColor = AppColors.border;
          cardBg   = AppColors.card;
        }

        return GestureDetector(
          onTap: () {
            final ok = provider.toggleMeal(meal);
            if (!ok) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Plan jest pełny — usuń jedno danie.'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: inPlan ? AppColors.green : AppColors.border,
                width: inPlan ? 2 : 1,
              ),
              boxShadow: inPlan
                  ? [BoxShadow(color: AppColors.green.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))]
                  : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: topColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              meal.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.tagBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${meal.kcal} kcal',
                              style: const TextStyle(fontSize: 11, color: AppColors.muted),
                            ),
                          ),
                          if (inPlan) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 22, height: 22,
                              decoration: const BoxDecoration(
                                color: AppColors.green,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${slot + 1}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: match.pct / 100,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation(topColor),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${match.pct}% dopasowania — ${match.have.length + match.substituted.length}/${meal.ingredients.length} składników',
                        style: const TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                      const SizedBox(height: 8),
                      _UrgentBanner(meal: meal, provider: provider),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          ...match.have.map((i) => _tag('${i.name} ${i.amount}', have: true)),
                          ...match.substituted.map((i) =>
                              _tag('🔄 ${i.name} ${i.amount}', have: true, substitute: true)),
                          ...match.missing.map((i) => _tag('${i.name} ${i.amount}', have: false)),
                        ],
                      ),
                      _SubstitutesInfo(match: match, provider: provider),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tag(String text, {required bool have, bool substitute = false}) {
    final Color bg, borderColor, textColor;
    if (substitute) {
      bg          = const Color(0xFFEAF2FB);
      borderColor = const Color(0xFFB9D4F0);
      textColor   = const Color(0xFF2C6FAF);
    } else if (have) {
      bg          = AppColors.hitBg;
      borderColor = const Color(0xFFB6E0C6);
      textColor   = const Color(0xFF2E7D52);
    } else {
      bg          = AppColors.missBg;
      borderColor = const Color(0xFFF5C6C6);
      textColor   = const Color(0xFFC0392B);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: textColor),
      ),
    );
  }
}

/// Shows, for each missing ingredient, whether a substitute ("wymiennik")
/// is already checked in the fridge, e.g. '🔄 pomidor → masz: cukinia'.
class _SubstitutesInfo extends StatelessWidget {
  final MealMatch match;
  final MealProvider provider;
  const _SubstitutesInfo({required this.match, required this.provider});

  @override
  Widget build(BuildContext context) {
    final hints = <Widget>[];
    for (final ing in match.substituted) {
      final subs = provider.availableSubstitutes(ing.name);
      if (subs.isEmpty) continue;
      hints.add(_hintTag('🔄 ${ing.name} → masz: ${subs.take(2).join(', ')}'));
    }
    if (hints.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(spacing: 4, runSpacing: 4, children: hints),
    );
  }

  Widget _hintTag(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF2FB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFB9D4F0)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C6FAF),
          ),
        ),
      );
}

class _UrgentBanner extends StatelessWidget {
  final Meal meal;
  final MealProvider provider;
  const _UrgentBanner({required this.meal, required this.provider});

  @override
  Widget build(BuildContext context) {
    final urgent = provider.urgentIngredientsForMeal(meal, withinDays: 3);
    if (urgent.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 4, runSpacing: 4,
        children: urgent.map((ing) {
          final e = provider.expiryOf(ing)!;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: e.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: e.color.withOpacity(0.4)),
            ),
            child: Text('${e.emoji} $ing',
                style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w700, color: e.color)),
          );
        }).toList(),
      ),
    );
  }
}
