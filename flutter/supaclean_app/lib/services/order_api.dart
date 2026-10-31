import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;

import '../models/app_notification.dart';
import '../models/laundry_order.dart';
import '../models/points.dart';
import 'api_client.dart';

/// A service on the server's price list. Orders refer to services by id.
class ApiService {
  const ApiService({
    required this.id,
    required this.name,
    required this.price,
    this.description = '',
    this.isActive = true,
    this.category,
  });

  final String id;
  final String name;
  final double price;
  final String description;

  /// False when the admin has switched the service off.
  final bool isActive;

  /// The heading the admin put the service under. Null for services saved
  /// before categories existed.
  final String? category;
}

/// The ASP.NET endpoints the app uses (see aspnet/SupaClean.WebApi).
class OrderApi {
  OrderApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  bool get isConfigured => _client.isConfigured;

  /// GET /api/v1/services. Only the services on offer, unless
  /// [includeInactive]: then the ones the admin switched off come too, marked
  /// by [ApiService.isActive], so the app can show them as unavailable.
  Future<List<ApiService>> services({bool includeInactive = false}) async {
    final data = await _client.get(
      includeInactive
          ? '/api/v1/services?includeInactive=true'
          : '/api/v1/services',
    ) as List<dynamic>;
    return [
      for (final item in data.cast<Map<String, dynamic>>())
        ApiService(
          id: item['serviceId'] as String,
          name: (item['serviceName'] ?? item['name']) as String,
          price: (item['price'] as num).toDouble(),
          description: (item['serviceDescription'] as String?) ?? '',
          isActive: (item['isActive'] as bool?) ?? true,
          category: (item['category'] as String?)?.trim(),
        ),
    ];
  }

  /// GET /api/v1/delivery-zones: the areas we deliver to, as id and name.
  Future<List<({String id, String name, double fee})>> deliveryZones() async {
    final data = await _client.get('/api/v1/delivery-zones') as List<dynamic>;
    return [
      for (final item in data.cast<Map<String, dynamic>>())
        (
          id: item['zoneId'] as String,
          name: item['name'] as String,
          fee: (item['fee'] as num).toDouble(),
        ),
    ];
  }

  /// Saved as the address of a customer who has not given one yet (the
  /// server requires an address). Replaced by the first real address.
  static const unknownAddress = 'Not provided yet';

  /// Makes sure the signed-in user has a customer profile, which orders
  /// need. GET /api/v1/customers/me, then POST /api/v1/customers on a 404.
  /// A customer saved without an address gets the first real one given.
  Future<void> ensureCustomer({
    required String fullName,
    required String email,
    required String phone,
    required String address,
    String city = 'Bloemfontein',
  }) async {
    final given = address.trim().isEmpty ? unknownAddress : address.trim();

    try {
      final me =
          await _client.get('/api/v1/customers/me') as Map<String, dynamic>?;
      if (me?['address'] == unknownAddress && given != unknownAddress) {
        await _client.put('/api/v1/customers/me', {
          'customerId': me?['customerId'],
          'fullName': fullName,
          'phoneNumber': phone,
          'city': (me?['city'] as String?) ?? city,
          'address': given,
        });
      }
      return;
    } on ApiException catch (error) {
      if (error.status != 404) rethrow;
    }

    final parts = fullName.trim().split(RegExp(r'\s+'));
    final firstName = parts.first.isEmpty ? 'Customer' : parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '-';

    await _client.post('/api/v1/customers', {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      // Sign-in is handled by Supabase; the app never sends a password.
      'passwordHash': '',
      'phoneNumber': phone,
      'city': city,
      'address': given,
    });
  }

  /// POST /api/v1/orders. Returns the new order's id.
  Future<String> createOrder({
    required String specialInstructions,
    required List<Map<String, Object>> items,
    required String fulfillmentMethod,
    String? deliveryZoneId,
    bool homePickup = false,
    DateTime? pickupDate,
    DateTime? deliveryDate,
    bool usePoints = false,
  }) async {
    final id = await _client.post('/api/v1/orders', {
      // The API uses the signed-in customer and ignores this.
      'customerId': '00000000-0000-0000-0000-000000000000',
      'deliveryZoneId': deliveryZoneId,
      // The server adds its own pickup fee; the app never sends an amount.
      'homePickup': homePickup,
      // UTC, as the server stores them; it shows them back on My Orders.
      'pickupDate': pickupDate?.toUtc().toIso8601String(),
      'deliveryDate': deliveryDate?.toUtc().toIso8601String(),
      'specialInstructions': specialInstructions,
      'items': items,
      'fulfillmentMethod': fulfillmentMethod,
      // The server works out the discount; the app only says yes.
      if (usePoints) 'usePoints': true,
    });
    return id as String;
  }

  /// GET /api/v1/orders/{id}: the short ticket number the customer quotes
  /// and uses as the bank-transfer reference.
  Future<String> orderNumber(String orderId) async =>
      (await placedOrder(orderId)).number;

  /// GET /api/v1/orders/{id}: the number to show, and how much the server
  /// really took off for points (0 if none were used).
  Future<({String number, double pointsDiscount})> placedOrder(
      String orderId) async {
    final order =
        await _client.get('/api/v1/orders/$orderId') as Map<String, dynamic>;
    // The customer-facing number (SC-1005); the paper ticket number only
    // exists once the admin links one.
    return (
      number: (order['orderNumber'] as String?) ??
          (order['ticketNumber'] as String?) ??
          orderId,
      pointsDiscount: (order['pointsDiscount'] as num?)?.toDouble() ?? 0,
    );
  }

  /// GET /api/v1/orders: the signed-in customer's orders.
  Future<List<LaundryOrder>> myOrders() async {
    final data = await _client.get('/api/v1/orders') as List<dynamic>;
    return [
      for (final item in data.cast<Map<String, dynamic>>())
        LaundryOrder.fromApi(item),
    ];
  }

  /// GET /api/v1/orders/{id}: one order with its latest status, for Track
  /// Order to pick up changes the admin has made.
  Future<LaundryOrder> order(String orderId) async {
    final data =
        await _client.get('/api/v1/orders/$orderId') as Map<String, dynamic>;
    return LaundryOrder.fromApi(data);
  }

  /// POST /api/v1/orders/{id}/cancel. The server refuses once the laundry
  /// has been collected.
  Future<void> cancelOrder(String orderId) async {
    await _client.post('/api/v1/orders/$orderId/cancel');
  }

  /// POST /api/v1/orders/{id}/payments. [paymentType] and [paymentMethod]
  /// must be the exact enum names the API expects: Orderpayment or
  /// DeliveryFee, and EFT or CashOnDelivery.
  Future<String> submitPayment({
    required String orderId,
    required String paymentType,
    required String paymentMethod,
    String? proofReference,
  }) async {
    final id = await _client.post('/api/v1/orders/$orderId/payments', {
      'orderId': orderId,
      'paymentType': paymentType,
      'paymentMethod': paymentMethod,
      'bankReference': null,
      'proofOfPaymentReference': proofReference,
    });
    return id as String;
  }

  /// GET /api/v1/customers/me/points: the balance, the rules and the history.
  Future<PointsSummary> myPoints() async => PointsSummary.fromApi(
      await _client.get('/api/v1/customers/me/points') as Map<String, dynamic>);

  /// GET /api/v1/notifications, newest first.
  Future<List<AppNotification>> notifications() async {
    final data = await _client.get('/api/v1/notifications') as List<dynamic>;
    final list = [
      for (final item in data.cast<Map<String, dynamic>>())
        AppNotification.fromApi(item),
    ]..sort((a, b) => b.time.compareTo(a.time));
    return list;
  }

  /// POST /api/v1/notifications/{id}/read
  Future<void> markNotificationRead(String id) async {
    await _client.post('/api/v1/notifications/$id/read');
  }

  /// Marks every unread notification about this order as read. Used when a
  /// notification is tapped outside the app, where only the order is known.
  Future<void> markOrderNotificationsRead(String orderId) async {
    for (final n in await notifications()) {
      if (n.orderId == orderId && !n.isRead && n.id.isNotEmpty) {
        await markNotificationRead(n.id);
      }
    }
  }

  /// POST /api/v1/notifications/read-all
  Future<void> markAllNotificationsRead() async {
    await _client.post('/api/v1/notifications/read-all');
  }

  /// DELETE /api/v1/notifications/{id}: removes one of this customer's
  /// notifications for good.
  Future<void> deleteNotification(String id) async {
    await _client.delete('/api/v1/notifications/$id');
  }

  /// POST /api/v1/devices: tells the server where to send this phone's
  /// push notifications.
  Future<void> registerDevice(String token) async {
    await _client.post('/api/v1/devices', {
      'token': token,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase(),
    });
  }
}
