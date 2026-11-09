import 'package:flutter/services.dart';
import 'package:type_racer/domain/room_code.dart';

/// Text-field formatter for room codes: upper case, letters and digits only,
/// at most [kRoomCodeLength] characters.
class RoomCodeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final clipped = text.length > kRoomCodeLength ? text.substring(0, kRoomCodeLength) : text;
    return TextEditingValue(
      text: clipped,
      selection: TextSelection.collapsed(offset: clipped.length),
    );
  }
}
