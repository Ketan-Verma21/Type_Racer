import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/screens/game/views/common.dart';
import 'package:type_racer/state/game_controller.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/theme/app_theme.dart';
import 'package:type_racer/widgets/chat_panel.dart';

/// Spectators and eliminated players watch the race live.
class WatchView extends StatelessWidget {
  final VoidCallback onLeave;
  const WatchView({super.key, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final out = game.me!.isEliminated;
    final watching = game.game.players.length - game.game.racers.length;
    final color = out ? AppColors.red : AppColors.cyan;
    return Column(
      children: [
        GameTopBar(msg: game.timer.msg, onLeave: onLeave),
        CountdownText(text: game.timer.countDown, size: 34),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            out
                ? "💀 You're out! Watching the rest of the race"
                : '👀 Spectating — you will join the next race ($watching watching)',
            textAlign: TextAlign.center,
            style: AppTheme.body(size: 16, weight: FontWeight.w700),
          ),
        ),
        const Expanded(child: RaceLanes()),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ReactionBar(onReact: game.sendReaction),
        ),
      ],
    );
  }
}
