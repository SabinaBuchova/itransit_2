import 'package:flutter/material.dart';
import '../../../data/services/favourite_service.dart';
import '../../../data/models/favourite_stop.dart';
import '../../../features/auth/auth_service.dart';
import 'widgets/favourite_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isAnonymous = AuthService.isAnonymous;

    return Scaffold(
      appBar: AppBar(
        title: const Text('iTransit'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: isAnonymous ? _AnonymousHome() : _LoggedInHome(),
    );
  }
}

class _AnonymousHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border_rounded,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'Obľúbené zastávky',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Prihlás sa a ulož si obľúbené zastávky pre rýchly prístup.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoggedInHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FavouriteStop>>(
      stream: FavouritesService.favouritesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final favourites = snapshot.data ?? [];

        if (favourites.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border_rounded,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'Žiadne obľúbené zastávky',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Klikni na zastávku na mape a stlač srdce.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: favourites.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => FavouriteCard(stop: favourites[i]),
        );
      },
    );
  }
}