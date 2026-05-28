import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../settings/visibility_screen.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            CupertinoIcons.chevron_back,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Account Preferences
          _sectionLabel('Account Preferences'),
          _settingsCard([
            _settingsTile(
              context,
              icon: CupertinoIcons.person,
              label: 'Account Preferences',
              isLast: false,
              onTap: () {},
            ),
            _settingsTile(
              context,
              icon: CupertinoIcons.lock,
              label: 'Login & Security',
              isLast: true,
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 24),

          // Visibility
          _sectionLabel('Visibility'),
          _settingsCard([
            _settingsTile(
              context,
              icon: CupertinoIcons.eye,
              label: 'Visibility',
              isLast: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VisibilityScreen(),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // Account
          _sectionLabel('Account'),
          _settingsCard([
            ListTile(
              leading: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFE50914).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  CupertinoIcons.square_arrow_left,
                  size: 16,
                  color: Color(0xFFE50914),
                ),
              ),
              title: const Text(
                'Log Out',
                style: TextStyle(
                  color: Color(0xFFE50914),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();

                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                        (route) => false,
                  );
                }
              },
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF555555),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: children),
    );
  }

  Widget _settingsTile(
      BuildContext context, {
        required IconData icon,
        required String label,
        required bool isLast,
        required VoidCallback onTap,
      }) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.grey),
          ),
          title: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          trailing: Icon(
            CupertinoIcons.chevron_right,
            size: 14,
            color: Colors.grey.shade700,
          ),
          onTap: onTap,
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 62),
            child: Container(
              height: 0.5,
              color: const Color(0xFF2C2C2E),
            ),
          ),
      ],
    );
  }
}