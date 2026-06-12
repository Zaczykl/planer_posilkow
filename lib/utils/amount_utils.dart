/// Multiplies the leading number in an amount string by [n].
///
/// Examples:
///   multiplyAmount('120 g', 3)   → '360 g'
///   multiplyAmount('1,5 kg', 2)  → '3 kg'
///   multiplyAmount('2 szt', 4)   → '8 szt'
String multiplyAmount(String amount, int n) {
  if (n <= 1) return amount;

  final match = RegExp(r'^(\d+(?:[.,]\d+)?)(.*)').firstMatch(amount);
  if (match == null) return amount;

  final parsed = double.tryParse(match.group(1)!.replaceAll(',', '.'));
  if (parsed == null) return amount;

  final result    = parsed * n;
  final resultStr = result == result.roundToDouble()
      ? result.round().toString()
      : result.toStringAsFixed(1).replaceAll('.', ',');

  return '$resultStr${match.group(2)}';
}

/// Parses the leading "number + unit" of a recipe amount string into
/// a base-unit value (kg→g, l→ml). Returns null for non-numeric amounts
/// like 'do smaku'.
///
/// Examples:
///   parseAmountValue('120 g')        → (value: 120, unit: 'g')
///   parseAmountValue('1,5 kg')       → (value: 1500, unit: 'g')
///   parseAmountValue('375 ml')       → (value: 375, unit: 'ml')
///   parseAmountValue('56 g (1 szt)') → (value: 56, unit: 'g')
({double value, String unit})? parseAmountValue(String amount) {
  final m = RegExp(r'^(\d+(?:[.,]\d+)?)\s*(g|kg|ml|l|szt)\b')
      .firstMatch(amount.trim());
  if (m == null) return null;

  var v = double.tryParse(m.group(1)!.replaceAll(',', '.'));
  if (v == null) return null;
  var u = m.group(2)!;

  if (u == 'kg') { v *= 1000; u = 'g'; }
  if (u == 'l')  { v *= 1000; u = 'ml'; }
  return (value: v, unit: u);
}

/// Formats a base-unit value back to a display string, e.g. 250 + 'g' → '250 g'.
String formatAmountValue(double value, String unit) {
  final v = value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(1).replaceAll('.', ',');
  return '$v $unit';
}
