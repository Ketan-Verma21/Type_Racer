import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:type_racer/app.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://4d04f8c7a05d03e52ef3a2f4c5abc753@o4507341116145664.ingest.us.sentry.io/4512209704124416';
      options.sendDefaultPii = false; // don't send player IP/device PII
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(SentryWidget(child: const MyApp())),
  );
}
