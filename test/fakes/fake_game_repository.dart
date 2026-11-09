import 'dart:async';

import 'package:type_racer/data/models/chat.dart';
import 'package:type_racer/data/models/game.dart';
import 'package:type_racer/data/models/game_settings.dart';
import 'package:type_racer/data/models/leaderboard.dart';
import 'package:type_racer/data/models/timer_state.dart';
import 'package:type_racer/data/repositories/game_repository.dart';

/// A [GameRepository] with no server: tests push server events in with the
/// `emit…` methods and read what the app sent from [sent].
class FakeGameRepository implements GameRepository {
  /// Every request the app made, as `[name, args...]`.
  final List<List<Object?>> sent = [];

  @override
  String? myPlayerId;
  @override
  String? socketId;

  final _games = StreamController<Game>.broadcast(sync: true);
  final _timers = StreamController<TimerState>.broadcast(sync: true);
  final _joinErrors = StreamController<String>.broadcast(sync: true);
  final _errors = StreamController<String>.broadcast(sync: true);
  final _chat = StreamController<ChatMessage>.broadcast(sync: true);
  final _history = StreamController<List<ChatMessage>>.broadcast(sync: true);
  final _reactions = StreamController<Reaction>.broadcast(sync: true);
  final _leaderboards = StreamController<Leaderboard>.broadcast(sync: true);

  // ── server -> app ──
  void emitGame(Game g) => _games.add(g);
  void emitTimer(TimerState t) => _timers.add(t);
  void emitJoinError(String m) => _joinErrors.add(m);
  void emitError(String m) => _errors.add(m);
  void emitChat(ChatMessage m) => _chat.add(m);
  void emitHistory(List<ChatMessage> l) => _history.add(l);
  void emitReaction(Reaction r) => _reactions.add(r);
  void emitLeaderboard(Leaderboard l) => _leaderboards.add(l);

  @override
  Stream<Game> get games => _games.stream;
  @override
  Stream<TimerState> get timers => _timers.stream;
  @override
  Stream<String> get joinErrors => _joinErrors.stream;
  @override
  Stream<String> get errors => _errors.stream;
  @override
  Stream<ChatMessage> get chatMessages => _chat.stream;
  @override
  Stream<List<ChatMessage>> get chatHistory => _history.stream;
  @override
  Stream<Reaction> get reactions => _reactions.stream;
  @override
  Stream<Leaderboard> get leaderboards => _leaderboards.stream;

  // ── app -> server ──
  @override
  void createGame(String nickname) => sent.add(['createGame', nickname]);
  @override
  void joinGame(String gameId, String nickname) => sent.add(['joinGame', gameId, nickname]);
  @override
  void startRace(String gameId, String playerId) => sent.add(['startRace', gameId, playerId]);
  @override
  void typeWord(String gameId, String word) => sent.add(['typeWord', gameId, word]);
  @override
  void updateSettings(String gameId, GameSettings s) => sent.add(['updateSettings', gameId, s]);
  @override
  void rematch(String gameId) => sent.add(['rematch', gameId]);
  @override
  void sendChat(String gameId, String text) => sent.add(['sendChat', gameId, text]);
  @override
  void sendReaction(String gameId, String emoji) => sent.add(['sendReaction', gameId, emoji]);
  @override
  void requestChatHistory(String gameId) => sent.add(['requestChatHistory', gameId]);
  @override
  void requestLeaderboard(String mode) => sent.add(['requestLeaderboard', mode]);
  @override
  void leaveGame(String gameId) => sent.add(['leaveGame', gameId]);
}
