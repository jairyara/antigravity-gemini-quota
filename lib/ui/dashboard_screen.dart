import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/model_quota.dart';
import '../providers/navigation_provider.dart';
import '../providers/quota_provider.dart';
import '../util/reset_time_formatter.dart';
import 'widgets/activity_grid.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DashboardHeader(),
          const Divider(height: 1, color: Color(0xFF252525)),
          Expanded(
            child: Consumer<QuotaProvider>(
              builder: (context, provider, _) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 380,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel('Activity — 52 weeks'),
                          const SizedBox(height: 10),
                          ActivityGrid(
                            activityCounts: provider.activityCounts,
                            weeks: 52,
                            cellSize: 6,
                            cellGap: 2,
                          ),
                          const SizedBox(height: 24),
                          const _SectionLabel('Insights'),
                          const SizedBox(height: 10),
                          _InsightsPanel(provider: provider),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFF252525)),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel('Model Quota'),
                          const SizedBox(height: 10),
                          if (provider.currentData != null)
                            ...provider.currentData!.models
                                .map((m) => _DashboardModelRow(model: m))
                          else
                            const _EmptyState('Cargando…'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<QuotaProvider>(
      builder: (context, provider, _) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            GestureDetector(
              onTap: () =>
                  context.read<NavigationProvider>().closeDashboard(),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios_new,
                      size: 13, color: Color(0xFF888888)),
                  SizedBox(width: 4),
                  Text('Back',
                      style: TextStyle(
                          color: Color(0xFF888888), fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Antigravity Quota',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            if (provider.currentData?.isStale == true)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFF3A3A3A)),
                ),
                child: Text(
                  'datos de hace ${_ago(provider.lastFetched!)}',
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const Spacer(),
            if (provider.lastFetched != null)
              Text(
                _relativeTime(provider.lastFetched!),
                style: const TextStyle(
                    color: Color(0xFF555555), fontSize: 11),
              ),
          ],
        ),
      ),
    );
  }

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    return '${d.inHours}h';
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

class _InsightsPanel extends StatelessWidget {
  final QuotaProvider provider;
  const _InsightsPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    final insights = provider.insights;
    if (insights == null) return const _EmptyState('No data yet');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InsightRow('Connected days', '${insights.totalConnectedDays}'),
        _InsightRow('Total polls', '${insights.totalPolls}'),
        if (insights.firstSeen != null)
          _InsightRow('First seen', _date(insights.firstSeen!)),
        if (insights.lastSeen != null)
          _InsightRow('Last seen', _date(insights.lastSeen!)),
      ],
    );
  }

  String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _InsightRow extends StatelessWidget {
  final String label;
  final String value;
  const _InsightRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label,
              style:
                  const TextStyle(color: Color(0xFF777777), fontSize: 11)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _DashboardModelRow extends StatelessWidget {
  final ModelQuota model;
  const _DashboardModelRow({required this.model});

  @override
  Widget build(BuildContext context) {
    final pct = model.usedPercent;
    final Color barColor = pct == 0
        ? const Color(0xFF2A2A2A)
        : pct < 50
            ? const Color(0xFF30D158)
            : pct < 80
                ? const Color(0xFFFF9F0A)
                : const Color(0xFFFF453A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  model.label,
                  style: TextStyle(
                    color: pct == 0 ? const Color(0xFF666666) : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                pct == 0 ? '—' : '$pct% used',
                style: TextStyle(
                  color: pct == 0 ? const Color(0xFF444444) : barColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formatResetTime(model.resetTime),
                style: const TextStyle(
                    color: Color(0xFF555555), fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 5),
          _ProgressBar(fraction: model.usedFraction, color: barColor),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double fraction;
  final Color color;
  const _ProgressBar({required this.fraction, required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final filled = constraints.maxWidth * fraction.clamp(0.0, 1.0);
        return Container(
          height: 5,
          width: constraints.maxWidth,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              height: 5,
              width: filled,
              decoration: BoxDecoration(
                color: fraction == 0 ? const Color(0xFF2C2C2E) : color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF666666),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState(this.message);

  @override
  Widget build(BuildContext context) => Text(
        message,
        style: const TextStyle(color: Color(0xFF555555), fontSize: 11),
      );
}
