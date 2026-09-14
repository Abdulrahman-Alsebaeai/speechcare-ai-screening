# Model Files

The trained ONNX model binaries are intentionally not stored in this Git repository because they are large artifacts.

Place the following files in this directory before running real on-device inference:

- `model1_normal_vs_disorder_best.onnx` — Stage 1: Normal Speech vs Speech Disorder
- `model2_dysarthria_vs_stuttering_best.onnx` — Stage 2: Dysarthria vs Stuttering

The Flutter application already looks for these paths at runtime. `EXPORT_SUMMARY.json` documents the exported model tasks and audio configuration.

For public distribution, host model artifacts in GitHub Releases, Git LFS, or a dedicated model registry and document the checksum/version.
