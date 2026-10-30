import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supaclean/models/laundry_order.dart';
import 'package:supaclean/services/api_client.dart';
import 'package:supaclean/views/track_order_screen.dart';

// An order as GET /api/v1/orders/{id} returns it. Times are midday UTC so the
// day is the same in any time zone the tests run in.
LaundryOrder order(
  String status, {
  List<(String, String)> history = const [],
}) =>
    LaundryOrder.fromApi({
      'orderId': '8f62daee-bdb5-447c-a652-ebf10a262203',
      'orderNumber': 'SC-1005',
      'orderStatus': status,
      'orderDate': '2026-10-28T10:00:00Z',
      'deliveryDate': '2026-11-01T10:00:00Z',
      'items': [
        {'description': 'Caps', 'quantity': 1},
      ],
      'statusHistory': [
        for (final (name, at) in history) {'status': name, 'changedAt': at},
      ],
    });

void main() {
  group('step times', () {
    test('each step gets the time the admin first moved the order into it', () {
      final o = order('Completed', history: const [
        ('PendingInTake', '2026-10-28T10:00:00Z'),
        ('Collected', '2026-10-29T08:00:00Z'),
        ('Washing', '2026-10-29T12:00:00Z'),
        ('ReadyForCustomerCollection', '2026-10-30T09:00:00Z'),
        ('Completed', '2026-11-01T10:00:00Z'),
      ]);

      expect(o.stepTimes[0]!.toUtc(), DateTime.utc(2026, 10, 28, 10));
      // Collected came first, so cleaning began then, not at Washing.
      expect(o.stepTimes[1]!.toUtc(), DateTime.utc(2026, 10, 29, 8));
      expect(o.stepTimes[2]!.toUtc(), DateTime.utc(2026, 10, 30, 9));
      expect(o.stepTimes[3]!.toUtc(), DateTime.utc(2026, 11, 1, 10));
    });

    test('a step the server never recorded has no time', () {
      final o = order('Washing', history: const [
        ('PendingInTake', '2026-10-28T10:00:00Z'),
        ('Washing', '2026-10-29T12:00:00Z'),
      ]);

      expect(o.stepTimes[2], isNull);
      expect(o.stepTimes[3], isNull);
    });

    test('cancelling is not a step', () {
      final o = order('Cancelled', history: const [
        ('PendingInTake', '2026-10-28T10:00:00Z'),
        ('Cancelled', '2026-10-29T12:00:00Z'),
      ]);

      expect(o.stepTimes[1], isNull);
      expect(o.stepTimes[2], isNull);
    });

    test('an order from before the history existed still knows when it began',
        () {
      final o = order('Washing');

      expect(o.stepTimes[0]!.toUtc(), DateTime.utc(2026, 10, 28, 10));
      expect(o.stepTimes[1], isNull);
    });

    test('the server id is kept for refreshing', () {
      expect(order('Washing').serverId, '8f62daee-bdb5-447c-a652-ebf10a262203');
    });
  });

  group('Track Order screen', () {
    void bigScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
    }

    Widget screen(LaundryOrder shown, Future<LaundryOrder> Function() load,
            {Duration? every}) =>
        MaterialApp(
          home: TrackOrderScreen(order: shown, load: load, refreshEvery: every),
        );

    testWidgets('shows the stage the admin set, with the times recorded',
        (tester) async {
      bigScreen(tester);
      final washing = order('Washing', history: const [
        ('PendingInTake', '2026-10-28T10:00:00Z'),
        ('Washing', '2026-10-29T12:00:00Z'),
      ]);
      await tester.pumpWidget(screen(washing, () async => washing));
      await tester.pumpAndSettle();

      expect(find.text('Order #SC-1005'), findsOneWidget);
      expect(find.text('In Cleaning'), findsNWidgets(2)); // badge + step
      expect(find.textContaining('28 Oct 2026'), findsOneWidget);
      // The time the step began, and the "Now: Washing · since ..." line.
      expect(find.textContaining('29 Oct 2026'), findsNWidgets(2));
      expect(find.textContaining('Now: Washing'), findsOneWidget);
      expect(find.text('Pending'), findsNWidgets(2));
      expect(find.text('Order delivered'), findsNothing);
    });

    testWidgets('picks up a status the admin changed after it opened',
        (tester) async {
      bigScreen(tester);
      final washing = order('Washing');
      final done = order('Completed', history: const [
        ('PendingInTake', '2026-10-28T10:00:00Z'),
        ('Completed', '2026-11-01T10:00:00Z'),
      ]);
      await tester.pumpWidget(screen(washing, () async => done));
      await tester.pumpAndSettle();

      expect(find.text('Order delivered'), findsOneWidget);
      expect(find.text('Your order has been delivered.'), findsOneWidget);
      expect(find.textContaining('1 Nov 2026'), findsOneWidget);
      // Every step is ticked off.
      expect(find.byIcon(Icons.check), findsNWidgets(4));
    });

    testWidgets('checks again on its own while open', (tester) async {
      bigScreen(tester);
      var calls = 0;
      await tester.pumpWidget(screen(order('Washing'), () async {
        calls++;
        return order(calls > 1 ? 'Completed' : 'Washing');
      }, every: const Duration(seconds: 30)));
      await tester.pump();
      expect(find.text('Order delivered'), findsNothing);

      await tester.pump(const Duration(seconds: 31));
      await tester.pump();
      expect(find.text('Order delivered'), findsOneWidget);

      // Leave the screen so its timer stops.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('shows Out for Delivery on the third step', (tester) async {
      bigScreen(tester);
      final out = order('OutForDelivery');
      await tester.pumpWidget(screen(out, () async => out));
      await tester.pumpAndSettle();

      expect(find.text('Out for Delivery'), findsNWidgets(2)); // badge + step
      expect(find.text('Ready for Collection'), findsNothing);
    });

    testWidgets('a cancelled order shows the cancelled message',
        (tester) async {
      bigScreen(tester);
      final cancelled = order('Cancelled');
      await tester.pumpWidget(screen(cancelled, () async => cancelled));
      await tester.pumpAndSettle();

      expect(find.text('Your order is cancelled.'), findsOneWidget);
      expect(find.text('In Cleaning'), findsNothing);
    });

    testWidgets('keeps showing the last status when the server cannot be reached',
        (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(screen(order('Washing'),
          () async => throw const ApiException('Server is down.')));
      await tester.pumpAndSettle();

      expect(find.text('In Cleaning'), findsNWidgets(2));
      expect(find.textContaining('Live updates are temporarily unavailable'),
          findsOneWidget);
    });
  });
}
