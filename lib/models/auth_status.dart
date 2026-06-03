class AuthStatus {
  final bool loggedIn;
  final String? email;
  final DateTime? expiresAt;

  const AuthStatus({
    required this.loggedIn,
    this.email,
    this.expiresAt,
  });

  static const loggedOut = AuthStatus(loggedIn: false);
}

AuthStatus parseAuthStatus(String stdout) {
  final loggedInMatch =
      RegExp(r'Logged in:\s*(Yes|No)', caseSensitive: false).firstMatch(stdout);
  if (loggedInMatch == null) return AuthStatus.loggedOut;

  final loggedIn = loggedInMatch.group(1)!.toLowerCase() == 'yes';
  if (!loggedIn) return AuthStatus.loggedOut;

  final emailMatch = RegExp(r'Email:\s*(\S+)').firstMatch(stdout);
  final expiresMatch =
      RegExp(r'Token expires:\s*(.+)').firstMatch(stdout);

  return AuthStatus(
    loggedIn: true,
    email: emailMatch?.group(1)?.trim(),
    expiresAt: expiresMatch != null ? _parseUsDate(expiresMatch.group(1)!) : null,
  );
}

/// Parses "5/20/2026, 9:53:09 AM" → DateTime (local). Returns null if unparseable.
DateTime? _parseUsDate(String raw) {
  final m = RegExp(
          r'(\d{1,2})/(\d{1,2})/(\d{4}),\s*(\d{1,2}):(\d{2}):(\d{2})\s*(AM|PM)',
          caseSensitive: false)
      .firstMatch(raw.trim());
  if (m == null) return null;

  final month = int.parse(m.group(1)!);
  final day = int.parse(m.group(2)!);
  final year = int.parse(m.group(3)!);
  var hour = int.parse(m.group(4)!);
  final minute = int.parse(m.group(5)!);
  final second = int.parse(m.group(6)!);
  final isPm = m.group(7)!.toUpperCase() == 'PM';

  if (hour == 12) hour = 0;
  if (isPm) hour += 12;

  return DateTime(year, month, day, hour, minute, second);
}
