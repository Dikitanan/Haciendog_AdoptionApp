import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

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
                              Icon(Icons.wc, size: 20, color: Colors.white),
                              SizedBox(width: 5),
                              Text(petData['Gender'],
                                  style: TextStyle(color: Colors.white)),
                              SizedBox(width: 10),
                              Icon(Icons.pets, size: 20, color: Colors.white),
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
                  padding: EdgeInsets.all(8),
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
                      onPressed: () async {
                        // Fetch user profile data
                        User? user = FirebaseAuth.instance.currentUser;
                        String? userEmail = user != null ? user.email : null;

                        if (userEmail != null) {
                          // Check if the user has already submitted a form for this pet
                          QuerySnapshot querySnapshot = await FirebaseFirestore
                              .instance
                              .collection('AdoptionForms')
                              .where('email', isEqualTo: userEmail)
                              .where('petId', isEqualTo: currentPetId)
                              .get();

                          if (querySnapshot.docs.isNotEmpty) {
                            // If a document exists, show an error message
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Error'),
                                content: Text(
                                    'You have already submitted a form for this pet.'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            // If no existing document, proceed to show the adoption form dialog
                            DocumentSnapshot profileSnapshot =
                                await FirebaseFirestore.instance
                                    .collection('Profiles')
                                    .doc(userEmail)
                                    .get();
                            if (profileSnapshot.exists) {
                              showDialog(
                                context: context,
                                builder: (context) => _buildAdoptionFormDialog(
                                    context, currentPetId),
                              );
                            } else {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Error'),
                                  content: Text(
                                      'Profile not set yet, please go to Settings.'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        }
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

Widget _buildAdoptionFormDialog(BuildContext context, String currentPetId) {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _occupation;
  String? _selfDescription;
  File? _proofOfCapability;
  final ValueNotifier<bool> _isUploading = ValueNotifier<bool>(false);
  final ValueNotifier<File?> _selectedImage = ValueNotifier<File?>(null);

  Future<String?> _uploadProofOfCapability() async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('proof_of_capability')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(_proofOfCapability!);
      return await storageRef.getDownloadURL();
    } catch (error) {
      print('Error uploading proof of capability: $error');
      // Handle error
      return null;
    } finally {
      _isUploading.value = false;
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _isUploading.value = true; // Start upload

      // Check if required fields are empty
      if (_occupation == null ||
          _selfDescription == null ||
          _proofOfCapability == null) {
        // Display error message if any required field is empty
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Please fill out all required fields.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
        _isUploading.value = false; // Stop upload
        return;
      }

      // Fetch user profile data
      User? user = FirebaseAuth.instance.currentUser;
      String? userEmail = user != null ? user.email : null;

      if (userEmail != null) {
        try {
          DocumentSnapshot profileSnapshot = await FirebaseFirestore.instance
              .collection('Profiles')
              .doc(userEmail)
              .get();
          if (profileSnapshot.exists) {
            Map<String, dynamic> profileData =
                profileSnapshot.data() as Map<String, dynamic>;

            // Extract necessary fields from profile data
            String name =
                '${profileData['firstName']} ${profileData['lastName']}';
            int age =
                0; // Default value if age is not present or cannot be parsed
            if (profileData['age'] != null) {
              try {
                age = int.parse(profileData['age']);
              } catch (e) {
                print('Error parsing age: $e');
                // Handle parsing error, maybe show a message to the user
              }
            }
            String address = profileData['address'];

            // Upload the adoption form to Firestore
            await FirebaseFirestore.instance.collection('AdoptionForms').add({
              'name': name,
              'age': age,
              'address': address,
              'occupation': _occupation!,
              'selfDescription': _selfDescription!,
              'email': userEmail,
              'petId': currentPetId,
              'proofOfCapabilityURL': await _uploadProofOfCapability(),
              'status': 'Pending',
            });

            // Display success message as dialog
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Success'),
                  content: Text('Adoption form submitted successfully'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context)
                            .pop(); // Close the adoption form dialog
                      },
                      child: Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
        } catch (error) {
          print('Error submitting form: $error');
          // Display error message as dialog
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Error'),
                content: Text(
                    'Failed to submit adoption form. Please try again later.'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        } finally {
          _isUploading.value = false; // Upload finished
        }
      }
    }
  }

  return AlertDialog(
    title: Text('Adoption Form'),
    content: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fill out the adoption form below:'),
            TextFormField(
              decoration: InputDecoration(labelText: 'Occupation'),
              onSaved: (value) {
                _occupation = value;
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Self Description'),
              maxLines: 3,
              onSaved: (value) {
                _selfDescription = value;
              },
            ),
            SizedBox(
              height: 10,
            ),
            ValueListenableBuilder<File?>(
              valueListenable: _selectedImage,
              builder: (context, selectedImage, _) {
                return selectedImage != null
                    ? Center(
                        child: Container(
                          height: 200,
                          width: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Image.file(selectedImage, fit: BoxFit.cover),
                        ),
                      )
                    : Center(
                        child: Container(
                          height: 200,
                          width: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Center(
                            child: Text(
                              'Upload Image',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
              },
            ),
            SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final pickedFile =
                      await ImagePicker().getImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    _proofOfCapability = File(pickedFile.path);
                    _selectedImage.value = _proofOfCapability;
                  }
                },
                child: Text('Select Proof of Capability'),
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () {
          Navigator.of(context).pop(); // Close the adoption form dialog
        },
        child: Text('Cancel'),
      ),
      ValueListenableBuilder<bool>(
        valueListenable: _isUploading,
        builder: (context, isUploading, _) {
          return ElevatedButton(
            onPressed: isUploading ? null : _submitForm,
            child: isUploading
                ? CircularProgressIndicator() // Show circular progress indicator if uploading
                : Text('Submit'),
          );
        },
      ),
    ],
  );
}
