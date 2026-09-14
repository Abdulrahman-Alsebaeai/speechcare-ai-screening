import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'screens/auth_screen.dart';
import 'screens/main_shell.dart';
import 'screens/splash_screen.dart';
import 'state/app_state.dart';

class SpeechScreeningApp extends StatelessWidget {
  const SpeechScreeningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => context.l10n.t('appTitle'),
          locale: state.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          home:
              state.isBootstrapping
                  ? const SplashScreen()
                  : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child:
                        state.currentUser == null
                            ? const AuthScreen()
                            : const MainShell(),
                  ),
        );
      },
    );
  }
}
