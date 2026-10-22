import 'package:flutter_test/flutter_test.dart';
import 'package:type_racer/utils/typing_stats.dart';

void main() {
  group('TypingStats', () {
    test('starts at 100% accuracy', () {
      expect(TypingStats().accuracy, 1.0);
    });

    test('accuracy = correct keys / all keys', () {
      final stats = TypingStats();

      stats.record(wrong: false);
      stats.record(wrong: false);
      stats.record(wrong: false);
      stats.record(wrong: true);

      expect(stats.accuracy, 0.75);
    });

    test('reset clears the counters', () {
      final stats = TypingStats()..record(wrong: true);

      stats.reset();

      expect(stats.keys, 0);
      expect(stats.errors, 0);
      expect(stats.accuracy, 1.0);
    });

    test('notifies listeners on every key', () {
      final stats = TypingStats();
      var calls = 0;
      stats.addListener(() => calls++);

      stats.record(wrong: false);
      stats.record(wrong: true);

      expect(calls, 2);
    });
  });
}
