import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:type_racer/data/models/leaderboard.dart';
import 'package:type_racer/data/repositories/game_repository.dart';

/// Best WPM per player, per mode (FR-15), as the server sends it.
class LeaderboardController extends ChangeNotifier {
  LeaderboardController(this._repo) {
    _sub = _repo.leaderboards.listen((lb) {
      _boards[lb.mode] = lb;
      _loading.remove(lb.mode);
      notifyListeners();
    });
  }

  final GameRepository _repo;
  late final StreamSubscription<Leaderboard> _sub;
  final Map<String, Leaderboard> _boards = {};
  final Set<String> _loading = {};

  /// null until the server has answered for [mode].
  Leaderboard? board(String mode) => _boards[mode];
  bool isLoading(String mode) => _loading.contains(mode);

  /// Ask the server for the latest top 10 of [mode].
  void load(String mode) {
    _loading.add(mode);
    notifyListeners();
    _repo.requestLeaderboard(mode);
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
