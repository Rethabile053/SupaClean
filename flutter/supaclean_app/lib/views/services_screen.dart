
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../services/service_catalogue.dart';
import '../viewmodels/service_viewmodel.dart';
import '../widgets/app_header.dart';
import 'detailed_services_screen.dart';
import 'main_shell.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen>
    with ServiceCatalogueWatcher {
  final ServiceViewModel viewModel = ServiceViewModel();
  String? selectedService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppHeader(title: 'Our Services'),
      bottomNavigationBar: const FlowBottomNav(),
body: ListView(
  padding: const EdgeInsets.all(16),
  children: [
    const Text(
      'Choose a service below to see more details and pricing.',
      style: TextStyle(
        fontSize: 14,
        color: AppColors.textGrey,
        height: 1.4,
      ),
    ),
    const SizedBox(height: 20),

    ...viewModel.services.map(

            (service) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ServiceCard(
                service: service,
                isSelected: selectedService == service.name,
                onTap: () {
                  setState(() {
                    selectedService = service.name;
                  });

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailedServicesScreen(
                        category: service.name,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceCategory service;
  final VoidCallback onTap;
  final bool isSelected;

  const _ServiceCard({
    required this.service,
    required this.onTap,
    required this.isSelected,
  });

  String get imageUrl {
    switch (service.name) {
      case 'Wash & Fold':
        return 'https://images.pexels.com/photos/7691101/pexels-photo-7691101.jpeg';
      case 'Dry Cleaning':
        return 'https://images.unsplash.com/photo-1520434901111-8e9bcb42c628?auto=format&fit=crop&w=400&q=80';
      case 'Ironing':
        return 'https://framerusercontent.com/images/wgAiMcd2q4u0SyOo60S9q3zZD0.jpg';
      case 'Bedding & Linen':
        return 'https://cdn.shopify.com/s/files/1/0106/0755/8722/files/white_bed_sheet_in_queen_size_Singapore_1.png?v=1764224729';
      case 'Shoe Cleaning':
        return 'https://bespokedxb.com/cdn/shop/products/sneaker-cleaning.jpg?v=1636543310';
      case 'Other Special Services':
        return 'https://files.elfsightcdn.com/eafe4a4d-3436-495d-b748-5bdce62d911d/77044514-a648-4b05-a57a-4e63e616c2e3/a_professional_realistic_photograph_of_a_carpet_cleaning_technician_cleaning_a_floor_happx3mxvt7ha909jm3x_2.png';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.background,
      elevation: isSelected ? 2 : 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: imageUrl.isEmpty
                      ? _imageFallback()
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _imageFallback();
                          },
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;

                            return Container(
                              color: AppColors.background,
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      service.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                        height: 1.4,
                      ),
                    ),
                    if (service.startingPrice != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'From R${service.startingPrice!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textGrey,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.background,
      alignment: Alignment.center,
      child: Icon(
        service.icon,
        size: 38,
        color: AppColors.primary,
      ),
    );
  }
}
