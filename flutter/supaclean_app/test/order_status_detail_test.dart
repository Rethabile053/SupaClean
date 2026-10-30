import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supaclean/models/laundry_order.dart';
import 'package:supaclean/services/push_notification_service.dart';
import 'package:supaclean/views/track_order_screen.dart';

LaundryOrder order(
  String status, {
  List<(String, String)> history = const [],
}) =>
    LaundryOrder.fromApi({
      'orderId': '8f62daee-bdb5-447c-a652-ebf10a262203',
      'orderNumber': 'SC-1006',
      'orderStatus': status,
      'orderDate': '2026-10-28T10:00:00Z',
      'items': [
        {'description': 'Caps', 'quantity': 1},
      ],
      'statusHistory': [
        for (final (name, at) in history) {'status': name, 'changedAt': at},
      ],
    });

void main() {
  group('the exact status', () {
    test('is the admin\'s status in words', () {
      expect(order('Accepted').statusDetail, 'Accepted');
      expect(order('ReadyForCollection').statusDetail, 'Ready For Collection');
      expect(order('PendingInTake').statusDetail, 'Pending In Take');
      expect(order('OutForDelivery').statusDetail, 'Out For Delivery');
    });

    test('says when the order reached it, the latest time it was set', () {
      final o = order('Accepted', history: const [
        ('PendingInTake', '2026-10-28T10:00:00Z'),
        ('Accepted', '2026-10-30T01:49:00Z'),
      ]);

      expect(o.statusSince!.toUtc(), DateTime.utc(2026, 10, 30, 1, 49));
    });

    test('has no time when the server has no record of it', () {
      expect(order('Accepted').statusSince, isNull);
    });

    test('Accepted and Pending are different statuses on the same step', () {
      final placed = order('PendingInTake');
      final accepted = order('Accepted');

      expect(placed.currentStep, accepted.currentStep); // the screen's step
      expect(placed.statusDetail, isNot(accepted.statusDetail)); // but not the words
    });
  });

  group('Track Order', () {
    void bigScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
    }

    Widget screen(LaundryOrder shown, Future<LaundryOrder> Function() load) =>
        MaterialApp(home: TrackOrderScreen(order: shown, load: load));

    testWidgets('shows where the order is inside its step', (tester) async {
      bigScreen(tester);
      final accepted = order('Accepted', history: const [
        ('PendingInTake', '2026-10-28T10:00:00Z'),
        ('Accepted', '2026-10-30T01:49:00Z'),
      ]);
      await tester.pumpWidget(screen(accepted, () async => accepted));
      await tester.pumpAndSettle();

      expect(find.textContaining('Now: Accepted'), findsOneWidget);
      expect(find.textContaining('since 30 Oct 2026'), findsOneWidget);
    });

    testWidgets('a status change inside one step is now visible',
        (tester) async {
      bigScreen(tester);
      final placed = order('PendingInTake');
      final accepted = order('Accepted', history: const [
        ('Accepted', '2026-10-30T01:49:00Z'),
      ]);
      var current = placed;
      await tester.pumpWidget(screen(placed, () async => current));
      await tester.pumpAndSettle();
      expect(find.textContaining('Now: Pending In Take'), findsOneWidget);

      // The admin accepts it; the app is told by a push and looks again.
      current = accepted;
      PushNotificationService.instance.arrivals.add(null);
      await tester.pumpAndSettle();

      expect(find.textContaining('Now: Accepted'), findsOneWidget);
      expect(find.textContaining('Now: Pending In Take'), findsNothing);
    });

    testWidgets('a cancelled order shows no "Now" line', (tester) async {
      bigScreen(tester);
      final cancelled = order('Cancelled', history: const [
        ('PendingInTake', '2026-10-28T10:00:00Z'),
        ('Cancelled', '2026-10-29T10:00:00Z'),
      ]);
      await tester.pumpWidget(screen(cancelled, () async => cancelled));
      await tester.pumpAndSettle();

      expect(find.textContaining('Now:'), findsNothing);
    });

    testWidgets('a finished order shows no "Now" line', (tester) async {
      bigScreen(tester);
      final done = order('Completed', history: const [
        ('Completed', '2026-11-01T10:00:00Z'),
      ]);
      await tester.pumpWidget(screen(done, () async => done));
      await tester.pumpAndSettle();

      expect(find.textContaining('Now:'), findsNothing);
    });
  });
}
