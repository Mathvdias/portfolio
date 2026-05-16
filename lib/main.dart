import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/bootstrap/app_bootstrap.dart';

void main() async {
  final config = await AppBootstrap.init();
  runApp(App(config: config));
}
