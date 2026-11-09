import 'package:type_racer/data/models/json.dart';

/// The room's settings, chosen by the host in the lobby.
class GameSettings {
  final String mode; // classic | no-mistakes | sudden-death
  final int timeLimit; // seconds
  final String length; // short | medium | long
  final int maxPlayers;

  const GameSettings({
    this.mode = 'classic',
    this.timeLimit = 120,
    this.length = 'medium',
    this.maxPlayers = 5,
  });

  static const defaults = GameSettings();

  /// Missing fields keep their default.
  factory GameSettings.fromJson(Object? json) {
    final j = readMap(json);
    return GameSettings(
      mode: readString(j['mode'], defaults.mode),
      timeLimit: readInt(j['timeLimit'], defaults.timeLimit),
      length: readString(j['length'], defaults.length),
      maxPlayers: readInt(j['maxPlayers'], defaults.maxPlayers),
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode,
        'timeLimit': timeLimit,
        'length': length,
        'maxPlayers': maxPlayers,
      };

  GameSettings copyWith({String? mode, int? timeLimit, String? length, int? maxPlayers}) =>
      GameSettings(
        mode: mode ?? this.mode,
        timeLimit: timeLimit ?? this.timeLimit,
        length: length ?? this.length,
        maxPlayers: maxPlayers ?? this.maxPlayers,
      );

  @override
  bool operator ==(Object other) =>
      other is GameSettings &&
      other.mode == mode &&
      other.timeLimit == timeLimit &&
      other.length == length &&
      other.maxPlayers == maxPlayers;

  @override
  int get hashCode => Object.hash(mode, timeLimit, length, maxPlayers);
}
