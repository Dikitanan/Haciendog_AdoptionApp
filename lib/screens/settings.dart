import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mad/features/user_auth/presentation/pages/login_page.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      print("User signed out successfully.");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      print("Error signing out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error signing out. Please try again."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      child: ElevatedButton(
          onPressed: () {
            _signOut(context);
          },
          child: Text('Logout')),
    ));
  }
}
