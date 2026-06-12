/// Quantity of an ingredient the user already owns.
/// Optional — when absent, a checked ingredient behaves as "fully owned".
class OwnedAmount {
  final double value;
  final String unit; // 'g' | 'kg' | 'ml' | 'l' | 'szt'

  const OwnedAmount(this.value, this.unit);

  static const units = ['g', 'kg', 'ml', 'l', 'szt'];

  /// Value converted to base unit (g / ml / szt).
  double get baseValue =>
      (unit == 'kg' || unit == 'l') ? value * 1000 : value;

  /// Base unit: kg→g, l→ml, otherwise unchanged.
  String get baseUnit =>
      unit == 'kg' ? 'g' : (unit == 'l' ? 'ml' : unit);

  String get label {
    final v = value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1).replaceAll('.', ',');
    return '$v $unit';
  }

  Map<String, dynamic> toJson() => {'v': value, 'u': unit};

  static OwnedAmount? fromJson(dynamic json) {
    if (json is! Map) return null;
    final v = json['v'];
    final u = json['u'];
    if (v is! num || u is! String || !units.contains(u)) return null;
    return OwnedAmount(v.toDouble(), u);
  }
}
