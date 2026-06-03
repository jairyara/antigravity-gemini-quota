import 'model_quota.dart';
import 'prompt_credits.dart';

class QuotaData {
  final List<ModelQuota> models;
  final PromptCredits? credits;
  final DateTime fetchedAt;
  final bool isStale;

  const QuotaData({
    required this.models,
    required this.credits,
    required this.fetchedAt,
    required this.isStale,
  });

  ModelQuota? get mostConstrained =>
      models.isEmpty ? null : models.first;

  QuotaData copyWith({
    List<ModelQuota>? models,
    PromptCredits? credits,
    bool clearCredits = false,
    DateTime? fetchedAt,
    bool? isStale,
  }) {
    return QuotaData(
      models: models ?? this.models,
      credits: clearCredits ? null : (credits ?? this.credits),
      fetchedAt: fetchedAt ?? this.fetchedAt,
      isStale: isStale ?? this.isStale,
    );
  }

  static List<ModelQuota> parseCloudModels(Map<String, dynamic> json) {
    final raw = (json['models'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final seenLabels = <String>{};
    final models = raw
        .where((m) => m['isAutocompleteOnly'] != true)
        .where((m) => seenLabels.add(m['label'] as String))
        .map(ModelQuota.fromCloudJson)
        .toList()
      ..sort((a, b) => a.remainingPercentage.compareTo(b.remainingPercentage));
    return models;
  }

  /// Optional — `promptCredits` only present when the CLI managed to talk
  /// to the language server (IDE running). Falls back to null otherwise.
  static PromptCredits? parsePromptCredits(Map<String, dynamic> json) {
    final pc = json['promptCredits'];
    if (pc is! Map) return null;
    final available = (pc['available'] as num?)?.toInt();
    final monthly = (pc['monthly'] as num?)?.toInt();
    if (available == null || monthly == null || monthly == 0) return null;
    return PromptCredits(available: available, monthly: monthly);
  }
}
