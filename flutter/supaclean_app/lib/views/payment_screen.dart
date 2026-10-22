
import 'package:flutter/material.dart';
import 'date_time_screen.dart';
import 'bank_transfer.dart';
import 'card_payment.dart';
import 'cash_on_delivery.dart';

const payRed = Color(0xFFEB3838);
const payInk = Color(0xFF242424);
const payMuted = Color(0xFF777777);
const payCanvas = Color(0xFFF8F9FB);
const payLine = Color(0xFFE8E9EC);

enum PaymentMethod { card, eft, cash }

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.booking,
    required this.onPay,
    required this.onNavigate,
    this.orderNumber = '1024',
    this.serviceName = 'Wash & Fold (3 kg)',
    this.servicePrice = 75,
    this.pickupFee = 15,
    this.deliveryFee = 15,
  });

  final BookingDetails booking;
  final Future<void> Function(PaymentMethod method, double total) onPay;
  final ValueChanged<String> onNavigate;
  final String orderNumber;
  final String serviceName;
  final double servicePrice;
  final double pickupFee;
  final double deliveryFee;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod method = PaymentMethod.card;
  bool processing = false;
  String? value;
  double get total =>
      widget.servicePrice + widget.pickupFee + widget.deliveryFee;

  String date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  String slot(TimeOfDay a, TimeOfDay b) =>
      '${a.format(context)} - ${b.format(context)}';


Future<void> pay() async {
  if (processing) return;

  setState(() => processing = true);

  try {
    switch (method) {
      case PaymentMethod.card:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CardPaymentScreen(
              orderId: widget.orderNumber,
              amount: total,
              onStartSecureCheckout: () async {
                // Connect your secure payment gateway here.
              },
            ),
          ),
        );
        break;

      case PaymentMethod.eft:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BankTransferPayment(
              orderId: widget.orderNumber,
              amount: total,
            ),
          ),
        );
        break;

      case PaymentMethod.cash:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CashOnDeliveryScreen(
              orderId: widget.orderNumber,
              amountDue: total,
              deliveryOtp: '1234', // Demo only.
            ),
          ),
        );
        break;
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open payment details: $e')),
      );
    }
  } finally {
    if (mounted) {
      setState(() => processing = false);
    }
  }
}


  Widget _buildDynamicPaymentView() {
    switch (method) {
      case PaymentMethod.card:
        return const _PaymentDetails(
          title: 'Card payment',
          message: 'Pay securely with your card.',
          icon: Icons.credit_card,
        );
      case PaymentMethod.eft:
        return const _PaymentDetails(
          title: 'EFT / Bank transfer',
          message: 'Bank transfer details will be provided when you pay.',
          icon: Icons.account_balance_outlined,
        );
      case PaymentMethod.cash:
        return const _PaymentDetails(
          title: 'Cash on delivery',
          message: 'Pay with cash when your order is delivered.',
          icon: Icons.payments_outlined,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: payCanvas,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 16,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFFFEAEA),
                          foregroundColor: payRed,
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),

                  Container(
                    padding: const EdgeInsets.all(13),
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Text(
                              'Service: Wash & Fold',
                              style: TextStyle(
                                fontSize: 9,
                                color: payRed,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _SummaryRow(
                          widget.serviceName,
                          widget.servicePrice,
                        ),
                        const SizedBox(height: 11),

                        _SummaryRow('Pickup Fee', widget.pickupFee),
                        const SizedBox(height: 11),

                        _SummaryRow('Delivery Fee', widget.deliveryFee),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 11),
                          child: Divider(
                            height: 1,
                            color: payLine,
                          ),
                        ),

                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Total Amount',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              'R${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: payRed,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Booking Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(12),
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
                          style: const TextStyle(fontSize: 10),
                        ),
                        const SizedBox(height: 5),

                        Text(
                          'Delivery: ${date(widget.booking.deliveryDate)}'
                          ' • ${slot(widget.booking.deliveryStart, widget.booking.deliveryEnd)}',
                          style: const TextStyle(fontSize: 10),
                        ),
                        const SizedBox(height: 5),

                        Text(
                          'Address: ${widget.booking.address}',
                          style: const TextStyle(fontSize: 10),
                        ),

                        if (widget.booking.instructions.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            'Instructions: ${widget.booking.instructions}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Choose Payment Method',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),

                  _PaymentChoice(
                    title: 'Card Payment',
                    subtitle: 'Visa, MasterCard, etc.',
                    value: 'card',
                    groupValue: method.name,
                    onChanged: (_) => setState(() => method = PaymentMethod.card),
                    icon: Icons.credit_card,
                    selected: method == PaymentMethod.card,
                    onTap: () {
                      setState(() => method = PaymentMethod.card);
                      // Card Payment


                    },
                  ),

                  const SizedBox(height: 8),

                  _PaymentChoice(
                    title: 'EFT / Bank Transfer',
                    subtitle: 'Instant bank payment',
                    value: 'eft',
                    groupValue: method.name,
                    onChanged: (_) {
                      setState(() => method = PaymentMethod.eft);
                    },
                    icon: Icons.account_balance_outlined,
                    selected: method == PaymentMethod.eft,
                    onTap: () {
                      setState(() => method = PaymentMethod.eft);
                      // Bank Transfer / EFT


                    },
                  ),

                  const SizedBox(height: 8),

                  _PaymentChoice(
                    title: 'Cash on Delivery',
                    subtitle: 'Pay with cash at doorstep',
                    value: 'cash',
                    groupValue: method.name,
                    onChanged: (_) {
                      setState(() => method = PaymentMethod.cash);
                    },
                    icon: Icons.payments_outlined,
                    selected: method == PaymentMethod.cash,
                    onTap: () {
                      setState(() => method = PaymentMethod.cash);
                      // Cash on Delivery

                    },
                  ),

                  const SizedBox(height: 15),

                  _buildDynamicPaymentView(),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 12,
                        color: payMuted,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Secured 256-bit SSL Encrypted Payment',
                        style: TextStyle(
                          fontSize: 9,
                          color: payMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Payment button container.
            // Fixed: color is inside BoxDecoration.
            Container(
              padding: const EdgeInsets.fromLTRB(18, 9, 18, 9),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: payLine),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: 
ElevatedButton(
  onPressed: processing ? null : pay,
  style: ElevatedButton.styleFrom(
    backgroundColor: payRed,
    foregroundColor: Colors.white,
    shape: const StadiumBorder(),
  ),
  child: processing
      ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
      : Text(
          'Pay R${total.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
)
,
              ),
            ),


            _PayBottomNav(onNavigate: widget.onNavigate),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.amount);

  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: payMuted,
            ),
          ),
        ),
        Text(
          'R${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PaymentDetails extends StatelessWidget {
  const _PaymentDetails({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: payLine),
      ),
      child: Row(
        children: [
          Icon(icon, color: payRed),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(message, style: const TextStyle(color: payMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
    


  }
}

class _PaymentChoice extends StatelessWidget {
  const _PaymentChoice({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    required String value,
    required String groupValue,
    required ValueChanged<String> onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
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
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEAEA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: payRed,
                size: 17,
              ),
            ),

            const SizedBox(width: 9),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 9,
                      color: payMuted,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected ? payRed : payMuted,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }
}

class _PayBottomNav extends StatelessWidget {
  const _PayBottomNav({required this.onNavigate});

  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Home', Icons.home_outlined),
      ('Orders', Icons.access_time),
      ('Schedule', Icons.calendar_today_outlined),
      ('Profile', Icons.person_outline),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: payLine),
        ),
      ),
      child: Row(
        children: items.map((item) {
          final active = item.$1 == 'Schedule';

          return Expanded(
            child: InkWell(
              onTap: () => onNavigate(item.$1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.$2,
                    size: 18,
                    color: active ? payRed : payMuted,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.$1,
                    style: TextStyle(
                      fontSize: 9,
                      color: active ? payRed : payMuted,
                      fontWeight: active
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
