import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supaclean/models/booking_details.dart';
import 'package:supaclean/models/order_draft.dart';
import 'package:supaclean/services/api_client.dart';
import 'package:supaclean/services/order_api.dart';
import 'package:supaclean/views/payment_screen.dart';

OrderApi apiWith(List<Map<String, String>> payments) => OrderApi(
      client: ApiClient(
        baseUrl: 'http://api.test',
        accessToken: () async => 't',
        httpClient: MockClient((request) async => http.Response(
              '[${payments.map((p) => '{"paymentMethod":"${p['m']}"}').join(',')}]',
              200,
              headers: {'content-type': 'application/json'},
            )),
      ),
    );

void main() {
  group('how the last order was paid', () {
    test('cash on delivery if the order payment was cash', () async {
      // The delivery fee is always a bank transfer, so cash shows up beside EFT.
      final api = apiWith([
        {'m': 'EFT'},
        {'m': 'CashOnDelivery'},
      ]);
      expect(await api.paymentMethodUsed('o'), PaymentMethod.cash);
    });

    test('bank transfer otherwise', () async {
      expect(await apiWith([{'m': 'EFT'}]).paymentMethodUsed('o'),
          PaymentMethod.eft);
    });

    test('nothing on record', () async {
      expect(await apiWith([]).paymentMethodUsed('o'), isNull);
    });
  });

  group('payment screen', () {
    final booking = BookingDetails(
      pickupDate: DateTime(2026, 11, 2),
      pickupStart: const TimeOfDay(hour: 8, minute: 0),
      pickupEnd: const TimeOfDay(hour: 10, minute: 0),
      deliveryDate: DateTime(2026, 11, 3),
      deliveryStart: const TimeOfDay(hour: 14, minute: 0),
      deliveryEnd: const TimeOfDay(hour: 16, minute: 0),
      address: '12 Church Street, Bloemfontein',
    );

    Future<void> pump(WidgetTester tester, PaymentMethod? initial) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: PaymentScreen(
          booking: booking,
          servicePrice: 84,
          pickupFee: 0,
          deliveryFee: 0,
          initialMethod: initial,
        ),
      ));
    }

    testWidgets('opens on the earlier method, cash', (tester) async {
      await pump(tester, PaymentMethod.cash);
      expect(find.text('Continue • R84.00'), findsOneWidget);
    });

    testWidgets('opens on bank transfer when nothing was chosen before',
        (tester) async {
      await pump(tester, null);
      expect(find.text('Pay R84.00'), findsOneWidget);
    });
  });
}
