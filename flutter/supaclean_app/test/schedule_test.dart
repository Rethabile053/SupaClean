import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supaclean/models/laundry_order.dart';
import 'package:supaclean/services/api_client.dart';
import 'package:supaclean/views/schedule_screen.dart';

// An order as GET /api/v1/orders returns it. Midday UTC keeps the day the same
// in any time zone the tests run in.
LaundryOrder order({
  String number = 'SC-1005',
  String status = 'PendingInTake',
  String? deliveryDate = '2026-11-01T10:00:00Z',
  String item = 'Caps',
}) =>
    LaundryOrder.fromApi({
      'orderId': 'id-$number',
      'orderNumber': number,
      'orderStatus': status,
      'orderDate': '2026-10-28T10:00:00Z',
      'deliveryDate': deliveryDate,
      'items': [
        {'description': item, 'quantity': 1},
      ],
    });

void main() {
  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  testWidgets('shows the order that was placed, on its delivery day',
      (tester) async {
    bigScreen(tester);
    await tester.pumpWidget(MaterialApp(
      home: ScheduleScreen(load: () async => [order()]),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Caps'), findsOneWidget);
    expect(find.text('Order #SC-1005 · Order Placed'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('NOV'), findsOneWidget);

    // The old placeholder order is gone.
    expect(find.text('Wash & Fold'), findsNothing);
  });

  testWidgets('earliest delivery comes first', (tester) async {
    bigScreen(tester);
    await tester.pumpWidget(MaterialApp(
      home: ScheduleScreen(
        load: () async => [
          order(number: 'SC-1', item: 'Later', deliveryDate: '2026-11-20T10:00:00Z'),
          order(number: 'SC-2', item: 'Sooner', deliveryDate: '2026-11-03T10:00:00Z'),
        ],
      ),
    ));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Sooner')).dy,
      lessThan(tester.getTopLeft(find.text('Later')).dy),
    );
  });

  testWidgets('finished orders and orders without a date are not listed',
      (tester) async {
    bigScreen(tester);
    await tester.pumpWidget(MaterialApp(
      home: ScheduleScreen(
        load: () async => [
          order(number: 'SC-1', status: 'Completed'),
          order(number: 'SC-2', status: 'Cancelled'),
          order(number: 'SC-3', deliveryDate: null),
        ],
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Nothing scheduled'), findsOneWidget);
  });

  testWidgets('a customer with no orders sees the empty message',
      (tester) async {
    bigScreen(tester);
    await tester.pumpWidget(MaterialApp(
      home: ScheduleScreen(load: () async => []),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Nothing scheduled'), findsOneWidget);
    expect(find.text('Place an order'), findsOneWidget);
  });

  testWidgets('a server problem is shown, and Try again loads again',
      (tester) async {
    bigScreen(tester);
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: ScheduleScreen(
        load: () async {
          if (++calls == 1) throw const ApiException('Server is down.');
          return [order()];
        },
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Server is down.'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Caps'), findsOneWidget);
  });
}
