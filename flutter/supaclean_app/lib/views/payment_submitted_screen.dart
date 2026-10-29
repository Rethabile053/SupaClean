import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/booking_details.dart';
import '../widgets/app_header.dart';
import 'main_shell.dart';

const _red = Color(0xFFEB3838);
const _green = Color(0xFF1E9E5A);
const _ink = Color(0xFF242424);
const _muted = Color(0xFF777777);
const _canvas = Color(0xFFF8F9FB);
const _line = Color(0xFFE8E9EC);

/// Shown once the proof of payment has reached SupaClean. The admin then
/// verifies it, and the customer is notified when it is approved.
class PaymentSubmittedScreen extends StatefulWidget {
  const PaymentSubmittedScreen({
    super.key,
    required this.booking,
    required this.orderNumber,
    required this.amount,
    this.cashOnDelivery = false,
  });

  final BookingDetails booking;
  final String orderNumber;
  final double amount;

  /// Cash orders are paid to the courier, so nothing has been paid or proved
  /// yet. The screen then says the order is confirmed instead.
  final bool cashOnDelivery;

  @override
  State<PaymentSubmittedScreen> createState() => _PaymentSubmittedScreenState();
}

class _PaymentSubmittedScreenState extends State<PaymentSubmittedScreen> {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
  ];

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
  }

  void _trackOrder() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const MainShell(initialIndex: MainShell.ordersTab),
      ),
      (_) => false,
    );
  }

  String get _collection {
    final d = widget.booking.pickupDate;
    return '${d.day} ${_months[d.month - 1]} ${d.year} at '
        '${widget.booking.pickupStart.format(context)}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _trackOrder();
      },
      child: Scaffold(
        backgroundColor: _canvas,
        appBar: const AppHeader(title: 'Done', showBack: false),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
                  children: [
                    Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.5, end: 1),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.elasticOut,
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: Container(
                          width: 104,
                          height: 104,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE5F5EC),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 68,
                              height: 68,
                              decoration: const BoxDecoration(
                                color: _green,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      widget.cashOnDelivery
                          ? 'Your order is confirmed!'
                          : 'Thank you for your payment!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.cashOnDelivery
                          ? 'Please pay the courier in cash when your order '
                              'arrives. We\'ll keep you updated on your order.'
                          : "Your proof has been submitted. We'll verify it "
                              'and keep you updated on your order.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 15, color: _muted, height: 1.4),
                    ),
                    const SizedBox(height: 22),
                    _summaryCard(),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_user_outlined,
                            size: 16, color: _muted),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            widget.cashOnDelivery
                                ? "We'll notify you when your order is on "
                                    'its way.'
                                : "We'll notify you as soon as your payment "
                                    'is verified.',
                            style: const TextStyle(
                                fontSize: 12.5, color: _muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: _line)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _trackOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Track Order',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${widget.orderNumber}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F5EC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.cashOnDelivery ? 'Pay on delivery' : 'Proof received',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _green,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 28, color: _line),
          _row('Payment reference', widget.orderNumber, _ink),
          const SizedBox(height: 12),
          _row(
            widget.cashOnDelivery ? 'Amount due in cash' : 'Amount paid',
            'R${widget.amount.toStringAsFixed(2)}',
            _red,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEAEA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_available_outlined,
                    color: _red, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimated collection arrival',
                        style: TextStyle(fontSize: 12, color: _muted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _collection,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color valueColor) {
    return Row(
      children: [
        Expanded(
          child:
              Text(label, style: const TextStyle(fontSize: 14, color: _muted)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
