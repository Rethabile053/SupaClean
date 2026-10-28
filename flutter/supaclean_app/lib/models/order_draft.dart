/// How the customer pays. The API supports bank transfer (EFT) and cash on
/// delivery; card payments are a separate demo screen for now.
enum PaymentMethod { card, eft, cash }

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

/// Everything chosen on Place Order, carried through to checkout.
class OrderDraft {
  const OrderDraft({
    required this.category,
    required this.lines,
    this.pickupOption = 'At my address',
    this.deliveryOption = 'Deliver to me',
    this.pickupFee = 0,
    this.deliveryFee = 0,
  });

  final String category;
  final List<OrderLine> lines;
  final String pickupOption;
  final String deliveryOption;

  /// Fees worked out on Place Order (0 when the customer drops off or
  /// collects at a depot).
  final double pickupFee;
  final double deliveryFee;

  double get subtotal => lines.fold(0, (sum, line) => sum + line.total);

  /// The customer wants the clean laundry brought to them.
  bool get isDelivery => deliveryOption == 'Deliver to me';

  String get summary {
    final count = lines.length;
    return '$category · $count ${count == 1 ? 'item' : 'items'}';
  }
}
