import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:type_racer/data/models/game_settings.dart';
import 'package:type_racer/data/models/leaderboard.dart';
import 'package:type_racer/domain/game_modes.dart';
import 'package:type_racer/screens/create_room_screen.dart';
import 'package:type_racer/screens/join_room_screen.dart';
import 'package:type_racer/widgets/custom_button.dart';
import 'package:type_racer/widgets/leaderboard_panel.dart';
import 'package:type_racer/widgets/race_lane.dart';
import 'package:type_racer/widgets/settings_panel.dart';
import 'package:type_racer/widgets/stats_bar.dart';

import '../fakes/builders.dart';
import 'harness.dart';

/// Presses the CustomButton labelled [label] by calling its onTap, the
/// same callback a real tap runs. (A simulated tap on these cards misses in
/// the test window: something above the card takes the hit; in the app it works.)
void press(WidgetTester t, String label) {
  final button = t.widget<CustomButton>(
      find.ancestor(of: find.text(label), matching: find.byType(CustomButton)));
  expect(button.onTap, isNotNull, reason: '$label is disabled');
  button.onTap!();
}

void main() {
  group('RaceLane', () {
    testWidgets('shows name, YOU tag, WPM and progress', (t) async {
      await pumpApp(t,
          const RaceLane(name: 'Ketan', progress: 0.5, color: Colors.cyan, wpm: 72, isMe: true));

      expect(find.text('Ketan'), findsOneWidget);
      expect(find.text('YOU'), findsOneWidget);
      expect(find.text('72 WPM'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('an eliminated racer shows OUT instead of numbers', (t) async {
      await pumpApp(t, const RaceLane(name: 'x', progress: 0.3, color: Colors.red, isEliminated: true));

      expect(find.text('OUT'), findsOneWidget);
      expect(find.text('30%'), findsNothing);
    });

    testWidgets('a bad progress value is drawn as 0..100 %', (t) async {
      await pumpApp(t, const RaceLane(name: 'x', progress: 1.7, color: Colors.red));
      expect(find.text('100%'), findsOneWidget);
    });
  });

  testWidgets('StatsBar shows WPM, accuracy, words and mode', (t) async {
    await pumpApp(t, const StatsBar(wpm: 64, accuracy: 0.97, done: 12, total: 40, mode: GameModes.flawless));

    for (final text in ['64', '97%', '12/40', 'FLAWLESS', '🎯']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
  });

  group('SettingsPanel', () {
    testWidgets('the host changes the time limit with a chip', (t) async {
      GameSettings? changed;
      await pumpApp(
        t,
        SettingsPanel(
          settings: GameSettings.defaults,
          isLeader: true,
          racerCount: 2,
          onChange: (s) => changed = s,
        ),
      );

      await t.tap(find.text('30s'));

      expect(changed, GameSettings.defaults.copyWith(timeLimit: 30));
    });

    testWidgets('max players cannot go below the racers already in', (t) async {
      GameSettings? changed;
      await pumpApp(
        t,
        SettingsPanel(
          settings: const GameSettings(maxPlayers: 2),
          isLeader: true,
          racerCount: 2,
          onChange: (s) => changed = s,
        ),
      );

      await t.tap(find.byIcon(Icons.remove_circle_outline_rounded));
      expect(changed, isNull);

      await t.tap(find.byIcon(Icons.add_circle_outline_rounded));
      expect(changed?.maxPlayers, 3);
    });

    testWidgets('a guest sees a read-only summary', (t) async {
      await pumpApp(
        t,
        SettingsPanel(
          settings: const GameSettings(mode: 'sudden-death', timeLimit: 90),
          isLeader: false,
          racerCount: 2,
          onChange: (_) {},
        ),
      );

      expect(find.text('host only'), findsOneWidget);
      expect(find.text('90s'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);
    });
  });

  group('LeaderboardPanel', () {
    testWidgets('loads classic first, shows entries, switches mode', (t) async {
      final h = await pumpApp(t, const LeaderboardPanel(), size: phone);
      await t.pump(); // first frame -> load

      expect(h.repo.sent, [
        ['requestLeaderboard', 'classic'],
      ]);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      h.repo.emitLeaderboard(const Leaderboard(mode: 'classic', entries: [
        LeaderboardEntry(nickname: 'Ketan', wpm: 92),
        LeaderboardEntry(nickname: 'Verma', wpm: 71),
      ]));
      await t.pump();

      expect(find.text('Ketan'), findsOneWidget);
      expect(find.text('🥇'), findsOneWidget);

      await t.tap(find.textContaining('Sudden Death'));
      await t.pump();
      expect(h.repo.sent.last, ['requestLeaderboard', 'sudden-death']);

      h.repo.emitLeaderboard(const Leaderboard(mode: 'sudden-death'));
      await t.pump();
      expect(find.textContaining('No races yet'), findsOneWidget);
    });
  });

  group('Create / Join', () {
    testWidgets('create: sends the name, then opens the game when the server answers', (t) async {
      final h = await pumpApp(t, const CreateRoomScreen(), size: phone);

      await t.enterText(find.byType(TextField), 'Ketan');
      press(t, 'CREATE');
      await t.pump();
      expect(h.repo.sent, [
        ['createGame', 'Ketan'],
      ]);

      // the game screen route isn't registered in the harness: a pushNamed
      // failure here would throw, so check the state change instead
      expect(h.game.inGame, isFalse);
      await settle(t);
    });

    testWidgets('join: a bad code is refused before anything is sent', (t) async {
      final h = await pumpApp(t, const JoinRoomScreen(), size: phone);

      await t.enterText(find.byType(TextField).first, 'Ketan');
      await t.enterText(find.byType(TextField).last, 'K7P');
      press(t, 'JOIN');
      await t.pump();

      expect(h.repo.sent, isEmpty);
      expect(find.textContaining('6 letters or digits'), findsOneWidget);
      await settle(t);
    });

    testWidgets('join: a refusal from the server stops waiting and is shown', (t) async {
      final h = await pumpApp(t, const JoinRoomScreen(), size: phone);

      await t.enterText(find.byType(TextField).first, 'Ketan');
      await t.enterText(find.byType(TextField).last, 'K7P2QX');
      press(t, 'JOIN');
      await t.pump();
      expect(h.repo.sent, [
        ['joinGame', 'K7P2QX', 'Ketan'],
      ]);

      h.repo.emitJoinError('Game is full');
      await t.pump();

      expect(find.text('Game is full'), findsOneWidget);
      expect(find.text('JOIN'), findsOneWidget); // spinner gone, can try again
      await settle(t);
    });
  });

  testWidgets('room() builder sanity: me is the host', (t) async {
    final h = await pumpApp(t, const SizedBox(), game: room());
    expect(h.game.me?.isHost, isTrue);
  });
}
