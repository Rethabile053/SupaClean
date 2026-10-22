import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  // ==========================================================
  // USER INFORMATION
  // ==========================================================

  String name = '';
  String email = '';
  String phone = '';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthViewModel>().currentUser;
    if (user != null) {
      name = user.fullName;
      email = user.email;
      phone = user.phoneNumber;
    }
  }

  // ==========================================================
  // EDIT PROFILE
  // ==========================================================

  void _editProfile() {

    final nameController =
        TextEditingController(text: name);

    final emailController =
        TextEditingController(text: email);

    final phoneController =
        TextEditingController(text: phone);

    showDialog(
      context: context,

      builder: (context) {

        return AlertDialog(

          title: const Text(
            'Edit Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: SingleChildScrollView(

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [

                // FULL NAME
                TextField(
                  controller: nameController,

                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',

                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Color(0xFFD94B4B),
                    ),

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // EMAIL
                TextField(
                  controller: emailController,

                  keyboardType:
                      TextInputType.emailAddress,

                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText:
                        'Enter your email address',

                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFFD94B4B),
                    ),

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // PHONE
                TextField(
                  controller: phoneController,

                  keyboardType:
                      TextInputType.phone,

                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText:
                        'Enter your phone number',

                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                      color: Color(0xFFD94B4B),
                    ),

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          actions: [

            // CANCEL
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),

            // SAVE
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFD94B4B),

                foregroundColor: Colors.white,
              ),

              onPressed: () {

                setState(() {

                  name =
                      nameController.text.trim();

                  email =
                      emailController.text.trim();

                  phone =
                      phoneController.text.trim();
                });

                Navigator.pop(context);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Profile updated successfully!',
                    ),
                  ),
                );
              },

              child: const Text(
                'Save Changes',
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  void _logout() {

    showDialog(
      context: context,

      builder: (context) {

        return AlertDialog(

          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: const Text(
            'Are you sure you want to logout '
            'of SupaClean?',
          ),

          actions: [

            // CANCEL
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'Cancel',
              ),
            ),

            // LOGOUT
            TextButton(
              onPressed: () async {

                final navigator = Navigator.of(this.context);
                final messenger = ScaffoldMessenger.of(this.context);
                final vm = this.context.read<AuthViewModel>();

                Navigator.pop(context); // close dialog

                await vm.logout();

                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                  (_) => false,
                );

                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'You have been logged out.',
                    ),
                  ),
                );
              },

              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // OPEN OTHER PAGES
  // ==========================================================

  void _openPage(String title) {

    Navigator.push(
      context,

      MaterialPageRoute(
        builder: (context) {

          return SimplePage(
            title: title,
          );
        },
      ),
    );
  }

  // ==========================================================
  // PROFILE SCREEN
  // ==========================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xFFF8FBFC),

      // ======================================================
      // APP BAR
      // ======================================================

      appBar: AppBar(

        backgroundColor:
            const Color(0xFFF8FBFC),

        elevation: 0,

        leading: IconButton(

          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFFD94B4B),
          ),

          onPressed: () {
            Navigator.maybePop(context);
          },
        ),

        title: const Text(
          'Profile',

          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [

          IconButton(

            icon: const Icon(
              Icons.settings_outlined,
              color: Color(0xFFD94B4B),
            ),

            onPressed: () {
              _openPage('Settings');
            },
          ),
        ],
      ),

      // ======================================================
      // BODY
      // ======================================================

      body: Column(

        children: [

          Expanded(

            child: SingleChildScrollView(

              child: Column(

                children: [

                  const SizedBox(height: 25),

                  // ==================================================
                  // PROFILE CIRCLE
                  // ==================================================

                  Container(

                    width: 96,
                    height: 96,

                    decoration: BoxDecoration(

                      shape: BoxShape.circle,

                      color:
                          const Color(0xFFFFE7E7),

                      border: Border.all(
                        color:
                            const Color(0xFFD94B4B),
                        width: 2,
                      ),
                    ),

                    child: Center(

                      child: Text(

                        name.isEmpty
                            ? 'U'
                            : name[0].toUpperCase(),

                        style: const TextStyle(

                          fontSize: 34,

                          fontWeight:
                              FontWeight.bold,

                          color:
                              Color(0xFFD94B4B),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ==================================================
                  // NAME
                  // ==================================================

                  Text(

                    name.isEmpty
                        ? 'Your Name'
                        : name,

                    style: const TextStyle(

                      fontSize: 22,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  // ==================================================
                  // EMAIL
                  // ==================================================

                  Text(

                    email.isEmpty
                        ? 'your@email.com'
                        : email,

                    style: const TextStyle(

                      color: Colors.grey,

                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 5),

                  // ==================================================
                  // PHONE
                  // ==================================================

                  Text(

                    phone.isEmpty
                        ? 'Your phone number'
                        : phone,

                    style: const TextStyle(

                      color:
                          Color(0xFFD94B4B),

                      fontSize: 15,

                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ==================================================
                  // EDIT PROFILE BUTTON
                  // ==================================================

                  OutlinedButton.icon(

                    onPressed: _editProfile,

                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                    ),

                    label: const Text(
                      'Edit Profile',
                    ),

                    style:
                        OutlinedButton.styleFrom(

                      foregroundColor:
                          const Color(0xFFD94B4B),

                      side: const BorderSide(
                        color:
                            Color(0xFFD94B4B),
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // MY ADDRESSES
                  // ==================================================

                  ProfileOption(

                    icon:
                        Icons.location_on_outlined,

                    title:
                        'My Addresses',

                    subtitle:
                        'Manage shipping & billing locations',

                    onTap: () {
                      _openPage(
                        'My Addresses',
                      );
                    },
                  ),

                  // ==================================================
                  // PAYMENT METHODS
                  // ==================================================

                  ProfileOption(

                    icon:
                        Icons.credit_card_outlined,

                    title:
                        'Payment Methods',

                    subtitle:
                        'Saved cards & transfer accounts',

                    onTap: () {
                      _openPage(
                        'Payment Methods',
                      );
                    },
                  ),

                  // ==================================================
                  // NOTIFICATION SETTINGS
                  // ==================================================

                  ProfileOption(

                    icon:
                        Icons.notifications_none,

                    title:
                        'Notification Settings',

                    subtitle:
                        'Control transactional & promo alerts',

                    onTap: () {

                      _openPage(
                        'Notification Settings',
                      );
                    },
                  ),

                  // ==================================================
                  // HELP & SUPPORT
                  // ==================================================

                  ProfileOption(

                    icon:
                        Icons.help_outline,

                    title:
                        'Help & Support',

                    subtitle:
                        'FAQs, contact chat & user guides',

                    onTap: () {

                      _openPage(
                        'Help & Support',
                      );
                    },
                  ),

                  // ==================================================
                  // ABOUT US
                  // ==================================================

                  ProfileOption(

                    icon:
                        Icons.info_outline,

                    title:
                        'About Us',

                    subtitle:
                        'FreshnClean version history & policies',

                    onTap: () {

                      _openPage(
                        'About Us',
                      );
                    },
                  ),

                  const SizedBox(height: 35),

                  // ==================================================
                  // LOGOUT
                  // ==================================================

                  InkWell(

                    onTap: _logout,

                    child: Container(

                      width:
                          double.infinity,

                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 18,
                      ),

                      decoration:
                          const BoxDecoration(

                        color: Colors.white,

                        border: Border(
                          top: BorderSide(
                            color:
                                Color(0xFFE5E5E5),
                          ),

                          bottom: BorderSide(
                            color:
                                Color(0xFFE5E5E5),
                          ),
                        ),
                      ),

                      child: const Center(

                        child: Text(
                          'Logout',

                          style: TextStyle(

                            color:
                                Color(0xFFD94B4B),

                            fontSize: 18,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ======================================================
          // BOTTOM NAVIGATION
          // ======================================================

          Container(

            height: 78,

            decoration:
                const BoxDecoration(

              color: Colors.white,

              border: Border(
                top: BorderSide(
                  color:
                      Color(0xFFE5E5E5),
                ),
              ),
            ),

            child: Row(

              mainAxisAlignment:
                  MainAxisAlignment.spaceAround,

              children: [

                // HOME
                BottomNavItem(

                  icon:
                      Icons.home_outlined,

                  label:
                      'Home',

                  onTap: () {
                    _openPage('Home');
                  },
                ),

                // ORDERS
                BottomNavItem(

                  icon:
                      Icons.access_time,

                  label:
                      'Orders',

                  onTap: () {
                    _openPage('Orders');
                  },
                ),

                // SCHEDULE
                BottomNavItem(

                  icon:
                      Icons.calendar_today_outlined,

                  label:
                      'Schedule',

                  onTap: () {
                    _openPage('Schedule');
                  },
                ),

                // PROFILE
                BottomNavItem(

                  icon:
                      Icons.person_outline,

                  label:
                      'Profile',

                  active: true,

                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// PROFILE OPTION
// ==========================================================

class ProfileOption extends StatelessWidget {

  final IconData icon;

  final String title;

  final String subtitle;

  final VoidCallback onTap;

  const ProfileOption({

    super.key,

    required this.icon,

    required this.title,

    required this.subtitle,

    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return InkWell(

      onTap: onTap,

      child: Container(

        padding:
            const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 15,
        ),

        decoration:
            const BoxDecoration(

          color: Colors.white,

          border: Border(
            bottom: BorderSide(
              color:
                  Color(0xFFE5E5E5),
            ),
          ),
        ),

        child: Row(

          children: [

            // ICON
            Icon(

              icon,

              size: 27,

              color:
                  const Color(0xFFD94B4B),
            ),

            const SizedBox(width: 18),

            // TEXT
            Expanded(

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(

                    title,

                    style: const TextStyle(

                      fontSize: 16,

                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(

                    subtitle,

                    style: const TextStyle(

                      fontSize: 13,

                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // ARROW
            const Icon(

              Icons.chevron_right,

              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// BOTTOM NAVIGATION ITEM
// ==========================================================

class BottomNavItem extends StatelessWidget {

  final IconData icon;

  final String label;

  final bool active;

  final VoidCallback onTap;

  const BottomNavItem({

    super.key,

    required this.icon,

    required this.label,

    required this.onTap,

    this.active = false,
  });

  @override
  Widget build(BuildContext context) {

    final Color color = active

        ? const Color(0xFFD94B4B)

        : const Color(0xFF555555);

    return InkWell(

      onTap: onTap,

      child: SizedBox(

        width: 75,

        child: Column(

          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Icon(

              icon,

              color: color,

              size: 25,
            ),

            const SizedBox(height: 5),

            Text(

              label,

              style: TextStyle(

                color: color,

                fontSize: 12,

                fontWeight: active

                    ? FontWeight.bold

                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// TEMPORARY OTHER PAGE
// ==========================================================

class SimplePage extends StatelessWidget {

  final String title;

  const SimplePage({

    super.key,

    required this.title,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xFFF8FBFC),

      appBar: AppBar(

        backgroundColor:
            const Color(0xFFF8FBFC),

        elevation: 0,

        leading: IconButton(

          icon: const Icon(

            Icons.arrow_back,

            color:
                Color(0xFFD94B4B),
          ),

          onPressed: () {

            Navigator.pop(context);
          },
        ),

        title: Text(

          title,

          style: const TextStyle(

            color: Colors.black,

            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: Center(

        child: Column(

          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            const Icon(

              Icons.construction_outlined,

              size: 60,

              color:
                  Color(0xFFD94B4B),
            ),

            const SizedBox(height: 20),

            Text(

              '$title screen',

              style: const TextStyle(

                fontSize: 22,

                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(

              'This screen can be connected\n'
              'to the SupaClean functionality.',

              textAlign:
                  TextAlign.center,

              style: TextStyle(

                color: Colors.grey,

                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

