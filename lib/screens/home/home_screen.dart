import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Enter is successful!'),
            const SizedBox(height: 8),
            Text(user?.email ?? ''),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              child: const Text('Log out.'),
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchScreen(),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Color(0xFFE50914),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Search Movies',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
