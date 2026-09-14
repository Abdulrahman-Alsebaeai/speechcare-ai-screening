import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';

class ProbabilityBars extends StatelessWidget {
  const ProbabilityBars({super.key, required this.values});

  final Map<String, double> values;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    final l10n = context.l10n;
    final palette = [
      AppTheme.teal,
      AppTheme.coral,
      AppTheme.amber,
      AppTheme.mint,
    ];
    return Column(
      children:
          values.entries.toList().asMap().entries.map((indexed) {
            final entry = indexed.value;
            final color = palette[indexed.key % palette.length];
            final percent = entry.value.clamp(0, 100);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.translateKnown(entry.key),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text('${percent.toStringAsFixed(1)}%'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: percent / 100,
                      minHeight: 10,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.14),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
