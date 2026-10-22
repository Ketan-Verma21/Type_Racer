import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:type_racer/utils/room_code.dart';

void main() {
  group('room codes', () {
    test('accepts 6 characters from the alphabet', () {
      expect(isValidRoomCode('K7P2QX'), isTrue);
    });

    test('rejects wrong length, confusable characters and lower case', () {
      for (final code in ['K7P2Q', 'K7P2QXX', 'K7P2Q0', 'K7P2QI', 'k7p2qx', '']) {
        expect(isValidRoomCode(code), isFalse, reason: code);
      }
    });

    test('normalizes what players type', () {
      expect(normalizeRoomCode('  k7p2qx '), 'K7P2QX');
    });

    test('alphabet matches the server (32 characters, no 0 O 1 I)', () {
      expect(kRoomCodeAlphabet.length, 32);
      for (final c in ['0', 'O', '1', 'I']) {
        expect(kRoomCodeAlphabet.contains(c), isFalse);
      }
    });
  });

  group('RoomCodeInputFormatter', () {
    TextEditingValue format(String typed) => RoomCodeInputFormatter()
        .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: typed));

    test('upper-cases and drops spaces and symbols', () {
      expect(format('k7 p-2q').text, 'K7P2Q');
    });

    test('stops at 6 characters', () {
      expect(format('K7P2QXYZ').text, 'K7P2QX');
    });
  });
}
