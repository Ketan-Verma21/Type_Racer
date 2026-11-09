import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/data/models/player.dart';
import 'package:type_racer/state/game_controller.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/theme/app_theme.dart';
import 'package:type_racer/utils/sound_service.dart';
import 'package:type_racer/widgets/race_lane.dart';

/// Leave button, the timer message ("TIME REMAINING") and the mute button.
class GameTopBar extends StatelessWidget {
  final String msg;
  final VoidCallback onLeave;
  const GameTopBar({super.key, required this.msg, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Leave',
            onPressed: onLeave,
            icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted),
          ),
          Expanded(
            child: Center(
              child: msg.isEmpty
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.yellow.withValues(alpha: 0.5)),
                      ),
                      child: Text(msg.toUpperCase(),
                          style: AppTheme.display(size: 12, color: AppColors.yellow, spacing: 2)),
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
}

/// The big countdown / race clock, popping in on every change.
class CountdownText extends StatelessWidget {
  final String text;
  final double size;
  const CountdownText({super.key, required this.text, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: Text(
        text,
        key: ValueKey(text),
        style: AppTheme.display(size: size, color: AppColors.cyan, spacing: 2).copyWith(shadows: [
          Shadow(color: AppColors.cyan.withValues(alpha: 0.8), blurRadius: 18),
        ]),
      ),
    );
  }
}

/// One lane per racer, with live WPM.
class RaceLanes extends StatelessWidget {
  const RaceLanes({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final racers = game.game.racers;
    final wordCount = game.game.words.length;
    final myId = game.me?.id;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView.builder(
          itemCount: racers.length,
          itemBuilder: (context, index) {
            final Player p = racers[index];
            return RaceLane(
              name: p.nickname,
              progress: p.progress(wordCount),
              color: AppColors.laneColors[index % AppColors.laneColors.length],
              wpm: game.wpmOf(p),
              isMe: p.id == myId,
              isLeader: p.isHost,
              isEliminated: p.isEliminated,
            );
          },
        ),
      ),
    );
  }
}
