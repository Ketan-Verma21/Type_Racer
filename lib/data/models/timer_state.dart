import 'package:type_racer/data/models/json.dart';

enum TimerPhase { waiting, countdown, racing }

/// The server's `timer` event: {countDown, msg}.
///   msg "Game Starting"  -> countDown is the seconds left before the start (5, 4, ...)
///   msg "Time Remaining" -> countDown is the race clock as "m:ss"
class TimerState {
  final String countDown;
  final String msg;

  const TimerState({this.countDown = '', this.msg = ''});

  static const idle = TimerState();

  factory TimerState.fromJson(Object? json) {
    final j = readMap(json);
    return TimerState(countDown: readString(j['countDown']), msg: readString(j['msg']));
  }

  TimerPhase get phase => switch (msg) {
        'Game Starting' => TimerPhase.countdown,
        'Time Remaining' => TimerPhase.racing,
        _ => TimerPhase.waiting,
      };

  /// Seconds left: the countdown, or the race clock. null if unreadable.
  int? get secondsLeft {
    final parts = countDown.split(':');
    if (parts.length == 1) return int.tryParse(parts[0]);
    if (parts.length != 2) return null;
    final m = int.tryParse(parts[0]), s = int.tryParse(parts[1]);
    return (m == null || s == null) ? null : m * 60 + s;
  }

  @override
  bool operator ==(Object other) =>
      other is TimerState && other.countDown == countDown && other.msg == msg;

  @override
  int get hashCode => Object.hash(countDown, msg);
}
