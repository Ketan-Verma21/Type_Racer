import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/screens/game/views/common.dart';
import 'package:type_racer/state/game_controller.dart';
import 'package:type_racer/state/typing_stats.dart';
import 'package:type_racer/ui/layout/breakpoints.dart';
import 'package:type_racer/widgets/game_text_field.dart';
import 'package:type_racer/widgets/sentence_game.dart';
import 'package:type_racer/widgets/stats_bar.dart';

/// Racing: the quote, my stats, the typing box and everyone's lanes.
/// On wider screens the quote and box grow (up to 1000 px) and the lanes
/// go into two columns once there are 3+ racers.
class RaceView extends StatelessWidget {
  final ValueNotifier<String> typed;
  final TypingStats stats;
  final VoidCallback onLeave;
  const RaceView({super.key, required this.typed, required this.stats, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final size = ScreenSize.of(context);
    final me = game.me!;
    final width = switch (size) {
      ScreenSize.compact => 600.0,
      ScreenSize.medium => 860.0,
      ScreenSize.expanded => 1000.0,
    };

    final statsBar = AnimatedBuilder(
      animation: stats,
      builder: (_, __) => StatsBar(
        wpm: game.wpmOf(me),
        accuracy: stats.accuracy,
        done: me.wordIndex,
        total: game.game.words.length,
        mode: game.mode,
        maxWidth: width,
      ),
    );
    final input = GameTextField(typed: typed, stats: stats, maxWidth: width);
    final lanes = RaceLanes(columns: size == ScreenSize.expanded ? 2 : 1, maxWidth: width + 32);

    return Column(
      children: [
        GameTopBar(msg: game.timer.msg, onLeave: onLeave),
        CountdownText(text: game.timer.countDown, size: size.isCompact ? 34 : 44),
        const SizedBox(height: 6),
        SentenceGame(typed: typed, maxWidth: width, fontSize: size.isCompact ? 24 : 28),
        if (size.isCompact) ...[
          // phone: keyboard at the bottom, under the lanes
          const SizedBox(height: 10),
          statsBar,
          const SizedBox(height: 6),
          Expanded(child: lanes),
          Padding(padding: const EdgeInsets.only(top: 8, bottom: 16), child: input),
        ] else ...[
          // wide: type right under the quote, lanes below
          const SizedBox(height: 12),
          input,
          const SizedBox(height: 12),
          statsBar,
          const SizedBox(height: 8),
          Expanded(child: lanes),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
