import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mad/features/app/splash_screen/splash_screen.dart';
import 'package:mad/features/user_auth/presentation/pages/Login_Page.dart';
import 'package:mad/screens/root_app.dart';

import 'admin/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: kIsWeb || Platform.isAndroid
        ? const FirebaseOptions(
            apiKey: "AIzaSyA61Nue5JodtUAQojy5mhtadERBdaqmSPM",
            appId: '622475624344:android:c5a581e2bd847ce69635ed',
            messagingSenderId: '622475624344',
            projectId: 'mads-df824',
            storageBucket: "mads-df824.appspot.com",
          )
        : null,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Firebase',
      home: _getInitialScreen(),
    );
  }

  Widget _getInitialScreen() {
    return SplashScreen(
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(); // Show loading indicator while checking auth state
          } else {
            if (snapshot.hasData) {
              // Check if the user is banned
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('UserEmails')
                    .doc(snapshot.data!.uid)
                    .get(),
                builder: (BuildContext context,
                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(); // Show loading indicator while fetching user data
                  } else {
                    if (snapshot.hasData && snapshot.data != null) {
                      // Cast data to Map<String, dynamic>
                      Map<String, dynamic>? userData =
                          snapshot.data!.data() as Map<String, dynamic>?;

                      // Check if the 'ban' field is true
                      if (userData?['ban'] == true) {
                        // User is banned, show Account Banned dialog
                        return AccountBannedDialog();
                      } else {
                        // User is not banned, proceed to dashboard
                        return kIsWeb ? AdminDashboard() : RootApp();
                      }
                    } else {
                      // User data not found, proceed to login
                      return LoginPage();
                    }
                  }
                },
              );
            } else {
              // User is not logged in, show login page
              return LoginPage();
            }
          }
        },
      ),
    );
  }
}

class AccountBannedDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Account Banned'),
      content: Text('Your account has been banned.'),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            // Log out the user when "OK" is pressed
            FirebaseAuth.instance.signOut();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => LoginPage()),
              (Route<dynamic> route) => false,
            );
          },
          child: Text('OK'),
        ),
      ],
    );
  }
}
