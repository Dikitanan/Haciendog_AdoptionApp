import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart'; // Import Firestore

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

        return Scaffold(
          appBar: AppBar(
            title: Text('Pet Details'),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          petData['Image'],
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            petData['Name'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.pets, size: 20, color: Colors.white),
                              SizedBox(width: 5),
                              Text(petData['Gender'],
                                  style: TextStyle(color: Colors.white)),
                              SizedBox(width: 10),
                              Icon(Icons.category,
                                  size: 20, color: Colors.white),
                              SizedBox(width: 5),
                              Text(petData['Breed'],
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          petData['Status'],
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'Additional Info:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(
                        10), // Adjust the radius as needed
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: _buildDetailRow('Species', petData['CatOrDog']),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: _buildDetailRow('Age', petData['AgeInShelter']),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: _buildDetailRow(
                            'Personality', petData['Personality']),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: _buildDetailRow('Health Status', petData['PWD']),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  'Description:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(
                        10), // Adjust the radius as needed
                  ),
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    height: 90,
                    width: double.infinity,
                    child: SingleChildScrollView(
                      child: Text(
                        petData['Description'],
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
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
                      child: Text('Adopt'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}

Widget _buildAdoptionFormDialog(BuildContext context) {
  return AlertDialog(
    title: Text('Adoption Form'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fill out the adoption form below:'),
          // Add form fields here
        ],
      ),
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
