
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const codRed = Color(0xFFE53935);
const codMuted = Color(0xFF626976);

class CashOnDeliveryScreen extends StatelessWidget {
  const CashOnDeliveryScreen({
    super.key,
    required this.orderId,
    required this.amountDue,
    required this.deliveryOtp,
    this.deliveryInstructions =
        'Pay the courier when your order arrives.',
  });

  final String orderId;
  final double amountDue;
  final String deliveryOtp;
  final String deliveryInstructions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cash on Delivery')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            color: codRed,
            size: 60,
          ),
          const SizedBox(height: 12),
          const Text(
            'Your order is awaiting delivery',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Order #$orderId',
            textAlign: TextAlign.center,
            style: const TextStyle(color: codMuted),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3F3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Text('Cash amount due on arrival'),
                const SizedBox(height: 8),
                Text(
                  'R${amountDue.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: codRed,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Delivery instructions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '$deliveryInstructions\n\n'
            'Please prepare the exact amount if possible. '
            'The courier must follow SupaClean delivery and '
            'cash-handling procedures. Request confirmation '
            'of payment before the delivery is completed.',
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: codRed,
                  size: 40,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your delivery verification code',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  deliveryOtp,
                  style: const TextStyle(
                    fontSize: 28,
                    letterSpacing: 6,
                    fontWeight: FontWeight.bold,
                    color: codRed,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Give this code to the courier only when '
                  'they request delivery verification after '
                  'receiving your cash.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: codMuted),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: deliveryOtp),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Delivery code copied'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy delivery code'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This code verifies the delivery process; it is not '
            'proof that cash has already been paid. The courier '
            'or backend must record the cash collection before '
            'the order is marked as paid.',
            style: TextStyle(color: codMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
