import 'package:flutter/material.dart';

/// Pickup and delivery choices made on the Choose Date & Time screen.
class BookingDetails {
  final DateTime pickupDate;
  final TimeOfDay pickupStart;
  final TimeOfDay pickupEnd;
  final DateTime deliveryDate;
  final TimeOfDay deliveryStart;
  final TimeOfDay deliveryEnd;
  final String address;
  final String instructions;

  const BookingDetails({
    required this.pickupDate,
    required this.pickupStart,
    required this.pickupEnd,
    required this.deliveryDate,
    required this.deliveryStart,
    required this.deliveryEnd,
    required this.address,
    this.instructions = '',
  });

  /// Standard service is 24 hours. Choosing a later delivery date earns this
  /// discount on the whole order.
  static const discountRate = 0.10;

  /// Whole days between the pickup day and the delivery day.
  int get daysToDelivery {
    DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
    return day(deliveryDate).difference(day(pickupDate)).inDays;
  }

  bool get qualifiesForDiscount => daysToDelivery > 1;

  /// [price] with the discount taken off when it applies, to the cent.
  double discounted(double price) => qualifiesForDiscount
      ? (price * (1 - discountRate) * 100).round() / 100
      : price;
}
