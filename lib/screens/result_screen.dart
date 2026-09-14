import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/screening_record.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/health_card.dart';
import '../widgets/probability_bars.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.record});

  final ScreeningRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = record.result;
    final risk = result.riskDetected;
    final accentColor = risk ? AppTheme.coral : AppTheme.teal;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.navy),
        title: Text(
          l10n.t('detailedReport'),
          style: const TextStyle(
            color: AppTheme.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // البطاقة الرئيسية للنتيجة
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    risk ? Icons.warning_rounded : Icons.verified_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.isArabic
                      ? l10n.translateKnown(result.finalLabel)
                      : result.finalLabel.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.aiConfidence(result.confidencePercent),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // التقرير الموجز والتوصية
          HealthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.notes_rounded,
                      color: AppTheme.navy,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.t('aiSummary'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.navy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.translateKnown(result.reportSummary),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    height: 1.6,
                    fontSize: 15,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1),
                ),
                Text(
                  l10n.t('recommendation'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.translateKnown(result.recommendation),
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          if (result.warning.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.amber.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.report_problem_rounded,
                    color: AppTheme.amber,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.translateKnown(result.warning),
                      style: const TextStyle(
                        color: AppTheme.amber,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          // بيانات الاحتمالية والمراحل (Technical Data)
          HealthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t('technicalAnalysis'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.navy,
                  ),
                ),
                const SizedBox(height: 20),
                _StageBadge(
                  label: l10n.stage1,
                  value: l10n.translateKnown(result.stage1),
                ),
                const SizedBox(height: 12),
                _StageBadge(
                  label: l10n.stage2,
                  value: l10n.translateKnown(result.stage2),
                ),
                const SizedBox(height: 24),
                ProbabilityBars(values: result.probabilities),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // تاريخ الفحص
          Center(
            child: Text(
              l10n.recordedOn(record.createdAt),
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 24),
          // إخلاء المسؤولية (المكان الوحيد المتبقي لها)
          const DisclaimerBanner(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _StageBadge extends StatelessWidget {
  const _StageBadge({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
