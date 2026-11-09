import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/theme/app_theme.dart';
import 'package:type_racer/domain/room_code.dart';
import 'package:type_racer/widgets/room_code_input_formatter.dart';
import 'package:type_racer/screens/enter_game.dart';
import 'package:type_racer/widgets/snack.dart';
import 'package:type_racer/widgets/back_button.dart';
import 'package:type_racer/widgets/game_background.dart';

import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({Key? key}) : super(key: key);

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> with EnterGame {
  final _nameController = TextEditingController();
  final _gameIdController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _gameIdController.dispose();
    super.dispose();
  }

  void _join() {
    final name = _nameController.text.trim();
    final code = normalizeRoomCode(_gameIdController.text);
    if (name.isEmpty) {
      showSnack(context, 'Please enter your name.');
      return;
    }
    if (!isValidRoomCode(code)) {
      showSnack(context, 'Room codes are 6 letters or digits, like K7P2QX.');
      return;
    }
    game.joinGame(code, name);
    startWaiting();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: const MyBackButton(),
      ),
      body: GameBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: AppColors.magenta.withValues(alpha: 0.35)),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.magenta.withValues(alpha: 0.15),
                          blurRadius: 30),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🚦', style: TextStyle(fontSize: 44)),
                      const SizedBox(height: 8),
                      Text('JOIN ROOM', style: AppTheme.display(size: 28)),
                      SizedBox(height: size.height * 0.04),
                      CustomTextfield(
                          controller: _nameController,
                          hintText: 'Enter your name here'),
                      const SizedBox(height: 15),
                      CustomTextfield(
                        controller: _gameIdController,
                        hintText: 'Room code, e.g. K7P2QX',
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [RoomCodeInputFormatter()],
                      ),
                      const SizedBox(height: 30),
                      waiting
                          ? const SpinKitWave(color: AppColors.magenta, size: 36)
                          : CustomButton(
                              text: 'Join',
                              secondary: true,
                              onTap: _join,
                            ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.15, curve: Curves.easeOut),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
