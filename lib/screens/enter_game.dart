import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/state/game_controller.dart';
import 'package:type_racer/widgets/snack.dart';

/// Shared by the Create and Join screens: after the request is sent, wait for
/// the server's first `updateGame` (then open the game screen) or a refusal
/// (then show it). Gives up after [enterTimeout].
mixin EnterGame<T extends StatefulWidget> on State<T> {
  static const Duration enterTimeout = Duration(seconds: 10);

  late final GameController game = context.read<GameController>();
  StreamSubscription<String>? _errors;
  Timer? _timeout;
  bool waiting = false;

  @override
  void initState() {
    super.initState();
    game.addListener(_onGame);
    _errors = game.joinErrors.listen((message) {
      if (!waiting || !mounted) return;
      _stop();
      showSnack(context, message,
          type: message == 'Please enter a valid game id' ? SnackType.failure : SnackType.warning);
    });
  }

  @override
  void dispose() {
    game.removeListener(_onGame);
    _errors?.cancel();
    _timeout?.cancel();
    super.dispose();
  }

  /// Call after sending create / join.
  void startWaiting() {
    setState(() => waiting = true);
    _timeout?.cancel();
    _timeout = Timer(enterTimeout, () {
      if (!mounted || !waiting) return;
      _stop();
      showSnack(context, "The server didn't respond. Please try again.");
    });
  }

  void _onGame() {
    if (!waiting || !game.inGame || !mounted) return;
    _stop();
    Navigator.of(context).pushNamed('/game-screen');
  }

  void _stop() {
    _timeout?.cancel();
    if (mounted) setState(() => waiting = false);
  }
}
