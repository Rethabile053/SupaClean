import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/laundry_order.dart';
import '../widgets/app_header.dart';

class TrackOrderScreen extends StatelessWidget {
  final LaundryOrder order;

  const TrackOrderScreen({
    super.key,
    required this.order,
  });

  static const red = Color(0xFFE53935);
  static const muted = Color(0xFF626976);



  String formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '${local.day} ${months[local.month - 1]} '
        '${local.year}, $hour:$minute $period';
  }

  DateTime? _timestampForStep(LaundryOrder currentOrder, String stage) {
    final eventStatus = currentOrder.status.toLowerCase();
    if (stage == 'Order Placed') {
      return DateTime.tryParse(currentOrder.date);
    }
    if ((stage == 'In Cleaning' && eventStatus == 'in progress') ||
        (stage == 'Ready for Collection' &&
            (eventStatus == 'completed' || eventStatus == 'ready for collection')) ||
        (stage == 'Delivered' && eventStatus == 'delivered')) {
      return currentOrder.dateCompletion;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LaundryOrder?>(
        stream: null,
      initialData: order,
      builder: (context, snapshot) {
        final liveOrder = snapshot.data ?? order;
        final isDelivered = liveOrder.status.toLowerCase() == 'delivered';
        final isCancelled = liveOrder.status.toLowerCase() == 'cancelled';
        const trackingSteps = [
          'Order Placed',
          'In Cleaning',
          'Ready for Collection',
          'Delivered',
        ];
;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const AppHeader(title: 'Track Your Order'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  // Order summary card
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE9EC),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: const Color(0xFFF9CDD3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Order #${order.orderId}',
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: red,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(liveOrder.status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                            ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: Color(0xFFF4C9D0)),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: red,
                              size: 30,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Date of completion',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isDelivered
                                        ? 'Order delivered'
                                        : liveOrder.dateCompletion != null
                                            ? formatDate(
                                                liveOrder.dateCompletion!)
                                            : 'Awaiting completion estimate',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 42),

                  const Text(
                    'Detailed Progress',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 24),
                  if (isCancelled)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: const Color(0xFFFFE6E6), borderRadius: BorderRadius.circular(12)),
                          child: const Text('This order has been cancelled. Please contact SupaClean if you need help.', style: TextStyle(color: Color(0xFFB3261E), fontWeight: FontWeight.w600)),
                        )
                      else

                  // Vertical tracking timeline
                  ...List.generate(trackingSteps.length, (index) {
                    final stage = trackingSteps[index];
                    final completed = index < liveOrder.currentStep;
                    final current = index == liveOrder.currentStep;
                    final pending = index > liveOrder.currentStep;
                    final stamp = _timestampForStep(liveOrder, stage);

                    final Color circleColor = completed
                        ? red
                        : current
                            ? const Color(0xFFFFCDD2)
                            : Colors.white;

                    final Color titleColor =
                        current ? red : const Color(0xFF171C2A);

                    final String timeText = stamp != null
                        ? formatDate(stamp)
                              : current
                                  ? 'Current status'
                                  : pending
                                      ? 'Pending'
                                      : 'Status time not recorded';

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 42,
                            child: Column(
                              children: [
                                Container(
                                  width: current ? 40 : 22,
                                  height: current ? 40 : 22,
                                  decoration: BoxDecoration(
                                    color: circleColor,
                                    shape: BoxShape.circle,
                                    border: pending
                                        ? Border.all(
                                            color: const Color(0xFFE2E4E8),
                                            width: 3,
                                          )
                                        : null,
                                  ),
                                  child: completed
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 15,
                                        )
                                      : null,
                                ),
                                if (index < trackingSteps.length - 1)
                                  Expanded(
                                    child: Container(
                                      width: 3,
                                      color: index < liveOrder.currentStep
                                          ? red
                                          : const Color(0xFFE2E4E8),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 18),

                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 30),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(stage, style: TextStyle(fontSize: 17, fontWeight: current || completed ? FontWeight.w700 : FontWeight.w400, color: current ? red : const Color(0xFF171C2A))),
                                        const SizedBox(height: 7),
                                        Text(timeText, style: const TextStyle(fontSize: 13, color: muted)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE9EC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                        isCancelled
                          ? 'Your order is cancelled.'
                          : isDelivered
                            ? 'Your order has been delivered.'
                            : 'We will notify you when your order is ready',
                      style: const TextStyle(
                        color: red,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                   if (snapshot.hasError) ...[
                        const SizedBox(height: 10),
                        const Text('Live updates are temporarily unavailable. Pull to refresh the screen.', style: TextStyle(color: muted, fontSize: 12)),
                ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  },
    );
  }
}