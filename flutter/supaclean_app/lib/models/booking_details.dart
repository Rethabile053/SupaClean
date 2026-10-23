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
}
