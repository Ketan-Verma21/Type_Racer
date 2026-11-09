import 'package:flutter/foundation.dart';

/// Keystroke accuracy for the local player.
class TypingStats extends ChangeNotifier {
  int keys = 0;
  int errors = 0;

  double get accuracy =>
      keys == 0 ? 1.0 : ((keys - errors) / keys).clamp(0.0, 1.0).toDouble();

  void record({required bool wrong}) {
    keys++;
    if (wrong) errors++;
    notifyListeners();
  }

  void reset() {
    keys = 0;
    errors = 0;
    notifyListeners();
  }
}
