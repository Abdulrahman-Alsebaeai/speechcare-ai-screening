class PredictionResult {
  const PredictionResult({
    required this.finalLabel,
    required this.confidencePercent,
    required this.stage1,
    required this.stage2,
    required this.probabilities,
    required this.warning,
    required this.recommendation,
    required this.reportSummary,
  });

  final String finalLabel;
  final double confidencePercent;
  final String stage1;
  final String stage2;
  final Map<String, double> probabilities;
  final String warning;
  final String recommendation;
  final String reportSummary;

  bool get riskDetected =>
      finalLabel.toLowerCase().contains('dysarthria') ||
      finalLabel.toLowerCase().contains('stuttering') ||
      confidencePercent < 70;

  Map<String, Object?> toMap() => {
    'final_label': finalLabel,
    'confidence_percent': confidencePercent,
    'stage1': stage1,
    'stage2': stage2,
    'probabilities': probabilities,
    'warning': warning,
    'recommendation': recommendation,
    'report_summary': reportSummary,
  };

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    final rawProbabilities = json['probabilities'];
    final probs = <String, double>{};
    if (rawProbabilities is Map) {
      rawProbabilities.forEach((key, value) {
        probs[key.toString()] = (value as num).toDouble();
      });
    }
    return PredictionResult(
      finalLabel: (json['final_label'] ?? 'Uncertain sample').toString(),
      confidencePercent: ((json['confidence_percent'] ?? 0) as num).toDouble(),
      stage1: (json['stage1'] ?? 'Audio quality screening').toString(),
      stage2: (json['stage2'] ?? 'Speech disorder classification').toString(),
      probabilities: probs,
      warning: (json['warning'] ?? '').toString(),
      recommendation: (json['recommendation'] ?? '').toString(),
      reportSummary: (json['report_summary'] ?? '').toString(),
    );
  }
}
