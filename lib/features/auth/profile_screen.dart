import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar + meno
            Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.blue.shade50,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? const Icon(Icons.person, size: 36, color: Colors.blue)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.displayName ?? 'Používateľ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 16),

            // Spôsob prihlásenia
            Text(
              'Prihlásený cez',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _providerName(user),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),

            const Spacer(),

            // Odhlásiť sa
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => AuthService.signOut(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text('Odhlásiť sa'),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _providerName(User? user) {
    final providers = user?.providerData.map((p) => p.providerId).toList() ?? [];
    if (providers.contains('google.com')) return 'Google';
    if (providers.contains('facebook.com')) return 'Facebook';
    if (providers.contains('password')) return 'Email a heslo';
    return 'Neznámy';
  }
}