import 'package:type_racer/data/models/json.dart';

/// One player in a room, as the server sends it in `updateGame`.
/// The JSON keeps the server's v1 field names (`_id`, `WPM`, `socketID`,
/// `isPartyLeader`, `currentWordIndex`); the Dart names are the clear ones.
class Player {
  final String id;
  final String nickname;
  final String socketId;
  final bool isHost;
  final int wordIndex; // words typed correctly so far
  final double wpm; // final WPM, or -1 while still racing
  final bool isSpectator;
  final bool isEliminated;
  final int mistakes;

  const Player({
    required this.id,
    required this.nickname,
    this.socketId = '',
    this.isHost = false,
    this.wordIndex = 0,
    this.wpm = -1,
    this.isSpectator = false,
    this.isEliminated = false,
    this.mistakes = 0,
  });

  factory Player.fromJson(Object? json) {
    final j = readMap(json);
    return Player(
      id: readString(j['_id']),
      nickname: readString(j['nickname']),
      socketId: readString(j['socketID']),
      isHost: readBool(j['isPartyLeader']),
      wordIndex: readInt(j['currentWordIndex']),
      wpm: readDouble(j['WPM'], -1),
      isSpectator: readBool(j['isSpectator']),
      isEliminated: readBool(j['isEliminated']),
      mistakes: readInt(j['mistakes']),
    );
  }

  /// True once the server has set this player's final WPM.
  bool get hasFinalWpm => wpm >= 0;

  bool finished(int wordCount) => wordCount > 0 && wordIndex >= wordCount;

  /// 0.0 .. 1.0 of the quote typed.
  double progress(int wordCount) =>
      wordCount == 0 ? 0 : (wordIndex / wordCount).clamp(0.0, 1.0).toDouble();
}
