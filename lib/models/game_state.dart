class GameState {
  static const Map<String, dynamic> defaultSettings = {
    'mode': 'classic', // classic | no-mistakes | sudden-death
    'timeLimit': 120, // seconds
    'length': 'medium', // short | medium | long
    'maxPlayers': 5,
  };

  final String id;
  final List players;
  final bool isJoin;
  final bool isOver;
  final List words;
  final Map<String, dynamic> settings;

  GameState({
    required this.id,
    required this.players,
    required this.isJoin,
    required this.isOver,
    required this.words,
    Map? settings,
  }) : settings = settings == null
      ? Map<String, dynamic>.from(defaultSettings)
      : {...defaultSettings, ...Map<String, dynamic>.from(settings)};

  Map<String, dynamic> toJson() => {
    'id': id,
    'players': players,
    'isJoin': isJoin,
    'isOver': isOver,
    'words': words,
    'settings': settings,
  };
}
