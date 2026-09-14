import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/app_database.dart';
import 'services/audio_service.dart';
import 'services/auth_service.dart';
import 'services/prediction_api_service.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  await database.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create:
              (_) => AppState(
                authService: AuthService(database),
                database: database,
                predictionApiService: PredictionApiService.mockFirst(),
                audioService: AudioService(),
              )..bootstrap(),
        ),
      ],
      child: const SpeechScreeningApp(),
    ),
  );
}
