import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';

import '../models/prediction_result.dart';
import 'audio_preprocessor_service.dart';

class OnDevicePredictionService {
  OnDevicePredictionService({AudioPreprocessorService? preprocessor})
    : _preprocessor = preprocessor ?? AudioPreprocessorService();

  final AudioPreprocessorService _preprocessor;

  OrtSession? _model1Session;
  OrtSession? _model2Session;
  Future<OrtSession>? _model1LoadTask;
  Future<OrtSession>? _model2LoadTask;
  bool _environmentReady = false;

  static const Duration _totalPredictionTimeout = Duration(seconds: 90);
  static const Duration _assetLoadTimeout = Duration(seconds: 35);
  static const Duration _singleModelRunTimeout = Duration(seconds: 35);

  static const List<String> _model1AssetCandidates = [
    'assets/models/model1_normal_vs_disorder_best.onnx',
    'assets/modes/model1_normal_vs_disorder_best.onnx',
    'asstes/modes/model1_normal_vs_disorder_best.onnx',
  ];

  static const List<String> _model2AssetCandidates = [
    'assets/models/model2_dysarthria_vs_stuttering_best.onnx',
    'assets/modes/model2_dysarthria_vs_stuttering_best.onnx',
    'asstes/modes/model2_dysarthria_vs_stuttering_best.onnx',
  ];

  Future<PredictionResult> predict(String audioPath) {
    return _predictInternal(audioPath).timeout(
      _totalPredictionTimeout,
      onTimeout: () {
        throw OnDeviceModelException(
          'Analysis took too long. Please close other apps, record a shorter clear sample, and try again.',
        );
      },
    );
  }

  Future<PredictionResult> _predictInternal(String audioPath) async {
    final prepared = await _preprocessor.prepareForModel(audioPath);
    if (!prepared.isSuitable) {
      return PredictionResult(
        finalLabel: 'Unsuitable sample',
        confidencePercent: 0,
        stage1: 'Rejected: audio quality check',
        stage2: 'Classification skipped',
        probabilities: const {
          'Normal Speech': 0,
          'Speech Disorder': 0,
          'Dysarthria': 0,
          'Stuttering': 0,
        },
        warning: prepared.warning,
        recommendation:
            'Record again in a quiet room for 8 to 15 seconds, then retry the screening.',
        reportSummary:
            'No screening conclusion was generated because the audio sample was incomplete, unclear, too silent, or unsuitable for analysis.',
      );
    }

    final model1 = await _ensureModel1Loaded();
    final model1Output = await _runModel(
      model1,
      prepared.inputValues,
      modelLabel: 'Stage 1',
    );
    final model1Probabilities = _probabilitiesFromOutput(model1Output);
    final normalProbability = model1Probabilities[0];
    final disorderProbability = model1Probabilities[1];

    if (normalProbability >= disorderProbability) {
      final confidence = normalProbability * 100;
      return PredictionResult(
        finalLabel: 'Normal Speech',
        confidencePercent: confidence,
        stage1: 'Normal Speech vs Speech Disorder',
        stage2: 'Skipped because Stage 1 predicted Normal Speech',
        probabilities: {
          'Normal Speech': normalProbability * 100,
          'Speech Disorder': disorderProbability * 100,
        },
        warning: _joinWarnings(
          prepared.warning,
          _lowConfidenceWarning(confidence),
        ),
        recommendation:
            'Continue periodic self-checks if concerns persist. This result is only an early screening result.',
        reportSummary:
            'The on-device AI model analyzed the submitted speech sample and did not detect strong acoustic indicators of dysarthria or stuttering in this recording.',
      );
    }

    final model2 = await _ensureModel2Loaded();
    final model2Output = await _runModel(
      model2,
      prepared.inputValues,
      modelLabel: 'Stage 2',
    );
    final model2Probabilities = _probabilitiesFromOutput(model2Output);
    final dysarthriaProbability = model2Probabilities[0];
    final stutteringProbability = model2Probabilities[1];

    final isDysarthria = dysarthriaProbability >= stutteringProbability;
    final finalLabel = isDysarthria ? 'Dysarthria' : 'Stuttering';
    final finalStage2Probability =
        isDysarthria ? dysarthriaProbability : stutteringProbability;
    final confidence = disorderProbability * finalStage2Probability * 100;

    return PredictionResult(
      finalLabel: finalLabel,
      confidencePercent: confidence,
      stage1: 'Speech Disorder detected',
      stage2: 'Dysarthria vs Stuttering',
      probabilities: {
        'Normal Speech': normalProbability * 100,
        'Speech Disorder': disorderProbability * 100,
        'Dysarthria': disorderProbability * dysarthriaProbability * 100,
        'Stuttering': disorderProbability * stutteringProbability * 100,
      },
      warning: _joinWarnings(
        prepared.warning,
        _lowConfidenceWarning(confidence),
      ),
      recommendation:
          'Consult a speech-language specialist for a professional assessment, especially if symptoms continue or affect daily communication.',
      reportSummary:
          'The on-device two-stage AI screening pipeline found acoustic indicators most consistent with $finalLabel. This is not a clinical diagnosis and should be interpreted with professional guidance.',
    );
  }

  Future<OrtSession> _ensureModel1Loaded() {
    final existing = _model1Session;
    if (existing != null) return Future.value(existing);
    return _model1LoadTask ??= _createSessionFromAsset(_model1AssetCandidates)
        .then((session) {
          _model1Session = session;
          _model1LoadTask = null;
          return session;
        })
        .catchError((Object error) {
          _model1LoadTask = null;
          throw error;
        });
  }

  Future<OrtSession> _ensureModel2Loaded() {
    final existing = _model2Session;
    if (existing != null) return Future.value(existing);
    return _model2LoadTask ??= _createSessionFromAsset(_model2AssetCandidates)
        .then((session) {
          _model2Session = session;
          _model2LoadTask = null;
          return session;
        })
        .catchError((Object error) {
          _model2LoadTask = null;
          throw error;
        });
  }

  Future<OrtSession> _createSessionFromAsset(List<String> candidates) async {
    if (!_environmentReady) {
      OrtEnv.instance.init();
      _environmentReady = true;
    }

    final modelBytes = await _loadFirstAvailableAsset(candidates);
    try {
      final options = OrtSessionOptions();
      return OrtSession.fromBuffer(modelBytes, options);
    } catch (error) {
      throw OnDeviceModelException(
        'Could not initialize the ONNX model on this device. The model may be incompatible with the mobile runtime or too large for available memory.',
        details: error.toString(),
      );
    }
  }

  Future<Uint8List> _loadFirstAvailableAsset(List<String> candidates) async {
    final errors = <String>[];
    for (final path in candidates) {
      try {
        final raw = await rootBundle.load(path).timeout(_assetLoadTimeout);
        return raw.buffer.asUint8List();
      } catch (error) {
        errors.add('$path -> $error');
      }
    }
    throw OnDeviceModelException(
      'Could not load ONNX model assets. Add the two ONNX files under assets/models and declare them in pubspec.yaml.',
      details: errors.join('\n'),
    );
  }

  Future<List<double>> _runModel(
    OrtSession session,
    List<double> inputValues, {
    required String modelLabel,
  }) async {
    final inputName =
        session.inputNames.isNotEmpty
            ? session.inputNames.first
            : 'input_values';
    final outputName =
        session.outputNames.isNotEmpty ? session.outputNames.first : 'logits';

    final inputOrt = OrtValueTensor.createTensorWithDataList(
      Float32List.fromList(inputValues),
      [1, inputValues.length],
    );
    final runOptions = OrtRunOptions();
    List<OrtValue?>? outputs;
    try {
      final runFuture = session.runAsync(
        runOptions,
        {inputName: inputOrt},
        [outputName],
      );
      if (runFuture == null) {
        throw OnDeviceModelException(
          '$modelLabel ONNX inference could not be started on this device.',
        );
      }
      outputs = await runFuture.timeout(
        _singleModelRunTimeout,
        onTimeout: () {
          throw OnDeviceModelException(
            '$modelLabel ONNX inference did not finish in time. Please retry with a clear 8 to 15 second WAV sample.',
          );
        },
      );
      if (outputs == null || outputs.isEmpty || outputs.first == null) {
        throw OnDeviceModelException(
          '$modelLabel ONNX model returned no output.',
        );
      }
      final value = (outputs.first! as OrtValueTensor).value;
      final flattened = _flattenNumbers(value);
      if (flattened.length < 2) {
        throw OnDeviceModelException(
          '$modelLabel ONNX model output is invalid.',
        );
      }
      return flattened.take(2).toList(growable: false);
    } on OnDeviceModelException {
      rethrow;
    } catch (error) {
      throw OnDeviceModelException(
        '$modelLabel ONNX inference failed. Check that the model input shape is [1, ${inputValues.length}] and input type is Float32.',
        details: error.toString(),
      );
    } finally {
      if (outputs != null) {
        for (final item in outputs) {
          item?.release();
        }
      }
      inputOrt.release();
      runOptions.release();
    }
  }

  List<double> _flattenNumbers(dynamic value) {
    final result = <double>[];
    void walk(dynamic item) {
      if (item is num) {
        result.add(item.toDouble());
      } else if (item is List) {
        for (final child in item) {
          walk(child);
        }
      } else if (item is Float32List) {
        result.addAll(item.map((v) => v.toDouble()));
      } else if (item is Float64List) {
        result.addAll(item);
      } else if (item is Int32List) {
        result.addAll(item.map((v) => v.toDouble()));
      } else if (item is Int64List) {
        result.addAll(item.map((v) => v.toDouble()));
      }
    }

    walk(value);
    return result;
  }

  List<double> _probabilitiesFromOutput(List<double> output) {
    final safe = output
        .take(2)
        .map((v) => v.isFinite ? v : 0.0)
        .toList(growable: false);
    final sum = safe.fold<double>(0, (a, b) => a + b);
    final looksLikeProbabilities =
        safe.every((v) => v >= 0 && v <= 1) && sum > 0.85 && sum < 1.15;
    if (looksLikeProbabilities) {
      return safe.map((v) => v / sum).toList(growable: false);
    }
    return _softmax(safe);
  }

  List<double> _softmax(List<double> logits) {
    final safe = logits
        .map((v) => v.isFinite ? v : 0.0)
        .toList(growable: false);
    final maxLogit = safe.reduce(max);
    final exps = safe.map((v) => exp(v - maxLogit)).toList(growable: false);
    final sum = exps.fold<double>(0, (a, b) => a + b);
    if (sum == 0 || !sum.isFinite) return [0.5, 0.5];
    return exps.map((v) => v / sum).toList(growable: false);
  }

  String _lowConfidenceWarning(double confidence) {
    if (confidence >= 60) return '';
    return 'Confidence is below the recommended threshold. Please repeat the screening with a clearer recording and consult a specialist if concerns persist.';
  }

  String _joinWarnings(String first, String second) {
    final items = [
      first,
      second,
    ].where((item) => item.trim().isNotEmpty).toList(growable: false);
    return items.join(' ');
  }

  void dispose() {
    _model1Session?.release();
    _model2Session?.release();
    _model1Session = null;
    _model2Session = null;
    _model1LoadTask = null;
    _model2LoadTask = null;
    if (_environmentReady) {
      OrtEnv.instance.release();
      _environmentReady = false;
    }
  }
}

class OnDeviceModelException implements Exception {
  OnDeviceModelException(this.message, {this.details = ''});
  final String message;
  final String details;

  @override
  String toString() => details.isEmpty ? message : '$message\n$details';
}
