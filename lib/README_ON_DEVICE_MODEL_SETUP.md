# On-device model setup for Flutter

This `lib` folder is prepared to run the trained ONNX models directly inside Flutter using `onnxruntime`.

## Required assets
Place the two trained models in one of these folders and declare them in `pubspec.yaml`:

Preferred path:

```yaml
flutter:
  assets:
    - assets/models/model1_normal_vs_disorder_best.onnx
    - assets/models/model2_dysarthria_vs_stuttering_best.onnx
```

The code also tries these fallback paths if they are declared in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/modes/model1_normal_vs_disorder_best.onnx
    - assets/modes/model2_dysarthria_vs_stuttering_best.onnx
    - asstes/modes/model1_normal_vs_disorder_best.onnx
    - asstes/modes/model2_dysarthria_vs_stuttering_best.onnx
```

## Required dependencies
Add these dependencies if they are missing:

```yaml
dependencies:
  onnxruntime: ^1.4.1
  provider: ^6.1.2
  sqflite: ^2.3.3
  path: ^1.9.0
  path_provider: ^2.1.4
  permission_handler: ^11.3.1
  record: ^5.2.0
  file_picker: ^8.1.2
  dio: ^5.7.0
  intl: ^0.19.0
```

## Audio format
The app records WAV audio at 16 kHz, mono, matching the training pipeline.
On-device upload mode currently accepts WAV files only because MP3/M4A decoding is not handled inside this `lib` folder.

## Model labels
Model 1:
- 0 = Normal Speech
- 1 = Speech Disorder

Model 2:
- 0 = Dysarthria
- 1 = Stuttering

This app is for early screening only and is not a clinical diagnosis.
