import 'package:type_racer/data/models/json.dart';

class LeaderboardEntry {
  final String nickname;
  final int wpm;

  const LeaderboardEntry({required this.nickname, required this.wpm});

  factory LeaderboardEntry.fromJson(Object? json) {
    final j = readMap(json);
    return LeaderboardEntry(nickname: readString(j['nickname']), wpm: readInt(j['wpm']));
  }
}

/// The server's `leaderboard` event: best WPM per player for one mode, highest first.
class Leaderboard {
  final String mode;
  final List<LeaderboardEntry> entries;

  const Leaderboard({required this.mode, this.entries = const []});

  factory Leaderboard.fromJson(Object? json) {
    final j = readMap(json);
    return Leaderboard(
      mode: readString(j['mode']),
      entries: readList(j['entries']).map(LeaderboardEntry.fromJson).toList(),
    );
  }
}
