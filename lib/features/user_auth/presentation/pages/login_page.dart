import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mad/admin/admin_dashboard.dart';
import 'package:mad/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:mad/features/user_auth/presentation/pages/sign_up_page.dart';
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

  bool _isLoading = false;

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
    Widget content = Container(
      padding: EdgeInsets.only(bottom: 30),
      child: Column(
        children: <Widget>[
          HeaderContainer(""),
          Expanded(
            flex: 1,
            child: Container(
              margin: EdgeInsets.only(left: 20, right: 20, top: 30),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  _textInput(
                    hint: "Email",
                    icon: Icons.email,
                    controller: _emailController,
                    isPassword: false,
                  ),
                  _textInput(
                    hint: "Password",
                    icon: Icons.vpn_key,
                    controller: _passwordController,
                    isPassword: true,
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 10),
                    alignment: Alignment.centerRight,
                    child: Text("Forgot Password?"),
                  ),
                  Expanded(
                    child: Center(
                      child: _isLoading
                          ? CircularProgressIndicator()
                          : ButtonWidget(
                              onClick: () {
                                _signIn();
                              },
                              btnText: "LOGIN",
                            ),
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: Colors.black),
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.baseline,
                          baseline: TextBaseline.alphabetic,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignUpPage(),
                                ),
                              );
                            },
                            child: Text(
                              "Register",
                              style: TextStyle(color: orangeColors),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (kIsWeb) {
      content = Center(
        child: Container(
          width: 600,
          padding: EdgeInsets.all(16),
          child: content,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Color.fromARGB(255, 218, 197, 196),
      body: content,
    );
  }

  Widget _textInput({controller, hint, icon, required bool isPassword}) {
    return Container(
      margin: EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        color: Colors.white,
      ),
      padding: EdgeInsets.only(left: 10),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  void _signIn() async {
    setState(() {
      _isLoading = true;
    });

    String email = _emailController.text;
    String password = _passwordController.text;

    try {
      // Check if the user's account is banned
      bool isBanned = await _checkUserBan(email);
      if (isBanned) {
        // Show modal indicating account is banned
        _showBannedModal();
        setState(() {
          _isLoading = false;
        });
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
    } finally {
      setState(() {
        _isLoading = false;
      });
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

class HeaderContainer extends StatelessWidget {
  var text = "Login";

  HeaderContainer(this.text);

  @override
  Widget build(BuildContext context) {
    final bool isWeb =
        kIsWeb; // Assuming you have imported 'package:flutter/foundation.dart';

    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [orangeColors, orangeLightColors],
          end: Alignment.bottomCenter,
          begin: Alignment.topCenter,
        ),
        borderRadius: isWeb
            ? BorderRadius.only(
                bottomLeft: Radius.circular(100),
                bottomRight: Radius.circular(100),
              )
            : BorderRadius.only(
                bottomLeft: Radius.circular(100),
              ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            bottom: 20,
            right: 20,
            child: Text(
              text,
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          Center(
            child:
                Image.asset('assets/icons/haciendoglogo-removebg-preview.png'),
          ),
        ],
      ),
    );
  }
}

class ButtonWidget extends StatelessWidget {
  var btnText;
  var onClick;

  ButtonWidget({this.btnText, this.onClick});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onClick,
      child: Container(
        width: double.infinity,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [orangeColors, orangeLightColors],
              end: Alignment.centerLeft,
              begin: Alignment.centerRight),
          borderRadius: BorderRadius.all(
            Radius.circular(100),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          btnText,
          style: TextStyle(
              fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

Color orangeColors = Color.fromARGB(255, 230, 143, 140);
Color orangeLightColors = Color(0xFFE96560);
