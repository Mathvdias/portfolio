import 'package:flutter/material.dart';
import '../../features/localization/presentation/viewmodels/locale_viewmodel.dart';
import '../../features/visitors/domain/repositories/visitor_repository.dart';

class AppDependencies extends InheritedWidget {
  const AppDependencies({
    super.key,
    required this.localeViewModel,
    required this.visitorRepository,
    required super.child,
  });

  final LocaleViewModel localeViewModel;
  final VisitorRepository visitorRepository;

  static AppDependencies of(BuildContext context) {
    final deps =
        context.dependOnInheritedWidgetOfExactType<AppDependencies>();
    assert(deps != null, 'AppDependencies not found in widget tree');
    return deps!;
  }

  @override
  bool updateShouldNotify(AppDependencies oldWidget) => false;
}
