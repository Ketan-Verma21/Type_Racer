import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:type_racer/data/models/chat.dart';
import 'package:type_racer/data/repositories/game_repository.dart';

export 'package:type_racer/data/models/chat.dart';

/// Lobby chat messages + floating emoji reactions of the current room.
class ChatProvider extends ChangeNotifier {
  ChatProvider(GameRepository repo, {this.reactionLifetime = const Duration(milliseconds: 2600)}) {
    _subs = [
      repo.chatMessages.listen(add),
      repo.chatHistory.listen(setHistory),
      repo.reactions.listen(addReaction),
    ];
  }

  static const maxMessages = 50;

  /// How long a reaction floats before it disappears.
  final Duration reactionLifetime;
  late final List<StreamSubscription<Object?>> _subs;

  final List<ChatMessage> messages = [];
  final List<Reaction> reactions = [];

  void add(ChatMessage m) {
    messages.add(m);
    if (messages.length > maxMessages) messages.removeAt(0);
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
    Timer(reactionLifetime, () {
      reactions.remove(r);
      notifyListeners();
    });
  }

  void clear() {
    messages.clear();
    reactions.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
