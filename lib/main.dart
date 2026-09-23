import 'package:flutter/material.dart';

import 'app/bootstrap/app.dart';
import 'app/bootstrap/dependencies.dart';
import 'core/config/app_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  runApp(B46App(dependencies: AppDependencies.create(config)));
}
