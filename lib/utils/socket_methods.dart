import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/providers/chat_provider.dart';
import 'package:type_racer/providers/game_state_provider.dart';
import 'package:type_racer/utils/socket_client.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

import '../providers/client_state_provider.dart';

class SocketMethods {
  final _socketClient = SocketClient.instance.socket!;
  bool is_playing = false;

  // Run `action` as soon as the socket is connected (right away if it is
  // already). Covers the case where the server just woke up and the socket
  // is still reconnecting, so the first Create/Join isn't lost.
  void _whenConnected(void Function() action) {
    if (_socketClient.connected) {
      action();
      return;
    }
    _socketClient.once('connect', (_) => action());
    SocketClient.instance.ensureConnected();
  }

  // ───────────── emits ─────────────
  CreateGame(String nickname) {
    if (nickname.isNotEmpty) {
      _whenConnected(
              () => _socketClient.emit('create-game', {'nickname': nickname}));
    }
  }

  JoinGame(String gameId, String nickname) {
    if (nickname.isNotEmpty && gameId.isNotEmpty) {
      _whenConnected(() => _socketClient
          .emit('join-game', {'nickname': nickname, 'gameId': gameId}));
    }
  }

  sendUserInput(String value, String gameId) {
    _socketClient.emit('userInput', {'userInput': value, 'gameId': gameId});
  }

  startTimer(playerId, gameId) {
    _socketClient.emit("timer", {'playerId': playerId, 'gameId': gameId});
  }

  /// Host only, lobby only. `settings` = {mode, timeLimit, length, maxPlayers}
  updateSettings(String gameId, Map<String, dynamic> settings) {
    _socketClient
        .emit('update-settings', {'gameId': gameId, 'settings': settings});
  }

  /// Host only, after the race is over.
  rematch(String gameId) {
    _socketClient.emit('rematch', {'gameId': gameId});
  }

  sendChat(String gameId, String text) {
    _socketClient.emit('chat-message', {'gameId': gameId, 'text': text});
  }

  sendReaction(String gameId, String emoji) {
    _socketClient.emit('reaction', {'gameId': gameId, 'emoji': emoji});
  }

  requestChatHistory(String gameId) {
    _socketClient.emit('chat-sync', {'gameId': gameId});
  }

  emitLeave(String gameId) {
    _socketClient.emit('leave-game', {'gameId': gameId});
  }

  // ───────────── listeners ─────────────
  // Rule: capture provider/navigator/messenger when registering and never
  // touch `context` inside a callback (the screen may be gone by then).
  // Always off() before on() so listeners never stack up.

  // Create/Join screens: updates state AND navigates to the game.
  // `onEnterGame` runs right before navigating (e.g. to stop a spinner).
  updateGameListener(BuildContext context, {VoidCallback? onEnterGame}) {
    final gameProvider = Provider.of<GameStateProvider>(context, listen: false);
    final navigator = Navigator.of(context);

    _socketClient.off('updateGame');
    _socketClient.on('updateGame', (data) {
      gameProvider.updateGameState(
        id: data['_id'],
        players: data['players'],
        isJoin: data['isJoin'],
        isOver: data['isOver'],
        words: data['words'],
        settings: data['settings'],
      );
      if (data['_id'].isNotEmpty && !is_playing) {
        onEnterGame?.call();
        navigator.pushNamed('/game-screen');
        is_playing = true;
      }
    });
  }

  // `onError` runs before the snackbar is shown (e.g. to stop a spinner).
  notCorrectGameListener(BuildContext context, {VoidCallback? onError}) {
    // findAncestorState... is safe inside initState; ScaffoldMessenger.of is not
    final messenger = context.findAncestorStateOfType<ScaffoldMessengerState>();

    _socketClient.off('notCorrectGame');
    _socketClient.on('notCorrectGame', (data) {
      onError?.call();
      messenger?.showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Oh Snap',
            message: data,
            contentType: data == "Please enter a valid game id"
                ? ContentType.failure
                : ContentType.warning,
          ),
        ),
      );
    });
  }

  /// `error-message` {code, message}: shown in a snackbar on the game screen
  /// (e.g. a guest tapping a host-only setting). Create/join use notCorrectGame.
  errorMessageListener(BuildContext context) {
    final messenger = context.findAncestorStateOfType<ScaffoldMessengerState>();
    _socketClient.off('error-message');
    _socketClient.on('error-message', (data) {
      final message = data is Map ? data['message']?.toString() : null;
      if (message == null || message.isEmpty) return;
      messenger?.showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Hmm',
            message: message,
            contentType: ContentType.warning,
          ),
        ),
      );
    });
  }

  stopErrorMessages() {
    _socketClient.off('error-message');
  }

  updateTimer(BuildContext context) {
    final clientStateProvider =
    Provider.of<ClientStateProvider>(context, listen: false);
    _socketClient.off('timer');
    _socketClient.on('timer', (data) {
      clientStateProvider.setClientState(data);
    });
  }

  // Game screen: state update only (no navigation).
  updateGame(BuildContext context) {
    final gameProvider = Provider.of<GameStateProvider>(context, listen: false);
    _socketClient.off('updateGame'); // replaces the Create/Join listener
    _socketClient.on('updateGame', (data) {
      gameProvider.updateGameState(
        id: data['_id'],
        players: data['players'],
        isJoin: data['isJoin'],
        isOver: data['isOver'],
        words: data['words'],
        settings: data['settings'],
      );
    });
  }

  chatListener(BuildContext context) {
    final chat = Provider.of<ChatProvider>(context, listen: false);

    _socketClient.off('chat-message');
    _socketClient.on('chat-message', (data) {
      chat.add(ChatMessage.fromJson(data));
    });

    _socketClient.off('chat-history');
    _socketClient.on('chat-history', (data) {
      chat.setHistory(List.from(data).map((d) => ChatMessage.fromJson(d)).toList());
    });

    _socketClient.off('reaction');
    _socketClient.on('reaction', (data) {
      chat.addReaction(ReactionEvent.fromJson(data));
    });
  }

  // When the connection drops and comes back, the socket gets a new id.
  // Tell the server who we are so it reattaches us to our player.
  dynamic Function(dynamic)? _connectHandler;
  rejoinOnReconnect(String gameId, String playerId) {
    if (_connectHandler != null) _socketClient.off('connect', _connectHandler);
    _connectHandler = (_) {
      _socketClient
          .emit('rejoin-game', {'gameId': gameId, 'playerId': playerId});
    };
    _socketClient.on('connect', _connectHandler!);
  }

  // Leave for good: tell the server and stop listening to this game's events.
  leaveGame(String gameId) {
    emitLeave(gameId);
    if (_connectHandler != null) {
      _socketClient.off('connect', _connectHandler);
      _connectHandler = null;
    }
    _socketClient.off('timer');
    _socketClient.off('updateGame');
    _socketClient.off('done');
    _socketClient.off('chat-message');
    _socketClient.off('chat-history');
    _socketClient.off('reaction');
    _socketClient.off('error-message');
    is_playing = false;
  }

  // 'done' is sent to a player when they finish. (We no longer stop listening
  // to 'timer' here: a rematch needs it again.)
  gameFinishedListener() {
    _socketClient.off('done');
    _socketClient.on('done', (data) {});
  }
}
