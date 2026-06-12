import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/meal_provider.dart';
import '../models/meal.dart';
import '../utils/amount_utils.dart';
import '../app_theme.dart';
import 'recipe_detail_screen.dart';

// ── Data class for aggregated shop item ──────────────────────────────────────
class _ShopEntry {
  final String name;
  final String amountPerServing; // from first occurrence
  int occurrences; // how many plan meals need this
  final OwnedAmount? owned; // set only for checked ingredients with a given amount
  _ShopEntry({
    required this.name,
    required this.amountPerServing,
    this.occurrences = 1,
    this.owned,
  });

  String totalAmount(int days) =>
      multiplyAmount(amountPerServing, occurrences * days);

  /// How much still needs to be bought (in base units: g/ml/szt),
  /// or null when not computable (no owned amount / incomparable units).
  double? remainingBase(int days) {
    if (owned == null) return null;
    final parsed = parseAmountValue(amountPerServing);
    if (parsed == null || parsed.unit != owned!.baseUnit) return null;
    return parsed.value * occurrences * days - owned!.baseValue;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  int _days = 4;
  final Set<String> _shopDone = {}; // ticked off while shopping

  // ── Aggregate missing ingredients across plan ────────────────────────────
  // Unchecked → missing as before. Checked without amount → fully owned (as
  // before). Checked with a comparable owned amount → included; the remainder
  // is computed per selected days and the entry is hidden when covered.
  Map<String, _ShopEntry> _buildEntries(MealProvider provider) {
    final map = <String, _ShopEntry>{};
    void addEntry(String name, String amount, OwnedAmount? owned) {
      if (map.containsKey(name)) {
        map[name]!.occurrences++;
      } else {
        map[name] = _ShopEntry(
            name: name, amountPerServing: amount, owned: owned);
      }
    }

    for (final meal in provider.plan) {
      if (meal == null) continue;
      final match = provider.matchOf(meal);
      // Substituted ingredients count as owned → not on the list.
      for (final ing in match.missing) {
        addEntry(ing.name, ing.amount, null);
      }
      for (final ing in match.have) {
        final owned = provider.ownedOf(ing.name);
        if (owned == null) continue; // no amount given → fully owned
        final parsed = parseAmountValue(ing.amount);
        if (parsed == null || parsed.unit != owned.baseUnit) {
          continue; // units not comparable → treat as fully owned
        }
        addEntry(ing.name, ing.amount, owned);
      }
    }
    return map;
  }

  /// Badge / copy text for one entry given the selected number of days.
  String _amountText(_ShopEntry entry) {
    final rem = entry.remainingBase(_days);
    if (rem != null && entry.owned != null) {
      return 'kup ${formatAmountValue(rem, entry.owned!.baseUnit)} '
          '(masz ${entry.owned!.label})';
    }
    return _days > 1
        ? '${entry.amountPerServing}  ×${_days}d = ${entry.totalAmount(_days)}'
        : entry.amountPerServing;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MealProvider>();
    final entries = _buildEntries(provider);
    final sortedEntries = entries.values
        .where((e) => e.owned == null || (e.remainingBase(_days) ?? 1) > 0)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final doneCount = sortedEntries.where((e) => _shopDone.contains(e.name)).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista zakupów'),
        actions: [
          if (_shopDone.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _shopDone.clear()),
              child: const Text('Resetuj', style: TextStyle(color: AppColors.muted)),
            ),
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Kopiuj listę',
            onPressed: () => _copyList(context, provider, sortedEntries),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Plan summary (meals) ───────────────────────────────────────
          ...provider.plan.asMap().entries.map((e) {
            final idx  = e.key;
            final meal = e.value;
            if (meal == null) return const SizedBox.shrink();
            final match = provider.matchOf(meal);
            final isSn  = meal.category.name == 'sniadanie';

            return InkWell(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => RecipeDetailScreen(meal: meal))),
              borderRadius: BorderRadius.circular(12),
              child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text('${idx+1}', style: const TextStyle(
                            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(meal.name,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: Colors.red.shade400,
                        tooltip: 'Usuń z planu',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => provider.removeFromPlan(idx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _badge(isSn ? 'Śniadanie/Kolacja' : 'Obiad'),
                      const SizedBox(width: 6),
                      _badge('${meal.kcal} kcal'),
                      const SizedBox(width: 6),
                      _badge('${match.pct}% gotowe'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 5, runSpacing: 5,
                    children: [
                      ...match.have.map((i) => _haveTag(provider, i)),
                      ...match.substituted.map((i) => _tag(
                          '🔄 ${i.name} ${multiplyAmount(i.amount, _days)}',
                          have: true, substitute: true)),
                      ...match.missing.map((i) => _tag(
                          '${i.name} ${multiplyAmount(i.amount, _days)}',
                          have: false)),
                    ],
                  ),
                ],
              ),
            ));   // closes Container + InkWell
          }),

          if (provider.planCount == 0)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Text('🍽', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text('Nie wybrano żadnego dania.\nDodaj dania z zakładek Śniadania lub Obiady.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
            ),

          // ── Days selector ──────────────────────────────────────────────
          if (provider.planCount > 0) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Liczba dni', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(7, (i) {
                      final d = i + 1;
                      final sel = d == _days;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () => setState(() => _days = d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: sel ? AppColors.accent : AppColors.tagBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: sel ? AppColors.accent : AppColors.border,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text('$d',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: sel ? Colors.white : AppColors.muted,
                                )),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Shopping checklist ─────────────────────────────────────────
          if (sortedEntries.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Text('🛒', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'Brakujące składniki',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                        color: Color(0xFFC0392B)),
                  ),
                  const Spacer(),
                  Text('$doneCount / ${sortedEntries.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: doneCount == sortedEntries.length
                            ? AppColors.green
                            : AppColors.muted,
                      )),
                ],
              ),
            ),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: sortedEntries.isEmpty
                    ? 0
                    : doneCount / sortedEntries.length,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.green),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: sortedEntries.asMap().entries.map((e) {
                  final idx   = e.key;
                  final entry = e.value;
                  final done  = _shopDone.contains(entry.name);
                  final isLast = idx == sortedEntries.length - 1;

                  return GestureDetector(
                    onTap: () => setState(() {
                      if (done) {
                        _shopDone.remove(entry.name);
                      } else {
                        _shopDone.add(entry.name);
                      }
                    }),
                    child: Container(
                      decoration: BoxDecoration(
                        color: done ? AppColors.hitBg : null,
                        border: isLast ? null : const Border(
                          bottom: BorderSide(color: AppColors.border),
                        ),
                        borderRadius: isLast
                            ? const BorderRadius.vertical(bottom: Radius.circular(12))
                            : (idx == 0
                                ? const BorderRadius.vertical(top: Radius.circular(12))
                                : null),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      child: Row(
                        children: [
                          // Checkbox
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              color: done ? AppColors.green : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: done ? AppColors.green : AppColors.border,
                                width: 2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: done
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          // Name
                          Expanded(
                            child: Text(
                              entry.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: done ? FontWeight.normal : FontWeight.w500,
                                color: done ? AppColors.muted : const Color(0xFF2C2C2C),
                                decoration: done ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          // Amount badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: done
                                  ? AppColors.green.withOpacity(0.12)
                                  : const Color(0xFFFFF3EC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: done
                                    ? AppColors.green.withOpacity(0.3)
                                    : AppColors.accent.withOpacity(0.25),
                              ),
                            ),
                            child: Text(
                              _amountText(entry),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: done ? AppColors.green : AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            if (doneCount == sortedEntries.length && sortedEntries.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.hitBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🎉 ', style: TextStyle(fontSize: 24)),
                    Text('Zakupy zrobione!',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                            color: Color(0xFF2E7D52))),
                  ],
                ),
              ),
            ],
          ] else if (provider.planCount > 0) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.hitBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🎉 ', style: TextStyle(fontSize: 24)),
                  Text('Masz wszystkie składniki!',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                          color: Color(0xFF2E7D52))),
                ],
              ),
            ),
          ],

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _badge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.tagBg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
  );

  /// Tag for an owned ingredient on a meal card. When a given owned amount
  /// only partially covers the need for the selected days, the tag turns
  /// orange and shows 'masz/potrzeba', e.g. 'mleko 30/120 g'.
  Widget _haveTag(MealProvider provider, Ingredient i) {
    final owned  = provider.ownedOf(i.name);
    final parsed = parseAmountValue(i.amount);
    if (owned != null && parsed != null && parsed.unit == owned.baseUnit) {
      final needed = parsed.value * _days;
      if (owned.baseValue < needed) {
        return _tag(
          '${i.name} ${_fmtNum(owned.baseValue)}/${_fmtNum(needed)} ${parsed.unit}',
          have: true,
          partial: true,
        );
      }
    }
    return _tag('${i.name} ${multiplyAmount(i.amount, _days)}', have: true);
  }

  String _fmtNum(double v) => v == v.roundToDouble()
      ? v.round().toString()
      : v.toStringAsFixed(1).replaceAll('.', ',');

  Widget _tag(String text,
      {required bool have, bool partial = false, bool substitute = false}) {
    final Color bg, borderColor, textColor;
    if (substitute) {
      bg          = const Color(0xFFEAF2FB);
      borderColor = const Color(0xFFB9D4F0);
      textColor   = const Color(0xFF2C6FAF);
    } else if (partial) {
      bg          = const Color(0xFFFFF3EC);
      borderColor = const Color(0xFFF0C9A8);
      textColor   = const Color(0xFFE07A3A);
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: textColor)),
    );
  }

  void _copyList(BuildContext context, MealProvider provider,
      List<_ShopEntry> entries) {
    final lines = <String>['=== PLAN POSIŁKÓW ===\n'];
    for (int i = 0; i < 3; i++) {
      final meal = provider.plan[i];
      if (meal == null) continue;
      final match = provider.matchOf(meal);
      lines.add('${i + 1}. ${meal.name} (${meal.kcal} kcal)');
      if (match.substituted.isNotEmpty) {
        lines.add('   🔄 Wymienniki: ${match.substituted.map((i) =>
            '${i.name} → ${provider.availableSubstitutes(i.name).take(2).join('/')}').join(', ')}');
      }
      if (match.missing.isNotEmpty) {
        lines.add(
            '   Brakuje: ${match.missing.map((i) => i.name).join(', ')}');
      } else {
        lines.add('   ✅ Wszystkie składniki są');
      }
      lines.add('');
    }

    if (entries.isNotEmpty) {
      lines.add('=== LISTA ZAKUPÓW (${_days} dni) ===');
      for (final e in entries) {
        final tick = _shopDone.contains(e.name) ? '✅' : '□';
        lines.add('$tick ${e.name} — ${_amountText(e)}');
      }
    }

    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Skopiowano do schowka!'),
          duration: Duration(seconds: 2)),
    );
  }
}
