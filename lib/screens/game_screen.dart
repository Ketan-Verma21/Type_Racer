import 'dart:async';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/providers/chat_provider.dart';
import 'package:type_racer/providers/client_state_provider.dart';
import 'package:type_racer/providers/game_state_provider.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/theme/app_theme.dart';
import 'package:type_racer/utils/game_modes.dart';
import 'package:type_racer/utils/player_utils.dart';
import 'package:type_racer/utils/socket_methods.dart';
import 'package:type_racer/utils/sound_service.dart';
import 'package:type_racer/utils/typing_stats.dart';
import 'package:type_racer/widgets/chat_panel.dart';
import 'package:type_racer/widgets/custom_button.dart';
import 'package:type_racer/widgets/game_background.dart';
import 'package:type_racer/widgets/game_text_field.dart';
import 'package:type_racer/widgets/race_lane.dart';
import 'package:type_racer/widgets/scoreboard.dart';
import 'package:type_racer/widgets/sentence_game.dart';
import 'package:type_racer/widgets/settings_panel.dart';
import 'package:type_racer/widgets/stats_bar.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final SocketMethods _socketMethods = SocketMethods();

  /// What the player has typed so far (shared by sentence card + input box).
  final ValueNotifier<String> _typed = ValueNotifier('');
  final TypingStats _stats = TypingStats();
  final ConfettiController _confetti =
  ConfettiController(duration: const Duration(seconds: 4));
  final ValueNotifier<String?> _banner = ValueNotifier(null);

  late final GameStateProvider _gameProvider;
  late final ClientStateProvider _clientProvider;
  String _gameId = '';
  bool _startPressed = false;
  Timer? _bannerTimer;

  // previous values, used to detect changes (sounds, banners, celebration)
  int? _prevIdx;
  bool _prevOver = false;
  bool _prevElim = false;
  String _lastCount = '';

  @override
  void initState() {
    super.initState();
    _gameProvider = Provider.of<GameStateProvider>(context, listen: false);
    _clientProvider = Provider.of<ClientStateProvider>(context, listen: false);

    _socketMethods.updateTimer(context);
    _socketMethods.updateGame(context);
    _socketMethods.gameFinishedListener();
    _socketMethods.chatListener(context);

    _gameId = _gameProvider.gameState['id'].toString();
    final me = findMe(_gameProvider.gameState['players'] as List);
    if (me != null) {
      _socketMethods.rejoinOnReconnect(_gameId, me['_id'].toString());
      _prevIdx = me['currentWordIndex'] as int;
      _prevElim = me['isEliminated'] == true;
    }
    _prevOver = _gameProvider.gameState['isOver'] == true;
    _socketMethods.requestChatHistory(_gameId);

    _gameProvider.addListener(_onGameChanged);
    _clientProvider.addListener(_onTimerChanged);
  }

  @override
  void dispose() {
    _gameProvider.removeListener(_onGameChanged);
    _clientProvider.removeListener(_onTimerChanged);
    // system back button etc.: make sure the server knows we left
    // (server ignores it if we already left via "Back to Home")
    _socketMethods.emitLeave(_gameId);
    _bannerTimer?.cancel();
    _banner.dispose();
    _confetti.dispose();
    _typed.dispose();
    _stats.dispose();
    super.dispose();
  }

  // ───────────── reacting to game changes ─────────────

  void _showBanner(String text) {
    _banner.value = text;
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(milliseconds: 1900), () {
      _banner.value = null;
    });
  }

  void _onTimerChanged() {
    final t = _clientProvider.clientState['timer'];
    final msg = t['msg'].toString();
    final c = t['countDown'].toString();
    if (c == _lastCount) return;
    _lastCount = c;
    if (msg == 'Game Starting') {
      if (c == '0') {
        SoundService.instance.play('go');
        HapticFeedback.heavyImpact();
      } else {
        SoundService.instance.play('beep');
        HapticFeedback.selectionClick();
      }
    }
  }

  void _onGameChanged() {
    if (!mounted) return;
    final players = _gameProvider.gameState['players'] as List;
    final me = findMe(players);
    if (me == null) return;
    final words = _gameProvider.gameState['words'] as List;
    final over = _gameProvider.gameState['isOver'] == true;
    final isJoin = _gameProvider.gameState['isJoin'] == true;
    final idx = me['currentWordIndex'] as int;
    final elim = me['isEliminated'] == true;

    if (!isJoin) _startPressed = false;

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
    if (elim && !_prevElim) {
      _showBanner("You're OUT! 💀");
      SoundService.instance.play('out');
      HapticFeedback.heavyImpact();
      _typed.value = '';
    }
    // race just ended -> celebrate
    if (over && !_prevOver) _celebrate(players, words, me);
    // rematch -> reset local state
    if (!over && _prevOver) {
      _typed.value = '';
      _stats.reset();
      _confetti.stop();
    }

    _prevIdx = idx;
    _prevElim = elim;
    _prevOver = over;
  }

  void _celebrate(List players, List words, dynamic me) {
    final ranked = rankPlayers(players, words.length);
    final winner = ranked.isNotEmpty ? ranked.first : null;
    final iWon =
        winner != null && winner['_id'].toString() == me['_id'].toString();
    if (iWon) {
      _confetti.play();
      SoundService.instance.play('win');
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 200), HapticFeedback.heavyImpact);
      Future.delayed(const Duration(milliseconds: 400), HapticFeedback.heavyImpact);
    } else if (me['isSpectator'] != true) {
      SoundService.instance.play('lose');
      HapticFeedback.lightImpact();
    }
  }

  // ───────────── actions ─────────────

  void _copyCode(String id) {
    Clipboard.setData(ClipboardData(text: id)).then((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          content: AwesomeSnackbarContent(
            title: 'Bonza!!',
            message: 'Game Code copied to clipboard.',
            contentType: ContentType.success,
          ),
        ),
      );
    });
  }

  /// Leave the room, clear the old game's state, return to the home screen.
  void _goHome() {
    final chat = Provider.of<ChatProvider>(context, listen: false);
    final gameId = _gameProvider.gameState['id'].toString();

    _socketMethods.leaveGame(gameId);
    Navigator.of(context).popUntil((route) => route.isFirst);
    // build() returns an empty screen when there is no player, so resetting
    // while the pop animation plays is safe.
    _gameProvider.updateGameState(
        id: '', players: [], isJoin: true, isOver: false, words: []);
    _clientProvider.setClientState({'countDown': '', 'msg': ''});
    chat.clear();
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
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Stay')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Leave',
                  style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (leave == true && mounted) _goHome();
  }

  // ───────────── small UI pieces ─────────────

  Widget _topBar(String msg) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Leave',
            onPressed: _confirmLeave,
            icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted),
          ),
          Expanded(
            child: Center(
              child: msg.isEmpty
                  ? const SizedBox.shrink()
                  : Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: AppColors.yellow.withOpacity(0.5)),
                ),
                child: Text(msg.toUpperCase(),
                    style: AppTheme.display(
                        size: 12, color: AppColors.yellow, spacing: 2)),
              ),
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: SoundService.instance.muted,
            builder: (_, muted, __) => IconButton(
              tooltip: muted ? 'Unmute' : 'Mute',
              onPressed: SoundService.instance.toggle,
              icon: Icon(
                muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _countdown(String text, double size) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: Text(
        text,
        key: ValueKey(text),
        style: AppTheme.display(size: size, color: AppColors.cyan, spacing: 2)
            .copyWith(shadows: [
          Shadow(color: AppColors.cyan.withOpacity(0.8), blurRadius: 18),
        ]),
      ),
    );
  }

  Widget _lanes(List racers, int wordCount, int Function(dynamic) wpm,
      String myId) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView.builder(
          itemCount: racers.length,
          itemBuilder: (context, index) {
            final p = racers[index];
            final progress = wordCount == 0
                ? 0.0
                : ((p['currentWordIndex'] as int) / wordCount).toDouble();
            return RaceLane(
              name: p['nickname'].toString(),
              progress: progress,
              color: AppColors.laneColors[index % AppColors.laneColors.length],
              wpm: wpm(p),
              isMe: p['_id'].toString() == myId,
              isLeader: p['isPartyLeader'] == true,
              isEliminated: p['isEliminated'] == true,
            );
          },
        ),
      ),
    );
  }

  // ───────────── views ─────────────

  Widget _lobbyView({
    required String msg,
    required String countDown,
    required String gameId,
    required List racers,
    required Map<String, dynamic> settings,
    required dynamic me,
  }) {
    final isLeader = me['isPartyLeader'] == true;
    return Column(
      children: [
        _topBar(msg),
        _countdown(countDown, 44),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // room code
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _copyCode(gameId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(14),
                        border:
                        Border.all(color: AppColors.cyan.withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.copy_rounded,
                              size: 18, color: AppColors.cyan),
                          const SizedBox(width: 10),
                          Text('Tap to copy game code',
                              style: AppTheme.body(
                                  size: 16, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SettingsPanel(
                    settings: settings,
                    isLeader: isLeader,
                    racerCount: racers.length,
                    onChange: (s) => _socketMethods.updateSettings(gameId, s),
                  ),
                  const SizedBox(height: 12),
                  // who is here
                  Text('PLAYERS ${racers.length}/${settings['maxPlayers']}',
                      style: AppTheme.display(
                          size: 12, color: AppColors.textMuted, spacing: 2)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (final p in racers)
                        Chip(
                          avatar: Text(p['isPartyLeader'] == true ? '👑' : '🏎️'),
                          label: Text(p['nickname'].toString() +
                              (p['_id'].toString() == me['_id'].toString()
                                  ? ' (you)'
                                  : '')),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ChatPanel(
                    myId: me['_id'].toString(),
                    onSend: (t) => _socketMethods.sendChat(gameId, t),
                    onReact: (e) => _socketMethods.sendReaction(gameId, e),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: isLeader
              ? (_startPressed
              ? Text('Starting...',
              style: AppTheme.display(
                  size: 14, color: AppColors.textMuted))
              : CustomButton(
            text: 'Start',
            onTap: () {
              setState(() => _startPressed = true);
              _socketMethods.startTimer(me['_id'], gameId);
              // safety: allow pressing again if nothing happened
              Future.delayed(const Duration(seconds: 8), () {
                if (mounted && _startPressed) {
                  setState(() => _startPressed = false);
                }
              });
            },
          ))
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_top_rounded,
                  size: 18, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Text('Waiting for the host to start...',
                  style: AppTheme.body(
                      size: 16, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _raceView({
    required String msg,
    required String countDown,
    required List racers,
    required int wordCount,
    required int Function(dynamic) wpm,
    required dynamic me,
    required GameMode mode,
  }) {
    return Column(
      children: [
        _topBar(msg),
        _countdown(countDown, 34),
        const SizedBox(height: 6),
        SentenceGame(typed: _typed),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: _stats,
          builder: (_, __) => StatsBar(
            wpm: wpm(me),
            accuracy: _stats.accuracy,
            done: me['currentWordIndex'] as int,
            total: wordCount,
            mode: mode,
          ),
        ),
        const SizedBox(height: 6),
        Expanded(child: _lanes(racers, wordCount, wpm, me['_id'].toString())),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          child: GameTextField(typed: _typed, stats: _stats),
        ),
      ],
    );
  }

  /// Spectators and eliminated players watch the race live.
  Widget _watchView({
    required String msg,
    required String countDown,
    required List racers,
    required int wordCount,
    required int Function(dynamic) wpm,
    required dynamic me,
    required String gameId,
    required int watching,
  }) {
    final out = me['isEliminated'] == true;
    return Column(
      children: [
        _topBar(msg),
        _countdown(countDown, 34),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: (out ? AppColors.red : AppColors.cyan).withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: (out ? AppColors.red : AppColors.cyan).withOpacity(0.5)),
          ),
          child: Text(
            out
                ? "💀 You're out! Watching the rest of the race"
                : '👀 Spectating — you will join the next race ($watching watching)',
            textAlign: TextAlign.center,
            style: AppTheme.body(size: 16, weight: FontWeight.w700),
          ),
        ),
        Expanded(child: _lanes(racers, wordCount, wpm, me['_id'].toString())),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ReactionBar(
              onReact: (e) => _socketMethods.sendReaction(gameId, e)),
        ),
      ],
    );
  }

  Widget _resultsView({
    required bool isOver,
    required bool isLeader,
    required String gameId,
    required String myId,
  }) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Scoreboard(myId: myId),
                  const SizedBox(height: 16),
                  ReactionBar(
                      onReact: (e) => _socketMethods.sendReaction(gameId, e)),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            children: [
              if (isOver && isLeader)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CustomButton(
                    text: 'Play Again',
                    onTap: () => _socketMethods.rematch(gameId),
                  ),
                )
              else if (isOver)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Waiting for the host to start a rematch...',
                      style:
                      AppTheme.body(size: 16, color: AppColors.textMuted)),
                ),
              CustomButton(
                text: 'Back to Home',
                secondary: true,
                onTap: _goHome,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ───────────── build ─────────────

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameStateProvider>(context);
    final clientStateProvider = Provider.of<ClientStateProvider>(context);

    final players = game.gameState['players'] as List;
    final me = findMe(players);
    if (me == null) {
      // state was reset / reconnecting: draw just the background
      return Scaffold(body: GameBackground(child: const SizedBox.shrink()));
    }

    final words = game.gameState['words'] as List;
    final settings = game.gameState['settings'] as Map<String, dynamic>;
    final gameId = game.gameState['id'].toString();
    final isOver = game.gameState['isOver'] == true;
    final isJoin = game.gameState['isJoin'] == true;
    final racers = racersOf(players);
    final idx = me['currentWordIndex'] as int;
    final finished = words.isNotEmpty && idx >= words.length;
    final isSpectator = me['isSpectator'] == true;
    final eliminated = me['isEliminated'] == true;

    final timer = clientStateProvider.clientState['timer'];
    final msg = timer['msg'].toString();
    final countDown = timer['countDown'].toString();

    // live WPM from the server clock (final WPM once a player is done)
    final elapsed =
    elapsedSeconds(msg, countDown, (settings['timeLimit'] as num).toInt());
    int wpm(dynamic p) {
      final w = wpmOf(p);
      if (w >= 0) return w.round();
      if (elapsed < 3) return 0;
      return ((p['currentWordIndex'] as int) / (elapsed / 60)).round();
    }

    Widget body;
    if (isOver || (finished && !isSpectator)) {
      body = _resultsView(
        isOver: isOver,
        isLeader: me['isPartyLeader'] == true,
        gameId: gameId,
        myId: me['_id'].toString(),
      );
    } else if (isSpectator || eliminated) {
      body = _watchView(
        msg: msg,
        countDown: countDown,
        racers: racers,
        wordCount: words.length,
        wpm: wpm,
        me: me,
        gameId: gameId,
        watching: players.length - racers.length,
      );
    } else if (isJoin) {
      body = _lobbyView(
        msg: msg,
        countDown: countDown,
        gameId: gameId,
        racers: racers,
        settings: settings,
        me: me,
      );
    } else {
      body = _raceView(
        msg: msg,
        countDown: countDown,
        racers: racers,
        wordCount: words.length,
        wpm: wpm,
        me: me,
        mode: GameModes.byId(settings['mode']?.toString()),
      );
    }

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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(text,
                      style: AppTheme.display(size: 15, spacing: 1)),
                )
                    .animate()
                    .scale(
                    duration: 250.ms, curve: Curves.easeOutBack)
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
