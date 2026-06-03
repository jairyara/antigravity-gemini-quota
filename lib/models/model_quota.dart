class ModelQuota {
  final String label;
  final String modelId;
  final double remainingPercentage;
  final bool isExhausted;
  final DateTime resetTime;

  const ModelQuota({
    required this.label,
    required this.modelId,
    required this.remainingPercentage,
    required this.isExhausted,
    required this.resetTime,
  });

  double get usedFraction => 1.0 - remainingPercentage;
  int get remainingPercent => (remainingPercentage * 100).round();
  int get usedPercent => (usedFraction * 100).round();

  Duration timeUntilReset({DateTime? now}) =>
      resetTime.difference(now ?? DateTime.now());

  factory ModelQuota.fromCloudJson(Map<String, dynamic> json) {
    return ModelQuota(
      label: (json['label'] as String?) ?? 'Unknown',
      modelId: (json['modelId'] as String?) ?? '',
      remainingPercentage:
          ((json['remainingPercentage'] as num?) ?? 1.0).toDouble(),
      isExhausted: (json['isExhausted'] as bool?) ?? false,
      resetTime: DateTime.parse(json['resetTime'] as String).toLocal(),
    );
  }
}
