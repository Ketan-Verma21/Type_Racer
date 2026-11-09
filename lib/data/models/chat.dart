import 'package:type_racer/data/models/json.dart';

/// A lobby chat message (`chat-message`, and the list in `chat-history`).
class ChatMessage {
  final String playerId;
  final String nickname;
  final String text;
  final int ts; // ms since epoch

  const ChatMessage({
    required this.playerId,
    required this.nickname,
    required this.text,
    required this.ts,
  });

  factory ChatMessage.fromJson(Object? json) {
    final j = readMap(json);
    return ChatMessage(
      playerId: readString(j['playerId']),
      nickname: readString(j['nickname']),
      text: readString(j['text']),
      ts: readInt(j['ts']),
    );
  }
}

/// A floating emoji reaction (`reaction`).
class Reaction {
  final String id;
  final String nickname;
  final String emoji;

  /// -0.8 .. 0.8: where the emoji floats up. Derived from the id, so every
  /// device draws it in the same place.
  final double x;

  const Reaction({required this.id, required this.nickname, required this.emoji, required this.x});

  factory Reaction.fromJson(Object? json) {
    final j = readMap(json);
    final id = readString(j['id']);
    return Reaction(
      id: id,
      nickname: readString(j['nickname']),
      emoji: readString(j['emoji']),
      x: ((id.hashCode % 160) / 100) - 0.8,
    );
  }
}
