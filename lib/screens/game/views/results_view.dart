import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/state/game_controller.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/theme/app_theme.dart';
import 'package:type_racer/widgets/chat_panel.dart';
import 'package:type_racer/widgets/custom_button.dart';
import 'package:type_racer/widgets/scoreboard.dart';

/// After I finish (live standings) and after the race (final results).
class ResultsView extends StatelessWidget {
  final VoidCallback onHome;
  const ResultsView({super.key, required this.onHome});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final isOver = game.game.isOver;
    final isHost = game.me?.isHost == true;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Scoreboard(myId: game.me?.id ?? ''),
                  const SizedBox(height: 16),
                  ReactionBar(onReact: game.sendReaction),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            children: [
              if (isOver && isHost)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CustomButton(text: 'Play Again', onTap: game.rematch),
                )
              else if (isOver)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Waiting for the host to start a rematch...',
                      style: AppTheme.body(size: 16, color: AppColors.textMuted)),
                ),
              CustomButton(text: 'Back to Home', secondary: true, onTap: onHome),
            ],
          ),
        ),
      ],
    );
  }
}
