import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/data/models/timer_state.dart';
import 'package:type_racer/domain/ranking.dart';
import 'package:type_racer/screens/game/views/lobby_view.dart';
import 'package:type_racer/screens/game/views/race_view.dart';
import 'package:type_racer/screens/game/views/results_view.dart';
import 'package:type_racer/screens/game/views/watch_view.dart';
import 'package:type_racer/state/chat_provider.dart';
import 'package:type_racer/state/game_controller.dart';
import 'package:type_racer/state/typing_stats.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/theme/app_theme.dart';
import 'package:type_racer/utils/sound_service.dart';
import 'package:type_racer/widgets/chat_panel.dart';
import 'package:type_racer/widgets/game_background.dart';
import 'package:type_racer/widgets/snack.dart';

/// Which view the game screen shows, decided from the game and from me.
enum GameView { lobby, race, watch, results }

GameView viewFor(GameController game) {
  final g = game.game, me = game.me!;
  final finished = me.finished(g.words.length);
  if (g.isOver || (finished && !me.isSpectator)) return GameView.results;
  if (me.isSpectator || me.isEliminated) return GameView.watch;
  if (g.isJoin) return GameView.lobby;
  return GameView.race;
}

/// The room: picks the view, and plays sounds / banners / confetti when
/// something happens to me (a word, a penalty, out, win).
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  /// What the player has typed so far (shared by sentence card + input box).
  final ValueNotifier<String> _typed = ValueNotifier('');
  final TypingStats _stats = TypingStats();
  final ConfettiController _confetti = ConfettiController(duration: const Duration(seconds: 4));
  final ValueNotifier<String?> _banner = ValueNotifier(null);

  late final GameController _game = context.read<GameController>();
  late final ChatProvider _chat = context.read<ChatProvider>();
  StreamSubscription<String>? _errors;
  Timer? _bannerTimer;

  // previous values, used to detect changes (sounds, banners, celebration)
  int? _prevIdx;
  bool _prevOver = false;
  bool _prevElim = false;
  String _lastCount = '';

  @override
  void initState() {
    super.initState();
    final me = _game.me;
    _prevIdx = me?.wordIndex;
    _prevElim = me?.isEliminated ?? false;
    _prevOver = _game.game.isOver;
    _game.requestChatHistory();
    _game.addListener(_onGameChanged);
    _errors = _game.errors.listen((m) {
      if (mounted) showSnack(context, m, title: 'Hmm');
    });
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChanged);
    _errors?.cancel();
    // System back button etc.: make sure the server knows we left. After this
    // frame, because leaving notifies listeners and the tree is locked now.
    // (No-op if "Back to Home" already left.)
    final game = _game;
    scheduleMicrotask(game.leaveGame);
    _bannerTimer?.cancel();
    _banner.dispose();
    _confetti.dispose();
    _typed.dispose();
    _stats.dispose();
    super.dispose();
  }

  // ───────────── reacting to changes ─────────────

  void _showBanner(String text) {
    _banner.value = text;
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(milliseconds: 1900), () => _banner.value = null);
  }

  void _onGameChanged() {
    if (!mounted) return;
    _onTimer(_game.timer);
    final me = _game.me;
    if (me == null) return;
    final over = _game.game.isOver;
    final idx = me.wordIndex;

    // a correct word / a penalty
    if (_prevIdx != null && !over && !_prevOver) {
      if (idx > _prevIdx!) {
        SoundService.instance.play('tick');
        HapticFeedback.selectionClick();
      } else if (idx < _prevIdx!) {
        _showBanner('Wrong word! Back to the start 🎯');
        SoundService.instance.play('error');
        HapticFeedback.heavyImpact();
        _typed.value = '';
      }
    }
    // sudden-death elimination
    if (me.isEliminated && !_prevElim) {
      _showBanner("You're OUT! 💀");
      SoundService.instance.play('out');
      HapticFeedback.heavyImpact();
      _typed.value = '';
    }
    // race just ended -> celebrate
    if (over && !_prevOver) _celebrate();
    // rematch -> reset local state
    if (!over && _prevOver) {
      _typed.value = '';
      _stats.reset();
      _confetti.stop();
    }

    _prevIdx = idx;
    _prevElim = me.isEliminated;
    _prevOver = over;
  }

  void _onTimer(TimerState t) {
    if (t.countDown == _lastCount) return;
    _lastCount = t.countDown;
    if (t.phase != TimerPhase.countdown) return;
    if (t.countDown == '0') {
      SoundService.instance.play('go');
      HapticFeedback.heavyImpact();
    } else {
      SoundService.instance.play('beep');
      HapticFeedback.selectionClick();
    }
  }

  void _celebrate() {
    final me = _game.me!;
    final ranked = rankPlayers(_game.game.players, _game.game.words.length);
    final iWon = ranked.isNotEmpty && ranked.first.id == me.id;
    if (iWon) {
      _confetti.play();
      SoundService.instance.play('win');
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 200), HapticFeedback.heavyImpact);
      Future.delayed(const Duration(milliseconds: 400), HapticFeedback.heavyImpact);
    } else if (!me.isSpectator) {
      SoundService.instance.play('lose');
      HapticFeedback.lightImpact();
    }
  }

  // ───────────── actions ─────────────

  void _copyCode(String id) {
    Clipboard.setData(ClipboardData(text: id)).then((_) {
      if (!mounted) return;
      showSnack(context, 'Game Code copied to clipboard.', title: 'Bonza!!', type: SnackType.success);
    });
  }

  /// Leave the room, clear the old game's state, return to the home screen.
  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    // build() draws an empty screen when there is no player, so resetting
    // while the pop animation plays is safe.
    _game.leaveGame();
    _chat.clear();
    _stats.reset();
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('LEAVE ROOM?', style: AppTheme.display(size: 18)),
        content: Text("You'll leave this race and go back to the home screen.",
            style: AppTheme.body(size: 16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Leave', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (leave == true && mounted) _goHome();
  }

  // ───────────── build ─────────────

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    if (game.me == null) {
      // state was reset / reconnecting: draw just the background
      return const Scaffold(body: GameBackground(child: SizedBox.shrink()));
    }

    final body = switch (viewFor(game)) {
      GameView.results => ResultsView(onHome: _goHome),
      GameView.watch => WatchView(onLeave: _confirmLeave),
      GameView.lobby => LobbyView(onLeave: _confirmLeave, onCopyCode: _copyCode),
      GameView.race => RaceView(typed: _typed, stats: _stats, onLeave: _confirmLeave),
    };

    return Scaffold(
      body: GameBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(child: body),
            const ReactionOverlay(),
            // "wrong word" / "you're out" banner
            ValueListenableBuilder<String?>(
              valueListenable: _banner,
              builder: (_, text, __) => text == null
                  ? const SizedBox.shrink()
                  : Align(
                      alignment: const Alignment(0, -0.6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(text, style: AppTheme.display(size: 15, spacing: 1)),
                      )
                          .animate()
                          .scale(duration: 250.ms, curve: Curves.easeOutBack)
                          .shake(hz: 6, duration: 400.ms),
                    ),
            ),
            // winner confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.06,
                numberOfParticles: 24,
                gravity: 0.25,
                shouldLoop: false,
                colors: const [
                  AppColors.cyan,
                  AppColors.magenta,
                  AppColors.yellow,
                  AppColors.green,
                  Colors.white,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
