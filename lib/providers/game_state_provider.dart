import 'package:flutter/cupertino.dart';
import 'package:type_racer/models/game_state.dart';

class GameStateProvider extends ChangeNotifier {
  GameState _gameState = GameState(
      id: '', players: [], isJoin: true, isOver: false, words: []);

  Map<String, dynamic> get gameState => _gameState.toJson();

  void updateGameState({
    required id,
    required players,
    required isJoin,
    required isOver,
    required words,
    settings, // optional: server game settings (mode, timeLimit, ...)
  }) {
    _gameState = GameState(
      id: id,
      players: players,
      isJoin: isJoin,
      isOver: isOver,
      words: words,
      settings: settings,
    );
    notifyListeners();
  }
}
