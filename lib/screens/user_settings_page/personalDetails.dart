import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class PersonalDetailsPage extends StatefulWidget {
  const PersonalDetailsPage({Key? key}) : super(key: key);

  @override
  _PersonalDetailsPageState createState() => _PersonalDetailsPageState();
}

class _PersonalDetailsPageState extends State<PersonalDetailsPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  String? userEmail = FirebaseAuth.instance.currentUser!.email;

  String? profilePictureUrl;
  bool uploading = false; // Track upload status

  @override
  void initState() {
    super.initState();
    fetchUserProfileData();
  }

  Future<void> fetchUserProfileData() async {
    try {
      final profileDoc = await FirebaseFirestore.instance
          .collection('Profiles')
          .doc(userEmail)
          .get();
      if (profileDoc.exists) {
        final data = profileDoc.data() as Map<String, dynamic>;
        setState(() {
          usernameController.text = data['username'] ?? '';
          firstNameController.text = data['firstName'] ?? '';
          lastNameController.text = data['lastName'] ?? '';
          addressController.text = data['address'] ?? '';
          profilePictureUrl = data['profilePicture'];
          ageController.text = data['age'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching user profile data: $e');
    }
  }

  Future<String> uploadImageToFirebase(
      Uint8List fileBytes, String fileName) async {
    try {
      final ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child(fileName);
      await ref.putData(fileBytes);
      final downloadURL = await ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Error uploading image to Firebase Storage: $e');
      return '';
    }
  }

  Future<void> uploadProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final fileBytes = await pickedFile.readAsBytes();
      setState(() {
        uploading = true;
      });
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final downloadUrl = await uploadImageToFirebase(fileBytes, fileName);
        setState(() {
          uploading = false;
          profilePictureUrl = downloadUrl;
        });
        // Update profile picture URL only
        updateProfilePicture(downloadUrl);
      } catch (e) {
        setState(() {
          uploading = false;
        });
      }
    }
  }

  Future<void> updateProfilePicture(String downloadUrl) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final String userEmail = user!.email!;

      await FirebaseFirestore.instance
          .collection('Profiles')
          .doc(userEmail)
          .update({'profilePicture': downloadUrl});

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Success'),
            content: Text('Profile picture updated successfully!'),
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
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Error updating profile picture: $e'),
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
    }
  }

  Future<void> updateProfile({
    required String profilePicture,
    required String username,
    required String firstName,
    required String lastName,
    required String address,
    required String email,
    required String age,
  }) async {
    try {
      // Validate required fields
      if (username.isEmpty ||
          firstName.isEmpty ||
          lastName.isEmpty ||
          address.isEmpty ||
          email.isEmpty ||
          age.isEmpty) {
        throw 'All fields are required';
      }

      // Check if age is a proper number
      if (int.tryParse(age) == null) {
        throw 'Age must be a valid number';
      }

      final existingProfile = await FirebaseFirestore.instance
          .collection('Profiles')
          .doc(email)
          .get();
      if (existingProfile.exists) {
        await existingProfile.reference.update({
          'profilePicture': profilePicture,
          'username': username,
          'firstName': firstName,
          'lastName': lastName,
          'address': address,
          'email': email,
          'age': age,
        });
      } else {
        await FirebaseFirestore.instance.collection('Profiles').doc(email).set({
          'profilePicture': profilePicture,
          'username': username,
          'firstName': firstName,
          'lastName': lastName,
          'address': address,
          'email': email,
          'age': age,
        });
      }
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Success'),
            content: Text('Profile updated successfully!'),
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
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Error updating profile: $e'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
            child: Text(
          'Personal Details',
          style: TextStyle(fontSize: 18),
        )),
      ),
      body: Padding(
        padding: const EdgeInsets.all(6),
        child: ListView(
          children: [
            if (profilePictureUrl != null)
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.transparent,
                child: ClipOval(
                  child: Image.network(
                    profilePictureUrl!,
                    fit: BoxFit.cover,
                    width: 100,
                    height: 100,
                  ),
                ),
              ),
            SizedBox(
              height: 5,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: uploading
                  ? Center(
                      child: Container(
                          width: 40,
                          child:
                              CircularProgressIndicator())) // Show loading indicator when uploading
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
                      child: ElevatedButton(
                        onPressed: uploadProfilePicture,
                        child: Text(
                          'Upload Profile Picture',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE96560),
                          padding: EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
            ),
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(fontSize: 14),
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                  controller: firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    border: OutlineInputBorder(),
                  ),
                  style: TextStyle(fontSize: 14)),
            ),
            SizedBox(
              height: 8,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                controller: lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(fontSize: 14),
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(fontSize: 14),
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              child: TextFormField(
                controller: ageController,
                decoration: InputDecoration(
                  labelText: 'Age',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 14),
              ),
            ),
            SizedBox(
              height: 8,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(50, 0, 50, 0),
              child: ElevatedButton(
                onPressed: () {
                  updateProfile(
                    profilePicture: profilePictureUrl ?? '',
                    username: usernameController.text,
                    firstName: firstNameController.text,
                    lastName: lastNameController.text,
                    address: addressController.text,
                    email: userEmail!,
                    age: ageController.text,
                  );
                },
                child: Text(
                  'Update Profile',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(12),
                  backgroundColor: Color(0xFFE96560),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ), // Set the background color here
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
