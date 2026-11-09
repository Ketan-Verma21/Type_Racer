// The models must read exactly what the server sends (server/src/transport/socket/gameDto.ts).
import 'package:flutter_test/flutter_test.dart';
import 'package:type_racer/data/models/game.dart';
import 'package:type_racer/data/models/game_settings.dart';
import 'package:type_racer/data/models/player.dart';

/// An `updateGame` payload as the server builds it.
Map<String, dynamic> gameJson({List<Map<String, dynamic>>? players, Object? settings}) => {
      '_id': 'K7P2QX',
      'words': ['the', 'quick', 'fox'],
      'players': players ??
          [
            {
              '_id': 'p1',
              'nickname': 'Ketan',
              'socketID': 's1',
              'isPartyLeader': true,
              'currentWordIndex': 2,
              'WPM': -1,
              'isSpectator': false,
              'isEliminated': false,
              'mistakes': 1,
            },
            {
              '_id': 'p2',
              'nickname': 'Verma',
              'socketID': 's2',
              'isPartyLeader': false,
              'currentWordIndex': 3,
              'WPM': 71.5,
              'isSpectator': true,
              'isEliminated': false,
              'mistakes': 0,
            },
          ],
      'isJoin': false,
      'isOver': false,
      'startTime': 1794143691000,
      'settings': settings ?? {'mode': 'sudden-death', 'timeLimit': 60, 'length': 'long', 'maxPlayers': 8},
    };

void main() {
  group('Game.fromJson', () {
    test('reads every field of the server payload', () {
      final g = Game.fromJson(gameJson());

      expect(g.id, 'K7P2QX');
      expect(g.words, ['the', 'quick', 'fox']);
      expect(g.isJoin, isFalse);
      expect(g.isOver, isFalse);
      expect(g.startTime, 1794143691000);
      expect(g.settings,
          const GameSettings(mode: 'sudden-death', timeLimit: 60, length: 'long', maxPlayers: 8));
      expect(g.players, hasLength(2));
    });

    test('maps the v1 player names to clear Dart names', () {
      final p = Game.fromJson(gameJson()).players.first;

      expect(p.id, 'p1');
      expect(p.nickname, 'Ketan');
      expect(p.socketId, 's1');
      expect(p.isHost, isTrue);
      expect(p.wordIndex, 2);
      expect(p.wpm, -1);
      expect(p.hasFinalWpm, isFalse);
      expect(p.mistakes, 1);
    });

    test('survives a payload with missing or oddly typed fields', () {
      final g = Game.fromJson({
        '_id': 'ABCDEF',
        'players': [
          {'_id': 'p1', 'WPM': '57', 'currentWordIndex': '4'},
        ],
      });

      expect(g.words, isEmpty);
      expect(g.isJoin, isTrue); // missing -> still joinable
      expect(g.startTime, isNull);
      expect(g.settings, GameSettings.defaults);
      expect(g.players.single.wpm, 57);
      expect(g.players.single.wordIndex, 4);
      expect(g.players.single.nickname, '');
    });

    test('is empty for null', () {
      expect(Game.fromJson(null).isEmpty, isTrue);
    });
  });

  group('Game helpers', () {
    final g = Game.fromJson(gameJson());

    test('racers leaves out spectators', () {
      expect(g.racers.map((p) => p.id), ['p1']);
    });

    test('finds a player by id, and the host', () {
      expect(g.playerById('p2')?.nickname, 'Verma');
      expect(g.playerById('nope'), isNull);
      expect(g.playerById(null), isNull);
      expect(g.host?.id, 'p1');
    });

    test('isRacing only between the start and the end', () {
      expect(g.isRacing, isTrue);
      expect(Game.fromJson({...gameJson(), 'isJoin': true}).isRacing, isFalse);
      expect(Game.fromJson({...gameJson(), 'isOver': true}).isRacing, isFalse);
    });

    test('Game.empty has no players', () {
      expect(Game.empty.isEmpty, isTrue);
      expect(Game.empty.players, isEmpty);
      expect(Game.empty.host, isNull);
    });
  });

  group('Player', () {
    test('finished and progress depend on the quote length', () {
      const p = Player(id: 'a', nickname: 'a', wordIndex: 3);

      expect(p.finished(3), isTrue);
      expect(p.finished(4), isFalse);
      expect(p.finished(0), isFalse);
      expect(p.progress(4), 0.75);
      expect(p.progress(0), 0);
      expect(const Player(id: 'a', nickname: 'a', wordIndex: 9).progress(3), 1.0);
    });
  });

  group('GameSettings', () {
    test('keeps defaults for missing fields and round-trips through JSON', () {
      final s = GameSettings.fromJson({'mode': 'no-mistakes'});

      expect(s, const GameSettings(mode: 'no-mistakes'));
      expect(GameSettings.fromJson(s.toJson()), s);
    });

    test('copyWith changes one field', () {
      expect(GameSettings.defaults.copyWith(timeLimit: 30).timeLimit, 30);
      expect(GameSettings.defaults.copyWith(timeLimit: 30).mode, 'classic');
    });

    test('equal settings have the same hash', () {
      expect(const GameSettings().hashCode, GameSettings.fromJson({}).hashCode);
    });
  });
}
