import 'package:type_racer/data/models/game.dart';
import 'package:type_racer/data/models/game_settings.dart';
import 'package:type_racer/data/models/player.dart';

const kWords = ['the', 'quick', 'brown', 'fox'];

Player player(
  String id, {
  bool host = false,
  int idx = 0,
  double wpm = -1,
  bool spectator = false,
  bool out = false,
  String? socket,
}) =>
    Player(
      id: id,
      nickname: id,
      socketId: socket ?? 'socket-$id',
      isHost: host,
      wordIndex: idx,
      wpm: wpm,
      isSpectator: spectator,
      isEliminated: out,
    );

/// A room with me ("me", host) and one rival, in the lobby by default.
Game room({
  List<Player>? players,
  bool isJoin = true,
  bool isOver = false,
  GameSettings settings = GameSettings.defaults,
}) =>
    Game(
      id: 'K7P2QX',
      words: kWords,
      players: players ?? [player('me', host: true), player('rival')],
      isJoin: isJoin,
      isOver: isOver,
      settings: settings,
    );
