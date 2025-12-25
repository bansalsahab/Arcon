import 'dart:developer' as developer;
import 'package:flutter/material.dart';

class Notifier {
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  static void success(String message) {
    _log('SUCCESS', message);
    _show(message, background: Colors.green.shade600, icon: Icons.check_circle_outline);
  }

  static void info(String message) {
    _log('INFO', message);
    _show(message, background: Colors.blueGrey.shade600, icon: Icons.info_outline);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log('ERROR', message, error: error, stackTrace: stackTrace);
    _show(message, background: Colors.red.shade600, icon: Icons.error_outline);
  }

  static void _show(String message, {required Color background, IconData? icon}) {
    final state = messengerKey.currentState;
    if (state == null) return;
    state.clearSnackBars();
    state.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) Icon(icon, color: Colors.white),
            if (icon != null) const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: background,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static void _log(String level, String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: 'Notifier:$level', error: error, stackTrace: stackTrace);
  }
}
