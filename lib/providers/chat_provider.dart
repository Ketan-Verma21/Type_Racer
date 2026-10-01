import 'dart:async';
import 'package:flutter/foundation.dart';

class ChatMessage {
  final String playerId;
  final String nickname;
  final String text;
  final int ts;
  ChatMessage({
    required this.playerId,
    required this.nickname,
    required this.text,
    required this.ts,
  });

  factory ChatMessage.fromJson(dynamic d) => ChatMessage(
        playerId: d['playerId'].toString(),
        nickname: d['nickname'].toString(),
        text: d['text'].toString(),
        ts: (d['ts'] as num).toInt(),
      );
}

class ReactionEvent {
  final String id;
  final String nickname;
  final String emoji;
  final double x; // -0.8 .. 0.8, horizontal position of the floating emoji
  ReactionEvent(
      {required this.id,
      required this.nickname,
      required this.emoji,
      required this.x});

  factory ReactionEvent.fromJson(dynamic d) {
    final id = d['id'].toString();
    return ReactionEvent(
      id: id,
      nickname: d['nickname'].toString(),
      emoji: d['emoji'].toString(),
      x: ((id.hashCode % 160) / 100) - 0.8,
    );
  }
}

/// Lobby chat messages + floating emoji reactions.
class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> messages = [];
  final List<ReactionEvent> reactions = [];

  void add(ChatMessage m) {
    messages.add(m);
    if (messages.length > 50) messages.removeAt(0);
    notifyListeners();
  }

  void setHistory(List<ChatMessage> list) {
    messages
      ..clear()
      ..addAll(list);
    notifyListeners();
  }

  void addReaction(ReactionEvent r) {
    reactions.add(r);
    notifyListeners();
    Timer(const Duration(milliseconds: 2600), () {
      reactions.remove(r);
      notifyListeners();
    });
  }

  void clear() {
    messages.clear();
    reactions.clear();
    notifyListeners();
  }
}
