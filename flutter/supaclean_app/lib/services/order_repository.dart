/*import 'package:flutter/material.dart';
//import 'package:supabase_flutter/supabase_flutter.dart';

//import '../models/booking_details.dart';
import '../models/laundry_order.dart';
//import '../models/order_draft.dart';
//import '../models/payment_method.dart';

class OrderRepository {
  OrderRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const String tableName = 'laundry_orders';

  String _dateForDatabase(DateTime date) {
    final value = date.toLocal();
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  String _timeForDatabase(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}:00';

  /// Call this only after [onPay] has confirmed the payment/accepted
  /// the cash-on-delivery order. The current SupaClean UI does not itself
  /// charge a card or verify an EFT transfer.
  Future<LaundryOrder> createOrder({
    ////required OrderDraft draft,
    //required BookingDetails booking,
    required PaymentMethod paymentMethod,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError(
        'You must be signed in to place an order. Please sign in and try again.',
      );
    }

    final paymentStatus = paymentMethod == PaymentMethod.cash
        ? 'pay_on_delivery'
        : 'paid';

    final payload = <String, dynamic>{
      'customer_id': user.id,
      'service_name': draft.category,
      'items': draft.items.map((item) => item.toJson()).toList(),
      'subtotal': draft.subtotal,
      'pickup_fee': draft.pickupFee,
      'delivery_fee': draft.deliveryFee,
      'total_amount': draft.total,
      'pickup_option': draft.pickupOption,
      'delivery_option': draft.deliveryOption,
      'pickup_date': _dateForDatabase(booking.pickupDate),
      'pickup_start': _timeForDatabase(booking.pickupStart),
      'pickup_end': _timeForDatabase(booking.pickupEnd),
      'delivery_date': _dateForDatabase(booking.deliveryDate),
      'delivery_start': _timeForDatabase(booking.deliveryStart),
      'delivery_end': _timeForDatabase(booking.deliveryEnd),
      'address': booking.address.trim(),
      'instructions': booking.instructions.trim(),
      'payment_method': paymentMethod.databaseValue,
      'payment_status': paymentStatus,
      'status': 'Order Placed',
    };

    final inserted = await _client
        .from(tableName)
        .insert(payload)
        .select()
        .single();

    return LaundryOrder.fromJson(Map<String, dynamic>.from(inserted));
  }

  Stream<List<Map<String, dynamic>>> watchMyOrders(String customerId) {
    return _client
        .from(tableName)
        .stream(primaryKey: ['id'])
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
  }

  Stream<LaundryOrder?> watchOrderById(String id) {
    return _client
        .from(tableName)
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .limit(1)
        .map((rows) => rows.isEmpty
            ? null
            : LaundryOrder.fromJson(Map<String, dynamic>.from(rows.first)));
  }
}
*/