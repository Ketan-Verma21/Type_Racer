import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/providers/game_state_provider.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/theme/app_theme.dart';
import 'package:type_racer/utils/player_utils.dart';
import 'package:type_racer/utils/socket_methods.dart';
import 'package:type_racer/widgets/custom_button.dart';
import 'package:type_racer/widgets/game_background.dart';
import 'package:type_racer/widgets/game_text_field.dart';
import 'package:type_racer/widgets/race_lane.dart';
import 'package:type_racer/widgets/scoreboard.dart';
import 'package:type_racer/widgets/sentence_game.dart';

import '../providers/client_state_provider.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final SocketMethods _socketMethods = SocketMethods();

  /// What the player has typed so far; shared by the sentence card
  /// (per-letter colours) and the input box (red/shake).
  final ValueNotifier<String> _typed = ValueNotifier('');

  String _gameId = '';

  @override
  void initState() {
    super.initState();
    _socketMethods.updateTimer(context);
    _socketMethods.updateGame(context);
    _socketMethods.gameFinishedListener();

    final gp = Provider.of<GameStateProvider>(context, listen: false);
    _gameId = gp.gameState['id'].toString();
    final me = findMe(gp.gameState['players'] as List);
    if (me != null) {
      _socketMethods.rejoinOnReconnect(_gameId, me['_id'].toString());
    }
  }

  @override
  void dispose() {
    // system back button etc.: make sure the server knows we left
    // (server ignores it if we already left via "Back to Home")
    _socketMethods.emitLeave(_gameId);
    _typed.dispose();
    super.dispose();
  }

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
    final gameProvider =
    Provider.of<GameStateProvider>(context, listen: false);
    final clientProvider =
    Provider.of<ClientStateProvider>(context, listen: false);
    final gameId = gameProvider.gameState['id'].toString();

    _socketMethods.leaveGame(gameId);
    Navigator.of(context).popUntil((route) => route.isFirst);
    // build() below returns an empty screen when there is no player, so
    // resetting while the pop animation plays is safe.
    gameProvider.updateGameState(
        id: '', players: [], isJoin: true, isOver: false, words: []);
    clientProvider.setClientState({'countDown': '', 'msg': ''});
  }

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
    // results show when you've typed everything OR time ran out / everyone finished
    final finished = (words.isNotEmpty &&
        (me['currentWordIndex'] as int) >= words.length) ||
        game.gameState['isOver'] == true;

    // ───────────── results view ─────────────
    if (finished) {
      return Scaffold(
        body: GameBackground(
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(child: const Scoreboard()),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: CustomButton(
                    text: 'Back to Home',
                    secondary: true,
                    onTap: _goHome,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ───────────── race view ─────────────
    final countDown =
    clientStateProvider.clientState['timer']['countDown'].toString();
    final msg = clientStateProvider.clientState['timer']['msg'].toString();

    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              // status pill
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.yellow.withOpacity(0.5)),
                ),
                child: Text(msg.toUpperCase(),
                    style: AppTheme.display(
                        size: 13, color: AppColors.yellow, spacing: 2)),
              ),
              // countdown that pops on every change
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale:
                  CurvedAnimation(parent: anim, curve: Curves.elasticOut),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Text(
                  countDown,
                  key: ValueKey(countDown),
                  style: AppTheme.display(
                    size: 44,
                    color: AppColors.cyan,
                    spacing: 2,
                  ).copyWith(shadows: [
                    Shadow(
                        color: AppColors.cyan.withOpacity(0.8),
                        blurRadius: 18),
                  ]),
                ),
              ),
              // room code (host, while waiting)
              if (game.gameState['isJoin'])
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _copyCode(game.gameState['id']),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.cyan.withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
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
                ),
              const SizedBox(height: 10),
              SentenceGame(typed: _typed),
              const SizedBox(height: 16),
              // race track
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView.builder(
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final p = players[index];
                      final progress = words.isEmpty
                          ? 0.0
                          : (p['currentWordIndex'] / words.length).toDouble();
                      return RaceLane(
                        name: p['nickname'].toString(),
                        progress: progress,
                        color: AppColors.laneColors[
                        index % AppColors.laneColors.length],
                      );
                    },
                  ),
                ),
              ),
              // input lives in the body now (same background, no bottom bar)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: GameTextField(typed: _typed),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
