import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/screens/game/views/common.dart';
import 'package:type_racer/state/game_controller.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/theme/app_theme.dart';
import 'package:type_racer/ui/layout/breakpoints.dart';
import 'package:type_racer/widgets/chat_panel.dart';
import 'package:type_racer/widgets/scoreboard.dart';

/// Spectators and eliminated players watch the race live.
/// Wide: [lanes | banner + live standings + reactions].
class WatchView extends StatelessWidget {
  final VoidCallback onLeave;
  const WatchView({super.key, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final size = ScreenSize.of(context);
    final out = game.me!.isEliminated;
    final watching = game.game.players.length - game.game.racers.length;
    final color = out ? AppColors.red : AppColors.cyan;

    final banner = Container(
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
    );
    final reactions = ReactionBar(onReact: game.sendReaction);

    return Column(
      children: [
        GameTopBar(msg: game.timer.msg, onLeave: onLeave),
        CountdownText(text: game.timer.countDown, size: size.isCompact ? 34 : 44),
        Expanded(
          child: Responsive(
            compact: (_) => Column(children: [
              banner,
              const Expanded(child: RaceLanes()),
              Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), child: reactions),
            ]),
            medium: (_) => Padding(
              padding: EdgeInsets.symmetric(horizontal: size.gutter),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(flex: 3, child: RaceLanes(maxWidth: 1000)),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ListView(children: [
                      banner,
                      const SizedBox(height: 12),
                      Scoreboard(myId: game.me!.id, maxWidth: 520),
                      const SizedBox(height: 16),
                      reactions,
                      const SizedBox(height: 16),
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
