import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:type_racer/data/models/chat.dart';

export 'package:type_racer/data/models/chat.dart';

/// Lobby chat messages + floating emoji reactions.
class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> messages = [];
  final List<Reaction> reactions = [];

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

  void addReaction(Reaction r) {
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
