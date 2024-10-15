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
  TextEditingController _houseNumberController = TextEditingController();

  String? _selectedBarangay;
  String? _selectedStreet;

  // Complete list of barangays in Sta. Cruz, Laguna
  final List<String> barangays = [
    'Alipit',
    'Bagong Bayan',
    'Bubukal',
    'Calios',
    'Duhat',
    'Gatid',
    'Jasaan',
    'Labuin',
    'Malinao',
    'Oogong',
    'Pagsawitan',
    'Palasan',
    'Patimbao',
    'Poblacion I',
    'Poblacion II',
    'Poblacion III',
    'San Pablo Norte',
    'San Pablo Sur',
    'Santo Angel Central',
    'Santo Angel Norte',
    'Santo Angel Sur',
  ];

  // Map of barangays to their respective streets
  final Map<String, List<String>> barangayStreets = {
    'Alipit': ['Alipit Road', 'C. Reyes St'],
    'Bagong Bayan': ['Mabini St', 'San Jose St'],
    'Bubukal': ['Bubukal Main Road'],
    'Calios': ['Calios Road', 'Gat Tayaw St'],
    'Duhat': ['Duhat St', 'San Vicente St'],
    'Gatid': ['Gatid Road', 'San Juan St'],
    'Jasaan': ['Jasaan St', 'Gat Tayaw St'],
    'Labuin': ['Labuin St', 'Riverbank St'],
    'Malinao': ['Malinao St'],
    'Oogong': ['Oogong Main Road', 'Rizal St'],
    'Pagsawitan': ['Pagsawitan Main Road'],
    'Palasan': ['Palasan Road'],
    'Patimbao': ['Patimbao St', 'M. Santos St'],
    'Poblacion I': ['Rizal St', 'Burgos St'],
    'Poblacion II': ['J. P. Rizal St', 'Bonifacio St'],
    'Poblacion III': ['General Luna St', 'Del Pilar St'],
    'San Pablo Norte': ['San Pablo Norte Road'],
    'San Pablo Sur': ['San Pablo Sur Road'],
    'Santo Angel Central': ['Santo Angel Central St'],
    'Santo Angel Norte': ['Santo Angel Norte St'],
    'Santo Angel Sur': ['Santo Angel Sur St'],
  };

  Future<void> _showLocationDialog() async {
    String? barangay = _selectedBarangay;
    String? street = _selectedStreet;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              title: Text("Set Shelter Location",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: MediaQuery.of(context).size.width *
                    0.5, // Adjust for web view
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Barangay Dropdown
                    DropdownButtonFormField<String>(
                      value: barangay,
                      decoration: InputDecoration(
                        labelText: 'Barangay',
                        border: OutlineInputBorder(),
                      ),
                      items: barangays.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setDialogState(() {
                          barangay = newValue;
                          street = null; // Reset street selection
                        });
                      },
                    ),

                    SizedBox(height: 10), // Spacing

                    // Street Dropdown (depends on selected barangay)
                    DropdownButtonFormField<String>(
                      value: street,
                      decoration: InputDecoration(
                        labelText: 'Street',
                        border: OutlineInputBorder(),
                      ),
                      items: barangay != null
                          ? barangayStreets[barangay]!.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList()
                          : [],
                      onChanged: (newValue) {
                        setDialogState(() {
                          street = newValue;
                        });
                      },
                    ),

                    SizedBox(height: 10), // Spacing

                    // House Number TextFormField with # prefix
                    TextFormField(
                      controller: _houseNumberController,
                      decoration: InputDecoration(
                        labelText: 'House Number',
                        prefixText: '#',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                    textStyle: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text("OK"),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    textStyle: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    if ((barangay == null || barangay!.isEmpty) &&
                        (street == null || street!.isEmpty)) {
                      // Show a message if barangay and street are not selected
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Please select a Barangay and a Street.')),
                      );
                      return;
                    }

                    setState(() {
                      _selectedBarangay = barangay;
                      _selectedStreet = street;

                      // Retrieve house number directly from the controller
                      String houseNumber = _houseNumberController.text;

                      // Update the location text (ignore null values)
                      String locationText = '';
                      if (houseNumber.isNotEmpty)
                        locationText += '#$houseNumber ';
                      if (street != null) locationText += '$street, ';
                      if (barangay != null)
                        locationText += '$barangay, Sta. Cruz, Laguna';

                      _locationController.text = locationText.trim();
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Shelter Settings",
          style: Theme.of(context).textTheme.headline4,
        ),
      ),
      body: SingleChildScrollView(
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
                                    _imageUrls[
                                        i]!, // Use the URL from _imageUrls
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
                          labelStyle: TextStyle(color: Colors.black),
                          hintStyle: TextStyle(color: Colors.black),
                          border: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.black, width: 2.0),
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
                        onTap: () {
                          FocusScope.of(context).requestFocus(
                              FocusNode()); // Prevents keyboard from showing
                          _showLocationDialog();
                        },
                        readOnly: true,
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
                          hintText:
                              "Write a brief description about the shelter",
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
      ),
    );
  }
}
