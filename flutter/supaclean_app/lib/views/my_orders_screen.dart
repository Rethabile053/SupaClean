import 'package:flutter/material.dart';
import '../models/laundry_order.dart';
import '../models/sample_orders.dart';
import 'services_screen.dart';
import 'track_order_screen.dart';

const red = Color(0xFFE53935);
const background = Color(0xFFF7F8FA);
const muted = Color(0xFF626976);

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  int selectedTab = 0;

  final List<LaundryOrder> orders = sampleOrders;

  List<LaundryOrder> get filteredOrders {
    if (selectedTab == 0) {
      return orders.where((o) =>
          o.status != 'Completed' &&
          o.status != 'Delivered' &&
          o.status != 'Cancelled').toList();
    }

    if (selectedTab == 1) {
      return orders.where((o) =>
          o.status == 'Completed' ||
          o.status == 'Delivered').toList();
    }

    return orders.where((o) => o.status == 'Cancelled').toList();
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
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  Text(
                    'My Orders',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF171C2A),
                    ),
                  ),
                ],
              ),
            ),

            // Active, Completed and Cancelled filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  tabButton('Active', 0),
                  const SizedBox(width: 10),
                  tabButton('Completed', 1),
                  const SizedBox(width: 10),
                  tabButton('Cancelled', 2),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: filteredOrders.isEmpty
                  ? const Center(
                      child: Text('No orders in this category'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          20, 0, 20, 20),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: const Color(0xFFE3E5E9),
                              width: 1.5,
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
                                              fontSize: 21,
                                              fontWeight:
                                                  FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            order.service,
                                            style: const TextStyle(
                                              color: muted,
                                              fontSize: 17,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 9,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor(order.status)
                                            .withValues(
                                          alpha: order.status ==
                                                  'In Cleaning' ||
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
                                              order.status),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 16),
                                  child: Divider(height: 1),
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_month,
                                      color: Color(0xFF9AA0AB),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        order.date,
                                        style: const TextStyle(
                                          fontSize: 16,
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

            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE3E5E9)),
                ),
              ),
              width: double.infinity,
              child: SizedBox(
                height: 68,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ServicesScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    '+ Place New Order',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
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
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? red : Colors.white,
            borderRadius: BorderRadius.circular(35),
            border: Border.all(
              color: selected
                  ? red
                  : const Color(0xFFE3E5E9),
              width: 1.5,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: selected ? Colors.white : muted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}