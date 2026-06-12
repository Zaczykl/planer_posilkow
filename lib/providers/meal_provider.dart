import 'package:flutter/material.dart';
import '../models/meal.dart';
import '../models/expiry_info.dart';
import '../models/owned_amount.dart';
import '../data/meals_data.dart';
import '../data/substitutes_data.dart';
import '../repositories/meal_repository.dart';
import '../utils/amount_utils.dart';

export '../models/expiry_info.dart';
export '../models/owned_amount.dart';

enum SortMode { match, alpha, kcal }
enum FilterMode { all, full, partial }

class MealProvider extends ChangeNotifier {
  final MealRepository _repo;

  final Set<String>              _checked = {};
  final List<Meal?>              _plan    = [null, null, null];
  final Map<String, DateTime>    _expiry  = {};
  final Map<String, OwnedAmount> _owned   = {};

  SortMode   sortMode   = SortMode.match;
  FilterMode filterMode = FilterMode.all;

  MealProvider(this._repo) {
    _load();
  }

  // ── Load state from repository ────────────────────

  Future<void> _load() async {
    _checked.addAll(await _repo.loadChecked());

    final planIds = await _repo.loadPlan();
    for (int i = 0; i < planIds.length && i < 3; i++) {
      if (planIds[i].isNotEmpty) {
        _plan[i] = allMeals.where((m) => m.id == planIds[i]).firstOrNull;
      }
    }

    _expiry.addAll(await _repo.loadExpiry());
    _owned.addAll(await _repo.loadOwned());

    notifyListeners();
  }

  // ── Ingredient state ──────────────────────────────

  Set<String> get checked    => _checked;
  int  get checkedCount      => _checked.length;
  bool isChecked(String ing) => _checked.contains(ing);

  int get fullMatchCount =>
      allMeals.where((m) => matchOf(m).pct == 100).length;

  void toggleIngredient(String ing) {
    if (_checked.contains(ing)) {
      _checked.remove(ing);
      _expiry.remove(ing);
      _owned.remove(ing);
      _repo.saveOwned(_owned);
    } else {
      _checked.add(ing);
      _setDefaultExpiry(ing);
    }
    notifyListeners();
    _repo.saveChecked(_checked);
    _repo.saveExpiry(_expiry);
  }

  void clearIngredients() {
    for (final ing in _checked) { _expiry.remove(ing); }
    _checked.clear();
    _owned.clear();
    notifyListeners();
    _repo.saveChecked(_checked);
    _repo.saveExpiry(_expiry);
    _repo.saveOwned(_owned);
  }

  void _setDefaultExpiry(String ing) {
    if (_expiry.containsKey(ing)) return;
    final today = _today();
    _expiry[ing] = today.add(const Duration(days: 5));
  }

  // ── Substitutes ───────────────────────────────────

  /// Checked (in-fridge) ingredients that can substitute [ing].
  List<String> availableSubstitutes(String ing) =>
      substitutesOf(ing).where(_checked.contains).toList()..sort();

  /// Match of [meal] against the fridge, with substitutes counted as owned.
  MealMatch matchOf(Meal meal) =>
      meal.calcMatch(_checked, substitutesFor: availableSubstitutes);

  // ── Owned amounts ─────────────────────────────────

  Map<String, String>? _unitCache;

  /// Base unit (g/ml/szt) that [ing] uses in recipes,
  /// or null when no recipe gives a measurable amount for it.
  String? unitOf(String ing) {
    _unitCache ??= _buildUnitCache();
    return _unitCache![ing];
  }

  Map<String, String> _buildUnitCache() {
    final map = <String, String>{};
    for (final meal in allMeals) {
      for (final i in meal.ingredients) {
        if (map.containsKey(i.name)) continue;
        final parsed = parseAmountValue(i.amount);
        if (parsed != null) map[i.name] = parsed.unit;
      }
    }
    return map;
  }

  /// Owned quantity of [ing], or null when not specified
  /// (null = behaves as before: checked means fully owned).
  OwnedAmount? ownedOf(String ing) => _owned[ing];

  void setOwned(String ing, OwnedAmount? owned) {
    if (owned == null || owned.value <= 0) {
      _owned.remove(ing);
    } else {
      _owned[ing] = owned;
    }
    notifyListeners();
    _repo.saveOwned(_owned);
  }

  // ── Expiry state ──────────────────────────────────

  ExpiryInfo? expiryOf(String ing) {
    final d = _expiry[ing];
    return d == null ? null : ExpiryInfo(daysUntil(d));
  }

  void setExpiry(String ing, int daysFromNow) {
    _expiry[ing] = _today().add(Duration(days: daysFromNow));
    notifyListeners();
    _repo.saveExpiry(_expiry);
  }

  /// Returns ingredient names that are checked AND expire within [withinDays].
  List<String> urgentIngredients({int withinDays = 1}) => _checked
      .where((ing) {
        final e = expiryOf(ing);
        return e != null && e.days <= withinDays;
      })
      .toList();

  /// Returns checked ingredient names of [meal] expiring within [withinDays].
  List<String> urgentIngredientsForMeal(Meal meal, {int withinDays = 3}) =>
      meal.ingredientNames.where((ing) {
        if (!_checked.contains(ing)) return false;
        final e = expiryOf(ing);
        return e != null && e.days <= withinDays;
      }).toList();

  /// Minimum days-to-expiry among checked+expiring ingredients of [meal].
  /// Returns null if no ingredient has an expiry date set.
  int? urgencyScore(Meal meal) {
    int? best;
    for (final ing in meal.ingredientNames) {
      if (!_checked.contains(ing)) continue;
      final e = expiryOf(ing);
      if (e == null) continue;
      if (best == null || e.days < best) best = e.days;
    }
    return best;
  }

  /// Returns 0–3 indicating the urgency bucket for display in the meals list:
  ///   0 = today, 1 = tomorrow, 2 = 2-3 days, 3 = longer / no expiry
  int urgencyBracketOf(Meal meal) {
    final score = urgencyScore(meal);
    if (score == null || score > 3) return 3;
    if (score == 0) return 0;
    if (score == 1) return 1;
    return 2;
  }

  // ── Plan state ────────────────────────────────────

  List<Meal?> get plan => _plan;
  int  get planCount       => _plan.where((m) => m != null).length;
  bool isMealInPlan(String id) => _plan.any((m) => m?.id == id);
  int  planSlotOf(String id)   => _plan.indexWhere((m) => m?.id == id);

  bool toggleMeal(Meal meal) {
    final existing = _plan.indexWhere((m) => m?.id == meal.id);
    if (existing != -1) {
      _plan[existing] = null;
      notifyListeners();
      _savePlan();
      return true;
    }
    final empty = _plan.indexWhere((m) => m == null);
    if (empty == -1) return false;
    _plan[empty] = meal;
    notifyListeners();
    _savePlan();
    return true;
  }

  void removeFromPlan(int slot) {
    _plan[slot] = null;
    notifyListeners();
    _savePlan();
  }

  void clearPlan() {
    _plan.fillRange(0, 3, null);
    notifyListeners();
    _savePlan();
  }

  void _savePlan() =>
      _repo.savePlan(_plan.map((m) => m?.id ?? '').toList());

  // ── Meal lists: filtering + sorting ──────────────

  List<Meal> getFilteredMeals(MealCategory category) {
    final source = category == MealCategory.sniadanie ? sniadania : obiady;
    return _applySort(_applyFilter(source.toList()));
  }

  List<Meal> _applyFilter(List<Meal> items) {
    switch (filterMode) {
      case FilterMode.full:
        return items.where((m) => matchOf(m).pct == 100).toList();
      case FilterMode.partial:
        return items.where((m) {
          final p = matchOf(m).pct;
          return p > 0 && p < 100;
        }).toList();
      case FilterMode.all:
        return items;
    }
  }

  List<Meal> _applySort(List<Meal> items) {
    switch (sortMode) {
      case SortMode.alpha:
        return items..sort((a, b) => a.name.compareTo(b.name));
      case SortMode.kcal:
        return items..sort((a, b) => b.kcal.compareTo(a.kcal));
      case SortMode.match:
        return items..sort(_compareByUrgencyThenMatch);
    }
  }

  int _compareByUrgencyThenMatch(Meal a, Meal b) {
    final ua = urgencyScore(a);
    final ub = urgencyScore(b);
    if (ua != null && ub != null && ua != ub) return ua.compareTo(ub);
    if (ua != null && ub == null) return -1;
    if (ua == null && ub != null) return 1;
    return matchOf(b).pct.compareTo(matchOf(a).pct);
  }

  List<Meal> searchRecipes(String query, {MealCategory? category}) {
    final q      = query.toLowerCase();
    final source = category == null
        ? allMeals
        : (category == MealCategory.sniadanie ? sniadania : obiady);
    if (q.isEmpty) return source.toList();
    return source.where((m) =>
        m.name.toLowerCase().contains(q) ||
        m.ingredientNames.any((i) => i.toLowerCase().contains(q))).toList();
  }

  void setSortMode(SortMode mode)     { sortMode = mode;   notifyListeners(); }
  void setFilterMode(FilterMode mode) { filterMode = mode; notifyListeners(); }

  // ── Private helpers ───────────────────────────────

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }
}
