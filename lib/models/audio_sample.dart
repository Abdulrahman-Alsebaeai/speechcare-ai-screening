class AudioSample {
  const AudioSample({
    required this.filePath,
    required this.durationSeconds,
    required this.source,
    required this.createdAt,
  });

  final String filePath;
  final int durationSeconds;
  final String source;
  final DateTime createdAt;

  bool get isTooShort => durationSeconds > 0 && durationSeconds < 4;
}
