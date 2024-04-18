import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
            return CircularProgressIndicator(); // Show loading indicator while checking auth state
          } else {
            if (snapshot.hasData) {
              return kIsWeb
                  ? AdminDashboard()
                  : RootApp(); // If user is logged in, show AdminDashboard or RootApp based on platform
            } else {
              return LoginPage(); // If user is not logged in, show LoginPage
            }
          }
        },
      ),
    );
  }
}
