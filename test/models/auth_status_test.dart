import 'package:antigravity_quota_app/models/auth_status.dart';
import 'package:flutter_test/flutter_test.dart';

const _loggedInOutput = '''
📍 Antigravity Usage Status
────────────────────────────────────────
✅ Logged in: Yes
📧 Email: ja**@gmail.com
⏰ Token expires: 5/20/2026, 9:53:09 AM
''';

const _loggedOutOutput = '''
📍 Antigravity Usage Status
────────────────────────────────────────
❌ Logged in: No
''';

const _notFoundOutput = "⚠️  Account 'fake@gmail.com' not found.";

void main() {
  group('parseAuthStatus', () {
    test('parses logged-in output with email + expiry', () {
      final s = parseAuthStatus(_loggedInOutput);
      expect(s.loggedIn, isTrue);
      expect(s.email, 'ja**@gmail.com');
      expect(s.expiresAt, isNotNull);
      expect(s.expiresAt!.year, 2026);
      expect(s.expiresAt!.month, 5);
      expect(s.expiresAt!.day, 20);
      expect(s.expiresAt!.hour, 9);
      expect(s.expiresAt!.minute, 53);
    });

    test('parses logged-out output', () {
      final s = parseAuthStatus(_loggedOutOutput);
      expect(s.loggedIn, isFalse);
      expect(s.email, isNull);
    });

    test('returns loggedOut when output has no Logged-in line', () {
      expect(parseAuthStatus(_notFoundOutput).loggedIn, isFalse);
      expect(parseAuthStatus('').loggedIn, isFalse);
    });

    test('handles PM hours correctly', () {
      const pmOut = '''
✅ Logged in: Yes
📧 Email: x@y.com
⏰ Token expires: 1/15/2026, 3:30:00 PM
''';
      final s = parseAuthStatus(pmOut);
      expect(s.expiresAt!.hour, 15);
    });

    test('handles 12 AM midnight as hour 0', () {
      const midnight = '''
✅ Logged in: Yes
📧 Email: x@y.com
⏰ Token expires: 1/15/2026, 12:00:00 AM
''';
      expect(parseAuthStatus(midnight).expiresAt!.hour, 0);
    });
  });
}
