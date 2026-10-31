
import 'package:flutter/material.dart';
import '../models/laundry_order.dart';
import '../services/api_client.dart';
import '../services/order_api.dart';
import '../widgets/app_header.dart';
import '../widgets/empty_state.dart';
import 'order_history_screen.dart';
import 'services_screen.dart';
import 'track_order_screen.dart';

const red = Color(0xFFE53935);
const background = Color(0xFFF7F8FA);
const muted = Color(0xFF626976);

class MyOrdersScreen extends StatefulWidget {
  /// [load] replaces the server call (used by tests).
  const MyOrdersScreen({super.key, this.load, this.cancel});

  final Future<List<LaundryOrder>> Function()? load;

  /// Replaces the server call that cancels an order (used by tests).
  final Future<void> Function(String orderId)? cancel;

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  int selectedTab = 0;

  List<LaundryOrder> orders = const [];
  bool loading = true;
  Object? error;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  /// Fetches the signed-in customer's orders from the server.
  Future<void> _reload() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }

    try {
      final loaded = widget.load != null
          ? await widget.load!()
          : await OrderApi().myOrders();
      if (!mounted) return;
      setState(() {
        orders = loaded;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e;
        loading = false;
      });
    }
  }

  void _trackOrder(LaundryOrder order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TrackOrderScreen(order: order)),
    );
  }

  void _viewHistory(LaundryOrder order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderHistoryScreen(order: order)),
    );
  }

  /// A finished order offers a choice, track it or look back on it; any
  /// other order goes straight to tracking.
  Future<void> _openOrder(LaundryOrder order) async {
    if (!order.isCompleted) {
      _trackOrder(order);
      return;
    }

    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${order.orderId}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'What would you like to see?',
                style: TextStyle(fontSize: 13, color: muted),
              ),
              const SizedBox(height: 14),
              _choiceTile(
                key: const Key('choice-track'),
                icon: Icons.local_shipping_outlined,
                title: 'Track order',
                subtitle: 'See each step this order went through',
                value: 'track',
              ),
              const SizedBox(height: 10),
              _choiceTile(
                key: const Key('choice-history'),
                icon: Icons.receipt_long_outlined,
                title: 'Order history',
                subtitle: 'What you ordered, what you paid, and reorder',
                value: 'history',
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || choice == null) return;
    if (choice == 'track') _trackOrder(order);
    if (choice == 'history') _viewHistory(order);
  }

  Widget _choiceTile({
    required Key key,
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.pop(context, value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E5E9)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEAEA),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: red),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: muted),
          ],
        ),
      ),
    );
  }

  /// Asks the customer to confirm, then cancels the order on the server.
  Future<void> _cancelOrder(LaundryOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: Text(
          'Order ${order.orderId} will be cancelled. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep order'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cancel order',
              style: TextStyle(color: red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final id = order.serverId;
    String message;
    try {
      if (widget.cancel != null) {
        await widget.cancel!(id ?? order.orderId);
      } else if (id != null) {
        await OrderApi().cancelOrder(id);
      }
      message = 'Order ${order.orderId} has been cancelled.';
    } on ApiException catch (e) {
      message = e.message;
    } catch (_) {
      message = 'We could not cancel the order. Please try again.';
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    await _reload();
  }

  List<LaundryOrder> get filteredOrders {
    if (selectedTab == 0) {
      return orders
          .where((o) =>
              o.status != 'Completed' &&
              o.status != 'Delivered' &&
              o.status != 'Cancelled')
          .toList();
    }

    if (selectedTab == 1) {
      return orders
          .where((o) =>
              o.status == 'Completed' ||
              o.status == 'Delivered')
          .toList();
    }

    return orders
        .where((o) => o.status == 'Cancelled')
        .toList();
  }

  Color statusColor(String status) {
    if (status == 'In Cleaning' || status == 'In Progress') {
      return red;
    }

    if (status == 'Completed') {
      return const Color(0xFFE7F5E8);
    }

    return const Color(0xFFE6E7EB);
  }

  Color statusTextColor(String status) {
    if (status == 'In Cleaning' || status == 'In Progress') {
      return red;
    }

    if (status == 'Completed') {
      return const Color(0xFF2E7D32);
    }

    return const Color(0xFF505866);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: const AppHeader(title: 'My Orders'),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // Active, Completed and Cancelled tabs.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  tabButton('Active', 0),
                  const SizedBox(width: 8),
                  tabButton('Completed', 1),
                  const SizedBox(width: 8),
                  tabButton('Cancelled', 2),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Orders list.
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(color: red),
                    )
                  : error != null
                      ? ErrorState(
                          message: error is ApiException
                              ? (error as ApiException).message
                              : 'We could not load your orders. Please '
                                  'try again.',
                          onRetry: _reload,
                        )
                      : RefreshIndicator(
                          color: red,
                          onRefresh: _reload,
                          child: filteredOrders.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: const [
                                    SizedBox(height: 120),
                                    Center(
                                      child:
                                          Text('No orders in this category'),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        20,
                      ),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFE3E5E9),
                              width: 1.2,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _openOrder(order),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Order #${order.orderId}',
                                            style: const TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            order.service,
                                            style: const TextStyle(
                                              color: muted,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 11,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor(order.status)
                                            .withValues(
                                          alpha:
                                              order.status == 'In Cleaning' ||
                                                      order.status ==
                                                          'In Progress'
                                                  ? 0.12
                                                  : 1,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                        order.status,
                                        style: TextStyle(
                                          color: statusTextColor(
                                            order.status,
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  child: Divider(height: 1),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_month,
                                      color: Color(0xFF9AA0AB),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        order.date,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: muted,
                                        ),
                                      ),
                                    ),
                                    // Only until we have collected the laundry.
                                    if (order.canCancel)
                                      OutlinedButton(
                                        onPressed: () => _cancelOrder(order),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: red,
                                          side: const BorderSide(color: red),
                                          shape: const StadiumBorder(),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        child: const Text(
                                          'Cancel order',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                        ),
            ),

            // Place New Order button matching the Payment screen.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 9, 18, 9),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFE8E9EC),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ServicesScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEB3838),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    '+ Place New Order',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget tabButton(String title, int index) {
    final selected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? red : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? red : const Color(0xFFE3E5E9),
              width: 1.2,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.white : muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
