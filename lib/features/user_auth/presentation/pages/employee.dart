import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mad/features/user_auth/presentation/pages/login_page.dart';
import 'package:mad/services/database.dart';
import 'package:random_string/random_string.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class Employee extends StatefulWidget {
  const Employee({Key? key}) : super(key: key);

  @override
  State<Employee> createState() => _EmployeeState();
}

class _EmployeeState extends State<Employee> {
  TextEditingController nameController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController locationController = TextEditingController();

  String imageURL = '';

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      print("User signed out successfully.");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      print("Error signing out: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error signing out. Please try again."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? 'User';

    final random = Random();
    final randomPercentage = random.nextInt(102);

    String isGay = '';

    if (randomPercentage <= 10) {
      isGay = '0-10% gay';
    } else if (randomPercentage <= 20) {
      isGay = '10-20% gay';
    } else if (randomPercentage <= 30) {
      isGay = '20-30% gay';
    } else if (randomPercentage <= 40) {
      isGay = '30-40% gay';
    } else if (randomPercentage <= 50) {
      isGay = '40-50% gay';
    } else if (randomPercentage <= 60) {
      isGay = '50-60% gay';
    } else if (randomPercentage <= 70) {
      isGay = '60-70% gay';
    } else if (randomPercentage <= 80) {
      isGay = '70-80% gay';
    } else if (randomPercentage <= 90) {
      isGay = '80-90% gay';
    } else if (randomPercentage <= 100) {
      isGay = '90-100% gay';
    } else {
      isGay = '999999999999% gay (The Progenitor)';
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan,
        title: const Text(
          'Gay Test Form',
          style: TextStyle(fontSize: 18),
        ),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (value) {
              switch (value) {
                case 'Logout':
                  _signOut(context);
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return {'Logout'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Name',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 24.0,
                    fontWeight: FontWeight.normal),
              ),
              const SizedBox(
                height: 15,
              ),
              Container(
                padding: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              const Text(
                'Age',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 24.0,
                    fontWeight: FontWeight.normal),
              ),
              const SizedBox(
                height: 15,
              ),
              Container(
                padding: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: ageController,
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              const Text(
                'Location',
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 24.0,
                    fontWeight: FontWeight.normal),
              ),
              const SizedBox(
                height: 15,
              ),
              Container(
                padding: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(10)),
                child: TextField(
                  controller: locationController,
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              UploadImageToFirebase(
                onImageUploaded: (url) {
                  setState(() {
                    imageURL = url;
                  });
                },
              ),
              const SizedBox(
                height: 20,
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    // Check if any of the fields are empty
                    if (nameController.text.isEmpty ||
                        ageController.text.isEmpty ||
                        locationController.text.isEmpty ||
                        imageURL.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please fill all fields and select an image',
                          ),
                        ),
                      );
                      return;
                    }

                    String id = randomAlphaNumeric(10);

                    Map<String, dynamic> employeeInfoMap = {
                      'Name': nameController.text,
                      'Age': ageController.text,
                      'Location': locationController.text,
                      'Email': userEmail,
                      'image': imageURL,
                      'result': isGay,
                    };

                    await DatabaseMethods()
                        .addEmployeeDetails(employeeInfoMap, id)
                        .then((value) {
                      Fluttertoast.showToast(
                          msg: "Added to Gay Test",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                          fontSize: 16.0);
                    }).catchError((error) {
                      Fluttertoast.showToast(
                          msg: "Failed to add employee data: $error",
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.CENTER,
                          timeInSecForIosWeb: 1,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: 16.0);
                    });
                  },
                  child: const Text(
                    'Add to The Gay List',
                    style:
                        TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UploadImageToFirebase extends StatefulWidget {
  final Function(String) onImageUploaded;

  const UploadImageToFirebase({Key? key, required this.onImageUploaded})
      : super(key: key);

  @override
  _UploadImageToFirebaseState createState() => _UploadImageToFirebaseState();
}

class _UploadImageToFirebaseState extends State<UploadImageToFirebase> {
  Future<void> pickAndUploadImage() async {
    Uint8List? fileBytes;
    String fileName = ''; // Initialize fileName with an empty string

    if (kIsWeb) {
      // Using FilePicker for web
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null) {
        fileBytes = result.files.first.bytes;
        fileName = result.files.first.name;
      }
    } else {
      // Using ImagePicker for mobile
      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final File imageFile = File(image.path);
        fileName = imageFile.path.split('/').last; // Get file name from path
        fileBytes = await imageFile.readAsBytes();
      }
    }

    if (fileBytes != null) {
      // Proceed to upload to Firebase
      String downloadURL = await uploadImage(fileBytes, fileName);
      widget.onImageUploaded(downloadURL);
      print(
          'Image uploaded. Download URL: $downloadURL'); // Print imageURL after upload
    } else {
      print("No file selected");
    }
  }

  Future<String> uploadImage(Uint8List fileBytes, String fileName) async {
    String uploadPath = 'images/$fileName';
    Reference ref = FirebaseStorage.instance.ref().child(uploadPath);
    await ref.putData(fileBytes);
    String downloadURL = await ref.getDownloadURL();
    return downloadURL;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          pickAndUploadImage();
        },
        child: const Icon(Icons.photo),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: Employee(),
  ));
}
