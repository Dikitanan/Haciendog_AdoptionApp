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
            ClipOval(
              child: Image.network(
                'https://cdn.i-scmp.com/sites/default/files/d8/images/canvas/2024/03/27/1e1676e5-4b7b-4734-9b77-b63abb5ca315_293a4ec5.jpg',
                width: 200,
                height: 200,
                fit: BoxFit
                    .cover, // Ensures the image covers the clip area without altering its aspect ratio
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
        color: Colors.blue.shade700,
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
