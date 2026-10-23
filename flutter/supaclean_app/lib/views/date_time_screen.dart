import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/booking_details.dart';
import '../models/order_draft.dart';
import '../services/checkout_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/app_header.dart';
import 'payment_screen.dart';

export '../models/booking_details.dart';

const Color kRed = Color(0xFFE53935);
const Color kBackground = Color(0xFFF1F6F6);
const Color kBorder = Color(0xFFE6E9EC);
const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextGrey = Color(0xFF6B7280);

const List<String> kPickupSlots = [
  '08:00 AM - 10:00 AM',
  '10:00 AM - 12:00 PM',
  '12:00 PM - 02:00 PM',
  '02:00 PM - 04:00 PM',
  '04:00 PM - 06:00 PM',
];

const List<String> kDeliverySlots = [
  '08:00 AM - 10:00 AM',
  '10:00 AM - 12:00 PM',
  '12:00 PM - 02:00 PM',
  '02:00 PM - 04:00 PM',
  '04:00 PM - 06:00 PM',
];

const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

/// Converts a time slot into its starting and ending times.
List<TimeOfDay> parseSlot(String slot) {
  TimeOfDay parse(String value) {
    final parts = value.trim().split(' ');
    final hourMinute = parts[0].split(':');

    var hour = int.parse(hourMinute[0]);
    final minute = int.parse(hourMinute[1]);
    final isPm = parts[1].toUpperCase() == 'PM';

    if (isPm && hour != 12) {
      hour += 12;
    }

    if (!isPm && hour == 12) {
      hour = 0;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  final parts = slot.split('-');

  return [
    parse(parts[0]),
    parse(parts[1]),
  ];
}

class ChooseDateTimeScreen extends StatefulWidget {
  final double orderSubtotal;

  /// The items chosen on Place Order. Needed to place the order; without it
  /// the screen only collects the booking.
  final OrderDraft? draft;

  /// Optional callback if another screen needs to handle the booking.
  final void Function(
    DateTime pickupDate,
    String pickupSlot,
    DateTime deliveryDate,
    String deliverySlot,
    String address,
    String instructions,
  )? onContinue;

  const ChooseDateTimeScreen({
    super.key,
    this.orderSubtotal = 80.00,
    this.draft,
    this.onContinue,
  });

  @override
  State<ChooseDateTimeScreen> createState() =>
      _ChooseDateTimeScreenState();
}

class _ChooseDateTimeScreenState extends State<ChooseDateTimeScreen> {
  late DateTime _pickupDate;
  late DateTime _deliveryDate;

  String _pickupSlot = kPickupSlots[1];
  String _deliverySlot = kDeliverySlots[4];

  final TextEditingController _addressController =
      TextEditingController();

  final TextEditingController _instructionsController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _pickupDate = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1));

    _deliveryDate = _pickupDate.add(const Duration(days: 3));
  }

  @override
  void dispose() {
    _addressController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isPickup}) async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final firstDate = isPickup ? todayDate : _pickupDate;
    final initialDate = isPickup ? _pickupDate : _deliveryDate;

    final picked = await showDatePicker(
      context: context,
      initialDate:
          initialDate.isBefore(firstDate) ? firstDate : initialDate,
      firstDate: firstDate,
      lastDate: DateTime(today.year + 1, today.month, today.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: kRed,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isPickup) {
        _pickupDate = picked;

        // Delivery cannot be earlier than pickup.
        if (_deliveryDate.isBefore(_pickupDate)) {
          _deliveryDate = _pickupDate;
        }
      } else {
        _deliveryDate = picked;
      }
    });
  }

  Future<void> _pickSlot({required bool isPickup}) async {
    final slots = isPickup ? kPickupSlots : kDeliverySlots;
    final currentSlot = isPickup ? _pickupSlot : _deliverySlot;

    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: kBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Select Time Slot',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final slot in slots)
                  ListTile(
                    leading: const Icon(
                      Icons.access_time,
                      color: kRed,
                    ),
                    title: Text(slot),
                    trailing: slot == currentSlot
                        ? const Icon(
                            Icons.check_circle,
                            color: kRed,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, slot),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isPickup) {
        _pickupSlot = picked;
      } else {
        _deliverySlot = picked;
      }
    });
  }

  /// Validates the booking details and opens the payment screen.
  void _onContinue() {
    FocusScope.of(context).unfocus();

    final address = _addressController.text.trim();
    final instructions = _instructionsController.text.trim();

    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your pickup address'),
        ),
      );
      return;
    }

    // Keep this callback available for any existing code using it.
    widget.onContinue?.call(
      _pickupDate,
      _pickupSlot,
      _deliveryDate,
      _deliverySlot,
      address,
      instructions,
    );

    final pickupTimes = parseSlot(_pickupSlot);
    final deliveryTimes = parseSlot(_deliverySlot);

    final booking = BookingDetails(
      pickupDate: _pickupDate,
      pickupStart: pickupTimes[0],
      pickupEnd: pickupTimes[1],
      deliveryDate: _deliveryDate,
      deliveryStart: deliveryTimes[0],
      deliveryEnd: deliveryTimes[1],
      address: address,
      instructions: instructions,
    );

    final draft = widget.draft;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          booking: booking,
          servicePrice: widget.orderSubtotal,
          pickupFee: 0,
          deliveryFee: 0,
          serviceName: draft?.summary ?? 'Wash & Fold (3 kg)',

          // Sends the order and payment to SupaClean once Pay is pressed.
          checkout: draft == null
              ? null
              : CheckoutService(
                  draft: draft,
                  booking: booking,
                  user: context.read<AuthViewModel>().currentUser,
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: const AppHeader(title: 'Choose Date & Time'),

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pickup date and time.
              const _SectionTitle('Pickup Date & Time'),
              const SizedBox(height: 10),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _LabeledField(
                      label: 'Date',
                      icon: Icons.calendar_today_outlined,
                      value: formatDate(_pickupDate),
                      onTap: () => _pickDate(isPickup: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabeledField(
                      label: 'Time Slot',
                      icon: Icons.access_time,
                      value: _pickupSlot,
                      onTap: () => _pickSlot(isPickup: true),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Delivery date and time.
              const _SectionTitle('Delivery Date & Time'),
              const SizedBox(height: 10),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _LabeledField(
                      label: 'Date',
                      icon: Icons.calendar_today_outlined,
                      value: formatDate(_deliveryDate),
                      onTap: () => _pickDate(isPickup: false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _LabeledField(
                      label: 'Time Slot',
                      icon: Icons.access_time,
                      value: _deliverySlot,
                      onTap: () => _pickSlot(isPickup: false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Pickup address.
              const _SectionTitle('Pickup Address'),
              const SizedBox(height: 10),

              Container(
                decoration: _boxDecoration(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: kRed,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _addressController,
                        keyboardType: TextInputType.streetAddress,
                        textCapitalization: TextCapitalization.words,
                        minLines: 1,
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 13,
                          color: kTextDark,
                        ),
                        decoration: const InputDecoration(
                          hintText:
                              'Enter your street address, suburb, city',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9CA3AF),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Optional special instructions.
              const _SectionTitle(
                'Special Instructions (Optional)',
              ),
              const SizedBox(height: 10),

              Container(
                decoration: _boxDecoration(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _instructionsController,
                  minLines: 3,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontSize: 13,
                    color: kTextDark,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'E.g. Gate code, house number, etc.',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // Subtotal and Continue button.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Order Subtotal',
                      style: TextStyle(
                        fontSize: 12,
                        color: kTextGrey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'R${widget.orderSubtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: kTextDark,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: 150,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
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

// Reusable widgets.

BoxDecoration _boxDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: kBorder),
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: kTextDark,
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  const _LabeledField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: kTextGrey,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: _boxDecoration(),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: kRed,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: kTextDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}