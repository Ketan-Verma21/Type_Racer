import 'package:flutter_test/flutter_test.dart';
import 'package:type_racer/data/models/chat.dart';
import 'package:type_racer/data/models/json.dart';
import 'package:type_racer/data/models/leaderboard.dart';
import 'package:type_racer/data/models/timer_state.dart';

void main() {
  group('TimerState', () {
    test('countdown before the start', () {
      final t = TimerState.fromJson({'countDown': 4, 'msg': 'Game Starting'});

      expect(t.phase, TimerPhase.countdown);
      expect(t.secondsLeft, 4);
    });

    test('race clock as m:ss', () {
      final t = TimerState.fromJson({'countDown': '1:05', 'msg': 'Time Remaining'});

      expect(t.phase, TimerPhase.racing);
      expect(t.secondsLeft, 65);
    });

    test('anything else is waiting; unreadable clock gives null', () {
      expect(TimerState.idle.phase, TimerPhase.waiting);
      expect(const TimerState(countDown: 'a:b').secondsLeft, isNull);
      expect(const TimerState(countDown: '1:2:3').secondsLeft, isNull);
      expect(TimerState.idle.secondsLeft, isNull);
    });

    test('equality by value', () {
      expect(TimerState.fromJson({'countDown': '3', 'msg': 'Game Starting'}),
          const TimerState(countDown: '3', msg: 'Game Starting'));
      expect(TimerState.idle.hashCode, const TimerState().hashCode);
    });
  });

  group('ChatMessage and Reaction', () {
    test('read the server payloads', () {
      final m = ChatMessage.fromJson({'playerId': 'p1', 'nickname': 'Ketan', 'text': 'gl hf', 'ts': 42});
      expect([m.playerId, m.nickname, m.text, m.ts], ['p1', 'Ketan', 'gl hf', 42]);

      final r = Reaction.fromJson({'id': 'r1', 'nickname': 'Ketan', 'emoji': '🔥'});
      expect([r.id, r.nickname, r.emoji], ['r1', 'Ketan', '🔥']);
    });

    test('a reaction always floats at the same place for the same id', () {
      final a = Reaction.fromJson({'id': 'r1'}), b = Reaction.fromJson({'id': 'r1'});

      expect(a.x, b.x);
      expect(a.x, inInclusiveRange(-0.8, 0.8));
    });
  });

  group('Leaderboard', () {
    test('reads mode and entries in order', () {
      final lb = Leaderboard.fromJson({
        'mode': 'classic',
        'entries': [
          {'nickname': 'a', 'wpm': 90},
          {'nickname': 'b', 'wpm': 71.6},
        ],
      });

      expect(lb.mode, 'classic');
      expect(lb.entries.map((e) => e.nickname), ['a', 'b']);
      expect(lb.entries.last.wpm, 71);
    });

    test('no entries -> empty list', () {
      expect(Leaderboard.fromJson({'mode': 'classic'}).entries, isEmpty);
    });
  });

  group('json readers', () {
    test('fall back instead of throwing', () {
      expect(readString(null, 'x'), 'x');
      expect(readInt('nope', 7), 7);
      expect(readInt(3.9), 3);
      expect(readDouble(null, -1), -1);
      expect(readDouble('2.5'), 2.5);
      expect(readBool('true'), isFalse); // only a real `true` counts
      expect(readMap('x'), isEmpty);
      expect(readList(5), isEmpty);
    });
  });
}
