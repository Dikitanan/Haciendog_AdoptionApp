import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

class PetDetailsDialog extends StatelessWidget {
  final String currentPetId;

  PetDetailsDialog({required this.currentPetId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('Animal')
          .doc(currentPetId)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        var petData = snapshot.data?.data() as Map<String, dynamic>?;

        if (petData == null) {
          return Center(child: Text('Pet not found'));
        }

        return Dialog(
          child: SingleChildScrollView(
            child: Container(
              width: 300, // Adjust width to fit content
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          petData['Image'],
                          width: 400,
                          height: 250,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Opacity(
                          opacity: 0.7,
                          child: Padding(
                            padding: const EdgeInsets.all(0), // Add padding
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 29, 25, 25),
                                borderRadius: BorderRadius.circular(
                                    10.0), // Set border radius for rounded corners
                              ),
                              width: 240,
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      petData['Name'],
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(Icons.pets,
                                            size: 24, color: Colors.white),
                                        SizedBox(width: 5),
                                        Text(
                                          petData['Gender'],
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        SizedBox(width: 10),
                                        Icon(Icons.category,
                                            size: 24, color: Colors.white),
                                        SizedBox(width: 5),
                                        Text(
                                          petData['Breed'],
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(Icons.check_circle,
                                            size: 24, color: Colors.green),
                                        SizedBox(width: 5),
                                        Text(
                                          petData['Status'],
                                          style: TextStyle(color: Colors.green),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    child: Text(
                      'Other Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.grey[200],
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Text('Species: ${petData['CatOrDog']}'),
                            SizedBox(width: 20),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text('Age: ${petData['AgeInShelter']}'),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Text('Personality: ${petData['Personality']}'),
                            SizedBox(width: 20),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text('Health Status: ${petData['PWD']}'),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    child: Text(
                      'Description:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.grey[200],
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        Container(
                          height: 70,
                          width: 230, // Limit height for description
                          child: SingleChildScrollView(
                            child: Text(
                              petData['Description'],
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.grey[300], // Text color
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12), // Button padding
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  8)), // Button border radius
                        ),
                        child: Text('Close'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) =>
                                _buildAdoptionFormDialog(context),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue, // Text color
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12), // Button padding
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  8)), // Button border radius
                        ),
                        child: Text('Adopt'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget _buildAdoptionFormDialog(BuildContext context) {
  return AlertDialog(
    title: Text('Adoption Form'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fill out the adoption form below:'),
        // Add form fields here
      ],
    ),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop(); // Close the adoption form dialog
        },
        child: Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () {
          // Implement form submission logic here
        },
        child: Text('Submit'),
      ),
    ],
  );
}
