import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supaclean/models/booking_details.dart';
import 'package:supaclean/models/order_draft.dart';
import 'package:supaclean/models/points.dart';
import 'package:supaclean/models/user_model.dart';
import 'package:supaclean/services/points_store.dart';
import 'package:supaclean/views/payment_screen.dart';
import 'package:supaclean/views/points_screen.dart';
import 'package:supaclean/widgets/points_card.dart';

import 'checkout_service_test.dart' show FakeServer;

void main() {
  tearDown(() => PointsStore.instance.setForTest(null));

  group('the rules', () {
    const summary = PointsSummary(balance: 125);

    test('10 points are worth R1, in whole rands', () {
      expect(summary.balanceValue, 12);
      expect(const PointsSummary(balance: 9).balanceValue, 0);
    });

    test('the discount is limited by the balance and by half the laundry', () {
      expect(summary.maxDiscount(200), 12);
      expect(const PointsSummary(balance: 5000).maxDiscount(100), 50);
      expect(const PointsSummary(balance: 5000).maxDiscount(75), 37);
      expect(const PointsSummary(balance: 0).maxDiscount(200), 0);
    });

    test('1 point is earned for every R2 paid', () {
      expect(summary.pointsEarned(200), 100);
      expect(summary.pointsEarned(75), 37);
      expect(summary.pointsEarned(0), 0);
    });

    test('reads what the server sends', () {
      final parsed = PointsSummary.fromApi({
        'balance': 135,
        'pointsPerRand': 10,
        'randSpentPerPoint': 2,
        'maxShareOfItems': 0.5,
        'history': [
          {
            'kind': 'Earned',
            'points': 15,
            'description': 'Order SC-1021 delivered',
            'createdAt': '2026-10-30T10:00:00Z',
          },
        ],
      });
      expect(parsed.balance, 135);
      expect(parsed.history.single.points, 15);
      expect(parsed.history.single.description, 'Order SC-1021 delivered');
    });
  });

  group('Home and the points page', () {
    testWidgets('the Home card is hidden until the points are known',
        (tester) async {
      final store = PointsStore(fetch: () async => null);
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PointsCard(store: store))),
      );
      expect(find.byKey(const Key('home-points')), findsNothing);

      store.setForTest(const PointsSummary(balance: 120));
      await tester.pump();
      expect(find.text('120 points (R12)'), findsOneWidget);
    });

    testWidgets('the points page shows the balance and the history',
        (tester) async {
      final store = PointsStore(fetch: () async => null)
        ..setForTest(PointsSummary(balance: 135, history: [
          PointsEntry(
            kind: 'Earned',
            points: 15,
            description: 'Order SC-1021 delivered',
            time: DateTime(2026, 10, 30),
          ),
          PointsEntry(
            kind: 'Redeemed',
            points: -120,
            description: 'Used on a new order',
            time: DateTime(2026, 10, 31),
          ),
        ]));

      await tester.pumpWidget(MaterialApp(home: PointsScreen(store: store)));
      await tester.pump();

      expect(find.text('135 points'), findsOneWidget);
      expect(find.text('Worth R13 off your next order'), findsOneWidget);
      expect(find.text('Order SC-1021 delivered'), findsOneWidget);
      expect(find.text('+15'), findsOneWidget);
      expect(find.text('-120'), findsOneWidget);
    });
  });

  group('Payment: use your points?', () {
    final booking = BookingDetails(
      pickupDate: DateTime(2026, 10, 24),
      pickupStart: const TimeOfDay(hour: 8, minute: 0),
      pickupEnd: const TimeOfDay(hour: 10, minute: 0),
      deliveryDate: DateTime(2026, 10, 25), // next day: no 10% discount
      deliveryStart: const TimeOfDay(hour: 14, minute: 0),
      deliveryEnd: const TimeOfDay(hour: 16, minute: 0),
      address: '12 Church Street, Bloemfontein',
    );

    const draft = OrderDraft(
      category: 'Wash & Fold',
      lines: [OrderLine(name: 'Laundry per kg', unitPrice: 42, quantity: 2)],
      deliveryOption: 'Collect at depot',
    );

    final user = UserModel(
      fullName: 'Thandi Mokoena',
      email: 't@example.com',
      phoneNumber: '0712345678',
      password: '',
    );

    Future<FakeServer> pumpPayment(
      WidgetTester tester, {
      required int balance,
      double serverDiscount = 12,
    }) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      final server = FakeServer(
        customerExists: true,
        paymentStatuses: const [200],
        pointsDiscount: serverDiscount,
      );
      PointsStore.instance.setForTest(PointsSummary(balance: balance));
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentScreen(
            booking: booking,
            servicePrice: 84,
            pickupFee: 0,
            deliveryFee: 0,
            checkout:
                server.checkout(draft: draft, booking: booking, user: user),
          ),
        ),
      );
      return server;
    }

    testWidgets('asks first, and Yes takes the points off the total',
        (tester) async {
      await pumpPayment(tester, balance: 120);

      expect(find.text('You have 120 points (R12)'), findsOneWidget);
      expect(find.text('Pay R84.00'), findsOneWidget);   // nothing taken yet

      await tester.tap(find.byKey(const Key('use-points-yes')));
      await tester.pump();

      expect(find.text('Points discount'), findsOneWidget);
      expect(find.text('-R12.00'), findsOneWidget);
      expect(find.text('Pay R72.00'), findsOneWidget);
    });

    testWidgets('No keeps the full price', (tester) async {
      await pumpPayment(tester, balance: 120);

      await tester.tap(find.byKey(const Key('use-points-no')));
      await tester.pump();

      expect(find.text('Points discount'), findsNothing);
      expect(find.text('Pay R84.00'), findsOneWidget);
    });

    testWidgets('points never take off more than half the laundry',
        (tester) async {
      await pumpPayment(tester, balance: 5000);

      await tester.tap(find.byKey(const Key('use-points-yes')));
      await tester.pump();

      expect(find.text('Pay R42.00'), findsOneWidget);   // half of R84
    });

    testWidgets('no prompt when there are too few points', (tester) async {
      await pumpPayment(tester, balance: 9);

      expect(find.byKey(const Key('use-points-yes')), findsNothing);
      expect(find.text('Pay R84.00'), findsOneWidget);
    });

    testWidgets('paying with points tells the server and uses its discount',
        (tester) async {
      final server = await pumpPayment(tester, balance: 120);

      await tester.tap(find.byKey(const Key('use-points-yes')));
      await tester.pump();
      await tester.tap(find.text('Cash on Delivery'));
      await tester.pump();
      await tester.tap(find.text('Continue • R72.00'));
      await tester.pumpAndSettle();

      final order =
          server.sent.firstWhere((s) => s.line == 'POST /api/v1/orders');
      expect(order.body!['usePoints'], true);
    });

    testWidgets('paying without points does not send the flag', (tester) async {
      final server = await pumpPayment(tester, balance: 120);

      await tester.tap(find.byKey(const Key('use-points-no')));
      await tester.pump();
      await tester.tap(find.text('Cash on Delivery'));
      await tester.pump();
      await tester.tap(find.text('Continue • R84.00'));
      await tester.pumpAndSettle();

      final order =
          server.sent.firstWhere((s) => s.line == 'POST /api/v1/orders');
      expect(order.body!.containsKey('usePoints'), isFalse);
    });
  });
}
