import 'package:type_racer/data/models/game_settings.dart';
import 'package:type_racer/data/models/json.dart';
import 'package:type_racer/data/models/player.dart';

/// A room, as broadcast by the server in `updateGame`.
class Game {
  final String id;
  final List<String> words;
  final List<Player> players;
  final bool isJoin; // lobby or countdown: people can still join
  final bool isOver;
  final int? startTime; // ms since epoch, once the race has started
  final GameSettings settings;

  const Game({
    required this.id,
    this.words = const [],
    this.players = const [],
    this.isJoin = true,
    this.isOver = false,
    this.startTime,
    this.settings = GameSettings.defaults,
  });

  /// No game yet (before create / join, or after leaving).
  static const empty = Game(id: '');

  factory Game.fromJson(Object? json) {
    final j = readMap(json);
    return Game(
      id: readString(j['_id']),
      words: readList(j['words']).map((w) => w.toString()).toList(),
      players: readList(j['players']).map(Player.fromJson).toList(),
      isJoin: j.containsKey('isJoin') ? readBool(j['isJoin']) : true,
      isOver: readBool(j['isOver']),
      startTime: j['startTime'] is num ? (j['startTime'] as num).toInt() : null,
      settings: GameSettings.fromJson(j['settings']),
    );
  }

  bool get isEmpty => id.isEmpty;

  /// The race is running (not in the lobby, not over).
  bool get isRacing => !isJoin && !isOver;

  /// Players that race (spectators excluded).
  List<Player> get racers => players.where((p) => !p.isSpectator).toList();

  Player? playerById(String? id) {
    if (id == null) return null;
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  Player? get host {
    for (final p in players) {
      if (p.isHost) return p;
    }
    return null;
  }
}
