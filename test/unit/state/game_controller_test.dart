import 'package:flutter_test/flutter_test.dart';
import 'package:type_racer/data/models/game.dart';
import 'package:type_racer/data/models/game_settings.dart';
import 'package:type_racer/data/models/timer_state.dart';
import 'package:type_racer/state/game_controller.dart';

import '../../fakes/builders.dart';
import '../../fakes/fake_game_repository.dart';

void main() {
  late FakeGameRepository repo;
  late GameController game;

  setUp(() {
    repo = FakeGameRepository()..myPlayerId = 'me';
    game = GameController(repo);
  });
  tearDown(() => game.dispose());

  test('starts with no game', () {
    expect(game.inGame, isFalse);
    expect(game.me, isNull);
    expect(game.timer, TimerState.idle);
  });

  test('keeps the latest game and timer from the server, and notifies', () {
    var notified = 0;
    game.addListener(() => notified++);

    repo.emitGame(room());
    repo.emitTimer(const TimerState(countDown: '3', msg: 'Game Starting'));

    expect(game.inGame, isTrue);
    expect(game.game.id, 'K7P2QX');
    expect(game.timer.secondsLeft, 3);
    expect(notified, 2);
  });

  group('me', () {
    test('is found by the player id from `joined`', () {
      repo.emitGame(room());
      expect(game.me?.id, 'me');
    });

    test('falls back to the socket id before `joined` arrives', () {
      repo
        ..myPlayerId = null
        ..socketId = 'socket-rival';
      repo.emitGame(room());

      expect(game.me?.id, 'rival');
    });

    test('is still me after a reconnect changed my socket id', () {
      repo.socketId = 'new-socket';
      repo.emitGame(room(players: [player('me', socket: 'old-socket'), player('rival')]));

      expect(game.me?.id, 'me');
    });

    test('is null when this device is not in the room', () {
      repo
        ..myPlayerId = 'ghost'
        ..socketId = 'nope';
      repo.emitGame(room());

      expect(game.me, isNull);
    });
  });

  test('live WPM comes from the race clock', () {
    repo.emitGame(room(
      isJoin: false,
      settings: const GameSettings(timeLimit: 60),
      players: [player('me', idx: 15)],
    ));
    repo.emitTimer(const TimerState(countDown: '0:30', msg: 'Time Remaining'));

    expect(game.elapsed, 30);
    expect(game.wpmOf(game.me!), 30);
  });

  test('mode follows the settings', () {
    repo.emitGame(room(settings: const GameSettings(mode: 'sudden-death')));
    expect(game.mode.name, 'Sudden Death');
  });

  group('actions', () {
    setUp(() => repo.emitGame(room()));

    test('are sent for the current room', () {
      game
        ..typeWord('the ')
        ..updateSettings(const GameSettings(timeLimit: 30))
        ..rematch()
        ..sendChat('gl')
        ..sendReaction('🔥')
        ..requestChatHistory()
        ..startRace();

      expect(repo.sent, [
        ['typeWord', 'K7P2QX', 'the '],
        ['updateSettings', 'K7P2QX', const GameSettings(timeLimit: 30)],
        ['rematch', 'K7P2QX'],
        ['sendChat', 'K7P2QX', 'gl'],
        ['sendReaction', 'K7P2QX', '🔥'],
        ['requestChatHistory', 'K7P2QX'],
        ['startRace', 'K7P2QX', 'me'],
      ]);
    });

    test('create and join go straight to the server', () {
      game
        ..createGame('Ketan')
        ..joinGame('ABCDEF', 'Ketan');

      expect(repo.sent.sublist(repo.sent.length - 2), [
        ['createGame', 'Ketan'],
        ['joinGame', 'ABCDEF', 'Ketan'],
      ]);
    });

    test('leave tells the server once and forgets the room', () {
      repo.emitTimer(const TimerState(countDown: '1:00', msg: 'Time Remaining'));

      game
        ..leaveGame()
        ..leaveGame(); // second call does nothing

      expect(repo.sent, [
        ['leaveGame', 'K7P2QX'],
      ]);
      expect(game.game, same(Game.empty));
      expect(game.timer, TimerState.idle);
    });
  });

  test('startRace does nothing when I am not in the room', () {
    repo.myPlayerId = 'ghost';
    repo.emitGame(room());

    game.startRace();

    expect(repo.sent, isEmpty);
  });

  test('passes refusals through for the screens', () async {
    final joinErrors = <String>[], errors = <String>[];
    game.joinErrors.listen(joinErrors.add);
    game.errors.listen(errors.add);

    repo
      ..emitJoinError('Game is full')
      ..emitError('Only the host can change settings');

    expect(joinErrors, ['Game is full']);
    expect(errors, ['Only the host can change settings']);
  });

  test('stops listening when disposed', () {
    final g2 = GameController(repo)..dispose();
    repo.emitGame(room());

    expect(g2.inGame, isFalse);
  });
}
