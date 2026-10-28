//Create class foer orders to use
class LaundryOrder {
  final String orderId;
  final String service;
  final String status;
  final String date;

  /// When the order should be ready. Null until the server can say.
  final DateTime? dateCompletion;
  final int currentStep;

  LaundryOrder({
    required this.orderId,
    required this.service,
    required this.status,
    required this.date,
    required this.dateCompletion,
    required this.currentStep,
  });

  /// Still being processed (not completed, delivered or cancelled).
  bool get isActive =>
      status != 'Completed' && status != 'Delivered' && status != 'Cancelled';

  factory LaundryOrder.fromJson(Map<String, dynamic> json) => LaundryOrder(
        orderId: json['orderId'] ?? '',
        service: json['service'] ?? '',
        status: json['status'] ?? '',
        date: json['date'] ?? '',
        dateCompletion: DateTime.tryParse(json['dateCompletion'] ?? ''),
        currentStep: json['currentStep'] ?? 0,
      );

  /// An order as the ASP.NET API returns it (GET /api/v1/orders).
  ///
  /// The server's status names are turned into the wording and the four
  /// tracking steps (placed, in cleaning, ready, delivered) the screens use.
  /// [dateCompletion] is the delivery time the customer chose, and [date] is
  /// the line shown on the order card (ready on, completed on or placed on).
  factory LaundryOrder.fromApi(Map<String, dynamic> json) {
    final (status, step) = _stageFor((json['orderStatus'] as String?) ?? '');

    final items = [
      for (final item in (json['items'] as List? ?? const []))
        item as Map<String, dynamic>,
    ];
    String describe(Map<String, dynamic> item) {
      final name = (item['description'] as String?)?.trim();
      final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
      final label = name == null || name.isEmpty ? 'Item' : name;
      return quantity > 1 ? '$label ×$quantity' : label;
    }

    final shown = items.take(2).map(describe).join(', ');
    final extra = items.length > 2 ? ' +${items.length - 2} more' : '';

    DateTime? when(String key) =>
        DateTime.tryParse((json[key] as String?) ?? '')?.toLocal();

    final ordered = when('orderDate');
    final returned = when('returnDate');
    final delivery = when('deliveryDate');

    return LaundryOrder(
      orderId: ((json['orderNumber'] ?? json['ticketNumber'] ?? json['orderId'])
              as String?) ??
          '',
      service: items.isEmpty ? 'Laundry order' : '$shown$extra',
      status: status,
      date: _describeDate(status, ordered, returned ?? delivery, delivery),
      dateCompletion: delivery,
      currentStep: step,
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _day(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';

  static String _describeDate(
    String status,
    DateTime? ordered,
    DateTime? finished,
    DateTime? ready,
  ) {
    if (status == 'Cancelled') return 'Cancelled';
    if (status == 'Completed' && finished != null) {
      return 'Completed on ${_day(finished)}';
    }
    if (ready != null) return 'Ready on ${_day(ready)}';
    if (ordered != null) return 'Placed on ${_day(ordered)}';
    return '';
  }

  static (String, int) _stageFor(String status) => switch (status) {
        'PendingInTake' ||
        'Accepted' ||
        'ReadyForCollection' =>
          ('Order Placed', 0),
        'Collected' ||
        'AtFactory' ||
        'ReadyForWashing' ||
        'Washing' ||
        'OnLaundryLine' ||
        'IssueFlagged' ||
        'Ironing' ||
        'Packing' =>
          ('In Cleaning', 1),
        'ReadyForCustomerCollection' => ('Ready for Collection', 2),
        'OutForDelivery' => ('Out for Delivery', 2),
        'Completed' => ('Completed', 3),
        'Cancelled' || 'Rejected' => ('Cancelled', 0),
        _ => (status.isEmpty ? 'Order Placed' : status, 0),
      };

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'service': service,
        'status': status,
        'date': date,
        'dateCompletion': dateCompletion?.toIso8601String(),
        'currentStep': currentStep,
      };

  @override
  String toString() => 'LaundryOrder(orderId: $orderId, service: $service, status: $status, date: $date, dateCompletion: $dateCompletion, currentStep: $currentStep)';
}
