
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/app_header.dart';

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

  Future<void> copyCode(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(text: deliveryOtp),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Delivery code copied'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: const AppHeader(title: 'Cash on Delivery'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            color: codRed,
            size: 65,
          ),
          const SizedBox(height: 12),
          const Text(
            'Your Order Is Awaiting Delivery',
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
                const Text(
                  'Cash Amount Due on Arrival',
                  style: TextStyle(fontSize: 14),
                ),
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
          const SizedBox(height: 24),
          const Text(
            'Delivery Instructions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$deliveryInstructions\n\n'
            'Please prepare the exact amount if possible. '
            'Ask the courier for confirmation when you pay.',
            style: const TextStyle(height: 1.5),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: codRed,
                  size: 42,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your Delivery Verification Code',
                  textAlign: TextAlign.center,
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
                  style: TextStyle(
                    color: codMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => copyCode(context),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Delivery Code'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: codMuted,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This code verifies delivery. It does not '
                    'confirm that payment has already been made. '
                    'Keep it private until the courier requests it.',
                    style: TextStyle(
                      color: codMuted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
