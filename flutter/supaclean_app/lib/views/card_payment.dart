
import 'package:flutter/material.dart';

const cardPayRed = Color(0xFFE53935);
const cardPayMuted = Color(0xFF626976);

class CardPaymentScreen extends StatelessWidget {
  const CardPaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.onStartSecureCheckout,
  });

  final String orderId;
  final double amount;

  // Connect this callback to your actual payment gateway SDK
  // or hosted checkout integration.
  final Future<void> Function() onStartSecureCheckout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Card Payment')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(
            Icons.lock_outline,
            size: 54,
            color: cardPayRed,
          ),
          const SizedBox(height: 16),
          const Text(
            'Secure card payment',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'You will continue to the secure payment form provided '
            'by our payment partner. Your card details are handled '
            'by the gateway, not stored in SupaClean.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cardPayMuted),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order #${orderId}'),
                  const SizedBox(height: 8),
                  Text(
                    'Total: R${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      color: cardPayRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const ListTile(
            leading: Icon(Icons.credit_card),
            title: Text('Card details'),
            subtitle: Text(
              'Enter your card number, expiry date and CVV '
              'on the secure gateway page.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.verified_user_outlined),
            title: Text('3D Secure verification'),
            subtitle: Text(
              'Your bank may request a one-time PIN or approval '
              'in your banking app.',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: cardPayRed,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () async {
              try {
                await onStartSecureCheckout();
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Unable to start checkout. Please try again.',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.lock),
            label: const Text('Continue to secure checkout'),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your order will only be marked as paid after the '
            'backend verifies the gateway transaction.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cardPayMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class CardPaymentSuccessScreen extends StatelessWidget {
  const CardPaymentSuccessScreen({
    super.key,
    required this.orderId,
    required this.amount,
    required this.transactionId,
    this.receiptUrl,
  });

  final String orderId;
  final double amount;
  final String transactionId;
  final String? receiptUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Confirmation')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 76,
              ),
              const SizedBox(height: 16),
              const Text(
                'Payment Successful',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text('Order: #$orderId'),
              Text('Amount: R${amount.toStringAsFixed(2)}'),
              Text('Transaction: $transactionId'),
              const SizedBox(height: 20),
              if (receiptUrl != null)
                OutlinedButton.icon(
                  onPressed: () {
                    // Open receiptUrl using url_launcher or your
                    // app's authenticated receipt viewer.
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('View transaction receipt'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
