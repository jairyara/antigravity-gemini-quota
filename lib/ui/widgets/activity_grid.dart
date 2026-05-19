import 'package:flutter/material.dart';

class ActivityGrid extends StatelessWidget {
  final Map<String, int> activityCounts;
  final int weeks;
  final double cellSize;
  final double cellGap;
  final Color accentColor;
  final Color emptyColor;

  const ActivityGrid({
    super.key,
    required this.activityCounts,
    this.weeks = 16,
    this.cellSize = 10.0,
    this.cellGap = 2.0,
    this.accentColor = const Color(0xFF30D158),
    this.emptyColor = const Color(0xFF1A3A2A),
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final daysSinceSunday = today.weekday % 7;
    final startDay = today.subtract(Duration(days: daysSinceSunday + (weeks - 1) * 7));
    final maxCount = activityCounts.values.fold(0, (a, b) => a > b ? a : b);

    return LayoutBuilder(builder: (context, constraints) {
      // Each column contributes (cellSize + cellGap), including the last one.
      // Solve: weeks * (fitted + cellGap) <= availableWidth
      final fitted = ((constraints.maxWidth / weeks) - cellGap)
          .floorToDouble()
          .clamp(3.0, cellSize);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(weeks, (weekIndex) {
              return Padding(
                padding: EdgeInsets.only(right: cellGap),
                child: Column(
                  children: List.generate(7, (dayIndex) {
                    final date = startDay.add(Duration(days: weekIndex * 7 + dayIndex));
                    final key = _dateKey(date);
                    final count = activityCounts[key] ?? 0;
                    final isFuture = date.isAfter(today);

                    return Padding(
                      padding: EdgeInsets.only(bottom: cellGap),
                      child: Tooltip(
                        message: isFuture ? '' : '$key: $count polls',
                        child: Container(
                          width: fitted,
                          height: fitted,
                          decoration: BoxDecoration(
                            color: isFuture ? Colors.transparent : _cellColor(count, maxCount),
                            borderRadius: BorderRadius.circular(fitted * 0.2),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
          SizedBox(height: cellGap * 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less', style: TextStyle(color: const Color(0xFF636366), fontSize: fitted * 0.9)),
              SizedBox(width: cellGap * 2),
              ...List.generate(5, (i) => Padding(
                padding: EdgeInsets.only(right: cellGap),
                child: Container(
                  width: fitted * 0.8,
                  height: fitted * 0.8,
                  decoration: BoxDecoration(
                    color: _scaleColor(i / 4),
                    borderRadius: BorderRadius.circular(fitted * 0.15),
                  ),
                ),
              )),
              Text('More', style: TextStyle(color: const Color(0xFF636366), fontSize: fitted * 0.9)),
            ],
          ),
        ],
      );
    });
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Color _cellColor(int count, int maxCount) {
    if (count == 0) return const Color(0xFF2C2C2E);
    final intensity = maxCount > 0 ? count / maxCount : 0.0;
    return _scaleColor(intensity.clamp(0.15, 1.0));
  }

  Color _scaleColor(double intensity) =>
      Color.lerp(emptyColor, accentColor, intensity)!;
}
