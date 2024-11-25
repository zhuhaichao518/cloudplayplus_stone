import 'package:flutter/material.dart';

class MessageBoxManager {
  static final MessageBoxManager _instance = MessageBoxManager._internal();
  BuildContext? _context;

  factory MessageBoxManager() {
    return _instance;
  }

  MessageBoxManager._internal();

  void init(BuildContext context) {
    _context = context;
  }

  void showMessage(String message, String title) {
    if (_context == null) return;

    showDialog(
      context: _context!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
