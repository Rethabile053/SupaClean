import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supaclean/models/laundry_order.dart';
import 'package:supaclean/services/api_client.dart';
import 'package:supaclean/views/my_orders_screen.dart';

LaundryOrder order(String number, String serverStatus) =>
    LaundryOrder.fromApi({
      'orderId': 'id-$number',
      'orderNumber': number,
      'orderStatus': serverStatus,
      'orderDate': '2026-10-20T08:00:00Z',
      'items': [
        {'description': 'Shirt', 'quantity': 1},
      ],
    });

void main() {
  group('LaundryOrder.canCancel', () {
    test('a new or accepted order can be cancelled', () {
      expect(order('SC-1', 'PendingInTake').canCancel, isTrue);
      expect(order('SC-2', 'Accepted').canCancel, isTrue);
    });

    test('an order we have collected or are working on cannot', () {
      for (final status in [
        'ReadyForCollection',
        'Collected',
        'Washing',
        'OutForDelivery',
        'Completed',
        'Cancelled',
      ]) {
        expect(order('SC-3', status).canCancel, isFalse, reason: status);
      }
    });
  });

  group('My Orders cancel button', () {
    Future<void> open(
      WidgetTester tester,
      List<LaundryOrder> Function() orders, {
      Future<void> Function(String)? cancel,
    }) async {
      tester.view.physicalSize = const Size(1400, 3000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: MyOrdersScreen(
          load: () async => orders(),
          cancel: cancel,
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('shows only on orders that can still be cancelled',
        (tester) async {
      await open(tester, () => [
            order('SC-1', 'PendingInTake'),
            order('SC-2', 'Washing'),
          ]);

      expect(find.text('Cancel order'), findsOneWidget);
    });

    testWidgets('asks first, and Keep order leaves the order alone',
        (tester) async {
      final cancelled = <String>[];
      await open(tester, () => [order('SC-1', 'PendingInTake')],
          cancel: (id) async => cancelled.add(id));

      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel this order?'), findsOneWidget);

      await tester.tap(find.text('Keep order'));
      await tester.pumpAndSettle();

      expect(cancelled, isEmpty);
      expect(find.text('Cancel order'), findsOneWidget);
    });

    testWidgets('confirming cancels it and moves it to the Cancelled tab',
        (tester) async {
      var status = 'PendingInTake';
      final cancelled = <String>[];
      await open(
        tester,
        () => [order('SC-1', status)],
        cancel: (id) async {
          cancelled.add(id);
          status = 'Cancelled';
        },
      );

      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel order').last);
      await tester.pumpAndSettle();

      expect(cancelled, ['id-SC-1']);
      expect(find.text('Order SC-1 has been cancelled.'), findsOneWidget);
      expect(find.text('No orders in this category'), findsOneWidget);

      await tester.tap(find.text('Cancelled'));
      await tester.pumpAndSettle();
      expect(find.text('Order #SC-1'), findsOneWidget);
      expect(find.text('Cancel order'), findsNothing);
    });

    testWidgets('shows the server\'s reason when it refuses', (tester) async {
      await open(
        tester,
        () => [order('SC-1', 'PendingInTake')],
        cancel: (_) async => throw const ApiException(
          'This order can no longer be cancelled because it is already '
          'being processed. Please contact SupaClean.',
        ),
      );

      await tester.tap(find.text('Cancel order'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel order').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('can no longer be cancelled'), findsOneWidget);
    });
  });
}
