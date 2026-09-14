import 'dart:convert';

import 'prediction_result.dart';

class ScreeningRecord {
  const ScreeningRecord({
    required this.id,
    required this.userId,
    required this.audioPath,
    required this.durationSeconds,
    required this.createdAt,
    required this.result,
  });

  final int? id;
  final int userId;
  final String audioPath;
  final int durationSeconds;
  final DateTime createdAt;
  final PredictionResult result;

  Map<String, Object?> toMap() => {
    'id': id,
    'userId': userId,
    'audioPath': audioPath,
    'durationSeconds': durationSeconds,
    'createdAt': createdAt.toIso8601String(),
    'finalLabel': result.finalLabel,
    'confidencePercent': result.confidencePercent,
    'stage1': result.stage1,
    'stage2': result.stage2,
    'probabilitiesJson': jsonEncode(result.probabilities),
    'warning': result.warning,
    'recommendation': result.recommendation,
    'reportSummary': result.reportSummary,
  };

  factory ScreeningRecord.fromMap(Map<String, Object?> map) => ScreeningRecord(
    id: map['id'] as int?,
    userId: map['userId'] as int,
    audioPath: map['audioPath'] as String,
    durationSeconds: map['durationSeconds'] as int,
    createdAt: DateTime.parse(map['createdAt'] as String),
    result: PredictionResult(
      finalLabel: map['finalLabel'] as String,
      confidencePercent: (map['confidencePercent'] as num).toDouble(),
      stage1: map['stage1'] as String,
      stage2: map['stage2'] as String,
      probabilities: (jsonDecode(map['probabilitiesJson'] as String) as Map)
          .map(
            (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
          ),
      warning: map['warning'] as String,
      recommendation: map['recommendation'] as String,
      reportSummary: map['reportSummary'] as String,
    ),
  );
}
