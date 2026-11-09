// Small, forgiving readers for socket payloads. The server is the source of
// truth, but a missing or oddly typed field must never crash the app: each
// reader falls back to a safe default instead.

String readString(Object? v, [String fallback = '']) => v?.toString() ?? fallback;

int readInt(Object? v, [int fallback = 0]) {
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? fallback;
}

double readDouble(Object? v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  return double.tryParse(v?.toString() ?? '') ?? fallback;
}

bool readBool(Object? v) => v == true;

Map<String, dynamic> readMap(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<dynamic> readList(Object? v) => v is List ? v : const [];
