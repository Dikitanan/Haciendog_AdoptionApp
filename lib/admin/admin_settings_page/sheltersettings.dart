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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Donations",
                style: Theme.of(context).textTheme.headline4,
              ),
              SizedBox(
                height: 25,
              ),
              Text(
                "Upload G-Cash QR Code",
                style: Theme.of(context).textTheme.headline6,
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int i = 0; i < 3; i++)
                    Tooltip(
                      message: 'UPLOAD IMAGE',
                      child: InkWell(
                        onTap: () => _pickImage(i),
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[200], // Placeholder color
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
              Text(
                "Shelter Description",
                style: Theme.of(context).textTheme.headline5,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: "Enter Description",
                  hintText: "Write a brief description about the shelter",
                ),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: "Enter Location",
                  hintText: "Write the Shelter's Location",
                ),
              ),
              SizedBox(height: 10),
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
                  labelText: "Enter Phone Number",
                  hintText: "Write your Phone Number",
                ),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _facebookController,
                decoration: InputDecoration(
                  labelText: "Enter Facebook Account",
                  hintText: "Write your Facebook Account",
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Validate form
                    _uploadDataToFirestore(); // Submit form if validation succeeds
                  }
                },
                child: Text("Update Shelter Settings"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
