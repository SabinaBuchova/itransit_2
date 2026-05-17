import 'package:flutter/material.dart';

class LoginPrompt {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Potrebné prihlásenie'),
        content: const Text(
          'Táto funkcia je dostupná len pre prihlásených používateľov.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Neskôr'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Prihlásiť sa'),
          ),
        ],
      ),
    );
  }
}