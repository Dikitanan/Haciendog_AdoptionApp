import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mad/features/app/splash_screen/splash_screen.dart';
import 'package:mad/features/user_auth/presentation/pages/Login_Page.dart';
import 'package:mad/screens/root_app.dart';

import 'admin/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: kIsWeb || Platform.isAndroid
        ? const FirebaseOptions(
            apiKey: 'AIzaSyA61Nue5JodtUAQojy5mhtadERBdaqmSPM',
            appId: '622475624344:android:c5a581e2bd847ce69635ed',
            messagingSenderId: '622475624344',
            projectId: 'mads-df824',
            storageBucket: 'mads-df824.appspot.com',
          )
        : null,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received a foreground message: ${message.messageId}');
    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
    }
  });

  runApp(MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling a background message: ${message.messageId}');
  // Add your custom logic to handle the background message
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
            return Container();
          } else {
            if (snapshot.hasData) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('UserEmails')
                    .doc(snapshot.data!.uid)
                    .get(),
                builder: (BuildContext context,
                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container();
                  } else {
                    if (snapshot.hasData && snapshot.data != null) {
                      Map<String, dynamic>? userData =
                          snapshot.data!.data() as Map<String, dynamic>?;

                      if (userData?['ban'] == true) {
                        return AccountBannedDialog();
                      } else {
                        return kIsWeb ? AdminDashboard() : RootApp();
                      }
                    } else {
                      return LoginPage();
                    }
                  }
                },
              );
            } else {
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
