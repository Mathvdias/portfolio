import 'package:flutter/material.dart';

import '../../core/services/analytics_service.dart';
import '../../features/desktop/presentation/viewmodels/desktop_viewmodel.dart';
import '../../features/guestbook/presentation/viewmodels/guestbook_viewmodel.dart';
import '../../features/localization/presentation/viewmodels/locale_viewmodel.dart';
import '../../features/visitors/domain/repositories/visitor_repository.dart';

class AppDependencies extends InheritedWidget {
  const AppDependencies({
    super.key,
    required this.localeViewModel,
    required this.visitorRepository,
    required this.guestbookViewModel,
    required this.desktopViewModel,
    required this.analyticsService,
    required super.child,
  });

  final LocaleViewModel localeViewModel;
  final VisitorRepository visitorRepository;
  final GuestbookViewModel guestbookViewModel;
  final DesktopViewModel desktopViewModel;
  final AnalyticsService analyticsService;

  static AppDependencies of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<AppDependencies>();
    assert(result != null, 'No AppDependencies found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppDependencies oldWidget) => false;
}
