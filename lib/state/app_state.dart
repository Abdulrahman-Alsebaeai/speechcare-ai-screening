import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/audio_sample.dart';
import '../models/screening_record.dart';
import '../services/app_database.dart';
import '../services/audio_service.dart';
import '../services/auth_service.dart';
import '../services/prediction_api_service.dart';

class AppState extends ChangeNotifier {
  AppState({
    required AuthService authService,
    required AppDatabase database,
    required PredictionApiService predictionApiService,
    required AudioService audioService,
  }) : _authService = authService,
       _database = database,
       _predictionApiService = predictionApiService,
       _audioService = audioService;

  final AuthService _authService;
  final AppDatabase _database;
  final PredictionApiService _predictionApiService;
  final AudioService _audioService;

  AppUser? currentUser;
  List<ScreeningRecord> records = [];
  bool isBootstrapping = true;
  bool isBusy = false;
  bool isRecording = false;
  bool isAnalyzing = false;
  Locale locale = const Locale('en');
  String? currentRecordingPath;
  int recordingSeconds = 0;
  String? errorMessage;
  Timer? _timer;

  bool get mockMode => _predictionApiService.useMockMode;
  ScreeningRecord? get latestRecord => records.isEmpty ? null : records.first;

  Future<void> bootstrap() async {
    final savedLanguageCode = await _database.savedLanguageCode();
    if (savedLanguageCode == 'ar') {
      locale = const Locale('ar');
    }
    currentUser = await _database.currentSessionUser();
    if (currentUser != null) {
      await refreshHistory();
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
    isBootstrapping = false;
    notifyListeners();
  }

  Future<void> setLocale(Locale newLocale) async {
    final supportedLocale =
        newLocale.languageCode == 'ar'
            ? const Locale('ar')
            : const Locale('en');
    if (locale.languageCode == supportedLocale.languageCode) return;
    locale = supportedLocale;
    notifyListeners();
    await _database.saveLanguageCode(supportedLocale.languageCode);
  }

  Future<void> register(String name, String email, String password) async {
    await _runBusy(() async {
      currentUser = await _authService.register(
        name: name,
        email: email,
        password: password,
      );
      final userId = currentUser?.id;
      if (userId != null) {
        await _database.saveCurrentUserId(userId);
      }
      records = [];
    });
  }

  Future<void> login(String email, String password) async {
    await _runBusy(() async {
      currentUser = await _authService.login(email: email, password: password);
      final userId = currentUser?.id;
      if (userId != null) {
        await _database.saveCurrentUserId(userId);
      }
      await refreshHistory();
    });
  }

  Future<void> logout() async {
    await _database.clearCurrentUserId();
    currentUser = null;
    records = [];
    notifyListeners();
  }

  Future<void> refreshHistory() async {
    final user = currentUser;
    if (user?.id == null) return;
    records = await _database.recordsForUser(user!.id!);
    notifyListeners();
  }

  Future<void> startRecording() async {
    if (isAnalyzing || isRecording) return;
    errorMessage = null;
    try {
      currentRecordingPath = await _audioService.startRecording();
      isRecording = true;
      recordingSeconds = 0;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        recordingSeconds += 1;
        notifyListeners();
      });
      notifyListeners();
    } on AudioException catch (error) {
      errorMessage = error.message;
      notifyListeners();
    } catch (_) {
      errorMessage =
          'Recording could not be started. Check microphone access and try again.';
      notifyListeners();
    }
  }

  Future<ScreeningRecord?> stopAndAnalyze() async {
    if (!isRecording || isAnalyzing) return null;
    _timer?.cancel();
    isRecording = false;
    notifyListeners();

    String? path;
    try {
      final stoppedPath = await _audioService.stopRecording();
      path = stoppedPath ?? currentRecordingPath;
    } on AudioException catch (error) {
      currentRecordingPath = null;
      errorMessage = error.message;
      notifyListeners();
      return null;
    } catch (_) {
      currentRecordingPath = null;
      errorMessage = 'The recording could not be saved. Please try again.';
      notifyListeners();
      return null;
    }

    currentRecordingPath = null;
    if (path == null) {
      errorMessage = 'No recording file was created.';
      notifyListeners();
      return null;
    }

    final actualDuration = await _safeDurationSeconds(path);
    return analyzeSample(
      AudioSample(
        filePath: path,
        durationSeconds: actualDuration > 0 ? actualDuration : recordingSeconds,
        source: 'microphone',
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<ScreeningRecord?> pickAndAnalyzeFile() async {
    if (isAnalyzing || isRecording) return null;
    errorMessage = null;
    notifyListeners();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['wav'],
      );
      final file = result?.files.single;
      if (file?.path == null) return null;

      final securedPath = await _audioService.importWavToSecureStorage(
        file!.path!,
      );
      final actualDuration = await _safeDurationSeconds(securedPath);
      return analyzeSample(
        AudioSample(
          filePath: securedPath,
          durationSeconds: actualDuration,
          source: 'upload',
          createdAt: DateTime.now(),
        ),
      );
    } on AudioException catch (error) {
      errorMessage = error.message;
      notifyListeners();
      return null;
    } catch (_) {
      errorMessage = 'The selected audio file could not be opened.';
      notifyListeners();
      return null;
    }
  }

  Future<ScreeningRecord?> analyzeSample(AudioSample sample) async {
    if (isAnalyzing) return null;
    final user = currentUser;
    if (user?.id == null) {
      errorMessage = 'Please sign in before running a screening.';
      notifyListeners();
      return null;
    }
    isAnalyzing = true;
    errorMessage = null;
    notifyListeners();
    try {
      final prediction = await _predictionApiService
          .predict(sample)
          .timeout(
            const Duration(seconds: 100),
            onTimeout: () {
              throw PredictionException(
                'Analysis did not finish. Please retry with a clear 8 to 15 second recording.',
              );
            },
          );
      final record = ScreeningRecord(
        id: null,
        userId: user!.id!,
        audioPath: sample.filePath,
        durationSeconds: sample.durationSeconds,
        createdAt: DateTime.now(),
        result: prediction,
      );
      await _database.insertRecord(record);
      await refreshHistory();
      return records.first;
    } on PredictionException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage =
          'Analysis failed. Please try a clearer sample or reconnect later.';
    } finally {
      isAnalyzing = false;
      notifyListeners();
    }
    return null;
  }

  Future<void> clearHistory() async {
    final user = currentUser;
    if (user?.id == null) return;
    await _database.clearRecords(user!.id!);
    records = [];
    notifyListeners();
  }

  Future<int> _safeDurationSeconds(String filePath) async {
    try {
      return await _audioService
          .wavDurationSeconds(filePath)
          .timeout(const Duration(seconds: 2));
    } catch (_) {
      return 0;
    }
  }

  Future<void> _runBusy(Future<void> Function() task) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await task();
    } on AuthException catch (error) {
      errorMessage = error.message;
    } catch (_) {
      errorMessage = 'Something went wrong. Please try again.';
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _predictionApiService.dispose();
    _audioService.dispose();
    super.dispose();
  }
}
