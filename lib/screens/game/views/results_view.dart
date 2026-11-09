import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/state/game_controller.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/theme/app_theme.dart';
import 'package:type_racer/ui/layout/breakpoints.dart';
import 'package:type_racer/widgets/chat_panel.dart';
import 'package:type_racer/widgets/custom_button.dart';
import 'package:type_racer/widgets/scoreboard.dart';

/// After I finish (live standings) and after the race (final results).
/// Wide: [scoreboard | what next: Play Again, Home, reactions].
class ResultsView extends StatelessWidget {
  final VoidCallback onHome;
  const ResultsView({super.key, required this.onHome});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameController>();
    final size = ScreenSize.of(context);
    final isOver = game.game.isOver;
    final isHost = game.me?.isHost == true;
    final myId = game.me?.id ?? '';

    final actions = Column(
      mainAxisSize: MainAxisSize.min,
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
                textAlign: TextAlign.center,
                style: AppTheme.body(size: 16, color: AppColors.textMuted)),
          ),
        CustomButton(text: 'Back to Home', secondary: true, onTap: onHome),
      ],
    );
    final reactions = ReactionBar(onReact: game.sendReaction);

    if (size.isCompact) {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(children: [
                  Scoreboard(myId: myId),
                  const SizedBox(height: 16),
                  reactions,
                ]),
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 20), child: actions),
        ],
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: size.maxContentWidth),
        child: Padding(
          padding: EdgeInsets.all(size.gutter),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: SingleChildScrollView(child: Scoreboard(myId: myId, maxWidth: 760)),
              ),
              SizedBox(width: size.gutter),
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [actions, const SizedBox(height: 24), reactions],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
