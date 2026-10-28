
import 'package:flutter/material.dart';
import '../models/laundry_order.dart';
import '../services/api_client.dart';
import '../services/order_api.dart';
import '../widgets/app_header.dart';
import '../widgets/empty_state.dart';
import 'services_screen.dart';
import 'track_order_screen.dart';

const red = Color(0xFFE53935);
const background = Color(0xFFF7F8FA);
const muted = Color(0xFF626976);

class MyOrdersScreen extends StatefulWidget {
  /// [load] replaces the server call (used by tests).
  const MyOrdersScreen({super.key, this.load});

  final Future<List<LaundryOrder>> Function()? load;

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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TrackOrderScreen(
                                    order: order,
                                  ),
                                ),
                              );
                            },
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
