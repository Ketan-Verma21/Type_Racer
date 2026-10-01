import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Styled input. Look comes from AppTheme.inputDecorationTheme.
class CustomTextfield extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const CustomTextfield({
    Key? key,
    required this.controller,
    required this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTheme.body(size: 18),
      cursorColor: Theme.of(context).colorScheme.primary,
      decoration: InputDecoration(hintText: hintText),
    );
  }
}
