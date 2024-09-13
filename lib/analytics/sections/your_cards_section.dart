import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mad/analytics/models/card_details.dart';
import 'package:mad/analytics/widgets/card_details_widget.dart';
import 'package:mad/analytics/widgets/category_box.dart';

class CardsSection extends StatefulWidget {
  final List<CardDetails> cardDetails;

  const CardsSection({Key? key, required this.cardDetails}) : super(key: key);

  @override
  _CardsSectionState createState() => _CardsSectionState();
}

class _CardsSectionState extends State<CardsSection> {
  String? imageUrl;
  String? phoneNumber;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch the first document from the ShelterSettings collection
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('ShelterSettings')
          .limit(1) // Limit the query to the first document
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          imageUrl = snapshot.docs.first['Image1'];
          phoneNumber = snapshot.docs.first['PhoneNumber'];
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20), // Rounded edges
      child: Container(
        height: 350,
        width: 700,
        color: Color(0xFFFFFFFF), // White color in Flutter
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Aligns content vertically
          children: [
            Text(
              'G-cash',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 0, 0, 0),
              ),
            ),

            //G-CASH NAME NEED TO ADD.
            if (phoneNumber != null) ...[
              SizedBox(height: 5), // Space between title and phone number
              Text(
                '$phoneNumber',
                style: TextStyle(
                    fontSize: 16,
                    color: const Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.bold),
              ),
            ],
            SizedBox(height: 10), // Space between the title/phone and the image
            Container(
              height: 250,
              width: 300,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.fill,
                    )
                  : Center(
                      child: Text(
                        'No Image Yet Please go to Settings.',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
