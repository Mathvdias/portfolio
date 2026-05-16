import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/bootstrap/app_bootstrap.dart';
import 'core/di/app_dependencies.dart';
import 'core/monitoring/jank_monitor.dart';
import 'features/desktop/presentation/pages/desktop_page.dart';
import 'features/desktop/presentation/viewmodels/desktop_viewmodel.dart';
import 'features/guestbook/data/repositories/guestbook_repository.dart';
import 'features/guestbook/presentation/viewmodels/guestbook_viewmodel.dart';
import 'features/localization/presentation/viewmodels/locale_viewmodel.dart';
import 'features/visitors/data/datasources/visitor_datasource.dart';
import 'features/visitors/data/repositories/visitor_repository_impl.dart';
import 'l10n/app_localizations.dart';
import 'shared/constants/app_strings.dart';
import 'shared/widgets/scroll_behavior.dart';
import 'theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key, required this.config});

  final AppConfig config;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final LocaleViewModel _localeVM;
  late final DesktopViewModel _desktopVM;
  late final GuestbookViewModel _guestbookVM;
  late final JankMonitor _jankMonitor;

  final _visitorRepository = VisitorRepositoryImpl(VisitorDatasource());

  @override
  void initState() {
    super.initState();
    _localeVM = LocaleViewModel()..init();
    _desktopVM = DesktopViewModel();
    _guestbookVM = GuestbookViewModel(
      GuestbookRepository(),
      widget.config.prefs,
    )..analytics = widget.config.analytics;
    _jankMonitor = JankMonitor(widget.config.analytics)..start();
  }

  @override
  void dispose() {
    _jankMonitor.stop();
    _localeVM.dispose();
    _guestbookVM.dispose();
    _desktopVM.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDependencies(
      localeViewModel: _localeVM,
      visitorRepository: _visitorRepository,
      guestbookViewModel: _guestbookVM,
      desktopViewModel: _desktopVM,
      analyticsService: widget.config.analytics,
      child: ListenableBuilder(
        listenable: _localeVM,
        builder:
            (context, _) => MaterialApp(
              title: AppStrings.appName,
              theme: AppTheme.darkTheme,
              debugShowCheckedModeBanner: false,
              locale: _localeVM.flutterLocale,
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
            ),
      ),
    );
  }
}
