import 'package:flutter/material.dart';
import '../../../features/map/widgets/departure_board.dart';
import '../../../../data/models/favourite_stop.dart';

class FavouriteCard extends StatelessWidget {
  final FavouriteStop stop;

  const FavouriteCard({super.key, required this.stop});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => DepartureBoard(
            stopId: stop.stopId,
            stopName: stop.stopName,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.favorite_rounded, color: Colors.red, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                stop.stopName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}