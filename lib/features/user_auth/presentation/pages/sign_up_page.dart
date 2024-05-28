import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mad/admin/admin_dashboard.dart';
import 'package:mad/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:mad/features/user_auth/presentation/pages/login_page.dart';

void main() => runApp(SignUpApp());

class SignUpApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SignUpPage(),
    );
  }
}

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final FirebaseAuthService _auth = FirebaseAuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                  _textInput(
                    hint: "Confirm Password",
                    icon: Icons.vpn_key,
                    controller: _confirmPasswordController,
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
                                setState(() {
                                  _isLoading =
                                      true; // Set isLoading to true when the button is clicked
                                });
                                _signUp();
                              },
                              btnText: "REGISTER",
                              isLoading:
                                  _isLoading, // Pass the isLoading state to ButtonWidget
                            ),
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "Have an account? ",
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
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            child: Text(
                              "Login",
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

  void _signUp() async {
    String email = _emailController.text;
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Start showing CircularProgressIndicator
    });

    try {
      // Sign up the user
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Access the user object from the userCredential
      User? user = userCredential.user;

      if (user != null) {
        print("Account Created");

        // Sign in the user after successful registration
        // This establishes a session for the user
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        await FirebaseFirestore.instance
            .collection('UserEmails')
            .doc(user.uid)
            .set({'email': email, 'ban': false});

        // Navigate to the home page after sign-up and sign-in
        if (kIsWeb) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => AdminDashboard(),
            ),
            (route) => false, // This prevents going back
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
            (route) => false, // This prevents going back
          );
        }

        // Display success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Successfully registered. Please Log in."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error creating account: $e");
      // Handle sign-up errors here

      // Display error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false; // Stop showing CircularProgressIndicator
      });
    }
  }
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
  final bool isLoading;

  ButtonWidget({this.btnText, this.onClick, required this.isLoading});

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
        child: isLoading
            ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : Text(
                btnText,
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

Color orangeColors = Color.fromARGB(255, 230, 143, 140);
Color orangeLightColors = Color(0xFFE96560);
