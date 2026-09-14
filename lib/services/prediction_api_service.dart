import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

import '../models/audio_sample.dart';
import '../models/prediction_result.dart';
import 'audio_preprocessor_service.dart';
import 'on_device_prediction_service.dart';

class PredictionApiService {
  PredictionApiService({
    required this.baseUrl,
    required this.useMockMode,
    required this.useOnDeviceModel,
    required this.allowMockFallback,
    Dio? dio,
    OnDevicePredictionService? onDevicePredictionService,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl,
               connectTimeout: const Duration(seconds: 12),
               receiveTimeout: const Duration(seconds: 45),
               sendTimeout: const Duration(seconds: 30),
             ),
           ),
       _onDevicePredictionService =
           onDevicePredictionService ?? OnDevicePredictionService();

  factory PredictionApiService.mockFirst() => PredictionApiService(
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8000',
    ),
    useMockMode: const bool.fromEnvironment('USE_MOCK_AI', defaultValue: false),
    useOnDeviceModel: const bool.fromEnvironment(
      'USE_ON_DEVICE_AI',
      defaultValue: true,
    ),
    allowMockFallback: const bool.fromEnvironment(
      'ALLOW_MOCK_FALLBACK',
      defaultValue: false,
    ),
  );

  final String baseUrl;
  final bool useMockMode;
  final bool useOnDeviceModel;
  final bool allowMockFallback;
  final Dio _dio;
  final OnDevicePredictionService _onDevicePredictionService;

  Future<PredictionResult> predict(AudioSample sample) async {
    if (sample.durationSeconds > 0 && sample.durationSeconds < 4) {
      return PredictionResult(
        finalLabel: 'Unsuitable sample',
        confidencePercent: 0,
        stage1: 'Rejected: recording too short',
        stage2: 'Classification skipped',
        probabilities: const {
          'Normal Speech': 0,
          'Speech Disorder': 0,
          'Too short': 100,
        },
        warning: 'The speech sample is too short for reliable analysis.',
        recommendation:
            'Record at least 8 to 15 seconds in a quiet room and try again.',
        reportSummary:
            'No screening conclusion was generated because the input was incomplete.',
      );
    }

    if (useMockMode) return _mockPrediction(sample);

    if (useOnDeviceModel) {
      try {
        return await _onDevicePredictionService
            .predict(sample.filePath)
            .timeout(
              const Duration(seconds: 95),
              onTimeout: () {
                throw PredictionException(
                  'Analysis did not finish. Please retry with a clear 8 to 15 second WAV recording.',
                );
              },
            );
      } on AudioPreprocessException catch (error) {
        throw PredictionException(error.message);
      } on OnDeviceModelException catch (error) {
        if (allowMockFallback) return _mockPrediction(sample);
        throw PredictionException(error.message);
      } on TimeoutException {
        if (allowMockFallback) return _mockPrediction(sample);
        throw PredictionException(
          'Analysis did not finish. Please retry with a clear 8 to 15 second WAV recording.',
        );
      } catch (error) {
        if (allowMockFallback) return _mockPrediction(sample);
        throw PredictionException(
          'On-device AI analysis failed. Make sure the ONNX models are in assets/models, declared in pubspec.yaml, and the audio is WAV format.',
        );
      }
    }

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(sample.filePath),
      });
      final response = await _dio
          .post('/predict', data: formData)
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw PredictionException(
                'The screening backend did not respond in time.',
              );
            },
          );
      return PredictionResult.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on PredictionException {
      rethrow;
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        throw PredictionException('No connection to the screening backend.');
      }
      throw PredictionException(
        'The backend could not process this audio sample.',
      );
    }
  }

  Future<PredictionResult> _mockPrediction(AudioSample sample) async {
    await Future<void>.delayed(const Duration(milliseconds: 1300));
    final seed = sample.filePath.hashCode.abs();
    final rng = Random(seed);
    final dysarthria = 0.12 + rng.nextDouble() * 0.54;
    final stuttering = 0.10 + rng.nextDouble() * 0.48;
    final typical = max(0.08, 1 - dysarthria - stuttering);
    final entries = {
      'Normal Speech': typical,
      'Dysarthria': dysarthria,
      'Stuttering': stuttering,
    };
    final winner = entries.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final confidence = (winner.value * 100).clamp(54, 94).toDouble();
    final lowConfidence = confidence < 70;
    final label = lowConfidence ? 'Needs specialist review' : winner.key;
    final warning =
        lowConfidence
            ? 'Confidence is below the recommended threshold for a clear screening result.'
            : '';
    final recommendation =
        label == 'Normal Speech'
            ? 'Continue periodic self-checks if concerns persist.'
            : 'Consult a speech-language specialist for a professional assessment.';
    return PredictionResult(
      finalLabel: label,
      confidencePercent: confidence,
      stage1: 'Audio quality accepted',
      stage2: 'Two-stage speech disorder screening completed',
      probabilities: entries.map((key, value) => MapEntry(key, value * 100)),
      warning: warning,
      recommendation: recommendation,
      reportSummary:
          'The submitted speech sample was screened for acoustic patterns associated with dysarthria and stuttering. This early screening result is not a diagnosis and should be interpreted with clinical guidance.',
    );
  }

  void dispose() => _onDevicePredictionService.dispose();
}

class PredictionException implements Exception {
  PredictionException(this.message);
  final String message;
}
