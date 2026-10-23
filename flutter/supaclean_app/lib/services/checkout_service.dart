import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/booking_details.dart';
import '../models/order_draft.dart';
import '../models/user_model.dart';
import 'api_client.dart';
import 'order_api.dart';
import 'proof_uploader.dart';

class CheckoutResult {
  const CheckoutResult({required this.orderId});

  final String orderId;
}

/// Turns a finished order draft into a real order on the server:
/// proof upload, order, then payment(s) for the admin to verify.
///
/// Create one per checkout attempt. If a step fails after the order was
/// created, calling [place] again carries on instead of creating a second
/// order.
class CheckoutService {
  CheckoutService({OrderApi? api, ProofUploader? uploader})
      : _api = api ?? OrderApi(),
        _uploader = uploader ?? SupabaseProofUploader();

  final OrderApi _api;
  final ProofUploader _uploader;

  String? _orderId;
  final Set<String> _paymentsDone = {};

  // Exact enum names the ASP.NET API parses.
  static const _typeOrder = 'Orderpayment';
  static const _typeDeliveryFee = 'DeliveryFee';

  /// Bank transfers always need proof. So does the delivery fee, which the
  /// business requires to be paid by EFT before pickup.
  static bool needsProof(OrderDraft draft, PaymentMethod method) =>
      method == PaymentMethod.eft || draft.isDelivery;

  Future<CheckoutResult> place({
    required OrderDraft draft,
    required BookingDetails booking,
    required PaymentMethod method,
    required UserModel? user,
    XFile? proof,
  }) async {
    if (!_api.isConfigured) {
      throw const ApiException(
        'The SupaClean server is not set up in this version of the app yet.',
      );
    }
    if (draft.lines.isEmpty) {
      throw const ApiException('Your order has no items.');
    }
    if (draft.isDelivery && draft.zone == null) {
      throw const ApiException('Please choose your delivery area.');
    }

    final proofNeeded = needsProof(draft, method);
    if (proofNeeded && proof == null) {
      throw const ApiException('Please add your proof of payment.');
    }

    await _api.ensureCustomer(
      fullName: user?.fullName ?? '',
      email: user?.email ?? '',
      phone: user?.phoneNumber ?? '',
      address: booking.address,
    );

    // Upload first: if it fails, nothing has been created yet.
    final proofReference =
        proofNeeded ? await _uploader.upload(proof!) : null;

    final orderId = _orderId ??= await _createOrder(draft, booking);

    if (_paymentsDone.add('order')) {
      try {
        await _api.submitPayment(
          orderId: orderId,
          paymentType: _typeOrder,
          paymentMethod: method == PaymentMethod.eft ? 'EFT' : 'CashOnDelivery',
          proofReference: method == PaymentMethod.eft ? proofReference : null,
        );
      } catch (_) {
        _paymentsDone.remove('order');
        rethrow;
      }
    }

    if (draft.isDelivery && _paymentsDone.add('deliveryFee')) {
      try {
        await _api.submitPayment(
          orderId: orderId,
          paymentType: _typeDeliveryFee,
          paymentMethod: 'EFT',
          proofReference: proofReference,
        );
      } catch (_) {
        _paymentsDone.remove('deliveryFee');
        rethrow;
      }
    }

    return CheckoutResult(orderId: orderId);
  }

  Future<String> _createOrder(OrderDraft draft, BookingDetails booking) async {
    final catalogue = await _api.services();
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

    return _api.createOrder(
      specialInstructions: _instructions(draft, booking),
      deliveryZoneId: draft.isDelivery ? draft.zone?.id : null,
      fulfillmentMethod: draft.isDelivery ? 'Delivery' : 'DropOff',
      items: [
        for (final line in draft.lines)
          {
            'serviceId': byName[line.name.trim().toLowerCase()]!.id,
            'quantity': line.quantity,
            'unitPrice': line.unitPrice,
            'description': line.name,
          },
      ],
    );
  }

  /// The API has no fields for pickup/delivery times or the address yet, so
  /// they travel in the order notes for the admin to read.
  String _instructions(OrderDraft draft, BookingDetails booking) {
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
      'Address: ${booking.address}',
      if (booking.instructions.isNotEmpty) 'Notes: ${booking.instructions}',
    ];
    return parts.join(' | ');
  }
}
