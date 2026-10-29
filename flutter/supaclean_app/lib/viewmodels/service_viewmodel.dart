import 'package:flutter/material.dart';
import '../services/service_catalogue.dart';

class ServiceItem {
  final String name;
  final double price;
  final String description;
  final bool isEstimated;

  const ServiceItem({
    required this.name,
    required this.price,
    required this.description,
    this.isEstimated = false,
  });
}

class ServiceCategory {
  final String name;
  final String description;
  final IconData icon;
  final List<ServiceItem> items;
  final double? startingPrice;

  const ServiceCategory({
    required this.name,
    required this.description,
    required this.icon,
    required this.items,
    this.startingPrice,
  });
}

class ServiceViewModel {
  static const List<ServiceCategory> _builtIn = [
    // 1. WASH & FOLD
    ServiceCategory(
      name: 'Wash & Fold',
      description: 'Fresh, clean and neatly folded laundry.',
      icon: Icons.local_laundry_service,
      startingPrice: 42.00,
      items: [
        ServiceItem(
          name: 'Laundry per kg',
          price: 42.00,
          description: 'Everyday laundry charged per kilogram.',
        ),
        ServiceItem(
          name: 'Shirts, T-shirts, Polo',
          price: 28.90,
          description: 'Laundry service for shirts and casual tops.',
        ),
        ServiceItem(
          name: 'Shorts',
          price: 28.90,
          description: 'Laundry service for shorts.',
        ),
        ServiceItem(
          name: 'Socks',
          price: 28.90,
          description: 'Laundry service for socks.',
        ),
      ],
    ),

    // 2. DRY CLEANING
    ServiceCategory(
      name: 'Dry Cleaning',
      description: 'Specialist cleaning for delicate garments.',
      icon: Icons.checkroom,
      startingPrice: 63.00,
      items: [
        ServiceItem(
            name: 'Beret',
            price: 63,
            description: 'Professional dry cleaning for a beret.'),
        ServiceItem(
            name: 'Caps',
            price: 63,
            description: 'Professional dry cleaning for caps.'),
        ServiceItem(
            name: 'Heavy Coat',
            price: 229,
            description: 'Professional dry cleaning for heavy coats.'),
        ServiceItem(
            name: 'Light Coat',
            price: 209,
            description: 'Professional dry cleaning for light coats.'),
        ServiceItem(
            name: 'Evening Dress',
            price: 250,
            description: 'Specialist cleaning for evening dresses.'),
        ServiceItem(
            name: 'Summer Dress',
            price: 167,
            description: 'Professional cleaning for summer dresses.'),
        ServiceItem(
            name: 'Dry Cleaning per kg',
            price: 171,
            description: 'Dry cleaning charged per kilogram.'),
        ServiceItem(
            name: 'Jackets',
            price: 126,
            description: 'Professional dry cleaning for jackets.'),
        ServiceItem(
            name: 'Scarves',
            price: 99,
            description: 'Professional dry cleaning for scarves.'),
        ServiceItem(
            name: 'Shirts',
            price: 63,
            description: 'Professional dry cleaning for shirts.'),
        ServiceItem(
            name: 'Shorts / Small',
            price: 63,
            description: 'Dry cleaning for shorts and small items.'),
        ServiceItem(
            name: 'Skirt Lined',
            price: 127,
            description: 'Professional dry cleaning for lined skirts.'),
        ServiceItem(
            name: 'Suit (1 × 2)',
            price: 225,
            description: 'Dry cleaning for a suit with two pieces.'),
        ServiceItem(
            name: 'Suit (1 × 3)',
            price: 298,
            description: 'Dry cleaning for a suit with three pieces.'),
        ServiceItem(
            name: 'Trouser',
            price: 98,
            description: 'Professional dry cleaning for trousers.'),
        ServiceItem(
            name: 'Graduation Gown',
            price: 206,
            description: 'Professional cleaning for graduation gowns.'),
        ServiceItem(
            name: 'Dress Pleated',
            price: 229,
            description: 'Professional cleaning for pleated dresses.'),
        ServiceItem(
            name: 'Dress Winter',
            price: 224,
            description: 'Professional cleaning for winter dresses.'),
        ServiceItem(
            name: 'Fancy Evening Beading',
            price: 217,
            description: 'Specialist cleaning for beaded evening wear.'),
        ServiceItem(
            name: 'Gym Dress',
            price: 92,
            description: 'Professional cleaning for gym dresses.'),
        ServiceItem(
            name: 'Jersey',
            price: 126,
            description: 'Professional dry cleaning for jerseys.'),
        ServiceItem(
            name: 'Jersey S/S',
            price: 106,
            description: 'Professional cleaning for short-sleeved jerseys.'),
        ServiceItem(
            name: 'Lumber Heavy',
            price: 138,
            description: 'Professional cleaning for heavy lumber garments.'),
        ServiceItem(
            name: 'Lumber Light',
            price: 126,
            description: 'Professional cleaning for light lumber garments.'),
        ServiceItem(
            name: 'Skirt Plain',
            price: 119,
            description: 'Professional dry cleaning for plain skirts.'),
        ServiceItem(
            name: 'Skirt Pleated',
            price: 171,
            description: 'Professional dry cleaning for pleated skirts.'),
        ServiceItem(
            name: 'Ties',
            price: 63,
            description: 'Professional dry cleaning for ties.'),
        ServiceItem(
            name: 'Waist-Coat',
            price: 90,
            description: 'Professional dry cleaning for waistcoats.'),
        ServiceItem(
            name: 'Wedding Gown',
            price: 345,
            description: 'Specialist cleaning for wedding gowns.'),
        ServiceItem(
            name: 'Mascot with Head Piece',
            price: 440,
            description: 'Specialist cleaning for mascot outfits.'),
      ],
    ),

    // 3. IRONING - ESTIMATED PROTOTYPE PRICES
    ServiceCategory(
      name: 'Ironing',
      description: 'Crisp, wrinkle-free clothing for a polished look.',
      icon: Icons.iron,
      startingPrice: 15.00,
      items: [
        ServiceItem(
            name: 'Shirt',
            price: 15,
            description: 'Ironing price per shirt.',
            isEstimated: true),
        ServiceItem(
            name: 'Trousers',
            price: 20,
            description: 'Ironing price per pair.',
            isEstimated: true),
        ServiceItem(
            name: 'Dress',
            price: 30,
            description: 'Ironing price per dress.',
            isEstimated: true),
        ServiceItem(
            name: 'Jacket',
            price: 35,
            description: 'Ironing price per jacket.',
            isEstimated: true),
      ],
    ),

    // 4. BEDDING & LINEN
    ServiceCategory(
      name: 'Bedding & Linen',
      description: 'Clean and fresh bedding, towels and linen.',
      icon: Icons.bed,
      items: [
        ServiceItem(
            name: 'Blanket Single',
            price: 90,
            description: 'Cleaning for a single blanket.'),
        ServiceItem(
            name: 'Blanket Double Light',
            price: 207,
            description: 'Cleaning for a light double blanket.'),
        ServiceItem(
            name: 'Blanket Double Heavy',
            price: 246,
            description: 'Cleaning for a heavy double blanket.'),
        ServiceItem(
            name: 'Duvet Cover Double',
            price: 70,
            description: 'Cleaning for a double duvet cover.'),
        ServiceItem(
            name: 'Duvet Cover Single',
            price: 38,
            description: 'Cleaning for a single duvet cover.'),
        ServiceItem(
            name: 'Duvet Inner Single Light',
            price: 115,
            description: 'Cleaning for a light single duvet inner.'),
        ServiceItem(
            name: 'Duvet Inner Heavy',
            price: 246,
            description: 'Cleaning for a heavy duvet inner.'),
        ServiceItem(
            name: 'Goose/Feather Down',
            price: 290,
            description: 'Specialist cleaning for down bedding.'),
        ServiceItem(
            name: 'Bed Spread/Quilt Light',
            price: 290,
            description: 'Cleaning for a light bedspread or quilt.'),
        ServiceItem(
            name: 'Bed Spread/Quilt Heavy',
            price: 290,
            description: 'Cleaning for a heavy bedspread or quilt.'),
        ServiceItem(
            name: 'Curtain No Lining (1.4m)',
            price: 194,
            description: 'Cleaning for unlined curtains.'),
        ServiceItem(
            name: 'Curtain With Lining',
            price: 241,
            description: 'Cleaning for lined curtains.'),
        ServiceItem(
            name: 'Terelene',
            price: 106,
            description: 'Cleaning for Terelene items.'),
        ServiceItem(
            name: 'Sleeping Bags',
            price: 106,
            description: 'Cleaning for sleeping bags.'),
        ServiceItem(
            name: 'Towels Small',
            price: 7,
            description: 'Cleaning for small towels.'),
        ServiceItem(
            name: 'Table Cloth Small (2)',
            price: 18.30,
            description: 'Cleaning for small tablecloths.'),
        ServiceItem(
            name: 'Table Skirts',
            price: 51.30,
            description: 'Cleaning for table skirts.'),
        ServiceItem(
            name: 'Pillow Case',
            price: 4.50,
            description: 'Cleaning for pillowcases.'),
        ServiceItem(
            name: 'Pillows',
            price: 83.50,
            description: 'Cleaning for pillows.'),
        ServiceItem(
            name: 'Bed Frill',
            price: 17.44,
            description: 'Cleaning for bed frills.'),
        ServiceItem(
            name: 'Towels Large / Sheet',
            price: 17.44,
            description: 'Cleaning for large towels or sheets.'),
        ServiceItem(
            name: 'Sheet Single',
            price: 11,
            description: 'Cleaning for a single sheet.'),
        ServiceItem(
            name: 'Sheet Fitted',
            price: 11,
            description: 'Cleaning for a fitted sheet.'),
        ServiceItem(
            name: 'Sheet Double / King / Queen',
            price: 17.44,
            description: 'Cleaning for larger sheets.'),
        ServiceItem(
            name: 'F/Sheet Double / King / Queen',
            price: 17.44,
            description: 'Cleaning for larger flat sheets.'),
        ServiceItem(
            name: 'Napkins', price: 3.50, description: 'Cleaning for napkins.'),
        ServiceItem(
            name: 'Table Cloth Large (3–5m)',
            price: 26.75,
            description: 'Cleaning for large tablecloths.'),
        ServiceItem(
            name: 'Apron', price: 18.19, description: 'Cleaning for aprons.'),
      ],
    ),

    // 5. SHOE CLEANING - ESTIMATED PROTOTYPE PRICES
    ServiceCategory(
      name: 'Shoe Cleaning',
      description: 'Keep your shoes looking fresh and clean.',
      icon: Icons.directions_walk,
      startingPrice: 65.00,
      items: [
        ServiceItem(
            name: 'Formal Shoes',
            price: 65,
            description: 'Price per pair.',
            isEstimated: true),
        ServiceItem(
            name: 'Sneakers',
            price: 80,
            description: 'Price per pair.',
            isEstimated: true),
        ServiceItem(
            name: 'Boots',
            price: 100,
            description: 'Price per pair.',
            isEstimated: true),
      ],
    ),

    // 6. OTHER SPECIAL SERVICES
    ServiceCategory(
      name: 'Other Special Services',
      description: 'Specialist cleaning for carpets and leather garments.',
      icon: Icons.auto_awesome,
      items: [
        ServiceItem(
          name: 'Carpet Cleaning',
          price: 0,
          description:
              'Cleaning for carpets and rugs. Pricing depends on the item and requires confirmation by SupaClean.',
        ),
        ServiceItem(
          name: 'Leather Garments',
          price: 0,
          description:
              'Specialist care for leather clothing, such as leather jackets. Items may need assessment before cleaning is accepted and priced.',
        ),
      ],
    ),
  ];

  /// The categories as shown: the server's prices, descriptions and
  /// availability laid over the built-in list (see [ServiceCatalogue]).
  List<ServiceCategory> get services =>
      ServiceCatalogue.instance.apply(_builtIn);

  List<ServiceItem> getItemsForCategory(String categoryName) {
    final category = services.firstWhere(
      (service) => service.name == categoryName,
      orElse: () => services.first,
    );

    return category.items;
  }
}
