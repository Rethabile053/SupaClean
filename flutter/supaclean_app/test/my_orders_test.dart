import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supaclean/models/laundry_order.dart';
import 'package:supaclean/services/api_client.dart';
import 'package:supaclean/views/my_orders_screen.dart';

// An order as GET /api/v1/orders returns it. The times are midday UTC so the
// day is the same in any time zone the tests run in.
Map<String, dynamic> apiOrder({
  String status = 'PendingInTake',
  List<Map<String, dynamic>>? items,
  String? returnDate,
  String? deliveryDate = '2026-11-01T10:00:00Z',
  String? orderDate = '2026-10-28T10:00:00Z',
}) =>
    {
      'orderId': '8f62daee-bdb5-447c-a652-ebf10a262203',
      'orderStatus': status,
      'ticketNumber': null,
      'orderNumber': 'SC-1005',
      'grandTotal': 126.01,
      'deliveryFee': 100,
      'itemsTotal': 26.01,
      'orderDate': orderDate,
      'returnDate': returnDate,
      'pickupDate': '2026-10-29T08:00:00Z',
      'deliveryDate': deliveryDate,
      'items': items ??
          [
            {'description': 'Caps', 'quantity': 2, 'unitPrice': 56.7},
            {'description': 'Shorts', 'quantity': 1, 'unitPrice': 26.01},
          ],
    };

void main() {
  group('LaundryOrder.fromApi', () {
    test('uses the customer-facing order number, items and delivery date', () {
      final order = LaundryOrder.fromApi(apiOrder());

      expect(order.orderId, 'SC-1005');
      expect(order.service, 'Caps ×2, Shorts');
      expect(order.status, 'Order Placed');
      expect(order.currentStep, 0);
      expect(order.date, 'Ready on 01 Nov 2026');
      expect(order.dateCompletion!.toUtc(), DateTime.utc(2026, 11, 1, 10));
      expect(order.isActive, isTrue);
    });

    test('long orders are shortened', () {
      final order = LaundryOrder.fromApi(apiOrder(items: [
        {'description': 'A', 'quantity': 1},
        {'description': 'B', 'quantity': 1},
        {'description': 'C', 'quantity': 1},
        {'description': 'D', 'quantity': 1},
      ]));

      expect(order.service, 'A, B +2 more');
    });

    test('a finished order says when it was completed', () {
      final order = LaundryOrder.fromApi(apiOrder(
        status: 'Completed',
        returnDate: '2026-11-02T10:00:00Z',
      ));

      expect(order.date, 'Completed on 02 Nov 2026');
    });

    test('without a chosen delivery date it says when it was placed', () {
      final order = LaundryOrder.fromApi(apiOrder(deliveryDate: null));

      expect(order.date, 'Placed on 28 Oct 2026');
      expect(order.dateCompletion, isNull);
    });

    test('an older server without dates still works', () {
      final order = LaundryOrder.fromApi(
          apiOrder(deliveryDate: null, orderDate: null));

      expect(order.date, '');
      expect(order.dateCompletion, isNull);
    });

    test('server stages become the four tracking steps', () {
      LaundryOrder of(String s) => LaundryOrder.fromApi(apiOrder(status: s));

      expect(of('Accepted').status, 'Order Placed');
      expect(of('Washing').status, 'In Cleaning');
      expect(of('Washing').currentStep, 1);
      expect(of('Ironing').currentStep, 1);
      expect(of('ReadyForCustomerCollection').status, 'Ready for Collection');
      expect(of('ReadyForCustomerCollection').currentStep, 2);
      expect(of('OutForDelivery').status, 'Out for Delivery');
      expect(of('Completed').status, 'Completed');
      expect(of('Completed').currentStep, 3);
      expect(of('Completed').isActive, isFalse);
      expect(of('Cancelled').isActive, isFalse);
      expect(of('Cancelled').date, 'Cancelled');
      expect(of('Rejected').status, 'Cancelled');
    });
  });

  group('My Orders screen', () {
    void bigScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
    }

    testWidgets('shows the order that was placed, not made-up ones',
        (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(MaterialApp(
        home: MyOrdersScreen(
          load: () async => [LaundryOrder.fromApi(apiOrder())],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Order #SC-1005'), findsOneWidget);
      expect(find.text('Caps ×2, Shorts'), findsOneWidget);
      expect(find.text('Order Placed'), findsOneWidget);
      expect(find.text('Ready on 01 Nov 2026'), findsOneWidget);

      // The old placeholder orders are gone.
      expect(find.text('Order #1024'), findsNothing);
      expect(find.text('Wash & Fold'), findsNothing);
    });

    testWidgets('finished orders are on the Completed tab', (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(MaterialApp(
        home: MyOrdersScreen(
          load: () async =>
              [LaundryOrder.fromApi(apiOrder(status: 'Completed'))],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No orders in this category'), findsOneWidget);

      await tester.tap(find.text('Completed'));
      await tester.pump();
      expect(find.text('Order #SC-1005'), findsOneWidget);
    });

    testWidgets('a customer with no orders sees an empty list',
        (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(MaterialApp(
        home: MyOrdersScreen(load: () async => []),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No orders in this category'), findsOneWidget);
    });

    testWidgets('a server problem is shown, and Try again loads again',
        (tester) async {
      bigScreen(tester);
      var calls = 0;
      await tester.pumpWidget(MaterialApp(
        home: MyOrdersScreen(
          load: () async {
            if (++calls == 1) throw const ApiException('Server is down.');
            return [LaundryOrder.fromApi(apiOrder())];
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Server is down.'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Order #SC-1005'), findsOneWidget);
    });
  });
}
