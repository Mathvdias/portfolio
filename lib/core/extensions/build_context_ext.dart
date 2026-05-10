import 'package:flutter/material.dart';
import '../di/app_dependencies.dart';
import '../../features/localization/presentation/viewmodels/locale_viewmodel.dart';

extension BuildContextExt on BuildContext {
  AppDependencies get deps => AppDependencies.of(this);
  LocaleViewModel get localeViewModel => deps.localeViewModel;
}
