import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supaclean/models/app_notification.dart';
import 'package:supaclean/models/app_search.dart';
import 'package:supaclean/models/laundry_order.dart';
import 'package:supaclean/services/service_catalogue.dart';
import 'package:supaclean/views/detailed_services_screen.dart';
import 'package:supaclean/views/search_screen.dart';
import 'package:supaclean/views/terms_screen.dart';
import 'package:supaclean/views/track_order_screen.dart';
import 'package:supaclean/viewmodels/service_viewmodel.dart';
import 'package:supaclean/widgets/app_header.dart';

LaundryOrder order(String number, String status, String item) =>
    LaundryOrder.fromApi({
      'orderId': 'id-$number',
      'orderNumber': number,
      'orderStatus': status,
      'orderDate': '2026-10-29T14:44:00Z',
      'items': [
        {'description': item, 'quantity': 1},
      ],
      'statusHistory': [],
    });

AppNotification note(String title, {String orderId = ''}) =>
    AppNotification.fromApi({
      'notificationId': 'n-$title',
      'title': title,
      'message': title,
      'orderId': orderId,
      'isRead': false,
      'sentAt': '2026-10-29T10:00:00Z',
    });

const catalogue = [
  ServiceCategory(
    name: 'Wash & Fold',
    description: 'Laundry',
    icon: Icons.local_laundry_service,
    items: [
      ServiceItem(name: 'Laundry per kg', price: 42, description: 'Everyday laundry.'),
      ServiceItem(
          name: 'Socks', price: 28.9, description: 'Socks.', isAvailable: false),
    ],
  ),
  ServiceCategory(
    name: 'Bedding & Linen',
    description: 'Beds',
    icon: Icons.bed,
    items: [
      ServiceItem(name: 'Pillow Wash', price: 35, description: 'Wash a pillow.'),
    ],
  ),
];

List<SearchResult> run(
  String query, {
  List<LaundryOrder> orders = const [],
  List<AppNotification> notifications = const [],
}) =>
    searchApp(query,
        services: catalogue, orders: orders, notifications: notifications);

void main() {
  tearDown(ServiceCatalogue.instance.reset);

  group('searchApp', () {
    test('an empty search finds nothing', () {
      expect(run(''), isEmpty);
      expect(run('   '), isEmpty);
      expect(run('!!!'), isEmpty);
    });

    test('finds a service by name, ignoring capital letters', () {
      final r = run('LAUNDRY');
      final service = r.firstWhere((x) => x.kind == SearchKind.service);
      expect(service.title, 'Laundry per kg');
      expect(service.subtitle, 'Wash & Fold · R42.00');
    });

    test('finds a service by its category', () {
      final names = run('bedding')
          .where((x) => x.kind == SearchKind.service)
          .map((x) => x.title);
      expect(names, ['Pillow Wash']);
    });

    test('every word typed must match, in any order', () {
      expect(run('kg laundry').any((x) => x.title == 'Laundry per kg'), isTrue);
      expect(run('laundry pillow').where((x) => x.kind == SearchKind.service),
          isEmpty);
    });

    test('a service that is switched off is still found, and says so', () {
      final socks = run('socks').firstWhere((x) => x.title == 'Socks');
      expect(socks.subtitle, 'Wash & Fold · Currently unavailable');
    });

    test('finds an order however its number is typed', () {
      final orders = [
        order('SC-1012', 'Washing', 'Caps'),
        order('SC-1015', 'Accepted', 'Jacket'),
      ];
      for (final q in ['SC-1012', 'sc 1012', 'sc1012', '1012']) {
        final r = run(q, orders: orders)
            .where((x) => x.kind == SearchKind.order)
            .toList();
        expect(r.length, 1, reason: q);
        expect(r.single.title, 'Order #SC-1012', reason: q);
      }
    });

    test('finds an order by what is in it or its status', () {
      final orders = [
        order('SC-1012', 'Washing', 'Caps'),
        order('SC-1015', 'Accepted', 'Jacket'),
      ];
      expect(
          run('jacket', orders: orders)
              .where((x) => x.kind == SearchKind.order)
              .single
              .title,
          'Order #SC-1015');
      expect(
          run('cleaning', orders: orders)
              .where((x) => x.kind == SearchKind.order)
              .single
              .title,
          'Order #SC-1012');
    });

    test('finds a notification by its title', () {
      final n = [
        note('Order SC-1012 update', orderId: 'o1'),
        note('Payment confirmed'),
      ];
      final r = run('payment', notifications: n)
          .where((x) => x.kind == SearchKind.notification)
          .toList();
      expect(r.single.title, 'Payment confirmed');
    });

    test('finds app pages, including by what they hold', () {
      pagesFor(String q) => run(q)
          .where((x) => x.kind == SearchKind.page)
          .map((x) => (x.source as AppPage))
          .toList();

      expect(pagesFor('terms'), [AppPage.terms]);
      expect(pagesFor('discount'), contains(AppPage.terms));
      expect(pagesFor('guarantee'), contains(AppPage.terms));
      expect(pagesFor('address'), contains(AppPage.addresses));
      expect(pagesFor('profile'), contains(AppPage.profile));
      expect(pagesFor('calendar'), contains(AppPage.schedule));
    });

    test('lists results grouped in a fixed order: pages, services, orders, notifications',
        () {
      final r = run('order',
          orders: [order('SC-1', 'Accepted', 'Caps')],
          notifications: [note('Order SC-1 update')]);
      final kinds = r.map((x) => x.kind).toList();
      final sorted = [...kinds]..sort((a, b) => a.index.compareTo(b.index));
      expect(kinds, sorted);
    });

    test('shows at most a few of each kind', () {
      final many = [for (var i = 0; i < 30; i++) order('SC-$i', 'Accepted', 'Caps')];
      final r = searchApp('accepted',
          services: catalogue, orders: many, perKind: 5);
      expect(r.where((x) => x.kind == SearchKind.order).length, 5);
    });

    test('a word that matches nothing finds nothing', () {
      expect(run('zzzz'), isEmpty);
    });
  });

  group('the Search screen', () {
    void bigScreen(WidgetTester tester) {
      tester.view.physicalSize = const Size(1400, 3000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
    }

    Future<void> open(
      WidgetTester tester, {
      Future<List<LaundryOrder>> Function()? orders,
      Future<List<AppNotification>> Function()? notifications,
    }) async {
      bigScreen(tester);
      await tester.pumpWidget(MaterialApp(
        home: SearchScreen(
          loadOrders: orders ?? () async => [],
          loadNotifications: notifications ?? () async => [],
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('starts with a hint, not results', (tester) async {
      await open(tester);

      expect(find.text('Search SupaClean'), findsOneWidget);
    });

    testWidgets('typing lists results under headings', (tester) async {
      await open(tester, orders: () async => [order('SC-1012', 'Washing', 'Caps')]);

      await tester.enterText(find.byType(TextField), 'caps');
      await tester.pumpAndSettle();

      expect(find.text('My orders'), findsOneWidget);
      expect(find.text('Order #SC-1012'), findsOneWidget);
    });

    testWidgets('a word with no match says nothing was found', (tester) async {
      await open(tester);

      await tester.enterText(find.byType(TextField), 'qqqq');
      await tester.pumpAndSettle();

      expect(find.text('Nothing found'), findsOneWidget);
    });

    testWidgets('the clear button empties the search', (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextField), 'terms');
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Clear'));
      await tester.pumpAndSettle();

      expect(find.text('Search SupaClean'), findsOneWidget);
    });

    testWidgets('tapping a page result opens that page', (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextField), 'terms');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terms and Conditions').first);
      await tester.pumpAndSettle();

      expect(find.byType(TermsScreen), findsOneWidget);
    });

    testWidgets('tapping a service opens its category', (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextField), 'laundry per kg');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Laundry per kg').first);
      await tester.pumpAndSettle();

      expect(find.byType(DetailedServicesScreen), findsOneWidget);
    });

    testWidgets('tapping an order opens its tracking', (tester) async {
      await open(tester, orders: () async => [order('SC-1012', 'Washing', 'Caps')]);
      await tester.enterText(find.byType(TextField), '1012');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Order #SC-1012'));
      await tester.pumpAndSettle();

      expect(find.byType(TrackOrderScreen), findsOneWidget);
    });

    testWidgets('if orders cannot be loaded, the rest still works and a note says so',
        (tester) async {
      await open(tester, orders: () async => throw Exception('offline'));
      await tester.enterText(find.byType(TextField), 'terms');
      await tester.pumpAndSettle();

      expect(find.textContaining('could not be loaded'), findsOneWidget);
      expect(find.text('Terms and Conditions'), findsWidgets);
    });
  });

  group('the header', () {
    testWidgets('has a search button next to the bell that opens Search',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(appBar: AppHeader(title: 'Anything', showBack: false)),
      ));

      expect(find.byTooltip('Search'), findsOneWidget);
      expect(find.byTooltip('Notifications'), findsOneWidget);
      // Search comes before the bell.
      expect(tester.getTopLeft(find.byTooltip('Search')).dx,
          lessThan(tester.getTopLeft(find.byTooltip('Notifications')).dx));
    });

    testWidgets('can be turned off', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          appBar: AppHeader(title: 'Search', showSearch: false),
        ),
      ));

      expect(find.byTooltip('Search'), findsNothing);
    });
  });
}
