import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/gemini_data.dart';
import '../../providers/gemini_provider.dart';
import '../widgets/activity_grid.dart';

class GeminiTab extends StatelessWidget {
  const GeminiTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GeminiProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.data == null) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Color(0xFF555555),
              ),
            ),
          );
        }

        final data = provider.data;
        if (data == null || !data.isInstalled) {
          return _notInstalled();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusRow(data: data),
              const SizedBox(height: 14),
              const _SectionLabel('Recent Projects'),
              const SizedBox(height: 8),
              if (data.projects.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'No sessions found',
                    style: TextStyle(color: Color(0xFF555555), fontSize: 12),
                  ),
                )
              else
                ...data.projects.take(8).map((p) => _ProjectRow(project: p)),
              const SizedBox(height: 14),
              const _SectionLabel('Activity'),
              const SizedBox(height: 8),
              ActivityGrid(
                activityCounts: data.activityByDay,
                accentColor: const Color(0xFF0A84FF),
                emptyColor: const Color(0xFF1C3050),
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  Widget _notInstalled() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2A2A3A)),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gemini CLI not found',
              style: TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Install with:\nnpm install -g @google/generative-ai',
              style: TextStyle(
                color: Color(0xFF555555),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final GeminiCliData data;
  const _StatusRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final authOk = data.isAuthenticated && !data.isTokenExpired;
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: authOk
                ? const Color(0xFF30D158)
                : const Color(0xFFFF9F0A),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          authOk ? 'Authenticated' : 'Token expired',
          style: TextStyle(
            color: authOk
                ? const Color(0xFF30D158)
                : const Color(0xFFFF9F0A),
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(
          'v${data.version}',
          style: const TextStyle(color: Color(0xFF444444), fontSize: 11),
        ),
      ],
    );
  }
}

class _ProjectRow extends StatelessWidget {
  final GeminiProject project;
  const _ProjectRow({required this.project});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF0A84FF),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              project.displayName,
              style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            project.relativeDate,
            style: const TextStyle(color: Color(0xFF555555), fontSize: 11),
          ),
        ],
      ),
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
