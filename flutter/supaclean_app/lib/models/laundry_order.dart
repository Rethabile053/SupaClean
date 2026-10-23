//Create class foer orders to use
class LaundryOrder {
  final String orderId;
  final String service;
  final String status;
  final String date;
  final DateTime dateCompletion;
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
        dateCompletion : DateTime.parse(json['dateCompletion'] ?? DateTime.now().toIso8601String()),
        currentStep: json['currentStep'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'service': service,
        'status': status,
        'date': date,
        'dateCompletion': dateCompletion.toIso8601String(),
        'currentStep': currentStep,
      };

  @override
  String toString() => 'LaundryOrder(orderId: $orderId, service: $service, status: $status, date: $date, dateCompletion: $dateCompletion, currentStep: $currentStep)';
}