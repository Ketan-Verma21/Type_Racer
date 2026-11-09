import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:type_racer/data/models/chat.dart';
import 'package:type_racer/data/models/game.dart';
import 'package:type_racer/data/models/game_settings.dart';
import 'package:type_racer/data/models/json.dart';
import 'package:type_racer/data/models/leaderboard.dart';
import 'package:type_racer/data/models/timer_state.dart';
import 'package:type_racer/data/repositories/game_repository.dart';
import 'package:type_racer/data/socket/socket_client.dart';
import 'package:type_racer/data/socket/socket_events.dart';

/// [GameRepository] over the shared Socket.IO connection.
///
/// Listeners are registered once, for the app's lifetime. Room events
/// (game, timer, chat, reactions, errors) are passed on only while we are in
/// a room: from create / join until leave. So a late `updateGame` from a room
/// we just left can't pull us back into it.
class SocketGameRepository implements GameRepository {
  SocketGameRepository([SocketClient? client]) : _client = client ?? SocketClient.instance {
    final s = _socket;
    s.on(ServerEvents.updateGame, (d) => _room(_games, Game.fromJson(d)));
    s.on(ServerEvents.timer, (d) => _room(_timers, TimerState.fromJson(d)));
    s.on(ServerEvents.errorMessage, (d) {
      final message = readString(readMap(d)['message']);
      if (message.isNotEmpty) _room(_errors, message);
    });
    s.on(ServerEvents.chatMessage, (d) => _room(_chat, ChatMessage.fromJson(d)));
    s.on(ServerEvents.chatHistory,
        (d) => _room(_history, readList(d).map(ChatMessage.fromJson).toList()));
    s.on(ServerEvents.reaction, (d) => _room(_reactions, Reaction.fromJson(d)));
    s.on(ServerEvents.notCorrectGame, (d) => _joinErrors.add(readString(d)));
    s.on(ServerEvents.leaderboard, (d) => _leaderboards.add(Leaderboard.fromJson(d)));
    s.on(ServerEvents.joined, (d) {
      final j = readMap(d);
      if (!_inRoom || j['playerId'] == null) return;
      _gameId = readString(j['gameId']);
      _playerId = readString(j['playerId']);
    });
    // The connection dropped and came back with a new socket id: tell the
    // server who we are so it reattaches us to our player.
    s.on(ServerEvents.connect, (_) {
      if (_inRoom && _gameId != null && _playerId != null) {
        s.emit(ClientEvents.rejoinGame, {'gameId': _gameId, 'playerId': _playerId});
      }
    });
  }

  final SocketClient _client;
  io.Socket get _socket => _client.socket;

  final _games = StreamController<Game>.broadcast();
  final _timers = StreamController<TimerState>.broadcast();
  final _joinErrors = StreamController<String>.broadcast();
  final _errors = StreamController<String>.broadcast();
  final _chat = StreamController<ChatMessage>.broadcast();
  final _history = StreamController<List<ChatMessage>>.broadcast();
  final _reactions = StreamController<Reaction>.broadcast();
  final _leaderboards = StreamController<Leaderboard>.broadcast();

  bool _inRoom = false;
  String? _gameId;
  String? _playerId;

  void _room<T>(StreamController<T> c, T value) {
    if (_inRoom) c.add(value);
  }

  /// Run [action] once the socket is connected (right away if it already is),
  /// so the first Create / Join isn't lost while a sleeping server wakes up.
  void _whenConnected(void Function() action) {
    if (_socket.connected) {
      action();
      return;
    }
    _socket.once(ServerEvents.connect, (_) => action());
    _client.ensureConnected();
  }

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

  @override
  String? get myPlayerId => _inRoom ? _playerId : null;
  @override
  String? get socketId => _socket.id;

  @override
  void createGame(String nickname) {
    _enterRoom();
    _whenConnected(() => _socket.emit(ClientEvents.createGame, {'nickname': nickname}));
  }

  @override
  void joinGame(String gameId, String nickname) {
    _enterRoom();
    _whenConnected(
        () => _socket.emit(ClientEvents.joinGame, {'nickname': nickname, 'gameId': gameId}));
  }

  void _enterRoom() {
    _inRoom = true;
    _gameId = null;
    _playerId = null;
  }

  @override
  void startRace(String gameId, String playerId) =>
      _socket.emit(ClientEvents.startTimer, {'playerId': playerId, 'gameId': gameId});

  @override
  void typeWord(String gameId, String word) =>
      _socket.emit(ClientEvents.userInput, {'userInput': word, 'gameId': gameId});

  @override
  void updateSettings(String gameId, GameSettings settings) => _socket
      .emit(ClientEvents.updateSettings, {'gameId': gameId, 'settings': settings.toJson()});

  @override
  void rematch(String gameId) => _socket.emit(ClientEvents.rematch, {'gameId': gameId});

  @override
  void sendChat(String gameId, String text) =>
      _socket.emit(ClientEvents.chatMessage, {'gameId': gameId, 'text': text});

  @override
  void sendReaction(String gameId, String emoji) =>
      _socket.emit(ClientEvents.reaction, {'gameId': gameId, 'emoji': emoji});

  @override
  void requestChatHistory(String gameId) =>
      _socket.emit(ClientEvents.chatSync, {'gameId': gameId});

  @override
  void requestLeaderboard(String mode) =>
      _whenConnected(() => _socket.emit(ClientEvents.getLeaderboard, {'mode': mode}));

  @override
  void leaveGame(String gameId) {
    _socket.emit(ClientEvents.leaveGame, {'gameId': gameId});
    _inRoom = false;
    _gameId = null;
    _playerId = null;
  }
}
