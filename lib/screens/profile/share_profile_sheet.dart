import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShareProfileSheet extends StatelessWidget {
  const ShareProfileSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final username = FirebaseAuth.instance.currentUser?.displayName ?? 'user';
    final profileLink = 'popcorn.app/$username';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(color: const Color(0xFF333333), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          const Text('share profile', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),

          // link box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(profileLink, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: profileLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('link copied'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Color(0xFF1E1E1E),
                      ),
                    );
                  },
                  child: const Icon(Icons.copy_outlined, color: Color(0xFFE50914), size: 18),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // share options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ShareOption(icon: Icons.link, label: 'copy link', onTap: () {
                Clipboard.setData(ClipboardData(text: profileLink));
                Navigator.pop(context);
              }),
              _ShareOption(icon: Icons.ios_share_outlined, label: 'share', onTap: () {}),
              _ShareOption(icon: Icons.qr_code_2_outlined, label: 'QR code', onTap: () {}),
            ],
          ),

          const SizedBox(height: 20),

          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('close', style: TextStyle(color: Color(0xFF666666), fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ShareOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
        ],
      ),
    );
  }
}
