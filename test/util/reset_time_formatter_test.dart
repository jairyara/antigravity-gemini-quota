import 'package:antigravity_quota_app/util/reset_time_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatResetTime', () {
    // Wed 2026-05-20 14:00
    final now = DateTime(2026, 5, 20, 14, 0);

    test('multi-day reset uses abbreviated weekday', () {
      // Fri 2026-05-22 15:00 → 2d, viernes 3pm
      final reset = DateTime(2026, 5, 22, 15, 0);
      expect(formatResetTime(reset, now: now),
          'resetea en 2d · vie 3pm');
    });

    test('same-day hours away uses "hoy"', () {
      // Wed 18:00 → 4h, hoy 6pm
      final reset = DateTime(2026, 5, 20, 18, 0);
      expect(formatResetTime(reset, now: now), 'resetea en 4h · hoy 6pm');
    });

    test('next-day uses "mañana"', () {
      // Thu 09:30 → 19h, mañana 9:30am
      final reset = DateTime(2026, 5, 21, 9, 30);
      expect(formatResetTime(reset, now: now),
          'resetea en 19h · mañana 9:30am');
    });

    test('under an hour omits absolute part', () {
      final reset = DateTime(2026, 5, 20, 14, 30);
      expect(formatResetTime(reset, now: now), 'resetea en 30m');
    });

    test('hour with non-zero minutes shows minutes', () {
      final reset = DateTime(2026, 5, 22, 15, 25);
      expect(formatResetTime(reset, now: now),
          'resetea en 2d · vie 3:25pm');
    });

    test('past reset shows reseteando placeholder', () {
      final reset = DateTime(2026, 5, 20, 13, 0);
      expect(formatResetTime(reset, now: now), 'reseteando…');
    });

    test('midnight reset formats as 12am', () {
      // Thu 00:00
      final reset = DateTime(2026, 5, 21, 0, 0);
      expect(formatResetTime(reset, now: now),
          'resetea en 10h · mañana 12am');
    });
  });
}
