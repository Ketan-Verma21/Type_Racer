import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:type_racer/utils/socket_client.dart';

enum ServerState { checking, waking, ready, failed }

/// Wakes the (free-tier, sleeping) server and tells the UI how it is doing.
/// Started once at app launch; the home screen waits for [isReady].
class ServerStatusProvider extends ChangeNotifier {
  ServerState state = ServerState.checking;
  int secondsWaiting = 0;

  DateTime? _lastReady;
  Completer<void>? _current;

  static const Duration _pingTimeout = Duration(seconds: 10);
  static const Duration _retryEvery = Duration(seconds: 3);
  static const Duration _maxWait = Duration(minutes: 4);
  // Render sleeps after 15 min idle; re-check well before that
  static const Duration _staleAfter = Duration(minutes: 8);

  bool get isReady => state == ServerState.ready;

  bool get _fresh =>
      _lastReady != null &&
          DateTime.now().difference(_lastReady!) < _staleAfter;

  /// Start (or join) a wake-up check. Safe to call repeatedly.
  Future<void> wake() {
    if (_current != null) return _current!.future;
    final c = Completer<void>();
    _current = c;
    _run().whenComplete(() {
      _current = null;
      c.complete();
    });
    return c.future;
  }

  /// True once the server answered recently (re-checks if it might be asleep).
  Future<bool> ensureReady() async {
    if (isReady && _fresh) return true;
    await wake();
    return isReady;
  }

  /// Cheap check for when the app returns to the foreground.
  void refreshIfStale() {
    if (!_fresh && _current == null) wake();
  }

  Future<void> _run() async {
    final started = DateTime.now();
    secondsWaiting = 0;
    state = ServerState.checking;
    notifyListeners();

    // after a few seconds without an answer we know it is waking up
    final ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      secondsWaiting = DateTime.now().difference(started).inSeconds;
      if (state == ServerState.checking && secondsWaiting >= 3) {
        state = ServerState.waking;
      }
      notifyListeners();
    });

    try {
      while (DateTime.now().difference(started) < _maxWait) {
        if (await _ping()) {
          state = ServerState.ready;
          _lastReady = DateTime.now();
          SocketClient.instance.ensureConnected(); // pre-connect the socket
          return;
        }
        await Future.delayed(_retryEvery);
      }
      state = ServerState.failed;
    } finally {
      ticker.cancel();
      notifyListeners();
    }
  }

  /// GET /health -> {"ok":true,"db":true}. While the server sleeps Render
  /// answers with an HTML loading page / 502, which counts as "not ready".
  Future<bool> _ping() async {
    try {
      final r = await http
          .get(Uri.parse('$kServerUrl/health'))
          .timeout(_pingTimeout);
      if (r.statusCode != 200) return false;
      final j = jsonDecode(r.body);
      return j is Map && j['ok'] == true && j['db'] == true;
    } catch (_) {
      return false;
    }
  }
}
