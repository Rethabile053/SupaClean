/// How the customer pays. The API supports bank transfer (EFT) and cash on
/// delivery.
enum PaymentMethod { eft, cash }

/// One item on the order, e.g. 3 kg of Laundry per kg.
class OrderLine {
  const OrderLine({
    required this.name,
    required this.unitPrice,
    required this.quantity,
  });

  final String name;
  final double unitPrice;
  final int quantity;

  double get total => unitPrice * quantity;
}

/// A delivery area from the server. Its fee is added to delivery orders.
class DeliveryZone {
  const DeliveryZone({required this.id, required this.name, required this.fee});

  final String id;
  final String name;
  final double fee;
}

/// Everything chosen on Place Order (and the delivery area from Choose Date
/// & Time), carried through to checkout.
class OrderDraft {
  const OrderDraft({
    required this.category,
    required this.lines,
    this.pickupOption = 'At my address',
    this.deliveryOption = 'Deliver to me',
    this.zone,
  });

  final String category;
  final List<OrderLine> lines;
  final String pickupOption;
  final String deliveryOption;
  final DeliveryZone? zone;

  double get subtotal => lines.fold(0, (sum, line) => sum + line.total);

  /// The customer wants the clean laundry brought to them.
  bool get isDelivery => deliveryOption == 'Deliver to me';

  /// Delivery fee as set by the server for the chosen area.
  double get deliveryFee => isDelivery ? (zone?.fee ?? 0) : 0;

  double get total => subtotal + deliveryFee;

  String get summary {
    final count = lines.length;
    return '$category · $count ${count == 1 ? 'item' : 'items'}';
  }

  OrderDraft copyWith({DeliveryZone? zone}) => OrderDraft(
        category: category,
        lines: lines,
        pickupOption: pickupOption,
        deliveryOption: deliveryOption,
        zone: zone ?? this.zone,
      );
}
