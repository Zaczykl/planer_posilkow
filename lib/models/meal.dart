import 'package:flutter/material.dart';

class Ingredient {
  final String name;
  final String amount;
  const Ingredient(this.name, this.amount);
}

enum MealCategory { sniadanie, obiad }

class Meal {
  final String id;
  final String name;
  final int kcal;
  final List<Ingredient> ingredients;
  final MealCategory category;
  final String preparation;

  const Meal({
    required this.id,
    required this.name,
    required this.kcal,
    required this.ingredients,
    required this.category,
    required this.preparation,
  });

  List<String> get ingredientNames => ingredients.map((i) => i.name).toList();

  /// [substitutesFor] (optional) returns available substitutes for a missing
  /// ingredient; when non-empty, the ingredient counts as owned (substituted).
  MealMatch calcMatch(Set<String> checked,
      {List<String> Function(String name)? substitutesFor}) {
    if (checked.isEmpty) {
      return MealMatch(pct: 0, have: const [], missing: ingredients);
    }
    final have        = <Ingredient>[];
    final missing     = <Ingredient>[];
    final substituted = <Ingredient>[];
    for (final i in ingredients) {
      if (checked.contains(i.name)) {
        have.add(i);
      } else if (substitutesFor != null && substitutesFor(i.name).isNotEmpty) {
        substituted.add(i);
      } else {
        missing.add(i);
      }
    }
    final pct = ((have.length + substituted.length) / ingredients.length * 100)
        .round();
    return MealMatch(
        pct: pct, have: have, missing: missing, substituted: substituted);
  }
}

class MealMatch {
  final int pct;
  final List<Ingredient> have;
  final List<Ingredient> missing;

  /// Missing in the fridge, but an available substitute covers them.
  final List<Ingredient> substituted;

  const MealMatch({
    required this.pct,
    required this.have,
    required this.missing,
    this.substituted = const [],
  });

  Color get barColor {
    if (pct == 100) return const Color(0xFF5A9E6F);
    if (pct > 0)    return const Color(0xFFE07A3A);
    return const Color(0xFFDDDDDD);
  }
}
