import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supaclean/models/booking_details.dart';
import 'package:supaclean/models/order_draft.dart';
import 'package:supaclean/models/user_model.dart';
import 'package:supaclean/services/api_client.dart';
import 'package:supaclean/services/checkout_service.dart';
import 'package:supaclean/services/order_api.dart';
import 'package:supaclean/services/proof_uploader.dart';

class FakeUploader implements ProofUploader {
  int uploads = 0;

  @override
  Future<String> upload(ProofFile file) async {
    uploads++;
    return 'payment-proofs/user-1/$uploads.jpg';
  }
}

class Sent {
  Sent(this.method, this.path, this.body, this.headers);

  final String method;
  final String path;
  final Map<String, dynamic>? body;
  final Map<String, String> headers;

  String get line => '$method $path';
}

class FakeServer {
  FakeServer({
    this.baseUrl = 'http://api.test',
    this.paymentStatuses = const [200, 200],
    this.customerExists = false,
    this.services,
  });

  final String baseUrl;
  final List<int> paymentStatuses;
  final bool customerExists;
  final List<Map<String, Object>>? services;

  final List<Sent> sent = [];
  final FakeUploader uploader = FakeUploader();
  int _paymentCalls = 0;

  CheckoutService checkout({
    required OrderDraft draft,
    required BookingDetails booking,
    required UserModel? user,
  }) {
    final mock = MockClient((request) async {
      final body = request.body.isEmpty
          ? null
          : jsonDecode(request.body) as Map<String, dynamic>;
      sent.add(Sent(request.method, request.url.path, body, request.headers));

      http.Response json(Object? data, [int status = 200]) => http.Response(
            jsonEncode(data),
            status,
            headers: {'content-type': 'application/json'},
          );

      switch ('${request.method} ${request.url.path}') {
        case 'GET /api/v1/customers/me':
          return customerExists
              ? json({'customerId': 'c-1'})
              : json({'code': 'not_found', 'message': 'No profile.'}, 404);
        case 'POST /api/v1/customers':
          return json('c-1');
        case 'GET /api/v1/services':
          return json(services ??
              [
                {
                  'serviceId': 'svc-1',
                  'serviceName': 'Laundry per kg',
                  'price': 42,
                  'isActive': true,
                },
              ]);
        case 'GET /api/v1/delivery-zones':
          return json([
            {
              'zoneId': 'zone-bfn',
              'name': 'Bloemfontein',
              'fee': 50,
              'isActive': true,
            },
          ]);
        case 'POST /api/v1/orders':
          return json('order-1');
        case 'GET /api/v1/orders/order-1':
          return json({'orderId': 'order-1', 'ticketNumber': 'ORD-1024'});
        default:
          if (request.url.path.endsWith('/payments')) {
            final status = paymentStatuses[_paymentCalls++];
            return status == 200
                ? json('payment-$_paymentCalls')
                : json({'code': 'server_error', 'message': 'Oops.'}, status);
          }
          return json({'code': 'not_found', 'message': 'Unknown.'}, 404);
      }
    });

    return CheckoutService(
      draft: draft,
      booking: booking,
      user: user,
      api: OrderApi(
        client: ApiClient(
          httpClient: mock,
          baseUrl: baseUrl,
          accessToken: () async => 'test-token',
        ),
      ),
      uploader: uploader,
    );
  }
}

void main() {
  final user = UserModel(
    fullName: 'Thandi Mokoena',
    email: 'thandi@example.com',
    phoneNumber: '0712345678',
    password: '',
  );

  final booking = BookingDetails(
    pickupDate: DateTime(2026, 10, 24),
    pickupStart: const TimeOfDay(hour: 8, minute: 0),
    pickupEnd: const TimeOfDay(hour: 10, minute: 0),
    deliveryDate: DateTime(2026, 10, 26),
    deliveryStart: const TimeOfDay(hour: 14, minute: 0),
    deliveryEnd: const TimeOfDay(hour: 16, minute: 0),
    address: '12 Church Street, Bloemfontein',
    instructions: 'Call on arrival',
  );

  OrderDraft draft({bool delivery = true}) => OrderDraft(
        category: 'Wash & Fold',
        lines: const [
          OrderLine(name: 'Laundry per kg', unitPrice: 42, quantity: 3),
        ],
        deliveryOption: delivery ? 'Deliver to me' : 'Collect at depot',
      );

  final proof = ProofFile(name: 'p.jpg', bytes: Uint8List.fromList([1, 2, 3]));

  test('creating the order returns its number, once, with the right data',
      () async {
    final server = FakeServer();
    final checkout =
        server.checkout(draft: draft(), booking: booking, user: user);

    final placed = await checkout.createOrder();
    expect(placed.orderId, 'order-1');
    expect(placed.orderNumber, 'ORD-1024');

    // Asking again does not create a second order.
    await checkout.createOrder();
    expect(server.sent.where((s) => s.line == 'POST /api/v1/orders'),
        hasLength(1));

    expect(server.sent.map((s) => s.line).toList(), [
      'GET /api/v1/customers/me',
      'POST /api/v1/customers',
      'GET /api/v1/services',
      'GET /api/v1/delivery-zones',
      'POST /api/v1/orders',
      'GET /api/v1/orders/order-1',
    ]);

    // Every call is made as the signed-in user.
    expect(
        server.sent.every((s) => s.headers['Authorization'] == 'Bearer test-token'),
        isTrue);

    final customer = server.sent[1].body!;
    expect(customer['firstName'], 'Thandi');
    expect(customer['lastName'], 'Mokoena');
    expect(customer['address'], '12 Church Street, Bloemfontein');

    final order = server.sent[4].body!;
    expect(order['deliveryZoneId'], 'zone-bfn');
    expect(order['fulfillmentMethod'], 'Delivery');
    expect(order['items'], [
      {
        'serviceId': 'svc-1',
        'quantity': 3,
        'unitPrice': 37.8, // 10% off: delivery is 2 days after pickup
        'description': 'Laundry per kg',
      },
    ]);
    expect(order['specialInstructions'], contains('24/10/2026 08:00-10:00'));
    expect(order['specialInstructions'], contains('12 Church Street'));
    expect(order['specialInstructions'], contains('Call on arrival'));
  });

  test('bank transfer: proof is uploaded and both payments reference it',
      () async {
    final server = FakeServer();
    final checkout =
        server.checkout(draft: draft(), booking: booking, user: user);

    await checkout.createOrder();
    final placed = await checkout.pay(PaymentMethod.eft, proof: proof);

    expect(placed.orderNumber, 'ORD-1024');
    expect(server.uploader.uploads, 1);

    final payments =
        server.sent.where((s) => s.path.endsWith('/payments')).toList();
    expect(payments, hasLength(2));

    expect(payments[0].body!['paymentType'], 'Orderpayment');
    expect(payments[0].body!['paymentMethod'], 'EFT');
    expect(payments[0].body!['proofOfPaymentReference'],
        'payment-proofs/user-1/1.jpg');

    expect(payments[1].body!['paymentType'], 'DeliveryFee');
    expect(payments[1].body!['paymentMethod'], 'EFT');
    expect(payments[1].body!['proofOfPaymentReference'],
        'payment-proofs/user-1/1.jpg');
  });

  test('cash on collection: one payment, no proof, no upload', () async {
    final server = FakeServer(customerExists: true, paymentStatuses: const [200]);
    final checkout = server.checkout(
        draft: draft(delivery: false), booking: booking, user: user);

    await checkout.pay(PaymentMethod.cash);

    expect(server.uploader.uploads, 0);
    final payments =
        server.sent.where((s) => s.path.endsWith('/payments')).toList();
    expect(payments, hasLength(1));
    expect(payments.single.body!['paymentMethod'], 'CashOnDelivery');
    expect(payments.single.body!['proofOfPaymentReference'], isNull);
    // Existing customers are not registered again.
    expect(server.sent.any((s) => s.line == 'POST /api/v1/customers'), isFalse);
    expect(
      server.sent.firstWhere((s) => s.line == 'POST /api/v1/orders').body![
          'fulfillmentMethod'],
      'DropOff',
    );
  });

  test('cash orders send only the order payment, even for delivery',
      () async {
    final server = FakeServer(paymentStatuses: const [200]);
    final checkout =
        server.checkout(draft: draft(), booking: booking, user: user);

    await checkout.pay(PaymentMethod.cash);

    expect(
      server.sent.where((s) => s.path.endsWith('/payments')),
      hasLength(1),
    );
  });

  test('bank transfer without proof is refused before anything is sent', () {
    final server = FakeServer();
    final checkout =
        server.checkout(draft: draft(), booking: booking, user: user);

    expect(
      () => checkout.pay(PaymentMethod.eft),
      throwsA(isA<ApiException>()
          .having((e) => e.message, 'message', contains('proof of payment'))),
    );
    expect(server.sent, isEmpty);
  });

  test('items missing from the server catalogue are named, no order made',
      () async {
    final server = FakeServer(services: const []);
    final checkout =
        server.checkout(draft: draft(), booking: booking, user: user);

    await expectLater(
      checkout.createOrder(),
      throwsA(isA<ApiException>().having(
          (e) => e.message, 'message', contains('Laundry per kg'))),
    );
    expect(server.sent.any((s) => s.path == '/api/v1/orders'), isFalse);
  });

  test('without a server address it says so instead of failing silently',
      () async {
    final server = FakeServer(baseUrl: '');
    final checkout =
        server.checkout(draft: draft(), booking: booking, user: user);

    await expectLater(
      checkout.createOrder(),
      throwsA(isA<ApiException>()
          .having((e) => e.message, 'message', contains('not set up'))),
    );
    expect(server.sent, isEmpty);
  });

  test('retrying after a payment failure does not create a second order',
      () async {
    final server = FakeServer(paymentStatuses: const [500, 200, 200]);
    final checkout =
        server.checkout(draft: draft(), booking: booking, user: user);

    await expectLater(
      checkout.pay(PaymentMethod.eft, proof: proof),
      throwsA(isA<ApiException>()),
    );

    final placed = await checkout.pay(PaymentMethod.eft, proof: proof);

    expect(placed.orderId, 'order-1');
    expect(server.sent.where((s) => s.line == 'POST /api/v1/orders'),
        hasLength(1));
    expect(server.sent.where((s) => s.path.endsWith('/payments')), hasLength(3));
  });

  test('API errors surface the server message; 401 asks to sign in again',
      () async {
    final client = ApiClient(
      httpClient: MockClient((request) async => request.url.path == '/a'
          ? http.Response(
              jsonEncode({'code': 'business_rule', 'message': 'Not allowed.'}),
              400)
          : http.Response('', 401)),
      baseUrl: 'http://api.test',
      accessToken: () async => null,
    );

    await expectLater(
      client.get('/a'),
      throwsA(isA<ApiException>()
          .having((e) => e.message, 'message', 'Not allowed.')
          .having((e) => e.code, 'code', 'business_rule')),
    );
    await expectLater(
      client.get('/b'),
      throwsA(isA<ApiException>()
          .having((e) => e.message, 'message', 'Please sign in again.')),
    );
  });
}
