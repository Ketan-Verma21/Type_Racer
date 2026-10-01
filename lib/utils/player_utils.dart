import 'package:type_racer/utils/socket_client.dart';

/// Returns the player entry that belongs to this device, or null if it
/// isn't found (e.g. after a reconnect the socket id changes, or the game
/// state was reset). Always null-check the result.
dynamic findMe(List players) {
  final id = SocketClient.instance.socket?.id;
  for (final p in players) {
    if (p['socketID'] == id) return p;
  }
  return null;
}

/// Players that are actually racing (spectators excluded).
List racersOf(List players) =>
    players.where((p) => p['isSpectator'] != true).toList();

num wpmOf(dynamic p) => num.tryParse(p['WPM'].toString()) ?? -1;

/// Final ranking: players still in the race first, finished before
/// unfinished, then higher WPM first.
List rankPlayers(List players, int wordCount) {
  final r = racersOf(players);
  bool finished(p) => (p['currentWordIndex'] as int) >= wordCount;
  r.sort((a, b) {
    final ae = a['isEliminated'] == true, be = b['isEliminated'] == true;
    if (ae != be) return ae ? 1 : -1;
    final af = finished(a), bf = finished(b);
    if (af != bf) return af ? -1 : 1;
    return wpmOf(b).compareTo(wpmOf(a));
  });
  return r;
}

/// Seconds since the race started, from the server's "m:ss" remaining-time
/// string. Returns 0 while the race hasn't started.
int elapsedSeconds(String msg, String countDown, int timeLimit) {
  if (msg != 'Time Remaining') return 0;
  final parts = countDown.split(':');
  if (parts.length != 2) return 0;
  final remaining =
      (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  return (timeLimit - remaining).clamp(0, timeLimit).toInt();
}
