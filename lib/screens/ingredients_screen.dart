import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/meal_provider.dart';
import '../data/ingredients_data.dart';
import '../app_theme.dart';

// ── Expiry options ────────────────────────────────────────────────────────────
const _expiryOptions = [
  (label: 'Dziś',    days: 0,  emoji: '🔴'),
  (label: 'Jutro',   days: 1,  emoji: '🟠'),
  (label: '2–3 dni', days: 2,  emoji: '🟡'),
  (label: 'Dłużej',  days: 5,  emoji: '🟢'),
];

class IngredientsScreen extends StatefulWidget {
  final void Function(FilterMode filter)? onStatTap;
  const IngredientsScreen({super.key, this.onStatTap});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MealProvider>();
    final urgent   = provider.urgentIngredients(withinDays: 1);

    return Column(
      children: [
        // ── Header stats ──────────────────────────
        Container(
          color: AppColors.card,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Szukaj składnika…',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v.toLowerCase()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statBox('${provider.checkedCount}', 'zaznaczonych'),
                  const SizedBox(width: 6),
                  _statBox(
                    '${provider.fullMatchCount}', 'gotowych dań',
                    onTap: widget.onStatTap == null
                        ? null
                        : () => widget.onStatTap!(FilterMode.full),
                  ),
                  if (urgent.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    _statBox(
                      '${urgent.length}', 'kończy się',
                      color: const Color(0xFFD32F2F),
                      onTap: widget.onStatTap == null
                          ? null
                          : () => widget.onStatTap!(FilterMode.all),
                    ),
                  ],
                  const Spacer(),
                  TextButton.icon(
                    onPressed: provider.checkedCount > 0 ? provider.clearIngredients : null,
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Wyczyść'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Ingredient list ───────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: ingredientCategories.length,
            itemBuilder: (_, catIdx) {
              final category = ingredientCategories.keys.elementAt(catIdx);
              final allIngs  = ingredientCategories[category]!;
              final filtered = _search.isEmpty
                  ? allIngs
                  : allIngs.where((i) => i.toLowerCase().contains(_search)).toList();

              if (filtered.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: Text(category,
                        style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w800,
                          color: AppColors.muted, letterSpacing: 0.5)),
                  ),
                  ...filtered.map((ing) => _IngTile(ing: ing)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _statBox(String number, String label, {Color? color, VoidCallback? onTap}) {
    final box = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: onTap != null
            ? Border.all(color: (color ?? AppColors.accent).withOpacity(0.3))
            : null,
      ),
      child: Column(
        children: [
          Text(number, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
              color: color ?? AppColors.accent)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              if (onTap != null) ...[
                const SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios, size: 9, color: AppColors.muted),
              ],
            ],
          ),
        ],
      ),
    );
    if (onTap == null) return box;
    return GestureDetector(onTap: onTap, child: box);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _IngTile extends StatelessWidget {
  final String ing;
  const _IngTile({required this.ing});

  @override
  Widget build(BuildContext context) {
    final provider  = context.watch<MealProvider>();
    final isChecked = provider.isChecked(ing);
    final expiry    = isChecked ? provider.expiryOf(ing) : null;

    return InkWell(
      onTap: () => provider.toggleIngredient(ing),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Main row ────────────────────────
            Row(
              children: [
                Checkbox(
                  value: isChecked,
                  onChanged: (_) => provider.toggleIngredient(ing),
                  activeColor: AppColors.green,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Expanded(
                  child: Text(ing,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                        color: isChecked ? const Color(0xFF2C2C2C) : AppColors.muted,
                      )),
                ),
              ],
            ),

            // ── Expiry buttons (when checked) ───
            if (isChecked)
              Padding(
                padding: const EdgeInsets.fromLTRB(44, 0, 12, 2),
                child: Wrap(
                  spacing: 6, runSpacing: 4,
                  children: _expiryOptions.map((opt) {
                    final selected = expiry != null && _matchesOption(expiry.days, opt.days);
                    return GestureDetector(
                        onTap: () {
                          if (selected) {
                            // keep
                          } else {
                            provider.setExpiry(ing, opt.days);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: selected
                                ? _optionColor(opt.days).withOpacity(0.15)
                                : AppColors.bg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: selected
                                  ? _optionColor(opt.days)
                                  : AppColors.border,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            '${opt.emoji} ${opt.label}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? _optionColor(opt.days)
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                    );
                  }).toList(),
                ),
              ),

            // ── Owned amount (optional) ─────────
            if (isChecked && provider.unitOf(ing) != null)
              GestureDetector(
                onTap: () {}, // absorb taps so they don't toggle the checkbox
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(44, 4, 12, 8),
                  child: _OwnedAmountEditor(ing: ing),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _matchesOption(int days, int optDays) {
    if (optDays == 0) return days == 0;
    if (optDays == 1) return days == 1;
    if (optDays == 2) return days == 2 || days == 3;
    return days >= 4;
  }

  Color _optionColor(int optDays) {
    if (optDays == 0) return const Color(0xFFD32F2F);
    if (optDays == 1) return const Color(0xFFE07A3A);
    if (optDays == 2) return const Color(0xFFD4A017);
    return const Color(0xFF5A9E6F);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Optional "owned amount" editor shown under a checked ingredient.
// Leaving the field empty = no amount given → app behaves as before.

class _OwnedAmountEditor extends StatefulWidget {
  final String ing;
  const _OwnedAmountEditor({required this.ing});

  @override
  State<_OwnedAmountEditor> createState() => _OwnedAmountEditorState();
}

class _OwnedAmountEditorState extends State<_OwnedAmountEditor> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    final owned = context.read<MealProvider>().ownedOf(widget.ing);
    _ctrl = TextEditingController(
      text: owned == null
          ? ''
          : (owned.value == owned.value.roundToDouble()
              ? owned.value.round().toString()
              : owned.value.toString().replaceAll('.', ',')),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save(String unit) {
    final provider = context.read<MealProvider>();
    final value = double.tryParse(_ctrl.text.trim().replaceAll(',', '.'));
    provider.setOwned(
      widget.ing,
      value == null ? null : OwnedAmount(value, unit),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Unit comes from the recipes; no unit → nothing to measure, no editor.
    final unit = context.read<MealProvider>().unitOf(widget.ing);
    if (unit == null) return const SizedBox.shrink();

    final hasValue =
        double.tryParse(_ctrl.text.trim().replaceAll(',', '.')) != null;

    return Row(
      children: [
        Text('Mam:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: hasValue ? const Color(0xFF2E7D52) : AppColors.muted,
            )),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          height: 30,
          child: TextField(
            controller: _ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'ilość',
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.muted),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            onChanged: (_) {
              setState(() {});
              _save(unit);
            },
          ),
        ),
        const SizedBox(width: 6),
        Text(unit,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: hasValue ? const Color(0xFF2E7D52) : AppColors.muted,
            )),
        if (hasValue)
          GestureDetector(
            onTap: () {
              _ctrl.clear();
              setState(() {});
              _save(unit);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.close, size: 16, color: AppColors.muted),
            ),
          ),
      ],
    );
  }
}
