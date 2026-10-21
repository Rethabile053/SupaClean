
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supaclean/views/date_time_screen.dart';
import 'package:supaclean/views/my_orders_screen.dart';

import '../core/constants.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/service_viewmodel.dart';
import 'services_screen.dart';
//import 'detailed_services_screen.dart';
//import 'my_orders_screen.dart';
//import 'choose_date_time_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthViewModel>().currentUser;
    final fullName = user?.fullName.trim() ?? '';
    

    final services = ServiceViewModel().services;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting and profile shortcut
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Good day!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hi, $fullName ',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () => _openTab(context, 3),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFFFE7E7),
                      child: Text(
                        fullName.isEmpty
                            ? 'U'
                            : fullName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Promotional banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF43B40),
                      Color(0xFFB9232B),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SUPACLEAN PROMO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'LET US TAKE CARE OF YOUR\nLAUNDRY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Fresh. Clean. On time.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Quick actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.add_circle_outline,
                      label: 'Place Order',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ServicesScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.access_time,
                      label: 'My Orders',
                      onTap: () => _openTab(context, 1),
                    ),
                  ),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.calendar_month_outlined,
                      label: 'Schedule',
                      onTap: () => _openTab(context, 2),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // Services heading
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Our Services',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  
TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ServicesScreen(),
      ),
    );
  },
  child: const Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'See All',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
        ),
      ),
      SizedBox(width: 4),
      Icon(
        Icons.arrow_forward_ios,
        color: AppColors.primary,
        size: 12,
      ),
    ],
  ),
),

                ],
              ),

              // Service cards
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length > 4 ? 4 : services.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  final service = services[index];

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const ServicesScreen(),
    ),
  );
},
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE9E9E9),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEEEE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  service.icon,
                                  color: AppColors.primary,
                                  size: 19,
                                ),
                              ),
                              const Spacer(),
                              if (service.startingPrice != null)
                                Flexible(
                                  child: Text(
                                    'R${service.startingPrice!.toStringAsFixed(0)}+',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            service.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              // Pickup and delivery information
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ServicesScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(13),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEEE),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: const Color(0xFFFFD8DA),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        color: AppColors.primary,
                        size: 25,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PICKUP & DELIVERY',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Choose your preferred option when placing an order.',
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: _BottomNavigation(
        selectedIndex: 0,
        onTap: (index) => _openTab(context, index),
      ),
    );
  }

  void _openTab(BuildContext context, int index) {
    Widget screen;

    switch (index) {
      case 0:
        screen = const HomeScreen();
        break;
      case 1:
        screen = const MyOrdersScreen();
        break;
      case 2:
        screen = const ChooseDateTimeScreen();
        break;
      case 3:
        screen = const ProfileScreen();
        break;
      default:
        screen = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEEEE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNavigation({
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_outlined, 'Home'),
      (Icons.access_time, 'My Orders'),
      (Icons.calendar_month_outlined, 'Schedule'),
      (Icons.person_outline, 'Profile'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE8E8E8)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(items.length, (index) {
              final active = index == selectedIndex;

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        items[index].$1,
                        color: active
                            ? AppColors.primary
                            : Colors.blueGrey,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[index].$2,
                        style: TextStyle(
                          fontSize: 10,
                          color: active
                              ? AppColors.primary
                              : Colors.blueGrey,
                          fontWeight: active
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
