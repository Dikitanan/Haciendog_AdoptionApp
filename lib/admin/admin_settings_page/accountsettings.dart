import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class AccountSettingsPage extends StatefulWidget {
  @override
  _AccountSettingsPageState createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  String? userEmail = FirebaseAuth.instance.currentUser!.email;
  String? profilePictureUrl;

  TextEditingController usernameController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController currentPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController ageController = TextEditingController();

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
      // Fetch profile picture URL from Firebase Storage if it's not already in the document
      if (profilePictureUrl == null) {
        final ref = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child('$userEmail.jpg');
        final downloadURL = await ref.getDownloadURL();
        setState(() {
          profilePictureUrl = downloadURL;
        });
        // Update the profile document with the profile picture URL
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
        final downloadUrl = await uploadImageToFirebase(fileBytes, fileName);
        // Call updateProfile function with the download URL
        updateProfile(
          profilePicture: downloadUrl,
          username: usernameController.text,
          firstName: firstNameController.text,
          lastName: lastNameController.text,
          address: addressController.text,
          age: ageController.text,
          email: userEmail!,
        );
        setState(() {
          profilePictureUrl =
              downloadUrl; // Set the profilePictureUrl here if needed
        });
        Fluttertoast.showToast(
          msg: 'Profile picture uploaded successfully!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Error uploading profile picture: $e',
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
      if (profilePicture.isEmpty ||
          username.isEmpty ||
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

  Future<void> changePassword() async {
    try {
      // Check if the new password matches the confirmation
      if (newPasswordController.text != confirmPasswordController.text) {
        throw Exception("Passwords do not match");
      }

      // Re-authenticate the user before changing the password
      AuthCredential credential = EmailAuthProvider.credential(
          email: userEmail!, password: currentPasswordController.text);
      await FirebaseAuth.instance.currentUser!
          .reauthenticateWithCredential(credential);

      // Change the password
      await FirebaseAuth.instance.currentUser!
          .updatePassword(newPasswordController.text);

      // Show success message
      Fluttertoast.showToast(
        msg: 'Password changed successfully!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      // Clear text fields
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
    } catch (e) {
      // Show error message
      Fluttertoast.showToast(
        msg: 'Error changing password: $e',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
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
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isWideScreen = constraints.maxWidth >
                          800; // Adjust the breakpoint as needed
                      return Row(
                        children: [
                          if (isWideScreen) ...[
                            Expanded(
                              child: _buildProfileImageSection(),
                            ),
                            SizedBox(width: 20),
                          ],
                          Expanded(
                            flex: 2,
                            child: _buildProfileFormSection(),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: 40),
                  Divider(),
                  Text(
                    'Change Password',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 700),
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 20),
                          _buildPasswordForm(),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        changePassword();
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFFE96560),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      ),
                      child: Text("Change Password"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: profilePictureUrl != null
                    ? NetworkImage(profilePictureUrl!)
                    : NetworkImage(
                            "https://static.vecteezy.com/system/resources/thumbnails/020/911/740/small/user-profile-icon-profile-avatar-user-icon-male-icon-face-icon-profile-icon-free-png.png")
                        as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        SizedBox(height: 10),
        Center(
          child: ElevatedButton(
            onPressed: uploadProfilePicture,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE96560),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: Text(
              "Upload Profile",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: usernameController,
          decoration: InputDecoration(
            labelText: "Username",
            hintText: "Enter your username",
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        TextFormField(
          controller: firstNameController,
          decoration: InputDecoration(
            labelText: "First Name",
            hintText: "Enter your first name",
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        TextFormField(
          controller: lastNameController,
          decoration: InputDecoration(
            labelText: "Last Name",
            hintText: "Enter your last name",
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        TextFormField(
          controller: ageController,
          decoration: InputDecoration(
            labelText: "Age",
            hintText: "Enter your Age",
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        TextFormField(
          controller: addressController,
          decoration: InputDecoration(
            labelText: "Address",
            hintText: "Enter your address",
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        TextFormField(
          initialValue: userEmail ?? "",
          readOnly: true,
          decoration: InputDecoration(
            labelText: "Email",
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),
        Center(
          child: ElevatedButton(
            onPressed: () {
              updateProfile(
                profilePicture:
                    profilePictureUrl ?? "default_profile_picture_url",
                username: usernameController.text,
                firstName: firstNameController.text,
                lastName: lastNameController.text,
                address: addressController.text,
                age: ageController.text,
                email: userEmail!,
              );
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Color(0xFFE96560),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: Text("Update Profile"),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: currentPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: "Current Password",
            hintText: "Enter your current password",
            labelStyle: TextStyle(color: Colors.black),
            hintStyle: TextStyle(color: Colors.black),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2.0),
            ),
          ),
        ),
        SizedBox(height: 20),
        TextFormField(
          controller: newPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: "New Password",
            hintText: "Enter your new password",
            labelStyle: TextStyle(color: Colors.black),
            hintStyle: TextStyle(color: Colors.black),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2.0),
            ),
          ),
        ),
        SizedBox(height: 20),
        TextFormField(
          controller: confirmPasswordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: "Confirm Password",
            hintText: "Confirm your new password",
            labelStyle: TextStyle(color: Colors.black),
            hintStyle: TextStyle(color: Colors.black),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 2.0),
            ),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }
}
