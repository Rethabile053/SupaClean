import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supaclean/models/app_notification.dart';
import 'package:supaclean/models/order_draft.dart';
import 'package:supaclean/services/api_client.dart';
import 'package:supaclean/views/date_time_screen.dart';
import 'package:supaclean/views/notification_center_screen.dart';
import 'package:supaclean/views/payment_screen.dart';
import 'package:supaclean/views/upload_proof_screen.dart';
import 'package:supaclean/widgets/primary_button.dart';

// A real 1x1 PNG, so Image.memory can decode it.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

void bigScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}

void main() {
  group('Upload proof of payment', () {
    Future<void> openProof(
      WidgetTester tester, {
      required Future<void> Function(XFile) onSubmit,
    }) async {
      bigScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UploadProofScreen(
                        amountDue: 126,
                        onSubmit: onSubmit,
                        pickImage: (_) async =>
                            XFile.fromData(_png, name: 'proof.png'),
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    Future<void> chooseFromGallery(WidgetTester tester) async {
      await tester.tap(find.text('Tap to add your proof'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from gallery'));
      await tester.pumpAndSettle();
    }

    PrimaryButton submitButton(WidgetTester tester) =>
        tester.widget<PrimaryButton>(find.byType(PrimaryButton));

    testWidgets('Submit is disabled until a photo is chosen, then sends it',
        (tester) async {
      XFile? sent;
      await openProof(tester, onSubmit: (file) async => sent = file);

      expect(find.text('R126.00'), findsOneWidget);
      expect(submitButton(tester).onPressed, isNull);

      await chooseFromGallery(tester);
      expect(find.text('Change photo'), findsOneWidget);
      expect(submitButton(tester).onPressed, isNotNull);

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(sent, isNotNull);
      expect(await sent!.readAsBytes(), _png);
      // The screen closes when the proof was sent.
      expect(find.byType(UploadProofScreen), findsNothing);
    });

    testWidgets('a failed upload shows the reason and lets the user retry',
        (tester) async {
      var attempts = 0;
      await openProof(
        tester,
        onSubmit: (_) async {
          attempts++;
          if (attempts == 1) throw const ApiException('The server is down.');
        },
      );

      await chooseFromGallery(tester);
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('The server is down.'), findsOneWidget);
      expect(find.byType(UploadProofScreen), findsOneWidget);
      expect(submitButton(tester).onPressed, isNotNull);

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.byType(UploadProofScreen), findsNothing);
    });
  });

  group('Delivery area and payment', () {
    const zones = [
      DeliveryZone(id: 'z1', name: 'Central', fee: 30),
      DeliveryZone(id: 'z2', name: 'Bayswater', fee: 45),
    ];

    const draft = OrderDraft(
      category: 'Wash & Fold',
      lines: [OrderLine(name: 'Laundry per kg', unitPrice: 42, quantity: 2)],
    );

    Future<void> pumpDateTime(WidgetTester tester, OrderDraft d) async {
      bigScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ChooseDateTimeScreen(
            orderSubtotal: d.subtotal,
            draft: d,
            loadZones: () async => zones,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('delivery orders must choose an area before continuing',
        (tester) async {
      await pumpDateTime(tester, draft);

      expect(find.text('Central · R30'), findsOneWidget);
      expect(find.text('Bayswater · R45'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '12 Church Street');
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(find.text('Please choose your delivery area'), findsOneWidget);
      expect(find.byType(PaymentScreen), findsNothing);

      await tester.tap(find.text('Bayswater · R45'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Payment shows the area's fee, bank transfer only, EFT preselected.
      expect(find.byType(PaymentScreen), findsOneWidget);
      expect(find.text('R45.00'), findsWidgets);
      expect(find.text('Card Payment'), findsNothing);
      expect(find.text('EFT / Bank Transfer'), findsOneWidget);
      expect(find.text('Cash on Delivery'), findsOneWidget);
    });

    testWidgets('collecting at the depot needs no delivery area',
        (tester) async {
      await pumpDateTime(
        tester,
        const OrderDraft(
          category: 'Wash & Fold',
          lines: [OrderLine(name: 'Laundry per kg', unitPrice: 42, quantity: 2)],
          deliveryOption: 'Collect at depot',
        ),
      );

      expect(find.text('Delivery Area'), findsNothing);

      await tester.enterText(find.byType(TextField).first, '12 Church Street');
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.byType(PaymentScreen), findsOneWidget);
    });

    testWidgets('a zone loading error can be retried', (tester) async {
      var calls = 0;
      bigScreen(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ChooseDateTimeScreen(
            draft: draft,
            loadZones: () async {
              if (++calls == 1) throw const ApiException('No connection.');
              return zones;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No connection.'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Central · R30'), findsOneWidget);
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
