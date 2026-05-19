import 'dart:convert';
import 'dart:io';
import '../models/gemini_data.dart';

class GeminiCliService {
  static const _historyDir = '.gemini/history';
  static const _credsFile = '.gemini/oauth_creds.json';

  // Common install locations for the `gemini` CLI. macOS GUI apps launched
  // from Finder don't inherit the shell PATH, so we fall back to absolute
  // paths when a bare `gemini` lookup fails.
  static const _fallbackBinaryPaths = [
    '/opt/homebrew/bin/gemini',
    '/usr/local/bin/gemini',
  ];

  Future<GeminiCliData> fetchData() async {
    try {
      final installed = await _checkInstalled();
      if (!installed.$1) return GeminiCliData.notInstalled();

      final auth = await _checkAuth();
      final projects = await _readProjects();
      final activity = _buildActivityMap(projects);

      return GeminiCliData(
        isInstalled: true,
        version: installed.$2,
        isAuthenticated: auth.$1,
        isTokenExpired: auth.$2,
        projects: projects,
        activityByDay: activity,
        fetchedAt: DateTime.now(),
      );
    } catch (_) {
      return GeminiCliData.notInstalled();
    }
  }

  Future<(bool, String)> _checkInstalled() async {
    for (final exe in ['gemini', ..._fallbackBinaryPaths]) {
      try {
        final result = await Process.run(exe, ['--version'])
            .timeout(const Duration(seconds: 5));
        if (result.exitCode == 0) {
          final version = (result.stdout as String).trim();
          return (true, version);
        }
      } catch (_) {
        // Try next candidate.
      }
    }
    return (false, '');
  }

  Future<(bool, bool)> _checkAuth() async {
    final home = Platform.environment['HOME'] ?? '';
    final file = File('$home/$_credsFile');
    if (!await file.exists()) return (false, false);

    try {
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      // If a refresh_token is present the CLI renews access tokens automatically —
      // treat the session as valid regardless of the short-lived expiry_date.
      final hasRefreshToken = (json['refresh_token'] as String?)?.isNotEmpty == true;
      if (hasRefreshToken) return (true, false);

      final expiryMs = (json['expiry_date'] as num?)?.toInt();
      if (expiryMs == null) return (true, false);
      final isExpired = DateTime.fromMillisecondsSinceEpoch(expiryMs)
          .isBefore(DateTime.now());
      return (true, isExpired);
    } catch (_) {
      return (false, false);
    }
  }

  Future<List<GeminiProject>> _readProjects() async {
    final home = Platform.environment['HOME'] ?? '';
    if (home.isEmpty) return [];
    final dir = Directory('$home/$_historyDir');
    if (!await dir.exists()) return [];

    final projects = <GeminiProject>[];
    try {
      await for (final entry in dir.list(followLinks: false)) {
        try {
          if (entry is Directory) {
            final name = entry.path.split('/').last;
            if (name.isEmpty || name.startsWith('.')) continue;
            final stat = await entry.stat();
            projects.add(GeminiProject(name: name, lastUsed: stat.modified));
          }
        } catch (_) {
          // Skip entries that fail to stat (permissions, transient files, …).
        }
      }
    } catch (_) {
      // Directory listing failed — return whatever we collected.
    }

    projects.sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    return projects;
  }

  Map<String, int> _buildActivityMap(List<GeminiProject> projects) {
    final map = <String, int>{};
    for (final p in projects) {
      final key = _dateKey(p.lastUsed);
      map[key] = (map[key] ?? 0) + 1;
    }
    return map;
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
