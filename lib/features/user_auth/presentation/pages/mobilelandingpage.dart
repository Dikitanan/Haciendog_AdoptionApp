import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html; // Add this import to use window.open

class LandingPageMobile extends StatefulWidget {
  const LandingPageMobile({super.key});

  @override
  State<LandingPageMobile> createState() => _LandingPageMobileState();
}

class _LandingPageMobileState extends State<LandingPageMobile> {
  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Loading state
  bool _isLoading = false;

  // Method to fetch data from Firestore
  Future<void> fetchShelterDetails() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      // Fetch the document from the ShelterSettings collection
      DocumentSnapshot snapshot = await _firestore
          .collection('ShelterSettings')
          .doc('KvScqKpMGE1zPrZAHdvS') // Replace with the actual document ID
          .get();

      if (snapshot.exists) {
        // Retrieve fields from the document
        String facebookAccount = snapshot.get('FacebookAccount') ?? 'No data';
        String shelterDetails = snapshot.get('ShelterDetails') ?? 'No data';
        String shelterLocation = snapshot.get('ShelterLocation') ?? 'No data';

        // Show the fetched data in a dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "Shelter Details",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Color(0xFFE96560), // Title color
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDetailRow(
                        Icons.location_on, "Location", shelterLocation),
                    _buildDetailRow(Icons.info, "Details", shelterDetails),
                    _buildDetailRow(Icons.link, "Facebook", facebookAccount),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _isLoading = false; // Stop loading when dialog is closed
                    });
                  },
                  child: Text("Close"),
                ),
              ],
            );
          },
        );
      } else {
        // Handle document not found case
        print("No document found");
        setState(() {
          _isLoading = false; // Stop loading if no document is found
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        _isLoading = false; // Stop loading on error
      });
      // Optionally show an error message
    }
  }

  // Helper method to build a detail row
  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 10.0), // Add vertical padding
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFE96560)), // Icon with color
          SizedBox(width: 10), // Space between icon and text
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "$title: ",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE96560), // Title color
                    ),
                  ),
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      color: Colors.black, // Value color
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE96560).withOpacity(0.9),
                  Color.fromARGB(255, 247, 210, 209).withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8.0,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/icons/haciendoglogo.jpg',
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Welcome Message
                  Text(
                    "Welcome to Haciendog",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE96560),
                    ),
                  ),
                  SizedBox(height: 10),
                  // Tagline or additional text
                  Text(
                    "Your trusted platform for animal adoption.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  // Download Button
                  ElevatedButton(
                    onPressed: () {
                      // Open the Google Drive link to auto-download the file
                      html.window.open(
                        'https://drive.google.com/uc?export=download&id=130DK7E7_Lm6ynXkUu9Cx2cUoYv9QfTIp',
                        '_blank',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE96560),
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      "Download the App",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // Learn More Button or Loading Indicator
                  _isLoading
                      ? CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : TextButton(
                          onPressed:
                              fetchShelterDetails, // Fetch shelter details when pressed
                          child: Text(
                            "Learn More",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
