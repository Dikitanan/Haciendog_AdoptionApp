import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

class ShelterSettingsForm extends StatefulWidget {
  @override
  _ShelterSettingsFormState createState() => _ShelterSettingsFormState();
}

class _ShelterSettingsFormState extends State<ShelterSettingsForm> {
  final _formKey = GlobalKey<FormState>(); // Add form key

  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  TextEditingController _phoneNumberController = TextEditingController();
  TextEditingController _facebookController = TextEditingController();

  List<String?> _imageUrls = List.filled(3, null); // Initialize with 3 nulls
  String? _shelterDocumentId;

  @override
  void initState() {
    super.initState();
    // Call a function to load existing data from Firestore
    loadExistingData();
  }

  Future<void> loadExistingData() async {
    // Query Firestore for existing data
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('ShelterSettings')
        .limit(1) // Limit to 1 to get only one document
        .get();

    if (snapshot.docs.isNotEmpty) {
      // If there's an existing document, populate the fields
      var data = snapshot.docs.first.data() as Map<String, dynamic>;
      setState(() {
        _descriptionController.text = data['ShelterDetails'];
        _locationController.text = data['ShelterLocation'];
        _phoneNumberController.text = data['PhoneNumber'];
        _facebookController.text = data['FacebookAccount'];
        _imageUrls[0] = data['Image1'];
        _imageUrls[1] = data['Image2'];
        _imageUrls[2] = data['Image3'];
        _shelterDocumentId = snapshot.docs.first.id;
      });
    }
  }

  Future<String> uploadImageToFirebase(
      Uint8List fileBytes, String fileName) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('shelter_images')
          .child(fileName);
      await ref.putData(fileBytes);
      final downloadURL = await ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error uploading image to Firebase Storage: $e');
      return '';
    }
  }

  Future<void> _uploadDataToFirestore() async {
    try {
      // Upload shelter details and image URLs to Firestore
      CollectionReference shelterSettings =
          FirebaseFirestore.instance.collection('ShelterSettings');

      Map<String, dynamic> data = {
        'FacebookAccount': _facebookController.text,
        'PhoneNumber': _phoneNumberController.text,
        'ShelterLocation': _locationController.text,
        'ShelterDetails': _descriptionController.text,
        'Image1': _imageUrls.length > 0 ? _imageUrls[0] : null,
        'Image2': _imageUrls.length > 1 ? _imageUrls[1] : null,
        'Image3': _imageUrls.length > 2 ? _imageUrls[2] : null,
      };

      if (_shelterDocumentId != null) {
        // Update existing document if ID exists
        await shelterSettings.doc(_shelterDocumentId).update(data);
      } else {
        // Otherwise, create a new document
        await shelterSettings.add(data);
      }

      // Show success message or navigate to next screen
      Fluttertoast.showToast(
        msg: 'Shelter Details updated successfully!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Error updating Shelter Details: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void _pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final fileBytes = await pickedFile.readAsBytes();
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final downloadUrl = await uploadImageToFirebase(fileBytes, fileName);
        setState(() {
          _imageUrls[index] = downloadUrl;
        });
        Fluttertoast.showToast(
          msg: 'Image uploaded successfully!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Error uploading image: $e',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey, // Assign the form key
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Color.fromARGB(255, 244, 217, 217),
                Colors.white,
              ],
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Donations",
                style: Theme.of(context).textTheme.headline4,
              ),
              SizedBox(
                height: 40,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(45, 0, 0, 0),
                child: Text(
                  "Upload QR Code",
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int i = 0; i < 3; i++)
                    Tooltip(
                      message: i == 0
                          ? 'UPLOAD IMAGE (G-Cash)'
                          : i == 1
                              ? 'UPLOAD IMAGE (PayMaya)'
                              : 'UPLOAD IMAGE (PayPal)',
                      child: InkWell(
                        onTap: () => _pickImage(i),
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Color.fromARGB(
                                255, 220, 153, 150), // Placeholder color
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: _imageUrls[i] != null
                              ? Image.network(
                                  _imageUrls[i]!, // Use the URL from _imageUrls
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.fill,
                                )
                              : Icon(Icons.add_photo_alternate, size: 50),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.fromLTRB(45, 0, 0, 0),
                child: Text(
                  "Shelter Description",
                  style: Theme.of(context).textTheme.headline5,
                ),
              ),
              SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.fromLTRB(70, 0, 70, 0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: "Enter Location",
                        hintText: "Write the Shelter's Location",
                        labelStyle:
                            TextStyle(color: Colors.black), // Text color
                        hintStyle:
                            TextStyle(color: Colors.black), // Hint text color
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.black,
                              width: 2.0), // Border color and thickness
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black, width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black, width: 1.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a phone number.';
                        }
                        if (value.length != 11) {
                          return 'Phone number must have 11 digits.';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: "Enter G-cash Number (If Applicable)",
                        hintText: "Write your G-cash Number",
                        labelStyle:
                            TextStyle(color: Colors.black), // Text color
                        hintStyle:
                            TextStyle(color: Colors.black), // Hint text color
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.black,
                              width: 2.0), // Border color and thickness
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black, width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black, width: 1.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      controller: _facebookController,
                      decoration: InputDecoration(
                        labelText: "Enter Facebook Account",
                        hintText: "Write your Facebook Account",
                        labelStyle:
                            TextStyle(color: Colors.black), // Text color
                        hintStyle:
                            TextStyle(color: Colors.black), // Hint text color
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.black,
                              width: 2.0), // Border color and thickness
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black, width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black, width: 1.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3, // Set the maximum lines to 3
                      decoration: InputDecoration(
                        labelText: "Enter Description",
                        hintText: "Write a brief description about the shelter",
                        labelStyle:
                            TextStyle(color: Colors.black), // Text color
                        hintStyle:
                            TextStyle(color: Colors.black), // Hint text color
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Colors.black,
                              width: 2.0), // Border color and thickness
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black, width: 1.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.black, width: 1.0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Validate form
                      _uploadDataToFirestore(); // Submit form if validation succeeds
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Color(0xFFE96560), // Text color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5), // Border radius
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15), // Button padding
                  ),
                  child: Text("Update Shelter Settings"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
