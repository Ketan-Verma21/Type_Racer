import 'package:flutter_test/flutter_test.dart';
import 'package:type_racer/data/models/leaderboard.dart';
import 'package:type_racer/state/chat_provider.dart';
import 'package:type_racer/state/leaderboard_controller.dart';

import '../../fakes/fake_game_repository.dart';

ChatMessage msg(int i) => ChatMessage(playerId: 'p', nickname: 'n', text: 'm$i', ts: i);

void main() {
  group('ChatProvider', () {
    late FakeGameRepository repo;
    late ChatProvider chat;

    setUp(() {
      repo = FakeGameRepository();
      chat = ChatProvider(repo, reactionLifetime: const Duration(milliseconds: 10));
    });
    tearDown(() => chat.dispose());

    test('adds messages and keeps only the last 50', () {
      for (var i = 0; i < 55; i++) {
        repo.emitChat(msg(i));
      }

      expect(chat.messages, hasLength(ChatProvider.maxMessages));
      expect(chat.messages.first.text, 'm5');
    });

    test('history replaces the list', () {
      repo
        ..emitChat(msg(1))
        ..emitHistory([msg(7), msg(8)]);

      expect(chat.messages.map((m) => m.text), ['m7', 'm8']);
    });

    test('a reaction floats for a while, then disappears', () async {
      repo.emitReaction(const Reaction(id: 'r', nickname: 'n', emoji: '🔥', x: 0));
      expect(chat.reactions, hasLength(1));

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(chat.reactions, isEmpty);
    });

    test('clear empties both lists', () {
      repo
        ..emitChat(msg(1))
        ..emitReaction(const Reaction(id: 'r', nickname: 'n', emoji: '🔥', x: 0));

      chat.clear();

      expect(chat.messages, isEmpty);
      expect(chat.reactions, isEmpty);
    });
  });

  group('LeaderboardController', () {
    test('asks the server, is loading until the answer for that mode arrives', () {
      final repo = FakeGameRepository();
      final lb = LeaderboardController(repo);

      lb.load('classic');
      expect(repo.sent, [
        ['requestLeaderboard', 'classic'],
      ]);
      expect(lb.isLoading('classic'), isTrue);
      expect(lb.board('classic'), isNull);

      repo.emitLeaderboard(const Leaderboard(
          mode: 'classic', entries: [LeaderboardEntry(nickname: 'Ketan', wpm: 92)]));

      expect(lb.isLoading('classic'), isFalse);
      expect(lb.board('classic')!.entries.single.nickname, 'Ketan');
      expect(lb.board('sudden-death'), isNull);
      lb.dispose();
    });
  });
}
