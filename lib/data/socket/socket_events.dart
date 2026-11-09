// Socket event names in one place. Must match the server's
// src/transport/socket/events.ts (Architecture.md §9).

/// Sent by the app.
abstract final class ClientEvents {
  static const createGame = 'create-game';
  static const joinGame = 'join-game';
  static const updateSettings = 'update-settings';
  static const startTimer = 'timer';
  static const userInput = 'userInput';
  static const rematch = 'rematch';
  static const chatMessage = 'chat-message';
  static const chatSync = 'chat-sync';
  static const reaction = 'reaction';
  static const leaveGame = 'leave-game';
  static const rejoinGame = 'rejoin-game';
  static const getLeaderboard = 'get-leaderboard';
}

/// Sent by the server.
abstract final class ServerEvents {
  static const connect = 'connect';
  static const updateGame = 'updateGame';
  static const timer = 'timer';
  static const notCorrectGame = 'notCorrectGame';
  static const errorMessage = 'error-message';
  static const joined = 'joined';
  static const chatMessage = 'chat-message';
  static const chatHistory = 'chat-history';
  static const reaction = 'reaction';
  static const leaderboard = 'leaderboard';
}
