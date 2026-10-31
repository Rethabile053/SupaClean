import 'package:flutter/material.dart';
import '../models/booking_details.dart';
import '../models/order_draft.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'order_api.dart';
import 'proof_uploader.dart';

/// The order as it now exists on the server.
class PlacedOrder {
  const PlacedOrder({
    required this.orderId,
    required this.orderNumber,
    this.pointsDiscount = 0,
  });

  final String orderId;

  /// Short number to show the customer, e.g. as the bank-transfer reference.
  final String orderNumber;

  /// Rand the server took off for points (0 when none were used).
  final double pointsDiscount;
}

/// Sends one customer's finished order to ASP.NET, in two steps:
///
/// 1. [createOrder] when the customer presses Pay: the customer profile and
///    the order are created, so the order number can be shown (the bank
///    transfer screen needs it as the payment reference).
/// 2. [pay] when they confirm: the proof is uploaded and the payment is sent
///    for the admin to verify.
///
/// Create one per checkout. Each step is safe to repeat after a failure: it
/// never creates a second order or a duplicate payment.
class CheckoutService {
  CheckoutService({
    required this.draft,
    required this.booking,
    required this.user,
    OrderApi? api,
    ProofUploader? uploader,
  })  : _api = api ?? OrderApi(),
        _uploader = uploader ?? SupabaseProofUploader();

  final OrderDraft draft;
  final BookingDetails booking;
  final UserModel? user;

  final OrderApi _api;
  final ProofUploader _uploader;

  /// Set before [createOrder]: use the customer's points on this order. The
  /// server decides the discount and may give less than the app previewed.
  bool usePoints = false;

  PlacedOrder? _placed;

  /// True once the order exists on the server, after which the choice about
  /// points can no longer change.
  bool get isPlaced => _placed != null;
  final Set<String> _paymentsDone = {};

  // Exact enum names the ASP.NET API parses.
  static const _typeOrder = 'Orderpayment';
  static const _typeDeliveryFee = 'DeliveryFee';

  /// Lower-cases an address or area name and accepts the alternative
  /// spellings, so "Thaba-Nchu" and "Botsabelo" still match the zone names.
  static String normalizeArea(String text) => text
      .toLowerCase()
      .replaceAll('-', ' ')
      .replaceAll('botsabelo', 'botshabelo')
      .replaceAll(RegExp(r'\s+'), ' ');

  /// Only bank transfers need proof; cash is paid on delivery.
  static bool needsProof(PaymentMethod method) => method == PaymentMethod.eft;

  Future<PlacedOrder> createOrder() async {
    final existing = _placed;
    if (existing != null) return existing;

    if (!_api.isConfigured) {
      throw const ApiException(
        'The SupaClean server is not set up in this version of the app yet.',
      );
    }
    if (draft.lines.isEmpty) {
      throw const ApiException('Your order has no items.');
    }

    await _api.ensureCustomer(
      fullName: user?.fullName ?? '',
      email: user?.email ?? '',
      phone: user?.phoneNumber ?? '',
      address: booking.address,
    );

    final orderId = await _createOrderOnServer();
    final placed = await _api.placedOrder(orderId);
    return _placed = PlacedOrder(
      orderId: orderId,
      orderNumber: placed.number,
      pointsDiscount: placed.pointsDiscount,
    );
  }

  /// Uploads [proof] (bank transfers) and sends the payment. Creates the
  /// order first if that has not happened yet.
  ///
  /// Instead of a file the customer may paste their bank's confirmation as
  /// [proofText]; it is sent as the payment's proof reference.
  Future<PlacedOrder> pay(
    PaymentMethod method, {
    ProofFile? proof,
    String? proofText,
  }) async {
    final text = proofText?.trim();
    final hasText = text != null && text.isNotEmpty;
    if (needsProof(method) && proof == null && !hasText) {
      throw const ApiException('Please add your proof of payment.');
    }

    final placed = await createOrder();

    // Upload before sending anything, so a failed upload changes nothing.
    final String? proofReference = !needsProof(method)
        ? null
        : proof != null
            ? await _uploader.upload(proof)
            : 'Text: $text';

    if (_paymentsDone.add('order')) {
      try {
        await _api.submitPayment(
          orderId: placed.orderId,
          paymentType: _typeOrder,
          paymentMethod: method == PaymentMethod.eft ? 'EFT' : 'CashOnDelivery',
          proofReference: proofReference,
        );
      } catch (_) {
        _paymentsDone.remove('order');
        rethrow;
      }
    }

    // The business requires the delivery fee to be paid by EFT up front, so a
    // bank-transfer delivery order carries the same proof for it.
    if (method == PaymentMethod.eft &&
        draft.isDelivery &&
        _paymentsDone.add('deliveryFee')) {
      try {
        await _api.submitPayment(
          orderId: placed.orderId,
          paymentType: _typeDeliveryFee,
          paymentMethod: 'EFT',
          proofReference: proofReference,
        );
      } catch (_) {
        _paymentsDone.remove('deliveryFee');
        rethrow;
      }
    }

    return placed;
  }

  Future<String> _createOrderOnServer() async {
    final catalogue = await _api.services(includeInactive: true);
    final byName = {
      for (final service in catalogue) service.name.trim().toLowerCase(): service,
    };

    final missing = [
      for (final line in draft.lines)
        if (!byName.containsKey(line.name.trim().toLowerCase())) line.name,
    ];
    if (missing.isNotEmpty) {
      throw ApiException(
        'Not available to order yet: ${missing.join(', ')}.',
      );
    }

    // The admin switched these off after they were added to the order.
    final switchedOff = [
      for (final line in draft.lines)
        if (!byName[line.name.trim().toLowerCase()]!.isActive) line.name,
    ];
    if (switchedOff.isNotEmpty) {
      throw ApiException(
        '${switchedOff.join(', ')} ${switchedOff.length == 1 ? 'is' : 'are'} '
        'currently unavailable. Please remove '
        '${switchedOff.length == 1 ? 'it' : 'them'} from your order.',
      );
    }

    return _api.createOrder(
      deliveryZoneId: draft.isDelivery || draft.pickupFee > 0
          ? await _deliveryZoneId()
          : null,
      homePickup: draft.pickupFee > 0,
      pickupDate: _at(booking.pickupDate, booking.pickupStart),
      deliveryDate: _at(booking.deliveryDate, booking.deliveryStart),
      specialInstructions: _instructions(),
      fulfillmentMethod: draft.isDelivery ? 'Delivery' : 'DropOff',
      usePoints: usePoints,
      items: [
        for (final line in draft.lines)
          {
            'serviceId': byName[line.name.trim().toLowerCase()]!.id,
            'quantity': line.quantity,
            'unitPrice': booking.discounted(line.unitPrice),
            'description': line.name,
          },
      ],
    );
  }

  /// The chosen day at the start of the chosen time slot (local time).
  static DateTime _at(DateTime day, TimeOfDay time) =>
      DateTime(day.year, day.month, day.day, time.hour, time.minute);

  /// The delivery area the server needs for a delivery order: the one whose
  /// name appears in the customer's address.
  Future<String> _deliveryZoneId() async {
    final zones = await _api.deliveryZones();
    final address = normalizeArea(booking.address);
    for (final zone in zones) {
      if (address.contains(normalizeArea(zone.name))) return zone.id;
    }
    throw const ApiException(
      'We do not deliver to that area yet. Please choose Collect at depot.',
    );
  }

  /// The API has no fields for pickup/delivery times or the address yet, so
  /// they travel in the order notes for the admin to read.
  String _instructions() {
    String day(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
    String time(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';

    final parts = [
      'Pickup (${draft.pickupOption}): ${day(booking.pickupDate)} '
          '${time(booking.pickupStart)}-${time(booking.pickupEnd)}',
      'Delivery (${draft.deliveryOption}): ${day(booking.deliveryDate)} '
          '${time(booking.deliveryStart)}-${time(booking.deliveryEnd)}',
      if (booking.qualifiesForDiscount)
        '10% discount: delivery in ${booking.daysToDelivery} days',
      'Address: ${booking.address}',
      if (booking.instructions.isNotEmpty) 'Notes: ${booking.instructions}',
    ];
    return parts.join(' | ');
  }
}
