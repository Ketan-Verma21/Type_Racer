// Every game view, at phone / tablet / desktop width: it lays out without
// overflow (a RenderFlex overflow fails the test) and uses the space (FR-19).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:type_racer/screens/game/game_screen.dart';
import 'package:type_racer/screens/game/views/common.dart';
import 'package:type_racer/widgets/chat_panel.dart';
import 'package:type_racer/widgets/game_text_field.dart';
import 'package:type_racer/widgets/scoreboard.dart';
import 'package:type_racer/widgets/sentence_game.dart';
import 'package:type_racer/widgets/settings_panel.dart';

import '../fakes/builders.dart';
import 'harness.dart';

final fourRacers = [
  player('me', host: true, idx: 1),
  player('rival', idx: 2),
  player('third'),
  player('fourth', idx: 3),
];

void main() {
  for (final entry in allSizes.entries) {
    final name = entry.key, size = entry.value;

    group('at $name width', () {
      testWidgets('lobby', (t) async {
        await pumpApp(t, const GameScreen(), size: size, game: room(players: fourRacers));

        expect(find.text('ROOM CODE'), findsOneWidget);
        expect(find.byType(SettingsPanel), findsOneWidget);
        expect(find.text('START'), findsOneWidget);
        if (size != phone) {
          // chat is a column of its own, visible without scrolling
          expect(onScreen(t, find.byType(ChatPanel)), isTrue);
        }
        await settle(t);
      });

      testWidgets('race', (t) async {
        await pumpApp(t, const GameScreen(), size: size, game: room(isJoin: false, players: fourRacers));

        expect(find.byType(SentenceGame), findsOneWidget);
        expect(find.byType(GameTextField), findsOneWidget);
        expect(find.byType(RaceLanes), findsOneWidget);
        expect(onScreen(t, find.byType(GameTextField)), isTrue);
        await settle(t);
      });

      testWidgets('watch (out)', (t) async {
        await pumpApp(t, const GameScreen(),
            size: size,
            game: room(isJoin: false, players: [player('me', out: true), ...fourRacers.skip(1)]));

        expect(find.textContaining("You're out"), findsOneWidget);
        expect(find.byType(RaceLanes), findsOneWidget);
        await settle(t);
      });

      testWidgets('results', (t) async {
        await pumpApp(t, const GameScreen(),
            size: size,
            game: room(isOver: true, players: [
              player('me', host: true, idx: kWords.length, wpm: 80),
              player('rival', idx: kWords.length, wpm: 60),
            ]));
        await t.pump(const Duration(seconds: 1)); // row animations

        expect(find.byType(Scoreboard), findsOneWidget);
        expect(find.text('YOU WON! 🎉'), findsOneWidget);
        expect(find.text('PLAY AGAIN'), findsOneWidget);
        await settle(t);
      });
    });
  }

  testWidgets('desktop race puts 3+ racers in two columns of lanes', (t) async {
    await pumpApp(t, const GameScreen(), size: desktop, game: room(isJoin: false, players: fourRacers));
    expect(find.byType(GridView), findsOneWidget);
    await settle(t);
  });

  testWidgets('phone race keeps one column of lanes', (t) async {
    await pumpApp(t, const GameScreen(), size: phone, game: room(isJoin: false, players: fourRacers));
    expect(find.byType(GridView), findsNothing);
    await settle(t);
  });

  testWidgets('the lobby shows a guest the waiting message, not Start', (t) async {
    final h = await pumpApp(t, const GameScreen(),
        game: room(players: [player('host', host: true), player('me')]));

    expect(find.text('START'), findsNothing);
    expect(find.text('Waiting for the host to start...'), findsOneWidget);
    expect(h.repo.sent, contains(equals(['requestChatHistory', 'K7P2QX'])));
    await settle(t);
  });

  testWidgets('the host taps Start -> the server is asked to start', (t) async {
    final h = await pumpApp(t, const GameScreen(), game: room());

    await t.tap(find.text('START'));
    await t.pump();

    expect(h.repo.sent, contains(equals(['startRace', 'K7P2QX', 'me'])));
    expect(find.text('Starting...'), findsOneWidget);
    await t.pump(const Duration(seconds: 9)); // safety timer re-enables Start
    expect(find.text('START'), findsOneWidget);
    await settle(t);
  });
}
