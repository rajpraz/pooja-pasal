import 'package:flutter/material.dart';

/// Shows a short message at the bottom of the screen (themed, floating
/// snackbar), replacing any message already showing. The one way pages
/// give feedback, so every message looks the same.
void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
