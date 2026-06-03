import 'dart:io';

/// Resolves the absolute path to a CLI binary at runtime.
///
/// When the app is launched from Finder/Dock, it inherits launchd's stripped
/// PATH (`/usr/bin:/bin:/usr/sbin:/sbin`) and can't find tools installed by
/// Homebrew or pipx. We ask the user's login shell to resolve the binary,
/// then cache the absolute path for the rest of the session.
class CliResolver {
  static final Map<String, String?> _cache = {};
  static String? _enrichedPath;

  /// Returns the absolute path of [name], or [name] itself if it cannot be
  /// resolved (so callers still get a sensible error from Process.run).
  static Future<String> resolve(String name) async {
    if (_cache.containsKey(name)) return _cache[name] ?? name;

    final resolved = await _viaLoginShell(name) ?? _viaKnownPaths(name);
    _cache[name] = resolved;
    return resolved ?? name;
  }

  /// PATH from the user's login shell, falling back to common locations.
  ///
  /// Pass this as `environment: {'PATH': await CliResolver.enrichedPath()}` so
  /// CLI shebangs like `#!/usr/bin/env node` can find their interpreter when
  /// the app is launched from Finder (where launchd's PATH is stripped).
  static Future<String> enrichedPath() async {
    if (_enrichedPath != null) return _enrichedPath!;
    final shellPath = await _shellPath();
    final fallback = [
      '/opt/homebrew/bin',
      '/usr/local/bin',
      '${Platform.environment['HOME'] ?? ''}/.local/bin',
      '/usr/bin',
      '/bin',
      '/usr/sbin',
      '/sbin',
    ].where((p) => p.isNotEmpty).join(':');
    _enrichedPath = shellPath ?? fallback;
    return _enrichedPath!;
  }

  static Future<String?> _shellPath() async {
    try {
      final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
      final result = await Process.run(shell, ['-lc', 'echo \$PATH'])
          .timeout(const Duration(seconds: 3));
      if (result.exitCode != 0) return null;
      final out = (result.stdout as String).trim();
      return out.isEmpty ? null : out;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _viaLoginShell(String name) async {
    try {
      final shell = Platform.environment['SHELL'] ?? '/bin/zsh';
      final result = await Process.run(shell, ['-lc', 'command -v $name'])
          .timeout(const Duration(seconds: 3));
      if (result.exitCode != 0) return null;
      final out = (result.stdout as String).trim();
      if (out.isEmpty) return null;
      return File(out).existsSync() ? out : null;
    } catch (_) {
      return null;
    }
  }

  static String? _viaKnownPaths(String name) {
    final home = Platform.environment['HOME'] ?? '';
    final candidates = [
      '/opt/homebrew/bin/$name',
      '/usr/local/bin/$name',
      '$home/.local/bin/$name',
      '/usr/bin/$name',
    ];
    for (final p in candidates) {
      if (File(p).existsSync()) return p;
    }
    return null;
  }
}
