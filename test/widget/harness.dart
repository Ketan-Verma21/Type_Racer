import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/data/models/game.dart';
import 'package:type_racer/state/chat_provider.dart';
import 'package:type_racer/state/game_controller.dart';
import 'package:type_racer/state/leaderboard_controller.dart';
import 'package:type_racer/theme/app_theme.dart';

import '../fakes/fake_game_repository.dart';

/// Window widths the layouts are checked at (PRD FR-19).
const phone = Size(400, 860);
const tablet = Size(900, 800);
const desktop = Size(1440, 900);
const allSizes = {'phone': phone, 'tablet': tablet, 'desktop': desktop};

class Harness {
  final FakeGameRepository repo;
  final GameController game;
  final ChatProvider chat;
  final LeaderboardController leaderboard;
  Harness(this.repo, this.game, this.chat, this.leaderboard);
}

/// Pumps [child] at [size] with the app's state wired to a fake server.
/// [game] is the room the fake server says we're in ("me" is player `me`).
Future<Harness> pumpApp(WidgetTester tester, Widget child, {Size size = desktop, Game? game}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final repo = FakeGameRepository()..myPlayerId = 'me';
  final h = Harness(repo, GameController(repo), ChatProvider(repo), LeaderboardController(repo));
  if (game != null) repo.emitGame(game);

  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: h.game),
      ChangeNotifierProvider.value(value: h.chat),
      ChangeNotifierProvider.value(value: h.leaderboard),
    ],
    child: MaterialApp(theme: AppTheme.dark, home: Scaffold(body: child)),
  ));
  await tester.pump();
  return h;
}

/// True if [finder]'s widget is fully inside the window (seen without scrolling).
bool onScreen(WidgetTester tester, Finder finder) {
  final r = tester.getRect(finder);
  final view = tester.view.physicalSize / tester.view.devicePixelRatio;
  return r.left >= 0 && r.top >= 0 && r.right <= view.width && r.bottom <= view.height;
}

/// Lets entry animations, delay timers and snackbars (4 s) finish (call at the end of
/// a test, or flutter_test reports pending timers).
Future<void> settle(WidgetTester tester) => tester.pump(const Duration(seconds: 5));
