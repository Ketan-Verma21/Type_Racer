import 'package:flutter/cupertino.dart';
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
      // print(nickname);
    }
  }

  JoinGame(String gameId, String nickname) {
    if (nickname.isNotEmpty && gameId.isNotEmpty) {
      _socketClient.emit('join-game', {'nickname': nickname, 'gameId': gameId});
      // print(nickname);
    }
  }

  updateGameListener(BuildContext context) {
    _socketClient.on('updateGame', (data) {
      final gameStateProvider =
          Provider.of<GameStateProvider>(context, listen: false)
              .updateGameState(
                  id: data['_id'],
                  players: data['players'],
                  isJoin: data['isJoin'],
                  isOver: data['isOver'],
                  words: data['words']);
      if (data['_id'].isNotEmpty && !is_playing) {
        Navigator.pushNamed(context, '/game-screen');
        is_playing = true;
      }
    });
  }
  sendUserInput(String value , String gameId){
    _socketClient.emit('userInput',{
      'userInput': value ,
      'gameId': gameId
    });
  }
  startTimer(playerId,gameId){
    _socketClient.emit("timer",{
      'playerId': playerId,
      'gameId': gameId,
    });
  }
  notCorrectGameListener(BuildContext context) {


    _socketClient.on(
      'notCorrectGame',
      (data) => ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Oh Snap',
            message: data,
            contentType: data=="Please enter a valid game id"? ContentType.failure: ContentType.warning,
          ),
        ),

      ),
    );
  }
  updateTimer(BuildContext context){
    final clientStateProvider = Provider.of<ClientStateProvider>(context,listen: false);
        _socketClient.on('timer',(data){
          clientStateProvider.setClientState(data);
    });
  }
  updateGame(BuildContext context){
    _socketClient.on('updateGame', (data) {
      final gameStateProvider =
      Provider.of<GameStateProvider>(context, listen: false)
          .updateGameState(
          id: data['_id'],
          players: data['players'],
          isJoin: data['isJoin'],
          isOver: data['isOver'],
          words: data['words']);

  });}
  gameFinishedListener(){
    _socketClient.on('done',(data)=>_socketClient.off('timer'));
  }
}
