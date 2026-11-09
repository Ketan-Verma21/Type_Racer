/// 6-character room codes like "K7P2QX" (no 0/O or 1/I). Must match the
/// server's src/domain/roomCode.ts.
const String kRoomCodeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const int kRoomCodeLength = 6;

final RegExp _roomCodePattern = RegExp(r'^[A-HJ-NP-Z2-9]{6}$');

/// "  k7p2qx " -> "K7P2QX"
String normalizeRoomCode(String raw) => raw.trim().toUpperCase();

bool isValidRoomCode(String code) => _roomCodePattern.hasMatch(code);
