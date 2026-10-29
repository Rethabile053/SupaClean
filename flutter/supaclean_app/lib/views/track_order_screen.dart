import 'dart:async';

import 'package:flutter/material.dart';

import '../models/laundry_order.dart';
import '../services/order_api.dart';
import '../widgets/app_header.dart';

/// Follows one order through cleaning to delivery. The stage comes from the
/// status the admin sets in SupaClean's admin site, so the screen asks the
/// server again when it opens, every [refreshEvery] while it is open, and
/// when the customer pulls down.
class TrackOrderScreen extends StatefulWidget {
  final LaundryOrder order;

  /// Replaces the server call (used by tests).
  final Future<LaundryOrder> Function()? load;

  /// How often to check for a new status while open. Null turns it off.
  final Duration? refreshEvery;

  const TrackOrderScreen({
    super.key,
    required this.order,
    this.load,
    this.refreshEvery = const Duration(seconds: 30),
  });

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  static const red = Color(0xFFE53935);
  static const muted = Color(0xFF626976);

  static const _trackingSteps = [
    'Order Placed',
    'In Cleaning',
    'Ready for Collection',
    'Delivered',
  ];

  late LaundryOrder order = widget.order;
  bool updatesFailed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    final every = widget.refreshEvery;
    if (every != null) _timer = Timer.periodic(every, (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Fetches the order again so a status the admin changed shows up.
  Future<void> _refresh() async {
    final id = order.serverId;
    if (widget.load == null && id == null) return;

    try {
      final fresh = widget.load != null
          ? await widget.load!()
          : await OrderApi().order(id!);
      if (!mounted) return;
      setState(() {
        order = fresh;
        updatesFailed = false;
      });
    } catch (_) {
      // Keep showing the last known status.
      if (mounted) setState(() => updatesFailed = true);
    }
  }

  String formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '${local.day} ${months[local.month - 1]} '
        '${local.year}, $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDelivered = order.status == 'Completed' || order.status == 'Delivered';
    final isCancelled = order.status == 'Cancelled';
    final step = order.currentStep;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const AppHeader(title: 'Track Your Order'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: red,
                onRefresh: _refresh,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                                  child: Text(
                                    order.status,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    if (isCancelled)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE6E6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'This order has been cancelled. Please contact SupaClean if you need help.',
                          style: TextStyle(
                            color: Color(0xFFB3261E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      // Vertical tracking timeline
                      ...List.generate(_trackingSteps.length, (index) {
                        // A delivered order has finished every step.
                        final completed =
                            index < step || (isDelivered && index == step);
                        final current = index == step && !isDelivered;
                        final pending = index > step;

                        final stage = index == 2 &&
                                order.status == 'Out for Delivery'
                            ? 'Out for Delivery'
                            : _trackingSteps[index];

                        final stamp = order.stepTimes[index];

                        final Color circleColor = completed
                            ? red
                            : current
                                ? const Color(0xFFFFCDD2)
                                : Colors.white;

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
                                    if (index < _trackingSteps.length - 1)
                                      Expanded(
                                        child: Container(
                                          width: 3,
                                          color: index < step
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
                                      Text(
                                        stage,
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: current || completed
                                              ? FontWeight.w700
                                              : FontWeight.w400,
                                          color: current
                                              ? red
                                              : const Color(0xFF171C2A),
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      Text(
                                        timeText,
                                        style: const TextStyle(
                                          fontSize: 13,
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
                    if (updatesFailed) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Live updates are temporarily unavailable. Pull to refresh the screen.',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
