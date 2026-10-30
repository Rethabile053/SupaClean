//Create class foer orders to use
class LaundryOrder {
  final String orderId;
  final String service;
  final String status;
  final String date;

  /// When the order should be ready. Null until the server can say.
  final DateTime? dateCompletion;
  final int currentStep;

  /// The server's id for the order, used to ask it for fresh status updates.
  final String? serverId;

  /// When the order was placed.
  final DateTime? placedAt;

  /// When the order first reached each of the four tracking steps, as
  /// recorded by the server when the admin changed its status. A step the
  /// server has no record of is null.
  final List<DateTime?> stepTimes;

  /// The customer can still cancel: we have not collected the laundry yet.
  final bool canCancel;

  /// The exact status the admin set, in words ("Accepted", "Washing", "Ready For
  /// Collection"). Several of these share one tracking step, so this is what
  /// shows that something changed inside a step.
  final String statusDetail;

  /// When the order reached that exact status. Null when the server has no record.
  final DateTime? statusSince;

  LaundryOrder({
    required this.orderId,
    required this.service,
    required this.status,
    required this.date,
    required this.dateCompletion,
    required this.currentStep,
    this.serverId,
    this.placedAt,
    this.stepTimes = const [null, null, null, null],
    this.canCancel = false,
    this.statusDetail = '',
    this.statusSince,
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

    // The first time the order reached each tracking step.
    final stepTimes = List<DateTime?>.filled(4, null);
    final history = [
      for (final change in (json['statusHistory'] as List? ?? const []))
        change as Map<String, dynamic>,
    ];
    for (final change in history) {
      final name = (change['status'] as String?) ?? '';
      if (name == 'Cancelled' || name == 'Rejected') continue;
      final at = DateTime.tryParse((change['changedAt'] as String?) ?? '')
          ?.toLocal();
      if (at == null) continue;
      final step = _stageFor(name).$2;
      final known = stepTimes[step];
      if (known == null || at.isBefore(known)) stepTimes[step] = at;
    }
    // Orders from before the history existed still know when they began.
    stepTimes[0] ??= ordered;

    // When the order reached its current exact status: the latest time that
    // status was set.
    final rawStatus = (json['orderStatus'] as String?) ?? '';
    DateTime? since;
    for (final change in history) {
      if (change['status'] != rawStatus) continue;
      final at = DateTime.tryParse((change['changedAt'] as String?) ?? '')?.toLocal();
      if (at != null && (since == null || at.isAfter(since))) since = at;
    }

    return LaundryOrder(
      serverId: json['orderId'] as String?,
      placedAt: ordered,
      stepTimes: stepTimes,
      canCancel: const ['PendingInTake', 'Accepted']
          .contains(json['orderStatus'] as String?),
      statusDetail: _words(rawStatus),
      statusSince: since,
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

  // "ReadyForCollection" -> "Ready For Collection", "PendingInTake" -> "Pending In Take".
  static String _words(String status) => status.replaceAllMapped(
        RegExp(r'(?<=[a-z])(?=[A-Z])'),
        (_) => ' ',
      );

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
