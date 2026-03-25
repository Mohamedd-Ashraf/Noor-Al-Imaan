/// Shared Hijri (Islamic) calendar utilities.
///
/// Uses the Tabular Islamic Calendar algorithm based on Julian Day Numbers.
/// The tabular calendar may differ from actual moon-sighting results by ±1–2
/// days — the user-configurable [offsetDays] in settings covers this gap.

// ── Gregorian ↔ Julian Day Number ──────────────────────────────────────────

/// Gregorian date → Julian Day Number (proleptic Gregorian calendar).
int gregToJdn(DateTime d) {
  final a = (14 - d.month) ~/ 12;
  final y = d.year + 4800 - a;
  final m = d.month + 12 * a - 3;
  return d.day +
      (153 * m + 2) ~/ 5 +
      365 * y +
      y ~/ 4 -
      y ~/ 100 +
      y ~/ 400 -
      32045;
}

// ── Julian Day Number ↔ Hijri ───────────────────────────────────────────────

/// Julian Day Number → Hijri date as `[year, month, day]`.
List<int> jdnToHijri(int jdn) {
  final l = jdn - 1948440 + 10632;
  final n = (l - 1) ~/ 10631;
  final l2 = l - 10631 * n + 354;
  final j = ((10985 - l2) ~/ 5316) * ((50 * l2) ~/ 17719) +
      (l2 ~/ 5670) * ((43 * l2) ~/ 15238);
  final l3 = l2 -
      ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
      (j ~/ 16) * ((15238 * j) ~/ 43) +
      29;
  final month = (24 * l3) ~/ 709;
  final day = l3 - (709 * month) ~/ 24;
  final year = 30 * n + j - 30;
  return [year, month, day];
}

/// Hijri date → Julian Day Number.
int hijriToJdn(int hy, int hm, int hd) {
  return 1948440 +
      (hy - 1) * 354 +
      (11 * hy + 3) ~/ 30 +
      (59 * hm - 58) ~/ 2 +
      hd;
}

// ── High-level helpers ───────────────────────────────────────────────────────

/// Returns the Hijri date for today, shifted by [offsetDays].
/// Result: `[hYear, hMonth, hDay]`.
List<int> todayHijri(int offsetDays) {
  final today = DateTime.now();
  final jdn = gregToJdn(today) + offsetDays;
  return jdnToHijri(jdn);
}

const List<String> _arMonths = [
  'محرم',
  'صفر',
  'ربيع الأول',
  'ربيع الثاني',
  'جمادى الأولى',
  'جمادى الآخرة',
  'رجب',
  'شعبان',
  'رمضان',
  'شوال',
  'ذو القعدة',
  'ذو الحجة',
];

const List<String> _enMonths = [
  'Muharram',
  'Safar',
  'Rabi Al-Awwal',
  'Rabi Al-Thani',
  'Jumada Al-Ula',
  'Jumada Al-Akhira',
  'Rajab',
  "Sha'ban",
  'Ramadan',
  'Shawwal',
  "Dhul-Qi'dah",
  'Dhul-Hijjah',
];

/// Formats a Hijri [hYear]/[hMonth]/[hDay] as a localised string.
///
/// Arabic example: ٢٧ رمضان ١٤٤٧
/// English example: 27 Ramadan 1447
String formatHijriDate(int hYear, int hMonth, int hDay,
    {required bool isAr}) {
  final monthName = isAr
      ? _arMonths[(hMonth - 1).clamp(0, 11)]
      : _enMonths[(hMonth - 1).clamp(0, 11)];
  if (isAr) {
    return '${_toArabicNumerals(hDay)} $monthName ${_toArabicNumerals(hYear)}';
  }
  return '$hDay $monthName $hYear';
}

String _toArabicNumerals(int n) {
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return n.toString().split('').map((c) {
    final d = int.tryParse(c);
    return d != null ? digits[d] : c;
  }).join();
}

// ── Ramadan window helper ────────────────────────────────────────────────────

/// Returns true when today (with [offsetDays] applied) is within the window:
/// [1 Ramadan − 3 days, last day of Ramadan + 3 days].
bool isRamadanPeriod(int offsetDays) {
  final today = DateTime.now();
  final todayJdn = gregToJdn(today) + offsetDays;
  final hYear = jdnToHijri(todayJdn)[0];

  final ramadanStartJdn = hijriToJdn(hYear, 9, 1);
  final shawwalFirstJdn = hijriToJdn(hYear, 10, 1);
  final ramadanEndJdn = shawwalFirstJdn - 1;

  return todayJdn >= ramadanStartJdn - 3 && todayJdn <= ramadanEndJdn + 3;
}
