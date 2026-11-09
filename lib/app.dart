import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/data/repositories/game_repository.dart';
import 'package:type_racer/data/repositories/socket_game_repository.dart';
import 'package:type_racer/screens/create_room_screen.dart';
import 'package:type_racer/screens/game/game_screen.dart';
import 'package:type_racer/screens/home_screen.dart';
import 'package:type_racer/screens/join_room_screen.dart';
import 'package:type_racer/state/chat_provider.dart';
import 'package:type_racer/state/game_controller.dart';
import 'package:type_racer/state/leaderboard_controller.dart';
import 'package:type_racer/state/server_status_provider.dart';
import 'package:type_racer/theme/app_theme.dart';

/// Wiring: the one place that picks the real [GameRepository].
/// Tests build the same widgets with a fake one.
class MyApp extends StatelessWidget {
  final GameRepository? repository;
  const MyApp({super.key, this.repository});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<GameRepository>(create: (_) => repository ?? SocketGameRepository()),
        ChangeNotifierProvider(create: (c) => GameController(c.read<GameRepository>())),
        ChangeNotifierProvider(create: (c) => ChatProvider(c.read<GameRepository>())),
        ChangeNotifierProvider(create: (c) => LeaderboardController(c.read<GameRepository>())),
        ChangeNotifierProvider(create: (_) => ServerStatusProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Type Racer',
        theme: AppTheme.dark,
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/create-room': (context) => const CreateRoomScreen(),
          '/join-room': (context) => const JoinRoomScreen(),
          '/game-screen': (context) => const GameScreen(),
        },
      ),
    );
  }
}
