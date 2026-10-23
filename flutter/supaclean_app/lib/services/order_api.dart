import '../models/app_notification.dart';
import 'api_client.dart';

/// A service on the server's price list. Orders refer to services by id.
class ApiService {
  const ApiService({required this.id, required this.name, required this.price});

  final String id;
  final String name;
  final double price;
}

/// The ASP.NET endpoints the app uses (see aspnet/SupaClean.WebApi).
class OrderApi {
  OrderApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  bool get isConfigured => _client.isConfigured;

  /// GET /api/v1/services
  Future<List<ApiService>> services() async {
    final data = await _client.get('/api/v1/services') as List<dynamic>;
    return [
      for (final item in data.cast<Map<String, dynamic>>())
        ApiService(
          id: item['serviceId'] as String,
          name: item['name'] as String,
          price: (item['price'] as num).toDouble(),
        ),
    ];
  }

  /// Makes sure the signed-in user has a customer profile, which orders
  /// need. GET /api/v1/customers/me, then POST /api/v1/customers on a 404.
  Future<void> ensureCustomer({
    required String fullName,
    required String email,
    required String phone,
    required String address,
    String city = 'Bloemfontein',
  }) async {
    try {
      await _client.get('/api/v1/customers/me');
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
      'address': address,
    });
  }

  /// POST /api/v1/orders. Returns the new order's id.
  Future<String> createOrder({
    required String specialInstructions,
    required List<Map<String, Object>> items,
    required String fulfillmentMethod,
  }) async {
    final id = await _client.post('/api/v1/orders', {
      // The API uses the signed-in customer and ignores this.
      'customerId': '00000000-0000-0000-0000-000000000000',
      'specialInstructions': specialInstructions,
      'items': items,
      'fulfillmentMethod': fulfillmentMethod,
    });
    return id as String;
  }

  /// GET /api/v1/orders/{id}: the short ticket number the customer quotes
  /// and uses as the bank-transfer reference.
  Future<String> orderNumber(String orderId) async {
    final order =
        await _client.get('/api/v1/orders/$orderId') as Map<String, dynamic>;
    return (order['ticketNumber'] as String?) ?? orderId;
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

  /// GET /api/v1/notifications, newest first.
  Future<List<AppNotification>> notifications() async {
    final data = await _client.get('/api/v1/notifications') as List<dynamic>;
    final list = [
      for (final item in data.cast<Map<String, dynamic>>())
        AppNotification.fromApi(item),
    ]..sort((a, b) => b.time.compareTo(a.time));
    return list;
  }

  /// POST /api/v1/devices: tells the server where to send this phone's
  /// push notifications. (The endpoint still has to be added to ASP.NET.)
  Future<void> registerDevice(String token) async {
    await _client.post('/api/v1/devices', {
      'token': token,
      'platform': 'android',
    });
  }
}
