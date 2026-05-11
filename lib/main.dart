import 'dart:developer' as dev;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:portifolio/shared/constants/app_strings.dart' show AppStrings;
import 'package:shared_preferences/shared_preferences.dart';

import 'core/di/app_dependencies.dart';
import 'features/desktop/presentation/pages/desktop_page.dart';
import 'features/desktop/presentation/viewmodels/desktop_viewmodel.dart';
import 'features/localization/presentation/viewmodels/locale_viewmodel.dart';
import 'features/visitors/data/datasources/visitor_datasource.dart';
import 'features/visitors/data/repositories/visitor_repository_impl.dart';
import 'features/guestbook/data/repositories/guestbook_repository.dart';
import 'features/guestbook/presentation/viewmodels/guestbook_viewmodel.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'shared/widgets/scroll_behavior.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  late final SharedPreferences prefs;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    dev.log('Firebase init error: $e', name: 'Main', level: 1000);
    prefs = await SharedPreferences.getInstance();
  }

  runApp(AppRoot(prefs: prefs));
}

class AppRoot extends StatefulWidget {
  final SharedPreferences prefs;

  const AppRoot({super.key, required this.prefs});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final _localeViewModel = LocaleViewModel();
  final _visitorRepository = VisitorRepositoryImpl(VisitorDatasource());
  final _desktopViewModel = DesktopViewModel();
  late final GuestbookViewModel _guestbookViewModel;

  @override
  void initState() {
    super.initState();
    _localeViewModel.init();
    _guestbookViewModel = GuestbookViewModel(
      GuestbookRepository(),
      widget.prefs,
    );
  }

  @override
  void dispose() {
    _localeViewModel.dispose();
    _guestbookViewModel.dispose();
    _desktopViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDependencies(
      localeViewModel: _localeViewModel,
      visitorRepository: _visitorRepository,
      guestbookViewModel: _guestbookViewModel,
      desktopViewModel: _desktopViewModel,
      child: ListenableBuilder(
        listenable: _localeViewModel,
        builder: (context, _) {
          return MaterialApp(
            title: AppStrings.appName,
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
