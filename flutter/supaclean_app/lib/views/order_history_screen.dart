import 'package:flutter/material.dart';

import '../models/laundry_order.dart';
import '../models/order_draft.dart' show PaymentMethod;
import '../services/order_api.dart';
import '../models/points.dart';
import '../models/reorder_plan.dart';
import '../viewmodels/service_viewmodel.dart';
import '../widgets/app_header.dart';
import 'place_order_screen.dart';

const _red = Color(0xFFEB3838);
const _green = Color(0xFF1E9E5A);
const _ink = Color(0xFF242424);
const _muted = Color(0xFF777777);
const _canvas = Color(0xFFF8F9FB);
const _line = Color(0xFFE8E9EC);

/// A finished order looked back on: what was ordered, how it travelled, what
/// was paid, and a button to order the same things again.
class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({
    super.key,
    required this.order,
    this.services,
    this.lastPaymentMethod,
  });

  final LaundryOrder order;

  /// The services Reorder checks against. Defaults to today's price list.
  final List<ServiceCategory>? services;

  /// Finds how this order was paid, so Reorder can offer the same again.
  /// Defaults to asking the server.
  final Future<PaymentMethod?> Function(String serverId)? lastPaymentMethod;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
  ];

  static String _day(DateTime d) => '${d.day} ${_months[d.month - 1]}';

  static String _money(double amount) => 'R${amount.toStringAsFixed(2)}';

  String get _when {
    final placed = order.placedAt;
    final done = order.completedAt;
    if (placed != null && done != null) {
      return 'Placed ${_day(placed)} · Delivered ${_day(done)}';
    }
    if (done != null) return 'Delivered ${_day(done)}';
    return placed == null ? '' : 'Placed ${_day(placed)}';
  }

  /// Points this order earned: 1 for every R2 paid for the laundry.
  int get _pointsEarned => const PointsSummary(balance: 0).pointsEarned(
        order.itemsTotal + order.pickupFee - order.pointsDiscount,
      );

  Future<void> _reorder(BuildContext context) async {
    final plan = ReorderPlan.of(order, services ?? ServiceViewModel().services);
    final messenger = ScaffoldMessenger.of(context);

    if (!plan.canReorder) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'None of the items on this order can be ordered right now.',
          ),
        ),
      );
      return;
    }

    if (plan.unavailable.isNotEmpty) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Left out, not available: ${plan.unavailable.join(', ')}.'),
        ),
      );
    }

    // Offer the way they paid last time; carry on without it if it cannot be found.
    PaymentMethod? paid;
    final serverId = order.serverId;
    if (serverId != null) {
      try {
        paid = await (lastPaymentMethod ?? OrderApi().paymentMethodUsed)(serverId);
      } catch (_) {}
    }
    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceOrderScreen(
          category: plan.category!,
          initialItems: plan.itemNames,
          initialQuantities: plan.quantities,
          initialPickupOption: plan.pickupOption,
          initialDeliveryOption: plan.deliveryOption,
          initialPaymentMethod: paid,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: const AppHeader(title: 'Order History'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _header(),
                  const SizedBox(height: 20),
                  _heading('What you ordered'),
                  _itemsCard(),
                  if (order.pickupMethod.isNotEmpty ||
                      order.returnMethod.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _heading('How it travelled'),
                    _travelCard(),
                  ],
                  const SizedBox(height: 20),
                  _heading('Payment'),
                  _paymentCard(),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 9, 18, 9),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _line)),
              ),
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  key: const Key('reorder'),
                  onPressed: () => _reorder(context),
                  icon: const Icon(Icons.replay_rounded, size: 20),
                  label: const Text(
                    'Reorder this order',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: _line),
        ),
        child: child,
      );

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      );

  Widget _header() => _card(
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.orderId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  if (_when.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _when,
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F5EC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Completed',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _green,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _itemsCard() => _card(
        order.items.isEmpty
            ? const Text(
                'The items on this order were not recorded.',
                style: TextStyle(fontSize: 12, color: _muted),
              )
            : Column(
                children: [
                  for (final line in order.items)
                    _row(
                      line.name,
                      '${line.quantity} × ${_money(line.unitPrice)}',
                    ),
                ],
              ),
      );

  Widget _travelCard() => _card(
        Column(
          children: [
            if (order.pickupMethod.isNotEmpty)
              _row('Pickup', order.pickupMethod, muted: true),
            if (order.returnMethod.isNotEmpty)
              _row('Return', order.returnMethod, muted: true),
          ],
        ),
      );

  Widget _paymentCard() => _card(
        Column(
          children: [
            _row('Items', _money(order.itemsTotal), muted: true),
            if (order.pickupFee > 0)
              _row('Pickup fee', _money(order.pickupFee), muted: true),
            if (order.deliveryFee > 0)
              _row('Delivery fee', _money(order.deliveryFee), muted: true),
            if (order.pointsDiscount > 0)
              _row('Points discount', '-${_money(order.pointsDiscount)}',
                  muted: true),
            const Divider(height: 22, color: _line),
            _row('Total paid', _money(order.grandTotal), bold: true),
            if (_pointsEarned > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.stars_rounded, size: 16, color: _green),
                  const SizedBox(width: 6),
                  Text(
                    'You earned $_pointsEarned points',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _green,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );

  Widget _row(String label, String value,
      {bool muted = false, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: muted ? _muted : _ink,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              color: bold ? _red : _ink,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
