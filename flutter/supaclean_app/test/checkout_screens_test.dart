import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supaclean/models/app_notification.dart';
import 'package:supaclean/models/booking_details.dart';
import 'package:supaclean/models/order_draft.dart';
import 'package:supaclean/models/user_model.dart';
import 'package:supaclean/services/api_client.dart';
import 'package:supaclean/views/bank_transfer.dart';
import 'package:supaclean/views/cash_on_delivery.dart';
import 'package:supaclean/views/notification_center_screen.dart';
import 'package:supaclean/views/payment_screen.dart';

import 'checkout_service_test.dart' show FakeServer;

void bigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

void main() {
  final booking = BookingDetails(
    pickupDate: DateTime(2026, 10, 24),
    pickupStart: const TimeOfDay(hour: 8, minute: 0),
    pickupEnd: const TimeOfDay(hour: 10, minute: 0),
    deliveryDate: DateTime(2026, 10, 26),
    deliveryStart: const TimeOfDay(hour: 14, minute: 0),
    deliveryEnd: const TimeOfDay(hour: 16, minute: 0),
    address: '12 Church Street',
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

  group('Payment (teammate design, now sending the order)', () {
    Future<FakeServer> pumpPayment(
      WidgetTester tester, {
      String baseUrl = 'http://api.test',
    }) async {
      bigScreen(tester);
      final server = FakeServer(
        baseUrl: baseUrl,
        customerExists: true,
        paymentStatuses: const [200],
      );
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

    testWidgets('keeps all three payment options, including card',
        (tester) async {
      await pumpPayment(tester);

      expect(find.text('Card Payment'), findsOneWidget);
      expect(find.text('EFT / Bank Transfer'), findsOneWidget);
      expect(find.text('Cash on Delivery'), findsOneWidget);
    });

    testWidgets(
        'bank transfer creates the order first and shows its number as the '
        'reference', (tester) async {
      final server = await pumpPayment(tester);

      await tester.tap(find.text('EFT / Bank Transfer'));
      await tester.pump();
      await tester.tap(find.text('Pay R84.00'));
      await tester.pumpAndSettle();

      expect(find.byType(BankTransferPayment), findsOneWidget);
      expect(find.text('Order ID #ORD-1024'), findsOneWidget);
      expect(server.sent.where((s) => s.line == 'POST /api/v1/orders'),
          hasLength(1));
      // Nothing is paid until a proof is chosen and submitted.
      expect(server.sent.any((s) => s.path.endsWith('/payments')), isFalse);

      // The Submit button is at the bottom of the long list.
      await tester.scrollUntilVisible(
        find.text('Submit proof of payment'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      final submit = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Submit proof of payment'),
      );
      expect(submit.onPressed, isNull);
    });

    testWidgets('cash on delivery sends the order and its payment',
        (tester) async {
      final server = await pumpPayment(tester);

      await tester.tap(find.text('Cash on Delivery'));
      await tester.pump();
      await tester.tap(find.text('Pay R84.00'));
      await tester.pumpAndSettle();

      expect(find.byType(CashOnDeliveryScreen), findsOneWidget);
      expect(find.text('Order #ORD-1024'), findsOneWidget);

      final payments =
          server.sent.where((s) => s.path.endsWith('/payments')).toList();
      expect(payments, hasLength(1));
      expect(payments.single.body!['paymentMethod'], 'CashOnDelivery');
    });

    testWidgets('a server problem is shown instead of failing silently',
        (tester) async {
      await pumpPayment(tester, baseUrl: '');

      await tester.tap(find.text('Cash on Delivery'));
      await tester.pump();
      await tester.tap(find.text('Pay R84.00'));
      await tester.pumpAndSettle();

      expect(find.textContaining('not set up'), findsOneWidget);
      expect(find.byType(CashOnDeliveryScreen), findsNothing);
    });
  });

  group('Notification Center', () {
    testWidgets('shows what the server sent, newest first', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationCenterScreen(
            load: () async => [
              AppNotification.fromApi({
                'title': 'Payment confirmed',
                'message':
                    'Your order payment for order ORD-1024 has been verified.',
                'orderId': 'abc',
                'sentAt': '2026-10-23T10:00:00Z',
              }),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Your order payment for order ORD-1024 has been verified.'),
        findsOneWidget,
      );
      expect(find.text('Payment'), findsOneWidget);
    });

    testWidgets('error state offers a retry that loads again', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: NotificationCenterScreen(
            load: () async {
              if (++calls == 1) throw const ApiException('Server is down.');
              return [];
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Server is down.'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('No notifications yet'), findsOneWidget);
    });

    test('stage is worked out from the wording', () {
      NotificationStatus of(String message) =>
          AppNotification.fromApi({'title': '', 'message': message}).status;

      expect(of('Thank you, payment received'), NotificationStatus.payment);
      expect(of('Order ORD-1 is being cleaned'), NotificationStatus.inCleaning);
      expect(of('Picked up by the driver'), NotificationStatus.pickedUp);
      expect(of('Your order has been delivered'), NotificationStatus.delivered);
      expect(of('New order confirmed'), NotificationStatus.confirmed);
      expect(of('Hello'), NotificationStatus.update);
    });
  });
}
