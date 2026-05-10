import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:portifolio/widgets/scroll_behavior.dart' show AppCustomScrollBehavior;
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'pages/desktop_page.dart';
import 'l10n/app_localizations.dart';
import 'controllers/language_controller.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageController(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageController>(
      builder: (context, languageController, _) {
        return MaterialApp(
          title: 'Matheus Dias',
          theme: AppTheme.darkTheme,
          debugShowCheckedModeBanner: false,
          locale: languageController.locale,
          supportedLocales: const [
            Locale('en'),
            Locale('es'),
            Locale('fr'),
            Locale('it'),
            Locale('pt'),
          ],
          scrollBehavior: AppCustomScrollBehavior(),
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const DesktopPage(),
        );
      },
    );
  }
}
