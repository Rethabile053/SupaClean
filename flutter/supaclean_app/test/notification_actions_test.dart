import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supaclean/models/app_notification.dart';
import 'package:supaclean/views/notification_center_screen.dart';

Map<String, dynamic> row(
  String id,
  String message, {
  String title = 'Order SC-1111 update',
  bool isRead = false,
  // These tests are about read state and removing, not opening an order (that
  // is notification_open_order_test), so by default a tap does not navigate.
  String? forOrder,
}) =>
    {
      'notificationId': id,
      'title': title,
      'message': message,
      'orderId': forOrder,
      'isRead': isRead,
      'sentAt': '2026-10-29T10:00:00Z',
    };

/// The red dot shown on a notification that has not been read.
final unreadDot = find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.constraints == const BoxConstraints.tightFor(width: 9, height: 9),
);

void main() {
  group('order number in the message', () {
    test('a new message from the server is shown as it is', () {
      final n = AppNotification.fromApi(
          row('1', 'Order SC-1111 has been cancelled.',
              title: 'Order SC-1111 cancelled'));
      expect(n.title, 'Order SC-1111 has been cancelled.');
    });

    test('an older message gets the order number from its title', () {
      final n = AppNotification.fromApi(
          row('1', 'Your order has been cancelled.',
              title: 'Order SC-1111 cancelled'));
      expect(n.title, 'Order SC-1111: Your order has been cancelled.');
    });

    test('works for the issue title too', () {
      final n = AppNotification.fromApi(
          row('1', 'Stain on the jacket', title: 'Issue with order SC-7'));
      expect(n.title, 'Order SC-7: Stain on the jacket');
    });

    test('a message with no order in the title is left alone', () {
      final n = AppNotification.fromApi(
          row('1', 'We received R50.00.', title: 'Payment received'));
      expect(n.title, 'We received R50.00.');
    });
  });

  group('Notification Center actions', () {
    Future<void> open(
      WidgetTester tester, {
      required Future<List<AppNotification>> Function() load,
      Future<void> Function(String)? markRead,
      Future<void> Function()? markAllRead,
      Future<void> Function(String)? remove,
    }) async {
      tester.view.physicalSize = const Size(1400, 3000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: NotificationCenterScreen(
          load: load,
          markRead: markRead,
          markAllRead: markAllRead,
          remove: remove,
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('tapping a notification saves it as read on the server',
        (tester) async {
      final saved = <String>[];
      await open(
        tester,
        load: () async => [
          AppNotification.fromApi(
              row('n1', 'Order SC-1111 has been cancelled.')),
        ],
        markRead: (id) async => saved.add(id),
      );
      expect(unreadDot, findsOneWidget);

      await tester.tap(find.text('Order SC-1111 has been cancelled.'));
      await tester.pumpAndSettle();

      expect(saved, ['n1']);
      expect(unreadDot, findsNothing);

      // Tapping it again does not send it again.
      await tester.tap(find.text('Order SC-1111 has been cancelled.'));
      await tester.pumpAndSettle();
      expect(saved, ['n1']);
    });

    testWidgets('coming back shows what the server says is read',
        (tester) async {
      // What the server answers the second time, after the earlier tap.
      await open(
        tester,
        load: () async => [
          AppNotification.fromApi(
              row('n1', 'Order SC-1111 has been cancelled.', isRead: true)),
          AppNotification.fromApi(row('n2', 'Order SC-1111 is now: Washing.')),
        ],
      );

      expect(find.text('Order SC-1111 has been cancelled.'), findsOneWidget);
      expect(unreadDot, findsOneWidget); // only the unread one has a dot
    });

    testWidgets('Mark all as read tells the server', (tester) async {
      var calls = 0;
      await open(
        tester,
        load: () async => [
          AppNotification.fromApi(row('n1', 'Order SC-1111 is now: Washing.')),
          AppNotification.fromApi(row('n2', 'Order SC-1111 is now: Ironing.')),
        ],
        markAllRead: () async => calls++,
      );
      expect(unreadDot, findsNWidgets(2));

      await tester.tap(find.text('Mark all as read'));
      await tester.pumpAndSettle();

      expect(calls, 1);
      expect(unreadDot, findsNothing);
    });

    testWidgets('the X removes a notification', (tester) async {
      final removed = <String>[];
      await open(
        tester,
        load: () async => [
          AppNotification.fromApi(
              row('n1', 'Order SC-1111 has been cancelled.')),
          AppNotification.fromApi(row('n2', 'Order SC-1111 is now: Washing.')),
        ],
        remove: (id) async => removed.add(id),
      );

      await tester.tap(find.byTooltip('Remove notification').first);
      await tester.pumpAndSettle();

      expect(removed, ['n1']);
      expect(find.text('Order SC-1111 has been cancelled.'), findsNothing);
      expect(find.text('Order SC-1111 is now: Washing.'), findsOneWidget);
    });

    testWidgets('removing the last one shows the empty message',
        (tester) async {
      await open(
        tester,
        load: () async => [
          AppNotification.fromApi(row('n1', 'Order SC-1111 is now: Washing.')),
        ],
        remove: (_) async {},
      );

      await tester.tap(find.byTooltip('Remove notification'));
      await tester.pumpAndSettle();

      expect(find.text('No notifications yet'), findsOneWidget);
    });

    testWidgets('a failed remove brings it back with a message',
        (tester) async {
      await open(
        tester,
        load: () async => [
          AppNotification.fromApi(row('n1', 'Order SC-1111 is now: Washing.')),
        ],
        remove: (_) async => throw Exception('offline'),
      );

      await tester.tap(find.byTooltip('Remove notification'));
      await tester.pumpAndSettle();

      expect(find.text('Order SC-1111 is now: Washing.'), findsOneWidget);
      expect(find.textContaining('Could not remove'), findsOneWidget);
    });
  });
}
