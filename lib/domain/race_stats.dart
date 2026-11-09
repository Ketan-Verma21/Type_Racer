import 'package:type_racer/data/models/player.dart';
import 'package:type_racer/data/models/timer_state.dart';

/// Seconds since the race started, from the server's race clock.
/// 0 before the race starts or if the clock can't be read.
int elapsedSeconds(TimerState timer, int timeLimit) {
  if (timer.phase != TimerPhase.racing) return 0;
  final left = timer.secondsLeft;
  if (left == null) return 0;
  return (timeLimit - left).clamp(0, timeLimit).toInt();
}

/// The WPM to show for a player: the server's final WPM once they're done,
/// otherwise an estimate from words typed so far. Shows 0 for the first
/// 3 seconds, when the estimate jumps around too much to be useful.
int liveWpm(Player p, int elapsed) {
  if (p.hasFinalWpm) return p.wpm.round();
  if (elapsed < 3) return 0;
  return (p.wordIndex / (elapsed / 60)).round();
}
