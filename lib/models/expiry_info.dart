import 'package:flutter/material.dart';

/// Returns the number of days from today to [date].
/// Negative value means the date has already passed.
int daysUntil(DateTime date) {
  final now   = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d     = DateTime(date.year, date.month, date.day);
  return d.difference(today).inDays;
}

/// Describes how soon an ingredient expires.
class ExpiryInfo {
  final int days;
  const ExpiryInfo(this.days);

  bool get isExpired => days < 0;
  bool get isUrgent  => days <= 1;  // today or tomorrow
  bool get isSoon    => days <= 3;  // up to 3 days

  String get label {
    if (days < 0)  return 'Przeterminowane';
    if (days == 0) return 'Dziś';
    if (days == 1) return 'Jutro';
    if (days <= 3) return '2–3 dni';
    return 'Dłużej';
  }

  Color get color {
    if (days < 0)  return const Color(0xFF8B0000);
    if (days == 0) return const Color(0xFFD32F2F);
    if (days == 1) return const Color(0xFFE07A3A);
    if (days <= 3) return const Color(0xFFD4A017);
    return const Color(0xFF5A9E6F);
  }

  String get emoji {
    if (days < 0)  return '💀';
    if (days == 0) return '🔴';
    if (days == 1) return '🟠';
    if (days <= 3) return '🟡';
    return '🟢';
  }
}
