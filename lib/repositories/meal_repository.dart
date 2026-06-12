import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/owned_amount.dart';

/// Handles all persistence for the meal planner.
/// Single responsibility: serialize/deserialize app state to SharedPreferences.
class MealRepository {
  static const _kChecked = 'checked_ingredients';
  static const _kPlan    = 'plan_meal_ids';
  static const _kExpiry  = 'ingredient_expiry';
  static const _kOwned   = 'ingredient_owned';

  // ── Checked ingredients ───────────────────────────

  Future<Set<String>> loadChecked() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_kChecked) ?? []).toSet();
  }

  Future<void> saveChecked(Set<String> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kChecked, items.toList());
  }

  // ── Meal plan ─────────────────────────────────────

  Future<List<String>> loadPlan() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_kPlan) ?? [];
  }

  Future<void> savePlan(List<String> mealIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kPlan, mealIds);
  }

  // ── Ingredient expiry ─────────────────────────────

  Future<Map<String, DateTime>> loadExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    final json  = prefs.getString(_kExpiry);
    if (json == null) return {};

    final raw    = Map<String, dynamic>.from(jsonDecode(json) as Map);
    final result = <String, DateTime>{};
    raw.forEach((k, v) {
      try { result[k] = DateTime.parse(v as String); } catch (_) {}
    });
    return result;
  }

  Future<void> saveExpiry(Map<String, DateTime> expiry) async {
    final prefs = await SharedPreferences.getInstance();
    final map   = expiry.map((k, v) => MapEntry(k, v.toIso8601String()));
    await prefs.setString(_kExpiry, jsonEncode(map));
  }

  // ── Owned amounts ─────────────────────────────────

  Future<Map<String, OwnedAmount>> loadOwned() async {
    final prefs = await SharedPreferences.getInstance();
    final json  = prefs.getString(_kOwned);
    if (json == null) return {};

    final raw    = Map<String, dynamic>.from(jsonDecode(json) as Map);
    final result = <String, OwnedAmount>{};
    raw.forEach((k, v) {
      final owned = OwnedAmount.fromJson(v);
      if (owned != null) result[k] = owned;
    });
    return result;
  }

  Future<void> saveOwned(Map<String, OwnedAmount> owned) async {
    final prefs = await SharedPreferences.getInstance();
    final map   = owned.map((k, v) => MapEntry(k, v.toJson()));
    await prefs.setString(_kOwned, jsonEncode(map));
  }
}
