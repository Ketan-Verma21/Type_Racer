import 'package:type_racer/data/models/chat.dart';
import 'package:type_racer/data/models/game.dart';
import 'package:type_racer/data/models/game_settings.dart';
import 'package:type_racer/data/models/leaderboard.dart';
import 'package:type_racer/data/models/timer_state.dart';

/// Everything the app can ask the server, and everything the server tells it.
/// State classes depend on this interface only: the app uses
/// [SocketGameRepository], tests use a fake.
abstract class GameRepository {
  // ── from the server ──
  /// Every `updateGame` of the room we're in.
  Stream<Game> get games;
  Stream<TimerState> get timers;

  /// Create / join refused ("Game is full", "Please enter a valid game id").
  Stream<String> get joinErrors;

  /// Any other refused request, shown in the game (e.g. a guest changing settings).
  Stream<String> get errors;
  Stream<ChatMessage> get chatMessages;
  Stream<List<ChatMessage>> get chatHistory;
  Stream<Reaction> get reactions;
  Stream<Leaderboard> get leaderboards;

  /// This device's player id in the current game (from `joined`).
  /// Unlike the socket id it survives a reconnect. null outside a game.
  String? get myPlayerId;

  /// The current socket id, used to find "me" in the moment between the
  /// first `updateGame` and `joined`.
  String? get socketId;

  // ── to the server ──
  void createGame(String nickname);
  void joinGame(String gameId, String nickname);
  void startRace(String gameId, String playerId);
  void typeWord(String gameId, String word);
  void updateSettings(String gameId, GameSettings settings);
  void rematch(String gameId);
  void sendChat(String gameId, String text);
  void sendReaction(String gameId, String emoji);
  void requestChatHistory(String gameId);
  void requestLeaderboard(String mode);

  /// Leave for good. Events of the old room are ignored from now on.
  void leaveGame(String gameId);
}
