import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<String> startRecording() async {
    final hasPermission = await requestMicrophone();
    if (!hasPermission) {
      throw AudioException('Microphone permission was denied.');
    }
    final recordingsDir = await _recordingsDirectory();
    final filePath = p.join(
      recordingsDir.path,
      'speech_${DateTime.now().millisecondsSinceEpoch}.wav',
    );
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        bitRate: 256000,
        sampleRate: 16000,
        numChannels: 1,
        autoGain: true,
        echoCancel: true,
        noiseSuppress: true,
      ),
      path: filePath,
    );
    return filePath;
  }

  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    if (path == null) return null;
    await _waitUntilFileReady(path);
    return path;
  }

  Future<String> importWavToSecureStorage(String sourcePath) async {
    final extension = p.extension(sourcePath).toLowerCase();
    if (extension != '.wav') {
      throw AudioException('Only WAV audio files are supported for analysis.');
    }

    final source = File(sourcePath);
    if (!await source.exists()) {
      throw AudioException('The selected audio file could not be found.');
    }

    final recordingsDir = await _recordingsDirectory();
    final normalizedSource = p.normalize(source.absolute.path);
    final normalizedStorage = p.normalize(recordingsDir.absolute.path);
    if (normalizedSource.startsWith(normalizedStorage)) {
      await _waitUntilFileReady(normalizedSource);
      return normalizedSource;
    }

    final safeName = 'uploaded_${DateTime.now().millisecondsSinceEpoch}_${_randomSuffix()}.wav';
    final destinationPath = p.join(recordingsDir.path, safeName);
    await source.copy(destinationPath);
    await _waitUntilFileReady(destinationPath);
    return destinationPath;
  }

  Future<int> wavDurationSeconds(String filePath) async {
    final duration = await wavDuration(filePath);
    return duration.inSeconds;
  }

  Future<Duration> wavDuration(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return Duration.zero;
    final bytes = await file.readAsBytes();
    if (bytes.length < 44) return Duration.zero;
    final data = ByteData.sublistView(bytes);
    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    final wave = String.fromCharCodes(bytes.sublist(8, 12));
    if (riff != 'RIFF' || wave != 'WAVE') return Duration.zero;

    int offset = 12;
    int? channels;
    int? sampleRate;
    int? bitsPerSample;
    int? dataSize;

    while (offset + 8 <= bytes.length) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = data.getUint32(offset + 4, Endian.little);
      final chunkDataOffset = offset + 8;
      if (chunkId == 'fmt ' && chunkSize >= 16) {
        channels = data.getUint16(chunkDataOffset + 2, Endian.little);
        sampleRate = data.getUint32(chunkDataOffset + 4, Endian.little);
        bitsPerSample = data.getUint16(chunkDataOffset + 14, Endian.little);
      } else if (chunkId == 'data') {
        dataSize = min(chunkSize, bytes.length - chunkDataOffset);
        break;
      }
      offset = chunkDataOffset + chunkSize;
      if (offset.isOdd) offset += 1;
    }

    if (channels == null || sampleRate == null || bitsPerSample == null || dataSize == null) {
      return Duration.zero;
    }
    final bytesPerSecond = sampleRate * channels * (bitsPerSample ~/ 8);
    if (bytesPerSecond <= 0) return Duration.zero;
    final seconds = dataSize / bytesPerSecond;
    return Duration(milliseconds: (seconds * 1000).round());
  }

  Future<void> dispose() => _recorder.dispose();

  Future<Directory> _recordingsDirectory() async {
    final dir = await getApplicationDocumentsDirectory();
    final recordingsDir = p.join(dir.path, 'secure_speech_samples');
    await DirectoryHelper.ensure(recordingsDir);
    return Directory(recordingsDir);
  }

  Future<void> _waitUntilFileReady(String path) async {
    final file = File(path);
    for (var i = 0; i < 12; i++) {
      if (await file.exists()) {
        final size = await file.length();
        if (size > 44) return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    if (!await file.exists() || await file.length() <= 44) {
      throw AudioException('The recording file was not created correctly. Please try again.');
    }
  }

  String _randomSuffix() {
    final random = Random.secure();
    return List<int>.generate(6, (_) => random.nextInt(36))
        .map((value) => value.toRadixString(36))
        .join();
  }
}

class DirectoryHelper {
  static Future<void> ensure(String path) async {
    final directory = await getApplicationDocumentsDirectory();
    final target = p.normalize(path);
    final base = p.normalize(directory.path);
    if (!target.startsWith(base)) {
      throw AudioException('Invalid storage location.');
    }
    await Directory(target).create(recursive: true);
  }
}

class AudioException implements Exception {
  AudioException(this.message);
  final String message;
}
