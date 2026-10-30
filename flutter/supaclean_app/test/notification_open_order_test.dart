import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supaclean/models/app_notification.dart';
import 'package:supaclean/models/laundry_order.dart';
import 'package:supaclean/services/api_client.dart';
import 'package:supaclean/views/notification_center_screen.dart';
import 'package:supaclean/views/track_order_loader.dart';
import 'package:supaclean/widgets/back_circle_button.dart';

const orderId = '8f62daee-bdb5-447c-a652-ebf10a262203';

LaundryOrder order(String status) => LaundryOrder.fromApi({
      'orderId': orderId,
      'orderNumber': 'SC-1012',
      'orderStatus': status,
      'orderDate': '2026-10-29T14:44:00Z',
      'items': [
        {'description': 'Caps', 'quantity': 1},
      ],
      'statusHistory': [
        {'status': 'PendingInTake', 'changedAt': '2026-10-29T14:44:00Z'},
        {'status': status, 'changedAt': '2026-10-30T00:27:00Z'},
      ],
    });

Map<String, dynamic> note(
  String id,
  String message, {
  String? forOrder = orderId,
  bool isRead = false,
  String title = 'Order SC-1012 update',
}) =>
    {
      'notificationId': id,
      'title': title,
      'message': message,
      'orderId': forOrder,
      'isRead': isRead,
      'sentAt': '2026-10-30T00:27:00Z',
    };

final unreadDot = find.byWidgetPredicate(
  (w) =>
      w is Container &&
      w.constraints == const BoxConstraints.tightFor(width: 9, height: 9),
);

void main() {
  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 3000);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  group('tapping a notification', () {
    testWidgets('opens that order\'s tracking, and marks it as seen',
        (tester) async {
      bigScreen(tester);
      final seen = <String>[];
      final opened = <String>[];
      // What the server says each time the list is loaded.
      var readOnServer = false;

      await tester.pumpWidget(MaterialApp(
        home: NotificationCenterScreen(
          load: () async => [
            AppNotification.fromApi(note(
                'n1', 'Order SC-1012 is now: Ready For Customer Collection.',
                isRead: readOnServer)),
          ],
          markRead: (id) async {
            seen.add(id);
            readOnServer = true;
          },
          loadOrder: (id) async {
            opened.add(id);
            return order('ReadyForCustomerCollection');
          },
        ),
      ));
      await tester.pumpAndSettle();
      expect(unreadDot, findsOneWidget);

      await tester.tap(find.textContaining('Ready For Customer Collection'));
      await tester.pumpAndSettle();

      // The order's tracking screen is showing, for that order.
      expect(opened, everyElement(orderId)); // opened, then its own refresh
      expect(opened, isNotEmpty);
      expect(find.text('Track Your Order'), findsOneWidget);
      expect(find.text('Order #SC-1012'), findsOneWidget);
      expect(find.textContaining('Now: Ready For Customer Collection'),
          findsOneWidget);
      // The server was told it was seen.
      expect(seen, ['n1']);

      // Back to the notifications: it is shown as read.
      await tester.tap(find.byType(BackCircleButton).first);
      await tester.pumpAndSettle();
      expect(find.text('Notifications'), findsOneWidget);
      expect(unreadDot, findsNothing);
    });

    testWidgets('a notification that is already read still opens its order',
        (tester) async {
      bigScreen(tester);
      final opened = <String>[];

      await tester.pumpWidget(MaterialApp(
        home: NotificationCenterScreen(
          load: () async =>
              [AppNotification.fromApi(note('n1', 'Order SC-1012 is now: Washing.', isRead: true))],
          loadOrder: (id) async {
            opened.add(id);
            return order('Washing');
          },
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('is now: Washing'));
      await tester.pumpAndSettle();

      expect(opened, isNotEmpty);
      expect(opened, everyElement(orderId));
      expect(find.text('Track Your Order'), findsOneWidget);
    });

    testWidgets('one that is not about an order only marks it as seen',
        (tester) async {
      bigScreen(tester);
      final seen = <String>[];
      var opened = 0;

      await tester.pumpWidget(MaterialApp(
        home: NotificationCenterScreen(
          load: () async => [
            AppNotification.fromApi(
                note('n9', 'Welcome to SupaClean.', forOrder: null, title: 'Welcome')),
          ],
          markRead: (id) async => seen.add(id),
          loadOrder: (id) async {
            opened++;
            return order('Washing');
          },
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Welcome to SupaClean.'));
      await tester.pumpAndSettle();

      expect(opened, 0);
      expect(seen, ['n9']);
      expect(find.text('Track Your Order'), findsNothing);
      expect(unreadDot, findsNothing);
    });

    testWidgets('only notifications about an order show the "open" arrow',
        (tester) async {
      bigScreen(tester);

      await tester.pumpWidget(MaterialApp(
        home: NotificationCenterScreen(
          load: () async => [
            AppNotification.fromApi(note('n1', 'Order SC-1012 is now: Washing.')),
            AppNotification.fromApi(
                note('n2', 'Welcome to SupaClean.', forOrder: null, title: 'Welcome')),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });
  });

  group('the order loader', () {
    testWidgets('shows a spinner, then the order\'s tracking', (tester) async {
      bigScreen(tester);
      await tester.pumpWidget(MaterialApp(
        home: TrackOrderLoader(
          orderId: orderId,
          load: (_) async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            return order('Washing');
          },
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Order #SC-1012'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('says why when the order cannot be opened, and can retry',
        (tester) async {
      bigScreen(tester);
      var calls = 0;
      await tester.pumpWidget(MaterialApp(
        home: TrackOrderLoader(
          orderId: orderId,
          load: (_) async {
            if (++calls == 1) throw const ApiException('Order not found.');
            return order('Washing');
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Order not found.'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(calls, greaterThanOrEqualTo(2));
      expect(find.text('Order #SC-1012'), findsOneWidget);
    });
  });
}
