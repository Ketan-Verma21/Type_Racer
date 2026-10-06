import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/providers/chat_provider.dart';
import 'package:type_racer/providers/client_state_provider.dart';
import 'package:type_racer/providers/game_state_provider.dart';
import 'package:type_racer/providers/server_status_provider.dart';
import 'package:type_racer/screens/create_room_screen.dart';
import 'package:type_racer/screens/game_screen.dart';
import 'package:type_racer/screens/home_screen.dart';
import 'package:type_racer/screens/join_room_screen.dart';
import 'package:type_racer/theme/app_theme.dart';
import 'package:sentry_flutter/sentry_flutter.dart';


Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://4d04f8c7a05d03e52ef3a2f4c5abc753@o4507341116145664.ingest.us.sentry.io/4512209704124416';
      options.sendDefaultPii = true;
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
    },
    appRunner: () => runApp(SentryWidget(child: const MyApp())),
  );
 }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameStateProvider()),
        ChangeNotifierProvider(create: (_) => ClientStateProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_)=> ServerStatusProvider())
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Slim Shady',
        theme: AppTheme.dark,
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/create-room': (context) => const CreateRoomScreen(),
          '/join-room': (context) => const JoinRoomScreen(),
          '/game-screen': (context) => const GameScreen()
        },
      ),
    );
  }
}
