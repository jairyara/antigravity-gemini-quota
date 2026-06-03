class PromptCredits {
  final int available;
  final int monthly;

  const PromptCredits({required this.available, required this.monthly});

  double get usedPercentage =>
      monthly == 0 ? 0.0 : (monthly - available) / monthly;

  int get usedPercent => (usedPercentage * 100).round();
}
