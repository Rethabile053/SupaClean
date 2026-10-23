import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_theme.dart';
import '../core/constants.dart';
import '../models/booking_details.dart';
import '../models/order_draft.dart';
import '../widgets/app_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_badge.dart';
import 'main_shell.dart';

/// Shown once the order and payment have reached SupaClean.
class PaymentSubmittedScreen extends StatefulWidget {
  const PaymentSubmittedScreen({
    super.key,
    required this.draft,
    required this.booking,
    required this.method,
  });

  final OrderDraft draft;
  final BookingDetails booking;
  final PaymentMethod method;

  @override
  State<PaymentSubmittedScreen> createState() => _PaymentSubmittedScreenState();
}

class _PaymentSubmittedScreenState extends State<PaymentSubmittedScreen> {
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

  String _day(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _slot(TimeOfDay a, TimeOfDay b) =>
      '${a.format(context)} - ${b.format(context)}';

  @override
  Widget build(BuildContext context) {
    final awaitingCheck =
        widget.method == PaymentMethod.eft || widget.draft.isDelivery;
    final booking = widget.booking;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _trackOrder();
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.s24),
            children: [
              const SizedBox(height: AppSpace.s32),
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.5, end: 1),
                  duration: AppMotion.slow * 2,
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: StatusTone.success.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 52,
                      color: StatusTone.success.foreground,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.s24),
              const Text(
                'Thank you!',
                textAlign: TextAlign.center,
                style: AppText.display,
              ),
              const SizedBox(height: AppSpace.s8),
              Text(
                awaitingCheck
                    ? 'We have received your order and proof of payment. '
                        "We'll confirm your payment shortly and send you a "
                        'notification.'
                    : 'We have received your order. Please have your cash '
                        'ready when we deliver.',
                textAlign: TextAlign.center,
                style: AppText.body,
              ),
              const SizedBox(height: AppSpace.s32),
              AppCard(
                child: Column(
                  children: [
                    _Row('Order', widget.draft.summary),
                    _Row(
                      'Amount',
                      'R${widget.draft.total.toStringAsFixed(2)}',
                    ),
                    _Row(
                      'Pickup',
                      '${_day(booking.pickupDate)} · '
                          '${_slot(booking.pickupStart, booking.pickupEnd)}',
                    ),
                    _Row(
                      'Delivery',
                      '${_day(booking.deliveryDate)} · '
                          '${_slot(booking.deliveryStart, booking.deliveryEnd)}',
                    ),
                    _Row('Address', booking.address, last: true),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.s32),
              PrimaryButton(text: 'Track my order', onPressed: _trackOrder),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool last;

  const _Row(this.label, this.value, {this.last = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppSpace.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: AppText.caption)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppText.figures(AppText.bodyStrong),
            ),
          ),
        ],
      ),
    );
  }
}
