import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/providers/game_state_provider.dart';
import 'package:type_racer/utils/socket_methods.dart';
import 'package:type_racer/widgets/game_text_field.dart';
import 'package:type_racer/widgets/sentence_game.dart';

import '../providers/client_state_provider.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final SocketMethods _socketMethods = SocketMethods();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _socketMethods.updateTimer(context);
    _socketMethods.updateGame(context);
    _socketMethods.gameFinishedListener();
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameStateProvider>(context);
    final clientStateProvider = Provider.of<ClientStateProvider>(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Chip(
                label: Text(
                  clientStateProvider.clientState['timer']['msg'].toString(),
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                clientStateProvider.clientState['timer']['countDown']
                    .toString(),
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              game.gameState['isJoin']
                  ? ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: TextField(
                        readOnly: true,
                        onTap: () {
                          Clipboard.setData(
                                  ClipboardData(text: game.gameState['id']))
                              .then((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                elevation: 0,
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.transparent,
                                content: AwesomeSnackbarContent(
                                  title: 'Bonza!!',
                                  message: "Game Code copied to clipboard.",
                                  contentType: ContentType.success,
                                ),
                              ),
                            );
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Colors.transparent)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  const BorderSide(color: Colors.transparent)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          fillColor: const Color(0xffF5F5FA),
                          hintText: "Click to copy Game code",
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    )
                  : Container(),
              SizedBox(
                height: 20,
              ),
              SentenceGame(),
              SizedBox(height: 60,),
              Expanded(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 600,
                    ),
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: game.gameState['players'].length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Chip(
                                    label: Text(
                                      game.gameState['players'][index]['nickname'],
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                  Slider(
                                      value: (game.gameState['players'][index]['currentWordIndex']/game.gameState['words'].length)
                                      , onChanged:(val){} )
                                ]),
                          );
                        })),
              ),

            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
          margin: const EdgeInsets.only(bottom: 10), child: GameTextField()),
    );
  }
}
