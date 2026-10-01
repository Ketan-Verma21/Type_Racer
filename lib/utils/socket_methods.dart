import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/providers/game_state_provider.dart';
import 'package:type_racer/utils/socket_client.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';

import '../providers/client_state_provider.dart';

class SocketMethods {
  final _socketClient = SocketClient.instance.socket!;
  bool is_playing = false;

  CreateGame(String nickname) {
    if (nickname.isNotEmpty) {
      _socketClient.emit('create-game', {'nickname': nickname});
    }
  }

  JoinGame(String gameId, String nickname) {
    if (nickname.isNotEmpty && gameId.isNotEmpty) {
      _socketClient.emit('join-game', {'nickname': nickname, 'gameId': gameId});
    }
  }

  // Used on Create/Join screens: updates state AND navigates to the game.
  //
  // FIX: provider + navigator are captured NOW (context is alive) and the
  // callback only uses those, never `context`. Old listeners are removed
  // first so they can't pile up or fire from disposed screens.
  updateGameListener(BuildContext context) {
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
      );
      if (data['_id'].isNotEmpty && !is_playing) {
        navigator.pushNamed('/game-screen');
        is_playing = true;
      }
    });
  }

  sendUserInput(String value, String gameId) {
    _socketClient.emit('userInput', {'userInput': value, 'gameId': gameId});
  }

  startTimer(playerId, gameId) {
    _socketClient.emit("timer", {
      'playerId': playerId,
      'gameId': gameId,
    });
  }

  notCorrectGameListener(BuildContext context) {
    // messenger belongs to MaterialApp, so it stays valid after this screen
    // is gone
    // (findAncestorState... is safe inside initState; ScaffoldMessenger.of is not)
    final messenger = context.findAncestorStateOfType<ScaffoldMessengerState>();

    _socketClient.off('notCorrectGame');
    _socketClient.on(
      'notCorrectGame',
          (data) => messenger?.showSnackBar(
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
      ),
    );
  }

  updateTimer(BuildContext context) {
    final clientStateProvider =
    Provider.of<ClientStateProvider>(context, listen: false);
    _socketClient.off('timer');
    _socketClient.on('timer', (data) {
      clientStateProvider.setClientState(data);
    });
  }

  // Used on the game screen: state update only (no navigation).
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
      );
    });
  }

  // Tell the server this player left (server must handle 'leave-game'),
  // and stop listening to this game's events.
  emitLeave(String gameId) {
    _socketClient.emit('leave-game', {'gameId': gameId});
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

  leaveGame(String gameId) {
    emitLeave(gameId);
    if (_connectHandler != null) {
      _socketClient.off('connect', _connectHandler);
      _connectHandler = null;
    }
    _socketClient.off('timer');
    _socketClient.off('updateGame');
    _socketClient.off('done');
    is_playing = false;
  }

  gameFinishedListener() {
    _socketClient.off('done');
    _socketClient.on('done', (data) => _socketClient.off('timer'));
  }
}
