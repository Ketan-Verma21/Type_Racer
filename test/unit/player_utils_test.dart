// Unit tests for the pure helpers in player_utils.dart.
// Pattern: Arrange (players) -> Act (call) -> Assert (expect).
import 'package:flutter_test/flutter_test.dart';
import 'package:type_racer/utils/player_utils.dart';

/// Builds a player map shaped like the server's `updateGame` payload.
Map<String, dynamic> player(
  String name, {
  int idx = 0,
  num wpm = -1,
  bool spectator = false,
  bool eliminated = false,
}) =>
    {
      '_id': name,
      'nickname': name,
      'currentWordIndex': idx,
      'WPM': wpm,
      'isSpectator': spectator,
      'isEliminated': eliminated,
    };

void main() {
  group('racersOf', () {
    test('leaves out spectators', () {
      final players = [player('a'), player('b', spectator: true), player('c')];

      final names = racersOf(players).map((p) => p['nickname']).toList();

      expect(names, ['a', 'c']);
    });
  });

  group('wpmOf', () {
    test('reads a number', () {
      expect(wpmOf(player('a', wpm: 42)), 42);
    });

    test('reads a numeric string', () {
      expect(wpmOf({'WPM': '57'}), 57);
    });

    test('returns -1 when WPM is missing', () {
      expect(wpmOf({'WPM': null}), -1);
    });
  });

  group('rankPlayers', () {
    const wordCount = 10;

    test('puts finished players before unfinished ones', () {
      final players = [
        player('slow', idx: 4, wpm: 90),
        player('done', idx: 10, wpm: 50),
      ];

      final ranked = rankPlayers(players, wordCount);

      expect(ranked.first['nickname'], 'done');
    });

    test('orders finished players by WPM, highest first', () {
      final players = [
        player('b', idx: 10, wpm: 60),
        player('a', idx: 10, wpm: 80),
        player('c', idx: 10, wpm: 70),
      ];

      final names =
          rankPlayers(players, wordCount).map((p) => p['nickname']).toList();

      expect(names, ['a', 'c', 'b']);
    });

    test('puts eliminated players last, even with high WPM', () {
      final players = [
        player('out', idx: 9, wpm: 120, eliminated: true),
        player('in', idx: 3, wpm: 20),
      ];

      final ranked = rankPlayers(players, wordCount);

      expect(ranked.last['nickname'], 'out');
    });

    test('does not rank spectators', () {
      final players = [player('a', idx: 10, wpm: 50), player('watcher', spectator: true)];

      expect(rankPlayers(players, wordCount).length, 1);
    });
  });

  group('elapsedSeconds', () {
    test('is 0 before the race starts', () {
      expect(elapsedSeconds('Game Starting', '3', 60), 0);
    });

    test('is the time limit minus the time remaining', () {
      expect(elapsedSeconds('Time Remaining', '1:30', 120), 30);
    });

    test('is the full limit when no time is left', () {
      expect(elapsedSeconds('Time Remaining', '0:00', 60), 60);
    });

    test('never goes below 0', () {
      expect(elapsedSeconds('Time Remaining', '2:00', 60), 0);
    });

    test('is 0 for a malformed countdown', () {
      expect(elapsedSeconds('Time Remaining', 'abc', 60), 0);
    });
  });
}
