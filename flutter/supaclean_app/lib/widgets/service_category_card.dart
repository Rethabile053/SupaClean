import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../viewmodels/service_viewmodel.dart';
import 'pressable.dart';

/// Colour-coded service card: a soft tinted background, the service icon
/// in a white circle, the name and a "from R xx" price.
class ServiceCategoryCard extends StatelessWidget {
  const ServiceCategoryCard({
    super.key,
    required this.category,
    required this.tint,
    required this.onTap,
  });

  final ServiceCategory category;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = category.startingPrice;

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.s16),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(category.icon, size: 22, color: AppColors.textDark),
            ),
            const Spacer(),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.bodyStrong,
            ),
            const SizedBox(height: AppSpace.s4),
            Text(
              price == null
                  ? category.description
                  : 'from R${price.toStringAsFixed(0)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.figures(AppText.caption),
            ),
          ],
        ),
      ),
    );
  }
}
