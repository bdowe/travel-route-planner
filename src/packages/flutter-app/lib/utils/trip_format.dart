// Shared trip-formatting helpers so the trips list, the home recent-trip tile,
// and the trip-detail header all speak the same language.

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _fmt(DateTime d) => '${_months[d.month - 1]} ${d.day}';

/// "Mon d – Mon d" from ISO start/end (same day collapses to one); null when
/// either date is missing or unparseable.
String? tripDateRange(String? startIso, String? endIso) {
  final a = DateTime.tryParse(startIso ?? '');
  final b = DateTime.tryParse(endIso ?? '');
  if (a == null || b == null) return null;
  final sameDay = a.year == b.year && a.month == b.month && a.day == b.day;
  return sameDay ? _fmt(a) : '${_fmt(a)} – ${_fmt(b)}';
}

/// "YYYY-MM-DD" from an ISO timestamp, falling back to the raw value.
String shortDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
