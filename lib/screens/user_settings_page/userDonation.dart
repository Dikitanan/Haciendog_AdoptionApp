import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DonatePage(),
    );
  }
}

class DonatePage extends StatefulWidget {
  @override
  _DonatePageState createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage> {
  int _currentStep = 0;
  String? _imageUrl;
  String? _userMessage;
  String? _amount;
  File? _proofOfDonation;
  final picker = ImagePicker();
  bool _isSubmitting = false;
  bool _hasProfile = true;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  Future<void> _pickImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _proofOfDonation = File(pickedFile.path);
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
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

  @override
  void initState() {
    super.initState();
    _checkUserProfile();
  }

  Future<void> _checkUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String email = user.email!;
      QuerySnapshot userProfileSnapshot = await FirebaseFirestore.instance
          .collection('Profiles')
          .where('email', isEqualTo: email)
          .get();

      if (userProfileSnapshot.docs.isEmpty) {
        setState(() {
          _hasProfile = false;
        });
        _showErrorDialog('Cannot Donate. Please set your Profile first.');
      } else {
        setState(() {
          _hasProfile = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Donate'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('ShelterSettings')
            .get()
            .then((querySnapshot) => querySnapshot.docs.first),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Data not available'));
          }

          final data = snapshot.data!;
          _imageUrl = data['Image1'] ?? '';

          return Stepper(
            currentStep: _currentStep,
            onStepContinue: () {
              if (!_hasProfile) {
                _showErrorDialog(
                    'Cannot Donate. Please set your Profile first.');
                return;
              }

              if (_currentStep == 2) {
                if (_userMessage == null || _userMessage!.isEmpty) {
                  _showErrorDialog('Please enter your message.');
                  return;
                }
                if (_amount == null || _amount!.isEmpty) {
                  _showErrorDialog('Please enter the amount.');
                  return;
                }
                if (_proofOfDonation == null) {
                  _showErrorDialog('Please upload proof of donation.');
                  return;
                }
              }

              if (_currentStep < 3) {
                setState(() {
                  _currentStep += 1;
                });
              } else {
                _submitDonation();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() {
                  _currentStep -= 1;
                });
              }
            },
            steps: [
              Step(
                title: Text('Description'),
                content: Column(
                  children: [
                    Text(
                      'Complete Steps To Donate',
                      style: TextStyle(fontSize: 20),
                    ),
                    SizedBox(height: 10),
                    Text(
                      data['ShelterDetails'] ?? 'Description not available',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16.5),
                    ),
                  ],
                ),
              ),
              Step(
                title: Text('Scan Here'),
                content: Column(
                  children: [
                    Container(
                      width: 350,
                      height: 450,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(_imageUrl!),
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Step(
                title: Text('Your Message'),
                content: Column(
                  children: [
                    TextField(
                      controller: _messageController,
                      decoration: InputDecoration(labelText: 'Your Message'),
                      onChanged: (value) {
                        _userMessage = value;
                      },
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _amountController,
                      decoration: InputDecoration(labelText: 'Amount'),
                      onChanged: (value) {
                        _amount = value;
                      },
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter
                            .digitsOnly // Accepts only digits
                      ],
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: Text('Upload Proof of Donation'),
                    ),
                    if (_proofOfDonation != null)
                      Image.file(
                        _proofOfDonation!,
                        height: 200,
                      ),
                  ],
                ),
              ),
              Step(
                title: Text('Finish Up'),
                content: Column(
                  children: [
                    Text(
                      'Thank you for donating to our Pet Shelter!',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    _isSubmitting
                        ? CircularProgressIndicator()
                        : Visibility(
                            visible: false,
                            child: ElevatedButton(
                              onPressed: _submitDonation,
                              child: Text('Finish'),
                            ),
                          )
                  ],
                ),
              ),
            ],
            controlsBuilder: (BuildContext context, ControlsDetails details) {
              return Row(
                children: <Widget>[
                  SizedBox(
                    height: 100,
                  ),
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFFE96560),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: _currentStep == 3 && _isSubmitting
                        ? CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : Text('Continue'),
                  ),
                  SizedBox(width: 8),
                  if (_currentStep != 3)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Cancel'),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _submitDonation() async {
    setState(() {
      _isSubmitting = true;
    });

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userMessage = _messageController.text;
      _amount = _amountController.text;

      String email = user.email!;
      DocumentSnapshot userProfile = await FirebaseFirestore.instance
          .collection('Profiles')
          .where('email', isEqualTo: email)
          .get()
          .then((querySnapshot) => querySnapshot.docs.first);

      String firstName = userProfile['firstName'];
      String lastName = userProfile['lastName'];
      String name = '$firstName $lastName';
      String username = userProfile['username'];

      String? proofOfDonationUrl;
      if (_proofOfDonation != null) {
        proofOfDonationUrl = await _uploadProofOfDonation(_proofOfDonation!);
      }

      await FirebaseFirestore.instance.collection('Donations').add({
        'name': name,
        'email': email,
        'username': username,
        'message': _userMessage,
        'amount': _amount,
        'proofOfDonation': proofOfDonationUrl,
        'status': 'Pending'
      });

      setState(() {
        _isSubmitting = false;
        _currentStep = 0;
        _userMessage = null;
        _messageController.clear();
        _amountController.clear();
        _proofOfDonation = null;
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Donation Successful'),
            content: Text('Thank you for your donation!'),
            actions: [
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

  Future<String?> _uploadProofOfDonation(File image) async {
    final storageRef = FirebaseStorage.instance.ref();
    final proofRef = storageRef
        .child('proofOfDonation/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await proofRef.putFile(image);
    return await proofRef.getDownloadURL();
  }
}
