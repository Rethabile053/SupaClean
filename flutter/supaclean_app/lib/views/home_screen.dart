import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/constants.dart';
import '../models/laundry_order.dart';
import '../models/sample_orders.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/service_viewmodel.dart';
import '../widgets/app_card.dart';
import '../widgets/app_header.dart';
import '../widgets/pressable.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_header.dart';
import '../widgets/service_category_card.dart';
import '../widgets/status_badge.dart';
import 'detailed_services_screen.dart';
import 'main_shell.dart';
import 'place_order_screen.dart';
import 'services_screen.dart';
import 'track_order_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final fullName = user?.fullName.trim() ?? '';
    final firstName = fullName.split(' ').first;

    final categories = ServiceViewModel().services;
    final activeOrders = sampleOrders.where((o) => o.isActive).toList()
      ..sort((a, b) => a.dateCompletion.compareTo(b.dateCompletion));
    final reorder = sampleOrders
        .where((o) => !o.isActive && categories.any((c) => c.name == o.service))
        .firstOrNull;

    return Scaffold(
      appBar: const AppHeader(title: 'Home', showBack: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.s16,
            AppSpace.s8,
            AppSpace.s16,
            AppSpace.s24,
          ),
          children: [
            // Greeting and profile shortcut
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting(), style: AppText.caption),
                      const SizedBox(height: AppSpace.s4),
                      Text(
                        firstName.isEmpty ? 'Hi there' : 'Hi, $firstName',
                        style: AppText.display,
                      ),
                    ],
                  ),
                ),
                Pressable(
                  onTap: () => MainShell.switchTab(
                    context,
                    MainShell.profileTab,
                  ),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryTint,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      firstName.isEmpty ? 'U' : firstName[0].toUpperCase(),
                      style: AppText.bodyStrong.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpace.s24),

            // The most useful thing first: where is my order?
            if (activeOrders.isNotEmpty)
              _LiveOrderCard(
                order: activeOrders.first,
                onTap: () =>
                    _push(context, TrackOrderScreen(order: activeOrders.first)),
              )
            else if (sampleOrders.isEmpty)
              _FirstPickupCard(
                onTap: () => _push(context, const ServicesScreen()),
              ),

            const SizedBox(height: AppSpace.s32),

            SectionHeader(
              title: 'Our services',
              actionLabel: 'See all',
              onAction: () => _push(context, const ServicesScreen()),
            ),
            const SizedBox(height: AppSpace.s12),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpace.s12,
              crossAxisSpacing: AppSpace.s12,
              childAspectRatio: 1.25,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var i = 0; i < categories.length && i < 4; i++)
                  ServiceCategoryCard(
                    category: categories[i],
                    tint: AppColors
                        .categoryTints[i % AppColors.categoryTints.length],
                    onTap: () => _push(
                      context,
                      DetailedServicesScreen(category: categories[i].name),
                    ),
                  ),
              ],
            ),

            if (reorder != null) ...[
              const SizedBox(height: AppSpace.s32),
              const SectionHeader(title: 'Order again'),
              const SizedBox(height: AppSpace.s12),
              _ReorderCard(
                order: reorder,
                icon: categories
                    .firstWhere((c) => c.name == reorder.service)
                    .icon,
                onTap: () => _push(
                  context,
                  PlaceOrderScreen(category: reorder.service),
                ),
              ),
            ],

            const SizedBox(height: AppSpace.s32),

            const _PromoBanner(),
          ],
        ),
      ),
    );
  }
}

/// Live status of the order in progress. Dark so it is the first thing
/// the eye lands on; the red progress bar is the screen's one key indicator.
class _LiveOrderCard extends StatelessWidget {
  final LaundryOrder order;
  final VoidCallback onTap;

  const _LiveOrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.s24),
        decoration: BoxDecoration(
          color: AppColors.textDark,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusBadge.order(order.status),
                const Spacer(),
                Text(
                  'Order #${order.orderId}',
                  style: AppText.figures(
                    AppText.caption.copyWith(color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.s16),
            Text(
              order.headline,
              style: AppText.title.copyWith(color: Colors.white),
            ),
            const SizedBox(height: AppSpace.s4),
            Text(
              order.date,
              style: AppText.figures(
                AppText.body.copyWith(color: Colors.white70),
              ),
            ),
            const SizedBox(height: AppSpace.s16),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: (order.currentStep / 5).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpace.s16),
            Row(
              children: [
                Text(
                  'Track order',
                  style: AppText.bodyStrong.copyWith(color: Colors.white),
                ),
                const SizedBox(width: AppSpace.s4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown instead of the live card when the user has no orders yet.
class _FirstPickupCard extends StatelessWidget {
  final VoidCallback onTap;

  const _FirstPickupCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Welcome to SupaClean', style: AppText.title),
          const SizedBox(height: AppSpace.s8),
          const Text(
            'We pick up, clean and deliver to you, right here in '
            'Bloemfontein.',
            style: AppText.body,
          ),
          const SizedBox(height: AppSpace.s24),
          PrimaryButton(text: 'Schedule your first pickup', onPressed: onTap),
        ],
      ),
    );
  }
}

class _ReorderCard extends StatelessWidget {
  final LaundryOrder order;
  final IconData icon;
  final VoidCallback onTap;

  const _ReorderCard({
    required this.order,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.canvas,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: AppColors.textDark),
          ),
          const SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.service, style: AppText.bodyStrong),
                const SizedBox(height: 2),
                Text(order.date, style: AppText.figures(AppText.caption)),
              ],
            ),
          ),
          PrimaryButton(
            text: 'Reorder',
            onPressed: onTap,
            variant: ButtonVariant.secondary,
            expand: false,
          ),
        ],
      ),
    );
  }
}

/// Small and flat, below the things people came to do.
class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.s16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.primaryTint),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_laundry_service_outlined, color: AppColors.primary),
          SizedBox(width: AppSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Let us take care of your laundry',
                  style: AppText.bodyStrong,
                ),
                SizedBox(height: 2),
                Text('Fresh. Clean. On time.', style: AppText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
