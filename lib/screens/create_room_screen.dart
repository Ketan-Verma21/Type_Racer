import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/theme/app_theme.dart';
import 'package:type_racer/screens/enter_game.dart';
import 'package:type_racer/widgets/snack.dart';
import 'package:type_racer/widgets/back_button.dart';
import 'package:type_racer/widgets/custom_button.dart';
import 'package:type_racer/widgets/custom_text_field.dart';
import 'package:type_racer/widgets/game_background.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({Key? key}) : super(key: key);

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> with EnterGame {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _create() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showSnack(context, 'Please enter your name.');
      return;
    }
    game.createGame(name);
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
                    border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35)),
                    boxShadow: [
                      BoxShadow(
                          color: AppColors.cyan.withValues(alpha: 0.15),
                          blurRadius: 30),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🏁', style: TextStyle(fontSize: 44)),
                      const SizedBox(height: 8),
                      Text('CREATE ROOM', style: AppTheme.display(size: 28)),
                      SizedBox(height: size.height * 0.04),
                      CustomTextfield(
                          controller: _nameController,
                          hintText: 'Enter your name here'),
                      const SizedBox(height: 30),
                      waiting
                          ? const SpinKitWave(color: AppColors.cyan, size: 36)
                          : CustomButton(text: 'Create', onTap: _create),
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
