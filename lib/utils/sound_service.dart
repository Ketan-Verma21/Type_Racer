import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Tiny sound-effect helper. Files live in assets/sounds/<name>.wav:
/// tick, error, beep, go, win, lose, out
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final ValueNotifier<bool> muted = ValueNotifier(false);
  final Map<String, AudioPlayer> _players = {};

  void toggle() => muted.value = !muted.value;

  Future<void> play(String name) async {
    if (muted.value) return;
    try {
      final player = _players.putIfAbsent(name, () {
        final p = AudioPlayer();
        p.setPlayerMode(PlayerMode.lowLatency);
        return p;
      });
      await player.stop();
      await player.play(AssetSource('sounds/$name.wav'));
    } catch (_) {
      // sound is optional; never crash the game because of it
    }
  }
}
