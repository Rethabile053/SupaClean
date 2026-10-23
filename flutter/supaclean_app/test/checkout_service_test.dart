import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supaclean/models/booking_details.dart';
import 'package:supaclean/models/order_draft.dart';
import 'package:supaclean/models/user_model.dart';
import 'package:supaclean/services/api_client.dart';
import 'package:supaclean/services/checkout_service.dart';
import 'package:supaclean/services/order_api.dart';
import 'package:supaclean/services/proof_uploader.dart';

class _FakeUploader implements ProofUploader {
  int uploads = 0;

  @override
  Future<String> upload(XFile file) async {
    uploads++;
    return 'payment-proofs/user-1/$uploads.jpg';
  }
}

class _Sent {
  _Sent(this.method, this.path, this.body, this.headers);

  final String method;
  final String path;
  final Map<String, dynamic>? body;
  final Map<String, String> headers;
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
    address: '12 Church Street',
    instructions: 'Call on arrival',
  );

  const zone = DeliveryZone(id: 'zone-1', name: 'Central', fee: 30);

  OrderDraft draft({bool delivery = true}) => OrderDraft(
        category: 'Wash & Fold',
        lines: const [
          OrderLine(name: 'Laundry per kg', unitPrice: 42, quantity: 3),
        ],
        deliveryOption: delivery ? 'Deliver to me' : 'Collect at depot',
        zone: delivery ? zone : null,
      );

  final proof = XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'p.jpg');

  /// A fake ASP.NET server. [paymentStatus] lets a test make payments fail.
  ({CheckoutService service, List<_Sent> sent, _FakeUploader uploader}) setUp({
    String baseUrl = 'http://api.test',
    List<int> paymentStatuses = const [200, 200],
    bool customerExists = false,
    List<Map<String, Object>>? services,
  }) {
    final sent = <_Sent>[];
    final uploader = _FakeUploader();
    var paymentCalls = 0;

    final mock = MockClient((request) async {
      final body = request.body.isEmpty
          ? null
          : jsonDecode(request.body) as Map<String, dynamic>;
      sent.add(_Sent(request.method, request.url.path, body, request.headers));

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
        case 'POST /api/v1/orders':
          return json('order-1');
        default:
          if (request.url.path.endsWith('/payments')) {
            final status = paymentStatuses[paymentCalls++];
            return status == 200
                ? json('payment-$paymentCalls')
                : json({'code': 'server_error', 'message': 'Oops.'}, status);
          }
          return json({'code': 'not_found', 'message': 'Unknown.'}, 404);
      }
    });

    final api = OrderApi(
      client: ApiClient(
        httpClient: mock,
        baseUrl: baseUrl,
        accessToken: () async => 'test-token',
      ),
    );
    return (
      service: CheckoutService(api: api, uploader: uploader),
      sent: sent,
      uploader: uploader,
    );
  }

  test('EFT delivery order: proof, order, then order and delivery payments',
      () async {
    final t = setUp();

    final result = await t.service.place(
      draft: draft(),
      booking: booking,
      method: PaymentMethod.eft,
      user: user,
      proof: proof,
    );

    expect(result.orderId, 'order-1');
    expect(t.uploader.uploads, 1);
    expect(
      t.sent.map((s) => '${s.method} ${s.path}').toList(),
      [
        'GET /api/v1/customers/me',
        'POST /api/v1/customers',
        'GET /api/v1/services',
        'POST /api/v1/orders',
        'POST /api/v1/orders/order-1/payments',
        'POST /api/v1/orders/order-1/payments',
      ],
    );

    // Every call is made as the signed-in user.
    expect(t.sent.every((s) => s.headers['Authorization'] == 'Bearer test-token'),
        isTrue);

    final customer = t.sent[1].body!;
    expect(customer['firstName'], 'Thandi');
    expect(customer['lastName'], 'Mokoena');
    expect(customer['address'], '12 Church Street');

    final order = t.sent[3].body!;
    expect(order['fulfillmentMethod'], 'Delivery');
    expect(order['deliveryZoneId'], 'zone-1');
    expect(order['items'], [
      {
        'serviceId': 'svc-1',
        'quantity': 3,
        'unitPrice': 42.0,
        'description': 'Laundry per kg',
      },
    ]);
    expect(order['specialInstructions'], contains('24/10/2026 08:00-10:00'));
    expect(order['specialInstructions'], contains('12 Church Street'));
    expect(order['specialInstructions'], contains('Call on arrival'));

    final itemsPayment = t.sent[4].body!;
    expect(itemsPayment['paymentType'], 'Orderpayment');
    expect(itemsPayment['paymentMethod'], 'EFT');
    expect(itemsPayment['proofOfPaymentReference'], 'payment-proofs/user-1/1.jpg');

    final feePayment = t.sent[5].body!;
    expect(feePayment['paymentType'], 'DeliveryFee');
    expect(feePayment['paymentMethod'], 'EFT');
    expect(feePayment['proofOfPaymentReference'], 'payment-proofs/user-1/1.jpg');
  });

  test('cash on collection needs no proof and one payment', () async {
    final t = setUp(customerExists: true, paymentStatuses: const [200]);

    await t.service.place(
      draft: draft(delivery: false),
      booking: booking,
      method: PaymentMethod.cash,
      user: user,
    );

    expect(t.uploader.uploads, 0);
    final payments =
        t.sent.where((s) => s.path.endsWith('/payments')).toList();
    expect(payments, hasLength(1));
    expect(payments.single.body!['paymentMethod'], 'CashOnDelivery');
    expect(payments.single.body!['proofOfPaymentReference'], isNull);
    // Existing customers are not registered again.
    expect(t.sent.any((s) => s.method == 'POST' && s.path == '/api/v1/customers'),
        isFalse);
    expect(t.sent.firstWhere((s) => s.path == '/api/v1/orders').body![
        'fulfillmentMethod'], 'DropOff');
  });

  test('cash on delivery still needs proof for the delivery fee', () {
    final t = setUp();

    expect(
      () => t.service.place(
        draft: draft(),
        booking: booking,
        method: PaymentMethod.cash,
        user: user,
      ),
      throwsA(isA<ApiException>().having(
          (e) => e.message, 'message', contains('proof of payment'))),
    );
    expect(CheckoutService.needsProof(draft(), PaymentMethod.cash), isTrue);
    expect(
        CheckoutService.needsProof(draft(delivery: false), PaymentMethod.cash),
        isFalse);
  });

  test('delivery without an area is refused before anything is sent',
      () async {
    final t = setUp();
    const noZone = OrderDraft(
      category: 'Wash & Fold',
      lines: [OrderLine(name: 'Laundry per kg', unitPrice: 42, quantity: 1)],
    );

    await expectLater(
      t.service.place(
        draft: noZone,
        booking: booking,
        method: PaymentMethod.eft,
        user: user,
        proof: proof,
      ),
      throwsA(isA<ApiException>()
          .having((e) => e.message, 'message', contains('delivery area'))),
    );
    expect(t.sent, isEmpty);
  });

  test('items missing from the server catalogue are named, no order made',
      () async {
    final t = setUp(services: const []);

    await expectLater(
      t.service.place(
        draft: draft(),
        booking: booking,
        method: PaymentMethod.eft,
        user: user,
        proof: proof,
      ),
      throwsA(isA<ApiException>().having(
          (e) => e.message, 'message', contains('Laundry per kg'))),
    );
    expect(t.sent.any((s) => s.path == '/api/v1/orders'), isFalse);
  });

  test('without a server address it says so instead of failing silently',
      () async {
    final t = setUp(baseUrl: '');

    await expectLater(
      t.service.place(
        draft: draft(),
        booking: booking,
        method: PaymentMethod.eft,
        user: user,
        proof: proof,
      ),
      throwsA(isA<ApiException>()
          .having((e) => e.message, 'message', contains('not set up'))),
    );
    expect(t.sent, isEmpty);
  });

  test('retrying after a payment failure does not create a second order',
      () async {
    final t = setUp(paymentStatuses: const [500, 200, 200]);

    await expectLater(
      t.service.place(
        draft: draft(),
        booking: booking,
        method: PaymentMethod.eft,
        user: user,
        proof: proof,
      ),
      throwsA(isA<ApiException>()),
    );

    final result = await t.service.place(
      draft: draft(),
      booking: booking,
      method: PaymentMethod.eft,
      user: user,
      proof: proof,
    );

    expect(result.orderId, 'order-1');
    expect(t.sent.where((s) => s.path == '/api/v1/orders'), hasLength(1));
    expect(t.sent.where((s) => s.path.endsWith('/payments')), hasLength(3));
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
