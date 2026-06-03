import 'dart:async';
import 'dart:io';

import '../models/auth_status.dart';
import '../util/cli_resolver.dart';

class AuthService {
  static const _executable = 'antigravity-usage';
  static const _statusTimeout = Duration(seconds: 5);
  static const _loginTimeout = Duration(minutes: 5);

  Process? _loginProcess;

  Future<AuthStatus> status() async {
    try {
      final exe = await CliResolver.resolve(_executable);
      final env = {'PATH': await CliResolver.enrichedPath()};
      final result = await Process.run(exe, ['status'], environment: env)
          .timeout(_statusTimeout);
      if (result.exitCode != 0) return AuthStatus.loggedOut;
      return parseAuthStatus(result.stdout?.toString() ?? '');
    } catch (_) {
      return AuthStatus.loggedOut;
    }
  }

  /// Runs `antigravity-usage login` to completion. Resolves true on success.
  /// While running, [cancelLogin] can terminate the OAuth flow.
  Future<bool> login() async {
    if (_loginProcess != null) return false;
    try {
      final exe = await CliResolver.resolve(_executable);
      final env = {'PATH': await CliResolver.enrichedPath()};
      _loginProcess = await Process.start(exe, ['login'], environment: env);
      final exitCode = await _loginProcess!.exitCode.timeout(_loginTimeout);
      return exitCode == 0;
    } catch (_) {
      return false;
    } finally {
      _loginProcess = null;
    }
  }

  void cancelLogin() {
    _loginProcess?.kill(ProcessSignal.sigterm);
    _loginProcess = null;
  }

  Future<bool> logout() async {
    try {
      final exe = await CliResolver.resolve(_executable);
      final env = {'PATH': await CliResolver.enrichedPath()};
      final result = await Process.run(exe, ['logout', '--all'], environment: env)
          .timeout(_statusTimeout);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}
