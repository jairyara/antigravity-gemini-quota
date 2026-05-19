class ModelQuota {
  final String label;
  final double remainingFraction;
  final DateTime resetTime;

  const ModelQuota({
    required this.label,
    required this.remainingFraction,
    required this.resetTime,
  });

  double get usedFraction => 1.0 - remainingFraction;
  int get usedPercent => (usedFraction * 100).round();
  int get remainingPercent => (remainingFraction * 100).round();

  Duration get timeUntilReset => resetTime.difference(DateTime.now());

  String get resetLabel {
    final d = timeUntilReset;
    if (d.isNegative) return 'Reset pending';
    if (d.inHours >= 1) return 'Resets in ${d.inHours}h ${d.inMinutes.remainder(60)}m';
    if (d.inMinutes >= 1) return 'Resets in ${d.inMinutes}m';
    return 'Resets soon';
  }

  factory ModelQuota.fromJson(Map<String, dynamic> json) {
    final quotaInfo = (json['quotaInfo'] as Map<String, dynamic>?) ?? {};
    final resetStr = quotaInfo['resetTime'] as String?;
    return ModelQuota(
      label: (json['label'] as String?) ?? 'Unknown',
      remainingFraction:
          ((quotaInfo['remainingFraction'] as num?) ?? 1.0).toDouble(),
      resetTime: resetStr != null ? DateTime.parse(resetStr) : DateTime.now(),
    );
  }
}

class QuotaData {
  final String name;
  final String email;
  final String planName;
  final String teamsTier;
  final String tierDisplayName;
  final List<ModelQuota> modelQuotas;
  final int availablePromptCredits;
  final int monthlyPromptCredits;
  final int availableFlowCredits;
  final int monthlyFlowCredits;
  final int availableAiCredits;
  final DateTime fetchedAt;

  QuotaData({
    required this.name,
    required this.email,
    required this.planName,
    required this.teamsTier,
    required this.tierDisplayName,
    required this.modelQuotas,
    required this.availablePromptCredits,
    required this.monthlyPromptCredits,
    required this.availableFlowCredits,
    required this.monthlyFlowCredits,
    required this.availableAiCredits,
    required this.fetchedAt,
  });

  factory QuotaData.fromJson(Map<String, dynamic> json) {
    final userStatus = (json['userStatus'] as Map<String, dynamic>?) ?? {};
    final planStatus =
        (userStatus['planStatus'] as Map<String, dynamic>?) ?? {};
    final planInfo = (planStatus['planInfo'] as Map<String, dynamic>?) ?? {};
    final userTier = (userStatus['userTier'] as Map<String, dynamic>?) ?? {};
    final cascadeData =
        (userStatus['cascadeModelConfigData'] as Map<String, dynamic>?) ?? {};
    final clientConfigs =
        (cascadeData['clientModelConfigs'] as List<dynamic>?) ?? [];

    final models = clientConfigs
        .map((c) => ModelQuota.fromJson(c as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.remainingFraction.compareTo(b.remainingFraction));

    return QuotaData(
      name: (userStatus['name'] as String?) ?? '',
      email: (userStatus['email'] as String?) ?? '',
      planName: (planInfo['planName'] as String?) ?? 'Unknown',
      teamsTier: (planInfo['teamsTier'] as String?) ?? '',
      tierDisplayName:
          (userTier['name'] as String?) ?? (planInfo['planName'] as String?) ?? 'Pro',
      modelQuotas: models,
      availablePromptCredits:
          (planStatus['availablePromptCredits'] as num?)?.toInt() ?? 0,
      monthlyPromptCredits:
          (planInfo['monthlyPromptCredits'] as num?)?.toInt() ?? 0,
      availableFlowCredits:
          (planStatus['availableFlowCredits'] as num?)?.toInt() ?? 0,
      monthlyFlowCredits:
          (planInfo['monthlyFlowCredits'] as num?)?.toInt() ?? 0,
      availableAiCredits: _parseAiCredits(userTier),
      fetchedAt: DateTime.now(),
    );
  }

  bool get isPro =>
      teamsTier.toUpperCase().contains('PRO') ||
      planName.toLowerCase().contains('pro');

  /// Most-used model (lowest remaining fraction).
  ModelQuota? get mostConstrained =>
      modelQuotas.isEmpty ? null : modelQuotas.first;

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return '$n';
  }

  String get promptCreditsLabel =>
      '${_fmt(availablePromptCredits)} / ${_fmt(monthlyPromptCredits)}';
  String get flowCreditsLabel =>
      '${_fmt(availableFlowCredits)} / ${_fmt(monthlyFlowCredits)}';
  String get aiCreditsLabel => _fmt(availableAiCredits);
}

int _parseAiCredits(Map<String, dynamic> userTier) {
  final credits = userTier['availableCredits'] as List<dynamic>?;
  if (credits == null || credits.isEmpty) return 0;
  for (final c in credits) {
    final map = c as Map<String, dynamic>;
    if ((map['creditType'] as String?) == 'GOOGLE_ONE_AI') {
      return int.tryParse(map['creditAmount'] as String? ?? '') ?? 0;
    }
  }
  return 0;
}
