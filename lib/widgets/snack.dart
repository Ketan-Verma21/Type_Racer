import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';

enum SnackType { success, warning, failure }

/// The app's floating snackbar. Does nothing if there is no ScaffoldMessenger.
void showSnack(BuildContext context, String message,
    {String title = 'Oh Snap', SnackType type = SnackType.warning}) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: switch (type) {
          SnackType.success => ContentType.success,
          SnackType.warning => ContentType.warning,
          SnackType.failure => ContentType.failure,
        },
      ),
    ),
  );
}
