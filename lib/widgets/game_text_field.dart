import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:type_racer/providers/game_state_provider.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/utils/player_utils.dart';
import 'package:type_racer/utils/socket_methods.dart';
import 'package:type_racer/widgets/custom_button.dart';

/// Typing box. Turns red + shakes when what you typed doesn't match the
/// current word. `typed` is shared with SentenceGame for per-letter colours.
class GameTextField extends StatefulWidget {
  final ValueNotifier<String> typed;
  const GameTextField({Key? key, required this.typed}) : super(key: key);

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
  bool isBtn = true;
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

  handleTextChange(String value, GameStateProvider game) {
    if (value.isEmpty) {
      widget.typed.value = '';
      _lastLen = 0;
      return;
    }
    if (value.endsWith(' ')) {
      _socketMethods.sendUserInput(value, game.gameState['id']);
      setState(() {
        _wordsController.text = '';
      });
      widget.typed.value = '';
      _lastLen = 0;
      return;
    }
    widget.typed.value = value;
    // shake only when a new wrong letter is added
    if (_isWrong(game, value) && value.length > _lastLen) {
      _shake.forward(from: 0);
    }
    _lastLen = value.length;
  }

  handleStart(GameStateProvider game, dynamic me) {
    _socketMethods.startTimer(me['_id'], game.gameState['id']);
    setState(() {
      isBtn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameData = Provider.of<GameStateProvider>(context);
    final me = findMe(gameData.gameState['players']);
    if (me == null) return const SizedBox.shrink();
    final waiting = gameData.gameState['isJoin'] == true;

    if (me['isPartyLeader'] && isBtn) {
      return Center(
        heightFactor: 1,
        child: CustomButton(
            text: 'Start', onTap: () => handleStart(gameData, me)),
      );
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
                    readOnly: waiting,
                    controller: _wordsController,
                    onChanged: (val) => handleTextChange(val, gameData),
                    cursorColor: border,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 20,
                      color: wrong ? AppColors.red : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: waiting
                          ? 'Waiting for the race to start...'
                          : 'Type here!',
                      prefixIcon: Icon(
                        wrong
                            ? Icons.error_outline_rounded
                            : (waiting
                            ? Icons.hourglass_top_rounded
                            : Icons.keyboard_rounded),
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
