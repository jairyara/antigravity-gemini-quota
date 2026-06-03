import 'dart:convert';

import 'package:antigravity_quota_app/models/quota_data.dart';
import 'package:flutter_test/flutter_test.dart';

const _sampleCloudJson = '''
{
  "timestamp": "2026-05-20T13:17:53.799Z",
  "method": "google",
  "email": "jair.yara11@gmail.com",
  "models": [
    {"label": "Claude Opus 4.6 (Thinking)", "modelId": "claude-opus-4-6-thinking", "remainingPercentage": 1, "isExhausted": false, "resetTime": "2026-05-20T18:17:53Z", "timeUntilResetMs": 0, "isAutocompleteOnly": false},
    {"label": "Claude Sonnet 4.6 (Thinking)", "modelId": "claude-sonnet-4-6", "remainingPercentage": 1, "isExhausted": false, "resetTime": "2026-05-20T18:17:53Z", "timeUntilResetMs": 0, "isAutocompleteOnly": false},
    {"label": "Gemini 2.5 Pro", "modelId": "gemini-2.5-pro", "remainingPercentage": 1, "isExhausted": false, "resetTime": "2026-05-20T18:17:53Z", "timeUntilResetMs": 0, "isAutocompleteOnly": true},
    {"label": "Gemini 3.1 Flash Lite", "modelId": "gemini-2.5-flash-thinking", "remainingPercentage": 1, "isExhausted": false, "resetTime": "2026-05-20T18:17:53Z", "timeUntilResetMs": 0, "isAutocompleteOnly": true},
    {"label": "Gemini 3.1 Pro (High)", "modelId": "gemini-pro-agent", "remainingPercentage": 0.4, "isExhausted": false, "resetTime": "2026-05-24T18:25:17Z", "timeUntilResetMs": 0, "isAutocompleteOnly": false},
    {"label": "Gemini 3.1 Pro (High)", "modelId": "gemini-3.1-pro-high", "remainingPercentage": 0.4, "isExhausted": false, "resetTime": "2026-05-24T18:25:17Z", "timeUntilResetMs": 0, "isAutocompleteOnly": false},
    {"label": "Gemini 3.1 Pro (Low)", "modelId": "gemini-3.1-pro-low", "remainingPercentage": 0.4, "isExhausted": false, "resetTime": "2026-05-24T18:25:17Z", "timeUntilResetMs": 0, "isAutocompleteOnly": false},
    {"label": "GPT-OSS 120B (Medium)", "modelId": "gpt-oss-120b-medium", "remainingPercentage": 1, "isExhausted": false, "resetTime": "2026-05-20T18:17:53Z", "timeUntilResetMs": 0, "isAutocompleteOnly": false}
  ]
}
''';

void main() {
  group('QuotaData.parseCloudModels', () {
    test('filters isAutocompleteOnly and dedups by label', () {
      final json = jsonDecode(_sampleCloudJson) as Map<String, dynamic>;
      final models = QuotaData.parseCloudModels(json);

      final labels = models.map((m) => m.label).toList();

      // Autocomplete-only ones removed
      expect(labels, isNot(contains('Gemini 2.5 Pro')));
      expect(labels, isNot(contains('Gemini 3.1 Flash Lite')));

      // Label appears only once even though there are two modelIds for it
      expect(labels.where((l) => l == 'Gemini 3.1 Pro (High)').length, 1);
    });

    test('sorts by remainingPercentage ascending (most constrained first)', () {
      final json = jsonDecode(_sampleCloudJson) as Map<String, dynamic>;
      final models = QuotaData.parseCloudModels(json);

      expect(models.first.remainingPercentage, 0.4);
      expect(models.first.label, contains('Gemini 3.1 Pro'));
    });

    test('parses resetTime as local DateTime', () {
      final json = jsonDecode(_sampleCloudJson) as Map<String, dynamic>;
      final models = QuotaData.parseCloudModels(json);

      expect(models.first.resetTime.isUtc, isFalse);
    });
  });
}
