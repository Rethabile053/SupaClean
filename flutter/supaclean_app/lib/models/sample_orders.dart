import 'laundry_order.dart';

/// Placeholder orders shared by the Orders and Schedule tabs.
/// Replace with real data once the order repository is connected.
final List<LaundryOrder> sampleOrders = [
  LaundryOrder(
    orderId: '1024',
    service: 'Wash & Fold',
    status: 'In Cleaning',
    date: 'Ready on 15 May 2024',
    dateCompletion: DateTime(2024, 5, 15, 16),
    currentStep: 2,
  ),
  LaundryOrder(
    orderId: '1018',
    service: 'Dry Cleaning',
    status: 'Delivered',
    date: 'Completed on 03 May 2024',
    dateCompletion: DateTime(2024, 5, 3),
    currentStep: 5,
  ),
  LaundryOrder(
    orderId: '1012',
    service: 'Duvet & Bedding',
    status: 'Completed',
    date: 'Completed on 28 Apr 2024',
    dateCompletion: DateTime(2024, 4, 28),
    currentStep: 4,
  ),
  LaundryOrder(
    orderId: '1007',
    service: 'Ironing Only',
    status: 'Completed',
    date: 'Completed on 15 Apr 2024',
    dateCompletion: DateTime(2024, 4, 15),
    currentStep: 4,
  ),
];
