import 'dart:convert';

import '../models/quota_data.dart';
import '../util/cli_resolver.dart';
import 'process_runner.dart';

class QuotaException implements Exception {
  final String message;
  QuotaException(this.message);
  @override
  String toString() => 'QuotaException: $message';
}

class QuotaService {
  static const _executable = 'antigravity-usage';
  static const _args = ['quota', '--json'];
  static const _timeout = Duration(seconds: 10);

  final ProcessRunner _runner;

  QuotaService({ProcessRunner runner = const SystemProcessRunner()})
      : _runner = runner;

  Future<QuotaData> fetch() async {
    final String stdout;
    final int exitCode;
    final String stderr;
    try {
      final exe = await CliResolver.resolve(_executable);
      final env = {'PATH': await CliResolver.enrichedPath()};
      final r = await _runner.run(exe, _args, environment: env).timeout(_timeout);
      stdout = r.stdout?.toString() ?? '';
      stderr = r.stderr?.toString() ?? '';
      exitCode = r.exitCode;
    } catch (e) {
      throw QuotaException('subprocess failed: $e');
    }

    if (exitCode != 0) {
      throw QuotaException('antigravity-usage exited $exitCode: $stderr');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(stdout) as Map<String, dynamic>;
    } catch (e) {
      throw QuotaException('invalid JSON from CLI: $e');
    }

    return QuotaData(
      models: QuotaData.parseCloudModels(json),
      credits: QuotaData.parsePromptCredits(json),
      fetchedAt: DateTime.now(),
      isStale: false,
    );
  }
}
