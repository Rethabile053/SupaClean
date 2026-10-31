import 'dart:math' as math;

/// One line of the customer's points history.
class PointsEntry {
  const PointsEntry({
    required this.kind,
    required this.points,
    required this.description,
    required this.time,
  });

  /// Earned, Redeemed or Refunded.
  final String kind;

  /// Positive when points were added, negative when they were used.
  final int points;
  final String description;
  final DateTime time;

  factory PointsEntry.fromApi(Map<String, dynamic> json) => PointsEntry(
        kind: (json['kind'] as String?) ?? 'Earned',
        points: (json['points'] as num?)?.toInt() ?? 0,
        description: (json['description'] as String?) ?? '',
        time: DateTime.tryParse((json['createdAt'] as String?) ?? '')
                ?.toLocal() ??
            DateTime.now(),
      );
}

/// The customer's points and the rules for using them, as the server sends
/// them. The server does the real sums; these only preview them.
class PointsSummary {
  const PointsSummary({
    required this.balance,
    this.pointsPerRand = 10,
    this.randSpentPerPoint = 2,
    this.maxShareOfItems = 0.5,
    this.history = const [],
  });

  final int balance;

  /// 10 points are worth R1 off.
  final int pointsPerRand;

  /// One point is earned for every R2 paid.
  final double randSpentPerPoint;

  /// Points never cover more than this share of the laundry price.
  final double maxShareOfItems;
  final List<PointsEntry> history;

  factory PointsSummary.fromApi(Map<String, dynamic> json) => PointsSummary(
        balance: (json['balance'] as num?)?.toInt() ?? 0,
        pointsPerRand: (json['pointsPerRand'] as num?)?.toInt() ?? 10,
        randSpentPerPoint:
            (json['randSpentPerPoint'] as num?)?.toDouble() ?? 2,
        maxShareOfItems: (json['maxShareOfItems'] as num?)?.toDouble() ?? 0.5,
        history: [
          for (final item
              in ((json['history'] as List<dynamic>?) ?? const [])
                  .cast<Map<String, dynamic>>())
            PointsEntry.fromApi(item),
        ],
      );

  /// What the whole balance is worth, in whole rands.
  double get balanceValue => (balance ~/ pointsPerRand).toDouble();

  /// The biggest whole-rand discount allowed on laundry worth [itemsTotal].
  double maxDiscount(double itemsTotal) {
    final cents = (itemsTotal * 100).round() / 100;
    final cap = (cents * maxShareOfItems).floorToDouble();
    return math.max(0, math.min(balanceValue, cap));
  }

  /// Points earned once an order whose laundry cost [paid] is delivered.
  int pointsEarned(double paid) =>
      paid <= 0 ? 0 : (paid / randSpentPerPoint).floor();
}
