import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

class AudioPreprocessorService {
  AudioPreprocessorService({
    this.targetSampleRate = 16000,
    this.targetSamples = 64000,
    this.minimumSeconds = 4.0,
    this.minimumActiveSpeechSeconds = 1.2,
    this.minimumRms = 0.004,
    this.maximumClippingRatio = 0.18,
  });

  final int targetSampleRate;
  final int targetSamples;
  final double minimumSeconds;
  final double minimumActiveSpeechSeconds;
  final double minimumRms;
  final double maximumClippingRatio;

  Future<PreparedAudio> prepareForModel(String filePath) async {
    final extension = p.extension(filePath).toLowerCase();
    if (extension != '.wav') {
      throw AudioPreprocessException(
        'On-device AI analysis currently supports WAV files only. Please record inside the app or upload a WAV file.',
      );
    }

    final file = File(filePath);
    if (!await file.exists()) {
      throw AudioPreprocessException(
        'The selected audio file could not be found.',
      );
    }

    final bytes = await file.readAsBytes();
    final decoded = _decodeWav(bytes);
    var mono = decoded.samples;

    if (mono.isEmpty) {
      throw AudioPreprocessException('The audio file is empty or unsupported.');
    }

    mono = _removeNanAndClamp(mono);

    final originalDuration = mono.length / decoded.sampleRate;
    final originalRms = _rms(mono);
    final clippingRatio = _clippingRatio(mono);
    final silenceThreshold = max(0.006, originalRms * 0.18);
    var trimmed = _trimSilence(mono, threshold: silenceThreshold);
    if (trimmed.isEmpty) trimmed = mono;
    final activeSpeechDuration = trimmed.length / decoded.sampleRate;
    final voicedRatio =
        (trimmed.length / max(1, mono.length)).clamp(0.0, 1.0).toDouble();

    final unsuitableInput = _padOrTrim(
      _resampleIfNeeded(trimmed.isEmpty ? mono : trimmed, decoded.sampleRate),
      targetSamples,
    );

    if (originalDuration < minimumSeconds) {
      return PreparedAudio.unsuitable(
        inputValues: unsuitableInput,
        durationSeconds: originalDuration,
        rms: originalRms,
        warning:
            'The speech sample is too short for reliable analysis. Please record a clearer 8 to 15 second sample.',
      );
    }

    if (activeSpeechDuration < minimumActiveSpeechSeconds ||
        voicedRatio < 0.08) {
      return PreparedAudio.unsuitable(
        inputValues: unsuitableInput,
        durationSeconds: originalDuration,
        rms: originalRms,
        warning:
            'The recording contains too little clear speech. Please read the prompt again in a quiet room.',
      );
    }

    if (originalRms < minimumRms) {
      return PreparedAudio.unsuitable(
        inputValues: unsuitableInput,
        durationSeconds: originalDuration,
        rms: originalRms,
        warning:
            'The speech sample is too silent or unclear for reliable analysis.',
      );
    }

    if (clippingRatio > maximumClippingRatio) {
      return PreparedAudio.unsuitable(
        inputValues: unsuitableInput,
        durationSeconds: originalDuration,
        rms: originalRms,
        warning:
            'The recording is distorted or too loud. Keep the phone around 15cm away and try again.',
      );
    }

    var resampled = _resampleIfNeeded(trimmed, decoded.sampleRate);
    resampled = _peakNormalize(resampled);
    final prepared = _padOrTrim(resampled, targetSamples);

    final zcr = _zeroCrossingRate(trimmed);
    final qualityWarning = _qualityWarning(
      activeSpeechDuration: activeSpeechDuration,
      clippingRatio: clippingRatio,
      zcr: zcr,
    );

    return PreparedAudio(
      inputValues: prepared,
      durationSeconds: originalDuration,
      rms: originalRms,
      warning: qualityWarning,
      isSuitable: true,
    );
  }

  _DecodedWav _decodeWav(Uint8List bytes) {
    if (bytes.length < 44) {
      throw AudioPreprocessException('Invalid WAV file: file is too small.');
    }
    final data = ByteData.sublistView(bytes);
    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    final wave = String.fromCharCodes(bytes.sublist(8, 12));
    if (riff != 'RIFF' || wave != 'WAVE') {
      throw AudioPreprocessException('Invalid WAV file.');
    }

    int offset = 12;
    int? audioFormat;
    int? channels;
    int? sampleRate;
    int? bitsPerSample;
    int? dataOffset;
    int? dataSize;

    while (offset + 8 <= bytes.length) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = data.getUint32(offset + 4, Endian.little);
      final chunkDataOffset = offset + 8;

      if (chunkDataOffset + chunkSize > bytes.length + 1) {
        throw AudioPreprocessException(
          'Invalid WAV file: corrupted chunk size.',
        );
      }

      if (chunkId == 'fmt ') {
        if (chunkSize < 16) {
          throw AudioPreprocessException(
            'Invalid WAV file: unsupported fmt chunk.',
          );
        }
        audioFormat = data.getUint16(chunkDataOffset, Endian.little);
        channels = data.getUint16(chunkDataOffset + 2, Endian.little);
        sampleRate = data.getUint32(chunkDataOffset + 4, Endian.little);
        bitsPerSample = data.getUint16(chunkDataOffset + 14, Endian.little);
      } else if (chunkId == 'data') {
        dataOffset = chunkDataOffset;
        dataSize = chunkSize;
        break;
      }

      offset = chunkDataOffset + chunkSize;
      if (offset.isOdd) offset += 1;
    }

    if (audioFormat == null ||
        channels == null ||
        sampleRate == null ||
        bitsPerSample == null ||
        dataOffset == null ||
        dataSize == null) {
      throw AudioPreprocessException('Unsupported WAV structure.');
    }

    if (channels <= 0 || sampleRate <= 0) {
      throw AudioPreprocessException(
        'Invalid WAV file: audio stream metadata is invalid.',
      );
    }

    if (audioFormat != 1 && audioFormat != 3) {
      throw AudioPreprocessException(
        'Unsupported WAV encoding. Please use PCM WAV audio.',
      );
    }

    final samples = <double>[];
    final bytesPerSample = bitsPerSample ~/ 8;
    if (bytesPerSample <= 0) {
      throw AudioPreprocessException(
        'Unsupported WAV bit depth: $bitsPerSample',
      );
    }
    final frameSize = bytesPerSample * channels;
    final end = min(bytes.length, dataOffset + dataSize);

    for (int frame = dataOffset; frame + frameSize <= end; frame += frameSize) {
      double mono = 0;
      for (int ch = 0; ch < channels; ch++) {
        final sampleOffset = frame + ch * bytesPerSample;
        mono += _readSample(data, sampleOffset, bitsPerSample, audioFormat);
      }
      samples.add(mono / channels);
    }

    return _DecodedWav(samples: samples, sampleRate: sampleRate);
  }

  double _readSample(
    ByteData data,
    int offset,
    int bitsPerSample,
    int audioFormat,
  ) {
    if (audioFormat == 3 && bitsPerSample == 32) {
      return data.getFloat32(offset, Endian.little).clamp(-1.0, 1.0).toDouble();
    }
    switch (bitsPerSample) {
      case 8:
        return (data.getUint8(offset) - 128) / 128.0;
      case 16:
        return data.getInt16(offset, Endian.little) / 32768.0;
      case 24:
        final b0 = data.getUint8(offset);
        final b1 = data.getUint8(offset + 1);
        final b2 = data.getUint8(offset + 2);
        var value = b0 | (b1 << 8) | (b2 << 16);
        if ((value & 0x800000) != 0) value |= ~0xFFFFFF;
        return value / 8388608.0;
      case 32:
        return data.getInt32(offset, Endian.little) / 2147483648.0;
      default:
        throw AudioPreprocessException(
          'Unsupported WAV bit depth: $bitsPerSample',
        );
    }
  }

  List<double> _removeNanAndClamp(List<double> input) {
    return input
        .map((v) => v.isFinite ? v.clamp(-1.0, 1.0).toDouble() : 0.0)
        .toList(growable: false);
  }

  double _rms(List<double> input) {
    if (input.isEmpty) return 0;
    double sum = 0;
    for (final v in input) {
      sum += v * v;
    }
    return sqrt(sum / input.length);
  }

  double _clippingRatio(List<double> input) {
    if (input.isEmpty) return 0;
    var clipped = 0;
    for (final v in input) {
      if (v.abs() >= 0.98) clipped += 1;
    }
    return clipped / input.length;
  }

  double _zeroCrossingRate(List<double> input) {
    if (input.length < 2) return 0;
    var crossings = 0;
    for (var i = 1; i < input.length; i++) {
      final prev = input[i - 1];
      final current = input[i];
      if ((prev >= 0 && current < 0) || (prev < 0 && current >= 0))
        crossings += 1;
    }
    return crossings / (input.length - 1);
  }

  List<double> _trimSilence(List<double> input, {required double threshold}) {
    int start = 0;
    int end = input.length - 1;
    while (start < input.length && input[start].abs() < threshold) {
      start++;
    }
    while (end > start && input[end].abs() < threshold) {
      end--;
    }
    if (start >= end) return <double>[];
    return input.sublist(start, end + 1);
  }

  List<double> _resampleIfNeeded(List<double> input, int sampleRate) {
    if (sampleRate == targetSampleRate) return List<double>.from(input);
    if (input.isEmpty) return <double>[];

    final ratio = targetSampleRate / sampleRate;
    final newLength = max(1, (input.length * ratio).round());
    final output = List<double>.filled(newLength, 0);

    for (int i = 0; i < newLength; i++) {
      final sourcePosition = i / ratio;
      final left = sourcePosition.floor().clamp(0, input.length - 1).toInt();
      final right = min(left + 1, input.length - 1);
      final fraction = sourcePosition - left;
      output[i] = input[left] * (1 - fraction) + input[right] * fraction;
    }
    return output;
  }

  List<double> _peakNormalize(List<double> input) {
    if (input.isEmpty) return input;
    double peak = 0;
    for (final v in input) {
      peak = max(peak, v.abs());
    }
    if (peak < 1e-8) return input;
    final scale = min(1.0 / peak, 8.0);
    return input
        .map((v) => (v * scale).clamp(-1.0, 1.0).toDouble())
        .toList(growable: false);
  }

  List<double> _padOrTrim(List<double> input, int length) {
    final output = List<double>.filled(length, 0);
    final copyLength = min(input.length, length);
    for (int i = 0; i < copyLength; i++) {
      output[i] = input[i];
    }
    return output;
  }

  String _qualityWarning({
    required double activeSpeechDuration,
    required double clippingRatio,
    required double zcr,
  }) {
    if (activeSpeechDuration < 2.0) {
      return 'The usable speech portion is short. A longer 8 to 15 second recording may improve reliability.';
    }
    if (clippingRatio > 0.05) {
      return 'Some parts of the recording are loud or clipped. Repeat in a quieter room if the result seems unexpected.';
    }
    if (zcr > 0.28) {
      return 'The sample may contain background noise. Repeat in a quieter room if needed.';
    }
    return '';
  }
}

class PreparedAudio {
  const PreparedAudio({
    required this.inputValues,
    required this.durationSeconds,
    required this.rms,
    required this.warning,
    required this.isSuitable,
  });

  factory PreparedAudio.unsuitable({
    required List<double> inputValues,
    required double durationSeconds,
    required double rms,
    required String warning,
  }) {
    return PreparedAudio(
      inputValues: inputValues,
      durationSeconds: durationSeconds,
      rms: rms,
      warning: warning,
      isSuitable: false,
    );
  }

  final List<double> inputValues;
  final double durationSeconds;
  final double rms;
  final String warning;
  final bool isSuitable;
}

class _DecodedWav {
  const _DecodedWav({required this.samples, required this.sampleRate});
  final List<double> samples;
  final int sampleRate;
}

class AudioPreprocessException implements Exception {
  AudioPreprocessException(this.message);
  final String message;

  @override
  String toString() => message;
}
