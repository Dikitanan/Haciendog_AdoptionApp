import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mad/admin/admin_dashboard.dart';
import 'package:mad/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:mad/features/user_auth/presentation/pages/home_page.dart';
import 'package:mad/features/user_auth/presentation/pages/sign_up_page.dart';
import 'package:mad/features/user_auth/presentation/widget/form_container_widget.dart';
import 'package:mad/screens/root_app.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuthService _auth = FirebaseAuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Check if the current user's account is banned
    _checkAndLogoutBannedUser();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Login",
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
              ),
              const SizedBox(
                height: 30,
              ),
              FormContainerWidget(
                controller: _emailController,
                hintText: "Email",
                isPasswordField: false,
              ),
              const SizedBox(
                height: 10,
              ),
              FormContainerWidget(
                controller: _passwordController,
                hintText: "Password",
                isPasswordField: true,
              ),
              const SizedBox(
                height: 30,
              ),
              GestureDetector(
                onTap: _signIn,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadiusDirectional.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      "Login",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an Account?"),
                  const SizedBox(
                    width: 5,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SignUpPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _signIn() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    try {
      // Check if the user's account is banned
      bool isBanned = await _checkUserBan(email);
      if (isBanned) {
        // Show modal indicating account is banned
        _showBannedModal();
        return;
      }

      // Sign in the user
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Access the user object from the userCredential
      User? user = userCredential.user;

      if (user != null) {
        print("User signed in successfully");

        // Navigate to the appropriate page after sign-in
        if (kIsWeb) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminDashboard(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const RootApp(),
            ),
          );
        }
      }
    } catch (e) {
      print("Error signing in: $e");
      // Handle sign-in errors here

      // Display error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _checkUserBan(String email) async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('UserEmails')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final userData = snapshot.docs.first.data() as Map<String, dynamic>?;

        // Check if userData is not null and contains the 'ban' field
        if (userData != null && userData.containsKey('ban')) {
          final isBanned = userData['ban'] as bool? ?? false;
          return isBanned;
        }
      }
    } catch (e) {
      print('Error checking user ban status: $e');
    }
    return false;
  }

  void _showBannedModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Account Banned'),
          content:
              Text('Your account has been banned. Please contact support.'),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkAndLogoutBannedUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final email = user.email;
        final isBanned = await _checkUserBan(email!);
        if (isBanned) {
          // Log out the banned user
          await FirebaseAuth.instance.signOut();
          print("Logged out banned user: $email");
        }
      }
    } catch (e) {
      print('Error checking and logging out banned user: $e');
    }
  }
}
