import 'package:flutter/material.dart';
import '../models/laundry_order.dart';

class TrackOrderScreen extends StatelessWidget {
  final LaundryOrder order;

  const TrackOrderScreen({
    super.key,
    required this.order,
  });

  static const red = Color(0xFFE53935);
  static const muted = Color(0xFF626976);

  final List<String> steps = const [
    'Order Placed',
    'Picked Up',
    'In Cleaning',
    'Quality Check',
    'Ready for Collection',
    'Delivered',
  ];

  final List<String> timestamps = const [
    '10 May 2024 09:30 AM',
    '10 May 2024 11:00 AM',
    '11 May 2024 08:45 AM',
    'Pending',
    'Pending',
    'Pending',
  ];

  String formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day} ${months[date.month - 1]} '
        '${date.year}, $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final delivered = order.currentStep == 5;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFFEAEC),
                      foregroundColor: red,
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Track Your Order',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF171C2A),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: red,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                delivered ? 'Delivered' : 'In Progress',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
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
                                    delivered
                                        ? 'Order delivered'
                                        : order.dateCompletion != null
                                            ? formatDate(
                                                order.dateCompletion!)
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

                  // Vertical tracking timeline
                  ...List.generate(steps.length, (index) {
                    final completed = index < order.currentStep;
                    final current = index == order.currentStep;
                    final pending = index > order.currentStep;

                    final Color circleColor = completed
                        ? red
                        : current
                            ? const Color(0xFFFFCDD2)
                            : Colors.white;

                    final Color titleColor =
                        current ? red : const Color(0xFF171C2A);

                    final String timeText =
                        index < order.currentStep
                            ? timestamps[index]
                            : current
                                ? timestamps[index]
                                : 'Pending';

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
                                if (index < steps.length - 1)
                                  Expanded(
                                    child: Container(
                                      width: 3,
                                      color: index < order.currentStep
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
                                  const SizedBox(height: 0),
                                  Text(
                                    steps[index],
                                    style: TextStyle(
                                      fontSize: 19,
                                      fontWeight: current || completed
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                      color: titleColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    timeText,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: muted,
                                    ),
                                  ),
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
                      delivered
                          ? 'Your order has been delivered.'
                          : 'We will notify you when your order is ready',
                      style: const TextStyle(
                        color: red,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}