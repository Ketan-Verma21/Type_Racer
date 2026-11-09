import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/screens/game/views/common.dart';
import 'package:type_racer/state/game_controller.dart';
import 'package:type_racer/state/typing_stats.dart';
import 'package:type_racer/widgets/game_text_field.dart';
import 'package:type_racer/widgets/sentence_game.dart';
import 'package:type_racer/widgets/stats_bar.dart';

/// Racing: the quote, my stats, everyone's lanes and the typing box.
class RaceView extends StatelessWidget {
  final ValueNotifier<String> typed;
  final TypingStats stats;
  final VoidCallback onLeave;
  const RaceView({super.key, required this.typed, required this.stats, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final me = game.me!;
    return Column(
      children: [
        GameTopBar(msg: game.timer.msg, onLeave: onLeave),
        CountdownText(text: game.timer.countDown, size: 34),
        const SizedBox(height: 6),
        SentenceGame(typed: typed),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: stats,
          builder: (_, __) => StatsBar(
            wpm: game.wpmOf(me),
            accuracy: stats.accuracy,
            done: me.wordIndex,
            total: game.game.words.length,
            mode: game.mode,
          ),
        ),
        const SizedBox(height: 6),
        const Expanded(child: RaceLanes()),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          child: GameTextField(typed: typed, stats: stats),
        ),
      ],
    );
  }
}
