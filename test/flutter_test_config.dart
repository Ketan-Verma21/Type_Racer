import 'dart:async';

import 'package:type_racer/theme/app_theme.dart';

/// Runs before every test file: no font downloads in tests.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppTheme.useGoogleFonts = false;
  await testMain();
}
