import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supaclean/models/booking_details.dart';

BookingDetails booking(DateTime pickup, DateTime delivery) => BookingDetails(
      pickupDate: pickup,
      pickupStart: const TimeOfDay(hour: 10, minute: 0),
      pickupEnd: const TimeOfDay(hour: 12, minute: 0),
      deliveryDate: delivery,
      deliveryStart: const TimeOfDay(hour: 16, minute: 0),
      deliveryEnd: const TimeOfDay(hour: 18, minute: 0),
      address: '123 Street',
    );

void main() {
  test('next-day delivery gets no discount', () {
    final b = booking(DateTime(2026, 10, 29, 9), DateTime(2026, 10, 30, 23));
    expect(b.qualifiesForDiscount, isFalse);
    expect(b.discounted(63), 63);
  });

  test('delivery exactly 2 days later gets no discount', () {
    final b = booking(DateTime(2026, 10, 29), DateTime(2026, 10, 31));
    expect(b.daysToDelivery, 2);
    expect(b.qualifiesForDiscount, isFalse);
    expect(b.discounted(63), 63);
  });

  test('delivery more than 2 days later takes 15% off', () {
    final b = booking(DateTime(2026, 10, 29), DateTime(2026, 11, 1));
    expect(b.daysToDelivery, 3);
    expect(b.qualifiesForDiscount, isTrue);
    expect(b.discounted(63), 53.55);
    expect(b.discounted(28.90), 24.57);
  });
}
