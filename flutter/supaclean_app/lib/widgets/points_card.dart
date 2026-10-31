import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../services/points_store.dart';
import '../views/points_screen.dart';

/// The balance on Home. Hidden until the server has told us the points, so a
/// phone that can't reach the server shows nothing rather than an error.
class PointsCard extends StatelessWidget {
  const PointsCard({super.key, this.store});

  /// Defaults to the shared store; tests pass their own.
  final PointsStore? store;

  @override
  Widget build(BuildContext context) {
    final points = store ?? PointsStore.instance;
    return ListenableBuilder(
      listenable: points,
      builder: (context, _) {
        final summary = points.summary;
        if (summary == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 18),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PointsScreen(store: store)),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0xFFFFEEEE),
                    child: Icon(Icons.stars_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${summary.balance} points '
                          '(R${summary.balanceValue.toStringAsFixed(0)})',
                          key: const Key('home-points'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Earn more on every delivered order',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textGrey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
