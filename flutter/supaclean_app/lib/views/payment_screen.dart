import 'package:flutter/material.dart';

import '../models/booking_details.dart';
import '../models/order_draft.dart';
import '../services/api_client.dart';
import '../services/checkout_service.dart';
import '../widgets/app_header.dart';

import 'bank_transfer.dart';
import 'cash_on_delivery.dart';
import 'main_shell.dart';
import 'payment_submitted_screen.dart';

export '../models/order_draft.dart' show PaymentMethod;

const payRed = Color(0xFFEB3838);
const payInk = Color(0xFF242424);
const payMuted = Color(0xFF777777);
const payCanvas = Color(0xFFF8F9FB);
const payLine = Color(0xFFE8E9EC);

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.booking,
    this.checkout,
    this.orderNumber = '1024',
    this.serviceName = 'Wash & Fold (3 kg)',
    this.servicePrice = 75,
    this.pickupFee = 15,
    this.deliveryFee = 15,
  });

  final BookingDetails booking;
  final CheckoutService? checkout;
  final String orderNumber;
  final String serviceName;
  final double servicePrice;
  final double pickupFee;
  final double deliveryFee;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod method = PaymentMethod.eft;
  bool processing = false;

  /// 10% off the items when delivery is more than a day after pickup. Worked
  /// out per line when the order is known, so it matches what is sent to the
  /// server to the cent.
  double get discount {
    final booking = widget.booking;
    if (!booking.qualifiesForDiscount) return 0;
    final lines = widget.checkout?.draft.lines;
    if (lines == null) {
      return widget.servicePrice - booking.discounted(widget.servicePrice);
    }
    return lines.fold<double>(
      0,
      (sum, line) =>
          sum + (line.unitPrice - booking.discounted(line.unitPrice)) * line.quantity,
    );
  }

  double get total =>
      widget.servicePrice - discount + widget.pickupFee + widget.deliveryFee;

  String date(DateTime d) => '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  String slot(TimeOfDay start, TimeOfDay end) =>
      '${start.format(context)} - ${end.format(context)}';

  void openConfirmation(String orderNumber, {bool cashOnDelivery = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentSubmittedScreen(
          booking: widget.booking,
          orderNumber: orderNumber,
          amount: total,
          cashOnDelivery: cashOnDelivery,
        ),
      ),
    );
  }

  Future<void> pay() async {
    if (processing) return;

    setState(() => processing = true);

    try {
      switch (method) {
        case PaymentMethod.eft:
        case PaymentMethod.card:
          // Create the order before opening the bank transfer screen.
          final placed = await widget.checkout?.createOrder();

          if (!mounted) return;

          final orderNumber = placed?.orderNumber ?? widget.orderNumber;

          // Bank details and proof upload; Continue sends the proof and
          // opens the payment submitted screen.
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BankTransferPayment(
                orderId: orderNumber,
                amount: total,
                onContinue: (proof) async {
                  await widget.checkout?.pay(PaymentMethod.eft, proof: proof);
                  if (mounted) openConfirmation(orderNumber);
                },
              ),
            ),
          );
          break;

        case PaymentMethod.cash:
          // Create the cash order before opening its confirmation screen.
          final placed = await widget.checkout?.pay(
            PaymentMethod.cash,
          );

          if (!mounted) return;

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CashOnDeliveryScreen(
                orderId: placed?.orderNumber ?? widget.orderNumber,
                amountDue: total,
                deliveryOtp: '1234', // Demo only.
                // The cash payment is already recorded; the driver confirms
                // the cash on their side, so the customer just carries on.
                onContinue: () => openConfirmation(
                  placed?.orderNumber ?? widget.orderNumber,
                  cashOnDelivery: true,
                ),
              ),
            ),
          );
          break;
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ApiException
                ? e.message
                : 'Unable to continue with payment: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => processing = false);
      }
    }
  }

  Widget paymentChoice({
    required String title,
    required String subtitle,
    required IconData icon,
    required PaymentMethod value,
  }) {
    final selected = method == value;

    return InkWell(
      onTap: () => setState(() => method = value),
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected ? payRed : payLine,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEAEA),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: payRed),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: payMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? payRed : payMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget summaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: payMuted,
              ),
            ),
          ),
          Text(
            amount < 0
                ? '-R${(-amount).toStringAsFixed(2)}'
                : 'R${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: payCanvas,
      appBar: const AppHeader(title: 'Payment'),
      bottomNavigationBar: const FlowBottomNav(
        selected: MainShell.scheduleTab,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: payLine),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Order #${widget.orderNumber}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.local_laundry_service,
                              color: payRed,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        summaryRow(
                          widget.serviceName,
                          widget.servicePrice,
                        ),
                        if (discount > 0)
                          summaryRow('Discount (10%)', -discount),
                        summaryRow('Pickup Fee', widget.pickupFee),
                        summaryRow('Delivery Fee', widget.deliveryFee),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Total Amount',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              'R${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 17,
                                color: payRed,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Booking Details',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: payLine),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pickup: ${date(widget.booking.pickupDate)}'
                          ' • ${slot(widget.booking.pickupStart, widget.booking.pickupEnd)}',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Delivery: ${date(widget.booking.deliveryDate)}'
                          ' • ${slot(widget.booking.deliveryStart, widget.booking.deliveryEnd)}',
                        ),
                        const SizedBox(height: 8),
                        Text('Address: ${widget.booking.address}'),
                        if (widget.booking.instructions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Instructions: ${widget.booking.instructions}',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Choose Payment Method',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  paymentChoice(
                    title: 'EFT / Bank Transfer',
                    subtitle: 'Pay using your banking app',
                    icon: Icons.account_balance_outlined,
                    value: PaymentMethod.eft,
                  ),
                  const SizedBox(height: 10),
                  paymentChoice(
                    title: 'Cash on Delivery',
                    subtitle: 'Pay the courier when your order arrives',
                    icon: Icons.payments_outlined,
                    value: PaymentMethod.cash,
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: payLine),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          method == PaymentMethod.cash
                              ? Icons.local_shipping_outlined
                              : Icons.account_balance_outlined,
                          color: payRed,
                          size: 27,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                method == PaymentMethod.cash
                                    ? 'Cash on Delivery'
                                    : 'EFT / Bank Transfer',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                method == PaymentMethod.cash
                                    ? 'Pay when your order is delivered.'
                                    : 'View SupaClean bank details on the next screen.',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: payMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 15,
                        color: payMuted,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Please verify your payment details before paying.',
                          style: TextStyle(
                            fontSize: 10,
                            color: payMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: payLine),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: processing ? null : pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: payRed,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: processing
                      ? const SizedBox(
                          height: 21,
                          width: 21,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          method == PaymentMethod.cash
                              ? 'Continue • R${total.toStringAsFixed(2)}'
                              : 'Pay R${total.toStringAsFixed(2)}',
                          style: const TextStyle(
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
}
