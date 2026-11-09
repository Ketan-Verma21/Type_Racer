import 'package:flutter_test/flutter_test.dart';
import 'package:type_racer/data/models/player.dart';
import 'package:type_racer/data/models/timer_state.dart';
import 'package:type_racer/domain/game_modes.dart';
import 'package:type_racer/domain/race_stats.dart';
import 'package:type_racer/domain/ranking.dart';

Player p(String id, {int idx = 0, double wpm = -1, bool spectator = false, bool out = false}) =>
    Player(id: id, nickname: id, wordIndex: idx, wpm: wpm, isSpectator: spectator, isEliminated: out);

void main() {
  group('rankPlayers', () {
    const words = 10;
    List<String> ids(List<Player> ps) => ps.map((x) => x.id).toList();

    test('finished before unfinished, then higher WPM first', () {
      final ranked = rankPlayers([
        p('slow', idx: 4, wpm: 90),
        p('b', idx: 10, wpm: 60),
        p('a', idx: 10, wpm: 80),
      ], words);

      expect(ids(ranked), ['a', 'b', 'slow']);
    });

    test('eliminated last, spectators left out', () {
      final ranked = rankPlayers([
        p('out', idx: 9, wpm: 120, out: true),
        p('in', idx: 3, wpm: 20),
        p('watcher', spectator: true),
      ], words);

      expect(ids(ranked), ['in', 'out']);
    });

    test('does not change the list it was given', () {
      final players = [p('b', idx: 1), p('a', idx: 10, wpm: 50)];
      rankPlayers(players, words);

      expect(ids(players), ['b', 'a']);
    });
  });

  group('elapsedSeconds', () {
    TimerState racing(String clock) => TimerState(countDown: clock, msg: 'Time Remaining');

    test('0 before the race', () {
      expect(elapsedSeconds(const TimerState(countDown: '3', msg: 'Game Starting'), 60), 0);
    });

    test('time limit minus time left, kept within 0..limit', () {
      expect(elapsedSeconds(racing('1:30'), 120), 30);
      expect(elapsedSeconds(racing('0:00'), 60), 60);
      expect(elapsedSeconds(racing('2:00'), 60), 0);
      expect(elapsedSeconds(racing('abc'), 60), 0);
    });
  });

  group('liveWpm', () {
    test('final WPM once the server has it', () {
      expect(liveWpm(p('a', idx: 5, wpm: 71.6), 30), 72);
    });

    test('0 in the first 3 seconds', () {
      expect(liveWpm(p('a', idx: 2), 2), 0);
    });

    test('words typed per minute so far', () {
      expect(liveWpm(p('a', idx: 30), 30), 60);
    });
  });

  group('GameModes', () {
    test('byId finds a mode and falls back to classic', () {
      expect(GameModes.byId('sudden-death'), GameModes.suddenDeath);
      expect(GameModes.byId('turbo'), GameModes.classic);
      expect(GameModes.byId(null), GameModes.classic);
    });

    test('ids match the server', () {
      expect(GameModes.all.map((m) => m.id), ['classic', 'no-mistakes', 'sudden-death']);
    });
  });
}
