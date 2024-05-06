import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DonatePage extends StatelessWidget {
  const DonatePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('ShelterSettings')
          .get()
          .then((querySnapshot) => querySnapshot.docs.first),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(); // Placeholder widget while data is loading
        }
        if (snapshot.hasError) {
          return Text(
              'Error: ${snapshot.error}'); // Display error if encountered
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Text(
              'Data not available'); // Handle case where data doesn't exist
        }

        final data = snapshot.data!;
        final imageUrl = data['Image1'] ??
            ''; // Use Image1 by default, change to Image2 or Image3 if needed
        final description =
            data['ShelterDetails'] ?? 'Description not available';

        return Center(
          child: Column(
            children: [
              SizedBox(
                height: 25,
              ),
              Text(
                'Scan Here to Donate',
                style: TextStyle(fontSize: 20),
              ),
              Center(
                child: Container(
                  width: 350, // Adjust the width according to your preference
                  height: 450, // Adjust the height according to your preference
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(imageUrl),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16.5),
              ),
            ],
          ),
        );
      },
    );
  }
}
