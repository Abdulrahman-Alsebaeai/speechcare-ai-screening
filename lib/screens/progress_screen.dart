import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../state/app_state.dart';
import '../widgets/empty_state.dart';
import '../widgets/health_card.dart';
import '../widgets/metric_tile.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final records = context.watch<AppState>().records.reversed.toList();
    final chartRecords =
        records.length > 25 ? records.sublist(records.length - 25) : records;
    final avg =
        records.isEmpty
            ? 0.0
            : records
                    .map((record) => record.result.confidencePercent)
                    .reduce((a, b) => a + b) /
                records.length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        centerTitle: false,
        title: Text(
          l10n.t('yourProgress'),
          style: const TextStyle(
            color: AppTheme.navy,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
      ),
      body:
          records.isEmpty
              ? EmptyState(
                icon: Icons.insights_rounded,
                title: l10n.t('notEnoughData'),
                message: l10n.t('notEnoughDataMessage'),
              )
              : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: MetricTile(
                          icon: Icons.timeline_rounded,
                          label: l10n.t('totalScans'),
                          value: '${records.length}',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: MetricTile(
                          icon: Icons.analytics_rounded,
                          label: l10n.t('avgConfidence'),
                          value: '${avg.toStringAsFixed(1)}%',
                          color: AppTheme.mint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  HealthCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('confidenceTrend'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.navy,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          height: 220,
                          child: LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: 100,
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 25,
                                getDrawingHorizontalLine:
                                    (value) => FlLine(
                                      color: Colors.grey.shade200,
                                      strokeWidth: 1,
                                      dashArray: [5, 5],
                                    ),
                              ),
                              titlesData: FlTitlesData(
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget:
                                        (value, meta) => Text(
                                          '${value.toInt()}',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                  ),
                                ),
                                bottomTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: [
                                    for (
                                      var i = 0;
                                      i < chartRecords.length;
                                      i++
                                    )
                                      FlSpot(
                                        i.toDouble(),
                                        chartRecords[i]
                                            .result
                                            .confidencePercent,
                                      ),
                                  ],
                                  isCurved: true,
                                  curveSmoothness: 0.35,
                                  barWidth: 4,
                                  color: AppTheme.teal,
                                  dotData: FlDotData(
                                    show: chartRecords.length <= 20,
                                    getDotPainter:
                                        (spot, percent, barData, index) =>
                                            FlDotCirclePainter(
                                              radius: 4,
                                              color: Colors.white,
                                              strokeWidth: 3,
                                              strokeColor: AppTheme.teal,
                                            ),
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.teal.withValues(alpha: 0.3),
                                        AppTheme.teal.withValues(alpha: 0.0),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  HealthCard(
                    color: AppTheme.navy,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.t('clinicalInsight'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                l10n.t('clinicalInsightMessage'),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}
