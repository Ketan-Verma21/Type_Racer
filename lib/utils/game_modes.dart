class GameMode {
  final String id;
  final String name;
  final String emoji;
  final String desc;
  const GameMode(this.id, this.name, this.emoji, this.desc);
}

class GameModes {
  static const classic = GameMode('classic', 'Classic', '🏁',
      'Wrong words are ignored. Fastest typist wins.');
  static const flawless = GameMode('no-mistakes', 'Flawless', '🎯',
      'A wrong word sends you back to the start!');
  static const suddenDeath = GameMode('sudden-death', 'Sudden Death', '💀',
      "One wrong word and you're out. First to finish, or last one standing, wins.");

  static const List<GameMode> all = [classic, flawless, suddenDeath];

  static GameMode byId(String? id) =>
      all.firstWhere((m) => m.id == id, orElse: () => classic);

  static const List<int> times = [30, 60, 90, 120];
  static const Map<String, String> lengths = {
    'short': 'Short',
    'medium': 'Medium',
    'long': 'Long',
  };
}
