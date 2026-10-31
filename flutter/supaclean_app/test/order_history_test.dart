import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supaclean/models/laundry_order.dart';
import 'package:supaclean/models/order_draft.dart' show PaymentMethod;
import 'package:supaclean/models/reorder_plan.dart';
import 'package:supaclean/viewmodels/service_viewmodel.dart';
import 'package:supaclean/views/my_orders_screen.dart';
import 'package:supaclean/views/order_history_screen.dart';
import 'package:supaclean/views/place_order_screen.dart';
import 'package:supaclean/views/track_order_screen.dart';

Map<String, dynamic> apiOrder({
  String status = 'Completed',
  List<Map<String, dynamic>>? items,
  double pointsDiscount = 0,
}) =>
    {
      'orderId': '8f62daee-bdb5-447c-a652-ebf10a262203',
      'orderStatus': status,
      'orderNumber': 'SC-1021',
      'itemsTotal': 183.0,
      'pickupFee': 30,
      'deliveryFee': 30,
      'pointsDiscount': pointsDiscount,
      'grandTotal': 243.0 - pointsDiscount,
      'orderDate': '2026-10-24T10:00:00Z',
      'returnDate': '2026-10-28T10:00:00Z',
      'deliveryDate': '2026-10-28T10:00:00Z',
      'pickupMethod': 'Home pickup',
      'returnMethod': 'Home delivery',
      'items': items ??
          [
            {
              'description': 'Shirts, T-shirts, Polo',
              'quantity': 3,
              'unitPrice': 28.9,
            },
            {'description': 'Laundry per kg', 'quantity': 2, 'unitPrice': 42},
          ],
    };

void main() {
  final services = ServiceViewModel().services;

  group('the order keeps what was on it', () {
    test('items, fees, points and how it travelled', () {
      final order = LaundryOrder.fromApi(apiOrder(pointsDiscount: 12));

      expect(order.isCompleted, isTrue);
      expect(order.items, hasLength(2));
      expect(order.items.first.name, 'Shirts, T-shirts, Polo');
      expect(order.items.first.quantity, 3);
      expect(order.items.first.total, closeTo(86.7, 0.001));
      expect(order.pickupFee, 30);
      expect(order.pointsDiscount, 12);
      expect(order.grandTotal, 231);
      expect(order.pickupMethod, 'Home pickup');
      expect(order.completedAt, isNotNull);
    });

    test('an order that is not finished has no completion date', () {
      final order = LaundryOrder.fromApi(apiOrder(status: 'Washing'));
      expect(order.isCompleted, isFalse);
      expect(order.completedAt, isNull);
    });
  });

  group('ReorderPlan', () {
    test('brings back the same items and quantities', () {
      final plan = ReorderPlan.of(LaundryOrder.fromApi(apiOrder()), services);

      expect(plan.canReorder, isTrue);
      expect(plan.category, 'Wash & Fold');
      expect(plan.quantities['Shirts, T-shirts, Polo'], 3);
      expect(plan.quantities['Laundry per kg'], 2);
      expect(plan.unavailable, isEmpty);
      expect(plan.pickupOption, 'At my address');
      expect(plan.deliveryOption, 'Deliver to me');
    });

    test('leaves out an item that is no longer offered', () {
      final order = LaundryOrder.fromApi(apiOrder(items: [
        {'description': 'Laundry per kg', 'quantity': 1, 'unitPrice': 42},
        {'description': 'Discontinued thing', 'quantity': 1, 'unitPrice': 10},
      ]));
      final plan = ReorderPlan.of(order, services);

      expect(plan.canReorder, isTrue);
      expect(plan.quantities.keys, ['Laundry per kg']);
      expect(plan.unavailable, ['Discontinued thing']);
    });

    test('cannot reorder when nothing is offered any more', () {
      final order = LaundryOrder.fromApi(apiOrder(items: [
        {'description': 'Discontinued thing', 'quantity': 1, 'unitPrice': 10},
      ]));

      expect(ReorderPlan.of(order, services).canReorder, isFalse);
    });

    test('an item switched off is not reordered', () {
      final switchedOff = [
        ServiceCategory(
          name: 'Wash & Fold',
          description: '',
          icon: Icons.local_laundry_service,
          items: const [
            ServiceItem(
              name: 'Laundry per kg',
              price: 42,
              description: '',
              isAvailable: false,
            ),
          ],
        ),
      ];
      final order = LaundryOrder.fromApi(apiOrder(items: [
        {'description': 'Laundry per kg', 'quantity': 1, 'unitPrice': 42},
      ]));

      expect(ReorderPlan.of(order, switchedOff).canReorder, isFalse);
    });
  });

  group('My Orders', () {
    Future<void> pumpOrders(WidgetTester tester, String status) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MyOrdersScreen(
            load: () async => [LaundryOrder.fromApi(apiOrder(status: status))],
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a completed order offers Track order or Order history',
        (tester) async {
      await pumpOrders(tester, 'Completed');
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Order #SC-1021'));
      await tester.pumpAndSettle();

      expect(find.text('What would you like to see?'), findsOneWidget);
      expect(find.byKey(const Key('choice-track')), findsOneWidget);
      expect(find.byKey(const Key('choice-history')), findsOneWidget);
      expect(find.byType(TrackOrderScreen), findsNothing);
    });

    testWidgets('Track order opens the tracking screen', (tester) async {
      await pumpOrders(tester, 'Completed');
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Order #SC-1021'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('choice-track')));
      await tester.pumpAndSettle();

      expect(find.byType(TrackOrderScreen), findsOneWidget);
    });

    testWidgets('Order history opens the history screen', (tester) async {
      await pumpOrders(tester, 'Completed');
      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Order #SC-1021'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('choice-history')));
      await tester.pumpAndSettle();

      expect(find.byType(OrderHistoryScreen), findsOneWidget);
    });

    testWidgets('an order still being cleaned goes straight to tracking',
        (tester) async {
      await pumpOrders(tester, 'Washing');

      await tester.tap(find.text('Order #SC-1021'));
      await tester.pumpAndSettle();

      expect(find.text('What would you like to see?'), findsNothing);
      expect(find.byType(TrackOrderScreen), findsOneWidget);
    });
  });

  group('Order history screen', () {
    Future<void> pumpHistory(
      WidgetTester tester, {
      double pointsDiscount = 12,
      List<ServiceCategory>? withServices,
      PaymentMethod? paid,
      bool paymentLookupFails = false,
    }) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          home: OrderHistoryScreen(
            order: LaundryOrder.fromApi(apiOrder(pointsDiscount: pointsDiscount)),
            services: withServices ?? services,
            lastPaymentMethod: (_) async {
              if (paymentLookupFails) throw Exception('offline');
              return paid;
            },
          ),
        ),
      );
    }

    testWidgets('shows what was ordered, how it travelled and what was paid',
        (tester) async {
      await pumpHistory(tester);

      expect(find.text('Order #SC-1021'), findsOneWidget);
      expect(find.text('Shirts, T-shirts, Polo'), findsOneWidget);
      expect(find.text('3 × R28.90'), findsOneWidget);
      expect(find.text('Laundry per kg'), findsOneWidget);
      expect(find.text('Home pickup'), findsOneWidget);
      expect(find.text('Home delivery'), findsOneWidget);
      expect(find.text('Pickup fee'), findsOneWidget);
      expect(find.text('-R12.00'), findsOneWidget);
      expect(find.text('R231.00'), findsOneWidget);   // total paid
      expect(find.text('You earned 100 points'), findsOneWidget);
    });

    testWidgets('has no points discount line when none were used',
        (tester) async {
      await pumpHistory(tester, pointsDiscount: 0);

      expect(find.text('Points discount'), findsNothing);
    });

    testWidgets('Reorder opens Place Order with the same items and quantities',
        (tester) async {
      await pumpHistory(tester);

      await tester.tap(find.byKey(const Key('reorder')));
      await tester.pumpAndSettle();

      final screen = tester.widget<PlaceOrderScreen>(find.byType(PlaceOrderScreen));
      expect(screen.category, 'Wash & Fold');
      expect(screen.initialQuantities['Shirts, T-shirts, Polo'], 3);
      expect(screen.initialQuantities['Laundry per kg'], 2);
      expect(screen.initialPickupOption, 'At my address');
      expect(screen.initialDeliveryOption, 'Deliver to me');
    });

    testWidgets('Reorder offers the way it was paid last time', (tester) async {
      await pumpHistory(tester, paid: PaymentMethod.cash);

      await tester.tap(find.byKey(const Key('reorder')));
      await tester.pumpAndSettle();

      final screen =
          tester.widget<PlaceOrderScreen>(find.byType(PlaceOrderScreen));
      expect(screen.initialPaymentMethod, PaymentMethod.cash);
    });

    testWidgets('Reorder still works when the last payment cannot be found',
        (tester) async {
      await pumpHistory(tester, paymentLookupFails: true);

      await tester.tap(find.byKey(const Key('reorder')));
      await tester.pumpAndSettle();

      final screen =
          tester.widget<PlaceOrderScreen>(find.byType(PlaceOrderScreen));
      expect(screen.initialPaymentMethod, isNull);
    });

    testWidgets('Reorder says so when nothing can be ordered again',
        (tester) async {
      await pumpHistory(tester, withServices: const []);

      await tester.tap(find.byKey(const Key('reorder')));
      await tester.pump();

      expect(
        find.text('None of the items on this order can be ordered right now.'),
        findsOneWidget,
      );
      expect(find.byType(PlaceOrderScreen), findsNothing);
    });
  });
}
