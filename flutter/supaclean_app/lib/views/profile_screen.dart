import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/app_header.dart';
import '../widgets/back_circle_button.dart';
import 'login_screen.dart';
import 'my_addresses_screen.dart';
import 'notification_center_screen.dart';
import 'contact_us_screen.dart';
import 'terms_screen.dart';

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

    var saving = false;

    showDialog(
      context: context,

      builder: (context) {

        return StatefulBuilder(
          builder: (context, setDialog) {

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

              onPressed: saving
                  ? null
                  : () async {
                      final vm = this.context.read<AuthViewModel>();
                      final messenger =
                          ScaffoldMessenger.of(this.context);
                      final dialog = Navigator.of(context);

                      setDialog(() => saving = true);
                      final ok = await vm.updateProfile(
                        fullName: nameController.text,
                        email: emailController.text,
                        phoneNumber: phoneController.text,
                      );
                      if (!mounted) return;

                      if (!ok) {
                        setDialog(() => saving = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              vm.errorMessage ??
                                  'Could not save your profile.',
                            ),
                          ),
                        );
                        return;
                      }

                      // Show what Supabase now holds.
                      final user = vm.currentUser;
                      setState(() {
                        name = user?.fullName ?? name;
                        email = user?.email ?? email;
                        phone = user?.phoneNumber ?? phone;
                      });
                      dialog.pop();

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            vm.emailChangePending
                                ? 'Profile saved. Check your new email '
                                    'address to confirm the change.'
                                : 'Profile updated successfully!',
                          ),
                        ),
                      );
                    },

              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save Changes',
                    ),
            ),
          ],
        );
          },
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

      appBar: const AppHeader(title: 'Profile'),

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
                        'Saved pickup addresses',

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyAddressesScreen(),
                        ),
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
                        'Notification Center',

                    subtitle:
                        'Control transactional & promo alerts',

                    onTap: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const NotificationCenterScreen(),
                        ),
                      );
                    },
                  ),

                  // ==================================================
                  // TERMS AND CONDITIONS
                  // ==================================================

                  ProfileOption(
                    icon: Icons.description_outlined,
                    title: 'Terms and Conditions',
                    subtitle: 'Payment, care and turnaround times',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TermsScreen(),
                        ),
                      );
                    },
                  ),

                  // ==================================================
                  // CONTACT US
                  // ==================================================

                  ProfileOption(
                    icon: Icons.phone_outlined,
                    title: 'Contact Us',
                    subtitle: 'Depot addresses and phone numbers',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ContactUsScreen(),
                        ),
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

        automaticallyImplyLeading: false,

        leading: const BackCircleButton(),

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

