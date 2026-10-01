import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/providers/game_state_provider.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/utils/player_utils.dart';
import 'package:type_racer/utils/socket_methods.dart';
import 'package:type_racer/utils/sound_service.dart';
import 'package:type_racer/utils/typing_stats.dart';

/// Typing box (only shown while racing). Turns red + shakes when what you
/// typed doesn't match the current word. `typed` is shared with SentenceGame
/// for per-letter colours; `stats` collects accuracy.
class GameTextField extends StatefulWidget {
  final ValueNotifier<String> typed;
  final TypingStats stats;
  const GameTextField({Key? key, required this.typed, required this.stats})
      : super(key: key);

  @override
  State<GameTextField> createState() => _GameTextFieldState();
}

class _GameTextFieldState extends State<GameTextField>
    with SingleTickerProviderStateMixin {
  final SocketMethods _socketMethods = SocketMethods();
  final TextEditingController _wordsController = TextEditingController();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  int _lastLen = 0;

  @override
  void dispose() {
    _shake.dispose();
    _wordsController.dispose();
    super.dispose();
  }

  /// Does `typed` still match the start of the current word?
  bool _isWrong(GameStateProvider game, String typed) {
    if (typed.isEmpty) return false;
    final me = findMe(game.gameState['players']);
    final List words = game.gameState['words'];
    if (me == null || me['currentWordIndex'] >= words.length) return false;
    return !words[me['currentWordIndex']].toString().startsWith(typed);
  }

  void _clear() {
    setState(() {
      _wordsController.text = '';
    });
    widget.typed.value = '';
    _lastLen = 0;
  }

  handleTextChange(String value, GameStateProvider game) {
    if (value.isEmpty) {
      widget.typed.value = '';
      _lastLen = 0;
      return;
    }
    if (value.endsWith(' ')) {
      if (value.trim().isEmpty) {
        _clear(); // just a space: nothing to send
        return;
      }
      widget.stats.record(wrong: false);
      _socketMethods.sendUserInput(value, game.gameState['id']);
      _clear();
      return;
    }
    widget.typed.value = value;
    if (value.length > _lastLen) {
      final wrong = _isWrong(game, value);
      widget.stats.record(wrong: wrong);
      if (wrong) {
        _shake.forward(from: 0);
        SoundService.instance.play('error');
        HapticFeedback.lightImpact();
      }
    }
    _lastLen = value.length;
  }

  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameStateProvider>(context);
    if (findMe(gameData.gameState['players']) == null) {
      return const SizedBox.shrink();
    }

    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ValueListenableBuilder<String>(
            valueListenable: widget.typed,
            builder: (context, t, _) {
              final wrong = _isWrong(gameData, t);
              final border = wrong ? AppColors.red : AppColors.cyan;
              return AnimatedBuilder(
                animation: _shake,
                builder: (context, child) => Transform.translate(
                  offset: Offset(
                    math.sin(_shake.value * math.pi * 6) *
                        8 *
                        (1 - _shake.value),
                    0,
                  ),
                  child: child,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: border.withOpacity(wrong ? 0.45 : 0.15),
                        blurRadius: wrong ? 18 : 10,
                      ),
                    ],
                  ),
                  child: TextFormField(
                    autofocus: true,
                    controller: _wordsController,
                    onChanged: (val) => handleTextChange(val, gameData),
                    cursorColor: border,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 20,
                      color: wrong ? AppColors.red : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type here!',
                      prefixIcon: Icon(
                        wrong
                            ? Icons.error_outline_rounded
                            : Icons.keyboard_rounded,
                        color: border,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: wrong
                              ? AppColors.red
                              : AppColors.cyan.withOpacity(0.15),
                          width: wrong ? 2 : 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: border, width: 2),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
