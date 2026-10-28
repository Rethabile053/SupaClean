import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/laundry_order.dart';
import '../models/sample_orders.dart';
import '../widgets/app_header.dart';
import 'services_screen.dart';
import 'track_order_screen.dart';

/// Upcoming pickups and deliveries: the user's active orders,
/// soonest first.
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  static const _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  String _time(DateTime date) {
    if (date.hour == 0 && date.minute == 0) return 'Time to be confirmed';
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return 'Expected ready by $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = sampleOrders
        .where((o) => o.isActive && o.dateCompletion != null)
        .toList()
      ..sort((a, b) => a.dateCompletion!.compareTo(b.dateCompletion!));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: const AppHeader(title: 'Schedule'),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                'Your upcoming pickups and deliveries.',
                style: TextStyle(fontSize: 14, color: AppColors.textGrey),
              ),
            ),
            Expanded(
              child: upcoming.isEmpty
                  ? _EmptyState(onPlaceOrder: () => _placeOrder(context))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: upcoming.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) =>
                          _card(context, upcoming[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _placeOrder(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ServicesScreen()),
    );
  }

  Widget _card(BuildContext context, LaundryOrder order) {
    final date = order.dateCompletion!;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TrackOrderScreen(order: order)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '${date.day}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    _months[date.month - 1],
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.service,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Order #${order.orderId} · ${order.status}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _time(date),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textGrey),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onPlaceOrder;

  const _EmptyState({required this.onPlaceOrder});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              size: 56,
              color: AppColors.textGrey,
            ),
            const SizedBox(height: 12),
            const Text(
              'Nothing scheduled',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Place an order and your pickup and delivery will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textGrey),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onPlaceOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Place an order'),
            ),
          ],
        ),
      ),
    );
  }
}
