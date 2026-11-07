/// Portuguese-style formatting used across the app. No locale package is
/// needed for these few, fixed formats.
library;

String _two(int n) => n.toString().padLeft(2, '0');

/// "4,5" or "9": decimal comma, no trailing ",0".
String formatNumber(double v) =>
    (v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1))
        .replaceAll('.', ',');

/// "1 avaliação", "3 avaliações".
String formatCount(int n, String one, String many) =>
    '$n ${n == 1 ? one : many}';

String formatPercent(double v) => '${formatNumber(v)}%';

/// "14:05".
String formatClock(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

/// "03/11/2026".
String formatDate(DateTime t) => '${_two(t.day)}/${_two(t.month)}/${t.year}';

/// Running timer: "04:09", or "1:04:09" past an hour.
String formatTimer(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  return h > 0 ? '$h:${_two(m)}:${_two(s)}' : '${_two(m)}:${_two(s)}';
}

/// Human duration: "45 s", "4 min 09 s", "1 h 04 min".
String formatDuration(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  if (h > 0) return '$h h ${_two(m)} min';
  if (m > 0) return '$m min ${_two(s)} s';
  return '$s s';
}
