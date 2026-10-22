import 'dart:async';

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:type_racer/theme/app_colors.dart';
import 'package:type_racer/theme/app_theme.dart';
import 'package:type_racer/utils/room_code.dart';
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
  /// How long we wait for the server before giving up.
  static const Duration _joinTimeout = Duration(seconds: 10);

  final _nameController = TextEditingController();
  final _gameIdController = TextEditingController();
  final SocketMethods _socketMethods = SocketMethods();
  bool _joining = false;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    // stop the spinner when we get into the game or the server says no
    _socketMethods.updateGameListener(context, onEnterGame: _stopSpinner);
    _socketMethods.notCorrectGameListener(context, onError: _stopSpinner);
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _nameController.dispose();
    _gameIdController.dispose();
    super.dispose();
  }

  void _join() {
    final name = _nameController.text.trim();
    final code = normalizeRoomCode(_gameIdController.text);
    if (name.isEmpty) {
      _showError('Please enter your name.');
      return;
    }
    if (!isValidRoomCode(code)) {
      _showError('Room codes are 6 letters or digits, like K7P2QX.');
      return;
    }
    setState(() => _joining = true);
    _socketMethods.JoinGame(code, name);

    _timeout?.cancel();
    _timeout = Timer(_joinTimeout, () {
      if (!mounted || !_joining) return;
      setState(() => _joining = false);
      _showError("The server didn't respond. Please try again.");
    });
  }

  void _stopSpinner() {
    _timeout?.cancel();
    if (mounted && _joining) setState(() => _joining = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: 'Oh Snap',
          message: message,
          contentType: ContentType.warning,
        ),
      ),
    );
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
                        hintText: 'Room code, e.g. K7P2QX',
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [RoomCodeInputFormatter()],
                      ),
                      const SizedBox(height: 30),
                      _joining
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
