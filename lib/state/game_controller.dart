import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:type_racer/data/models/game.dart';
import 'package:type_racer/data/models/game_settings.dart';
import 'package:type_racer/data/models/player.dart';
import 'package:type_racer/data/models/timer_state.dart';
import 'package:type_racer/data/repositories/game_repository.dart';
import 'package:type_racer/domain/game_modes.dart';
import 'package:type_racer/domain/race_stats.dart';

/// The room this device is in: the latest game state and race clock from the
/// server, and the actions the screens can take. Knows nothing about
/// sockets or widgets — it talks to a [GameRepository].
class GameController extends ChangeNotifier {
  GameController(this._repo) {
    _subs = [
      _repo.games.listen(_onGame),
      _repo.timers.listen(_onTimer),
    ];
  }

  final GameRepository _repo;
  late final List<StreamSubscription<Object?>> _subs;

  Game _game = Game.empty;
  TimerState _timer = TimerState.idle;

  Game get game => _game;
  TimerState get timer => _timer;

  /// Create / join refusals, for the create and join screens.
  Stream<String> get joinErrors => _repo.joinErrors;

  /// Other refused requests, for the game screen.
  Stream<String> get errors => _repo.errors;

  bool get inGame => !_game.isEmpty;

  /// This device's player: by the id from `joined`, or by socket id in the
  /// moment before `joined` arrives. null when not in a game.
  Player? get me {
    final byId = _game.playerById(_repo.myPlayerId);
    if (byId != null) return byId;
    final sid = _repo.socketId;
    if (sid == null) return null;
    for (final p in _game.players) {
      if (p.socketId == sid) return p;
    }
    return null;
  }

  GameMode get mode => GameModes.byId(_game.settings.mode);

  /// Seconds since the race started (0 before it does).
  int get elapsed => elapsedSeconds(_timer, _game.settings.timeLimit);

  /// The WPM to show for [p] right now.
  int wpmOf(Player p) => liveWpm(p, elapsed);

  void _onGame(Game g) {
    _game = g;
    notifyListeners();
  }

  void _onTimer(TimerState t) {
    _timer = t;
    notifyListeners();
  }

  // ── actions ──
  void createGame(String nickname) => _repo.createGame(nickname);
  void joinGame(String gameId, String nickname) => _repo.joinGame(gameId, nickname);

  void startRace() {
    final m = me;
    if (m != null) _repo.startRace(_game.id, m.id);
  }

  void typeWord(String word) => _repo.typeWord(_game.id, word);
  void updateSettings(GameSettings s) => _repo.updateSettings(_game.id, s);
  void rematch() => _repo.rematch(_game.id);
  void sendChat(String text) => _repo.sendChat(_game.id, text);
  void sendReaction(String emoji) => _repo.sendReaction(_game.id, emoji);
  void requestChatHistory() => _repo.requestChatHistory(_game.id);

  /// Leave the room and forget it. Safe to call twice.
  void leaveGame() {
    if (!inGame) return;
    _repo.leaveGame(_game.id);
    _game = Game.empty;
    _timer = TimerState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
