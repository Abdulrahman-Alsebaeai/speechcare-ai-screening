# Architecture Notes

The application is organized around a small service layer and `Provider`-managed application state. `AudioService` captures/imports WAV audio, `AudioPreprocessorService` normalizes and validates it, and `PredictionApiService` selects between on-device ONNX inference, an optional remote API, or an explicitly enabled development mock mode. Results are persisted through `AppDatabase` and surfaced through history/progress screens.

The AI path is intentionally fail-closed by default: if model files are missing or inference fails and `ALLOW_MOCK_FALLBACK` is false, the user receives an error instead of a fabricated clinical result.
