import 'dart:io';

import 'package:antigravity_quota_app/services/process_runner.dart';
import 'package:antigravity_quota_app/services/quota_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRunner implements ProcessRunner {
  final int exitCode;
  final String stdout;
  final String stderr;
  final Object? throwError;

  FakeRunner({
    this.exitCode = 0,
    this.stdout = '',
    this.stderr = '',
    this.throwError,
  });

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> args, {
    Map<String, String>? environment,
  }) async {
    if (throwError != null) throw throwError!;
    return ProcessResult(0, exitCode, stdout, stderr);
  }
}

const _localJson = '''
{
  "timestamp": "2026-05-20T14:32:11.201Z",
  "method": "local",
  "email": "jair.yara11@gmail.com",
  "models": [
    {"label": "Claude Opus 4.6 (Thinking)", "modelId": "x", "remainingPercentage": 1, "isExhausted": false, "resetTime": "2026-05-20T19:27:46Z", "isAutocompleteOnly": false},
    {"label": "Gemini 3.1 Pro (High)", "modelId": "y", "remainingPercentage": 0.4, "isExhausted": false, "resetTime": "2026-05-20T19:27:46Z", "isAutocompleteOnly": false}
  ],
  "promptCredits": {
    "available": 500,
    "monthly": 50000,
    "usedPercentage": 0.99,
    "remainingPercentage": 0.01
  }
}
''';

const _googleFallbackJson = '''
{
  "timestamp": "2026-05-20T14:32:11.201Z",
  "method": "google",
  "models": [
    {"label": "Claude Opus 4.6 (Thinking)", "modelId": "x", "remainingPercentage": 1, "isExhausted": false, "resetTime": "2026-05-20T19:27:46Z", "isAutocompleteOnly": false}
  ]
}
''';

void main() {
  group('QuotaService.fetch', () {
    test('parses models AND promptCredits when IDE is running (local method)',
        () async {
      final svc = QuotaService(runner: FakeRunner(stdout: _localJson));
      final data = await svc.fetch();
      expect(data.models.length, 2);
      expect(data.credits, isNotNull);
      expect(data.credits!.available, 500);
      expect(data.credits!.monthly, 50000);
    });

    test('parses models with credits=null when IDE closed (google fallback)',
        () async {
      final svc =
          QuotaService(runner: FakeRunner(stdout: _googleFallbackJson));
      final data = await svc.fetch();
      expect(data.models.length, 1);
      expect(data.credits, isNull);
    });

    test('throws QuotaException on non-zero exit', () {
      final svc = QuotaService(
          runner: FakeRunner(exitCode: 1, stderr: 'not authenticated'));
      expect(svc.fetch(), throwsA(isA<QuotaException>()));
    });

    test('throws QuotaException on invalid JSON', () {
      final svc = QuotaService(runner: FakeRunner(stdout: 'nope'));
      expect(svc.fetch(), throwsA(isA<QuotaException>()));
    });
  });
}
