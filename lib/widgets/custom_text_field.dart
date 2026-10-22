import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Styled input. Look comes from AppTheme.inputDecorationTheme.
class CustomTextfield extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const CustomTextfield({
    Key? key,
    required this.controller,
    required this.hintText,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTheme.body(size: 18),
      cursorColor: Theme.of(context).colorScheme.primary,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(hintText: hintText),
    );
  }
}
