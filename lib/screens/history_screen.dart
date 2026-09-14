import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/screening_record.dart';
import '../state/app_state.dart';
import '../widgets/empty_state.dart';
import '../widgets/health_card.dart';
import 'result_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.t('screeningHistory'),
          style: const TextStyle(
            color: AppTheme.navy,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
      ),
      body:
          state.records.isEmpty
              ? EmptyState(
                icon: Icons.folder_open_rounded,
                title: l10n.t('noScreenings'),
                message: l10n.t('noScreeningsMessage'),
              )
              : RefreshIndicator(
                onRefresh: state.refreshHistory,
                color: AppTheme.teal,
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: state.records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder:
                      (context, index) =>
                          _HistoryTile(record: state.records[index]),
                ),
              ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.record});

  final ScreeningRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final risk = record.result.riskDetected;
    final color = risk ? AppTheme.coral : AppTheme.teal;

    return HealthCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ResultScreen(record: record)),
            ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  risk ? Icons.flag_rounded : Icons.check_rounded,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.translateKnown(record.result.finalLabel),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.formatShortDateTime(record.createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${record.result.confidencePercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
