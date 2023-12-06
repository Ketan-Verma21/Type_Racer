import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/providers/game_state_provider.dart';
import 'package:type_racer/utils/socket_methods.dart';
import 'package:type_racer/widgets/scoreboard.dart';

import '../utils/socket_client.dart';
class SentenceGame extends StatefulWidget {
  const SentenceGame({Key? key}) : super(key: key);

  @override
  State<SentenceGame> createState() => _SentenceGameState();
}

class _SentenceGameState extends State<SentenceGame> {
  var playerMe=null;
  final SocketMethods _socketMethods=SocketMethods();
  void initState(){
    super.initState();
    _socketMethods.updateGame(context);
  }
  findPlayerMe(GameStateProvider game){
    game.gameState['players'].forEach((player){
      if(player['socketID']==SocketClient.instance.socket!.id){
        playerMe=player;
      }
    });
  }
  Widget getTypedWords(words,player){
    var tempWords =words.sublist(0,player['currentWordIndex']);
    String typedWord= tempWords.join(' ');
    return Text(typedWord.toString(),style: TextStyle(color: Color.fromRGBO(52, 235, 119, 1),
    fontSize: 30),);
  }
  Widget getCurrentWord(words,player){

    return Text(words[player['currentWordIndex']],style: TextStyle(decoration: TextDecoration.underline,
        fontSize: 30),);
  }
  Widget getRemainingWords(words,player){
    var tempWords =words.sublist(player['currentWordIndex']+1,words.length);
    String typedWord= tempWords.join(' ');
    return Text(typedWord,style: TextStyle(color: Colors.grey[600],
        fontSize: 30),);
  }
  @override
  Widget build(BuildContext context) {
    final game=Provider.of<GameStateProvider>(context);
    findPlayerMe(game);
    if(game.gameState['words'].length > playerMe['currentWordIndex']){
      return Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
        child:Wrap(
          textDirection: TextDirection.ltr,
          children: [
            getTypedWords(game.gameState['words'], playerMe),
            getCurrentWord(game.gameState['words'], playerMe),
            getRemainingWords(game.gameState['words'], playerMe),


          ],
        ) ,
      );
    }
    return Scoreboard();

  }
}
