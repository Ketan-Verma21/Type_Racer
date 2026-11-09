import 'package:flutter/material.dart';
import 'package:type_racer/widgets/back_button.dart';
import 'package:type_racer/widgets/game_background.dart';
import 'package:type_racer/widgets/leaderboard_panel.dart';

/// The leaderboard on its own screen (phones; wide screens show it on Home).
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(leading: const MyBackButton()),
      body: GameBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(16, 56, 16, 16),
                child: LeaderboardPanel(fill: true),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
