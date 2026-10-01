import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/theme/app_theme.dart';
import 'package:type_racer/utils/socket_methods.dart';
import 'package:type_racer/widgets/back_button.dart';
import 'package:type_racer/widgets/custom_button.dart';
import 'package:type_racer/widgets/custom_text_field.dart';
import 'package:type_racer/widgets/game_background.dart';

import '../utils/socket_client.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({Key? key}) : super(key: key);

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController _nameController = TextEditingController();
  final SocketClient _socketClient = SocketClient.instance;
  final SocketMethods _socketMethods = SocketMethods();
  bool showSpinner = false;

  @override
  void dispose() {
    super.dispose();
    _nameController.dispose();
  }

  @override
  void initState() {
    _socketMethods.updateGameListener(context);
    _socketMethods.notCorrectGameListener(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return LoaderOverlay(
      child: Scaffold(
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
                      color: AppColors.surface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(24),
                      border:
                      Border.all(color: AppColors.cyan.withOpacity(0.35)),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.cyan.withOpacity(0.15),
                            blurRadius: 30),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🏁', style: TextStyle(fontSize: 44)),
                        const SizedBox(height: 8),
                        Text('CREATE ROOM',
                            style: AppTheme.display(size: 28)),
                        SizedBox(height: size.height * 0.04),
                        CustomTextfield(
                            controller: _nameController,
                            hintText: 'Enter your name here'),
                        const SizedBox(height: 30),
                        showSpinner
                            ? const SpinKitWave(
                            color: AppColors.cyan, size: 36)
                            : CustomButton(
                          text: 'Create',
                          onTap: () {
                            setState(() {
                              showSpinner = true;
                            });
                            _socketMethods.CreateGame(
                                _nameController.text.toString());
                            setState(() {
                              showSpinner = false;
                            });
                          },
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
      ),
    );
  }
}
