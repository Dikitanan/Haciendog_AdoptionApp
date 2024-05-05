import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
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

  String? profilePictureUrl;
  bool uploading = false; // Track upload status

  @override
  void initState() {
    super.initState();
    fetchUserProfileData();
  }

  Future<void> fetchUserProfileData() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final String userEmail = user!.email!;

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
      if (profilePictureUrl == null) {
        final ref = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('$userEmail.jpg');
        final downloadURL = await ref.getDownloadURL();
        setState(() {
          profilePictureUrl = downloadURL;
        });
        await profileDoc.reference.update({'profilePicture': downloadURL});
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
      try {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        setState(() {
          uploading = true; // Set uploading to true when starting upload
        });
        final downloadUrl = await uploadImageToFirebase(fileBytes, fileName);
        setState(() {
          profilePictureUrl = downloadUrl;
          uploading = false; // Set uploading to false when upload finished
        });
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Success'),
              content: Text('Profile picture uploaded successfully!'),
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
        setState(() {
          uploading = false; // Set uploading to false in case of error
        });
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Error uploading profile picture: $e'),
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
    required String username,
    required String firstName,
    required String lastName,
    required String address,
    required String age,
  }) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final String userEmail = user!.email!;

      if (username.isEmpty ||
          firstName.isEmpty ||
          lastName.isEmpty ||
          address.isEmpty ||
          age.isEmpty) {
        throw 'All fields are required';
      }

      if (int.tryParse(age) == null) {
        throw 'Age must be a valid number';
      }

      await FirebaseFirestore.instance
          .collection('Profiles')
          .doc(userEmail)
          .update({
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'address': address,
        'age': age,
      });

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
                  : ElevatedButton(
                      onPressed: uploadProfilePicture,
                      child: Text('Upload Profile Picture'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
            ),
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton(
                onPressed: () {
                  updateProfile(
                    username: usernameController.text,
                    firstName: firstNameController.text,
                    lastName: lastNameController.text,
                    address: addressController.text,
                    age: ageController.text,
                  );
                },
                child: Text('Update Profile'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
