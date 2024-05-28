import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:animated_text_kit/animated_text_kit.dart';

class SplashScreen extends StatefulWidget {
  final Widget? child;
  const SplashScreen({Key? key, this.child}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late String randomTip;

  final List<String> tips = [
    "Regularly exercise your pet.",
    "Ensure your pet has a healthy diet.",
    "Regular vet check-ups are important.",
    "Teach your pet social skills.",
    "Love and care for your pet unconditionally.",
  ];

  @override
  void initState() {
    super.initState();
    randomTip = tips[math.Random().nextInt(tips.length)];
    Future.delayed(const Duration(seconds: 4), () {
      if (widget.child != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => widget.child!),
          (route) => false,
        );
      } else {
        print("SplashScreen child is null");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                color: Color(0xFFE96560),
                shape: BoxShape.circle, // Set the shape to circle
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/icons/haciendoglogo-removebg-preview.png',
                  width: 300,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 20), // Provides some spacing
            kIsWeb ? webText() : animatedMobileText(),
            SizedBox(height: 20), // More spacing
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(randomTip,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24.0,
                    fontStyle: FontStyle.italic,
                  )),
            ),
            SizedBox(height: 30), // Even more spacing
            CircularProgressIndicator(), // Adds a loading indicator at the bottom
          ],
        ),
      ),
    );
  }

  Widget webText() {
    return Text(
      'Haciendog',
      style: TextStyle(
        fontSize: 35.0,
        fontWeight: FontWeight.bold,
        color: Color(0xFFE96560),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget animatedMobileText() {
    return ColorizeAnimatedTextKit(
      onTap: () {
        print("Tap Event");
      },
      text: const ['Haciendog'],
      textStyle: const TextStyle(
        fontSize: 30.0,
        fontWeight: FontWeight.bold,
      ),
      colors: [
        Colors.red,
        Colors.orange,
        Colors.yellow,
        Colors.green,
        Colors.blue,
        Colors.indigo,
        Colors.purple,
      ],
      textAlign: TextAlign.center,
    );
  }
}
