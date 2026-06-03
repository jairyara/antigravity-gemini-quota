const _weekdaysEs = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

String formatResetTime(DateTime resetTime, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final diff = resetTime.difference(reference);

  if (diff.isNegative) return 'reseteando…';

  final relative = _relative(diff);
  final absolute = _absolute(resetTime, reference, diff);
  if (absolute == null) return 'resetea en $relative';
  return 'resetea en $relative · $absolute';
}

String _relative(Duration d) {
  if (d.inDays >= 1) return '${d.inDays}d';
  if (d.inHours >= 1) return '${d.inHours}h';
  if (d.inMinutes >= 1) return '${d.inMinutes}m';
  return '<1m';
}

String? _absolute(DateTime reset, DateTime now, Duration diff) {
  if (diff.inMinutes < 60) return null;

  final time = _formatClock(reset);

  final today = DateTime(now.year, now.month, now.day);
  final resetDay = DateTime(reset.year, reset.month, reset.day);
  final dayDelta = resetDay.difference(today).inDays;

  if (dayDelta == 0) return 'hoy $time';
  if (dayDelta == 1) return 'mañana $time';
  return '${_weekdaysEs[reset.weekday - 1]} $time';
}

String _formatClock(DateTime dt) {
  final hour24 = dt.hour;
  final minute = dt.minute;
  final isPm = hour24 >= 12;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final suffix = isPm ? 'pm' : 'am';
  if (minute == 0) return '$hour12$suffix';
  final mm = minute.toString().padLeft(2, '0');
  return '$hour12:$mm$suffix';
}
