import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/app_dependencies.dart';
import 'features/desktop/presentation/pages/desktop_page.dart';
import 'features/localization/presentation/viewmodels/locale_viewmodel.dart';
import 'features/visitors/data/datasources/visitor_datasource.dart';
import 'features/visitors/data/repositories/visitor_repository_impl.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'shared/widgets/scroll_behavior.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  runApp(const AppRoot());
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final _localeViewModel = LocaleViewModel();
  final _visitorRepository = VisitorRepositoryImpl(VisitorDatasource());

  @override
  void dispose() {
    _localeViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDependencies(
      localeViewModel: _localeViewModel,
      visitorRepository: _visitorRepository,
      child: ListenableBuilder(
        listenable: _localeViewModel,
        builder: (context, _) {
          return MaterialApp(
            title: 'Matheus Dias',
            theme: AppTheme.darkTheme,
            debugShowCheckedModeBanner: false,
            locale: _localeViewModel.flutterLocale,
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
      ),
    );
  }
}
