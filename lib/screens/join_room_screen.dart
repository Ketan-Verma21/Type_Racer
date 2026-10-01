import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/theme/app_theme.dart';
import 'package:type_racer/utils/socket_methods.dart';
import 'package:type_racer/widgets/back_button.dart';
import 'package:type_racer/widgets/game_background.dart';

import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({Key? key}) : super(key: key);

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _nameController = TextEditingController();
  final _gameIdController = TextEditingController();
  final SocketMethods _socketMethods = SocketMethods();

  @override
  void initState() {
    _socketMethods.updateGameListener(context);
    _socketMethods.notCorrectGameListener(context);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _nameController.dispose();
    _gameIdController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
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
                    color: AppColors.surface.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(24),
                    border:
                    Border.all(color: AppColors.magenta.withOpacity(0.35)),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.magenta.withOpacity(0.15),
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
                          hintText: 'Enter game id here'),
                      const SizedBox(height: 30),
                      CustomButton(
                        text: 'Join',
                        secondary: true,
                        onTap: () => _socketMethods.JoinGame(
                          _gameIdController.text.toString(),
                          _nameController.text.toString(),
                        ),
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
