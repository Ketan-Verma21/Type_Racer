import 'package:type_racer/data/models/player.dart';

/// Final ranking, same rules as the server (src/domain/rules.ts):
/// players still in the race first, finished before unfinished,
/// then higher WPM first. Spectators are left out.
List<Player> rankPlayers(List<Player> players, int wordCount) {
  final ranked = players.where((p) => !p.isSpectator).toList();
  ranked.sort((a, b) {
    if (a.isEliminated != b.isEliminated) return a.isEliminated ? 1 : -1;
    final af = a.finished(wordCount), bf = b.finished(wordCount);
    if (af != bf) return af ? -1 : 1;
    return b.wpm.compareTo(a.wpm);
  });
  return ranked;
}
