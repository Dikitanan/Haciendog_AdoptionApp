import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mad/services/database.dart';
import 'package:random_string/random_string.dart';

class PetProfileForm extends StatefulWidget {
  @override
  _PetProfileFormState createState() => _PetProfileFormState();
}

class _PetProfileFormState extends State<PetProfileForm> {
  TextEditingController nameController = TextEditingController();
  TextEditingController breedController = TextEditingController();
  TextEditingController ageInShelterController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController personalityController = TextEditingController();
  TextEditingController pwdController = TextEditingController();
  String gender = 'Male';
  String catOrDog = 'Cat';
  bool isHearted = false;
  String status = 'Unadopted';
  String imageURL = '';
  bool isImageUploaded = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          width: 1150,
          margin: EdgeInsets.symmetric(
            vertical: 25,
            horizontal: 25,
          ), // Adjust width according to your preference
          padding: EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 50,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ADD PET FORM',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 25,
                      ),
                    ),
                    SizedBox(
                      height: 35,
                    ),
                    Text(
                      'Pet Name:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter pet name',
                      ),
                    ),
                    SizedBox(height: 35),
                    Text(
                      'Age in Shelter:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: ageInShelterController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter age in shelter',
                      ),
                    ),
                    SizedBox(height: 35),
                    Text(
                      'Behavior:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(
                            RegExp(r"\s")), // Deny spaces
                      ],
                      controller: personalityController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter Behavior',
                      ),
                    ),
                    SizedBox(height: 35),
                    Text(
                      'Breed:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: breedController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter breed',
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.start, // Change MainAxisAlignment
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gender:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            DropdownButton<String>(
                              value: gender,
                              onChanged: (String? newValue) {
                                setState(() {
                                  gender = newValue!;
                                });
                              },
                              items: <String>[
                                'Male',
                                'Female'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        SizedBox(
                            width:
                                200), // Add some space between the two columns
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Species:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            DropdownButton<String>(
                              value: catOrDog,
                              onChanged: (String? newValue) {
                                setState(() {
                                  catOrDog = newValue!;
                                });
                              },
                              items: <String>[
                                'Cat',
                                'Dog'
                              ].map<DropdownMenuItem<String>>((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 35),
                    Text(
                      'Health Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      controller: pwdController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Enter Health status',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 50,
              ),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 50,
                    ),
                    Text(
                      'Upload Image',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 35,
                    ),
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                        ),
                        height: 210,
                        width: 500,
                        child: isImageUploaded
                            ? Image.network(
                                imageURL,
                                fit: BoxFit.fill,
                                width: double
                                    .infinity, // Make the image fill the container width
                                height: double.infinity,
                              )
                            : Center(child: Text('Enter Image')),
                      ),
                    ),
                    SizedBox(height: 35),
                    UploadImageToFirebase(
                      onImageUploaded: (url) {
                        setState(() {
                          imageURL = url;
                          isImageUploaded = true;
                        });
                      },
                    ),
                    SizedBox(height: 45),
                    Text(
                      'Description:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      height:
                          200, // Adjust the height according to your preference
                      child: TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter description',
                        ),
                        maxLines: 10,
                      ),
                    ),
                    SizedBox(height: 35),
                    Center(
                      child: ElevatedButton(
                        onPressed: isImageUploaded
                            ? () async {
                                if (nameController.text.isEmpty ||
                                    breedController.text.isEmpty ||
                                    ageInShelterController.text.isEmpty ||
                                    descriptionController.text.isEmpty ||
                                    personalityController.text.isEmpty ||
                                    pwdController.text.isEmpty ||
                                    imageURL.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Please fill all fields and upload an image.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                DateTime now = DateTime.now();
                                String id = randomAlphaNumeric(10);
                                Map<String, dynamic> petInfoMap = {
                                  'Name': nameController.text,
                                  'Breed': breedController.text,
                                  'AgeInShelter': ageInShelterController.text,
                                  'Description': descriptionController.text,
                                  'Personality': personalityController.text,
                                  'Gender': gender,
                                  'PWD': pwdController.text,
                                  'CatOrDog': catOrDog,
                                  'IsHearted': isHearted,
                                  'Status': status,
                                  'Image': imageURL,
                                  'dateCreated': now,
                                };

                                await AnimalDatabase()
                                    .addAnimalDetails(petInfoMap, id)
                                    .then((value) {
                                  Fluttertoast.showToast(
                                      msg: "Pet profile added successfully",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.CENTER,
                                      timeInSecForIosWeb: 1,
                                      backgroundColor: Colors.green,
                                      textColor: Colors.white,
                                      fontSize: 16.0);

                                  // Clear fields and image URL after successful addition
                                  nameController.clear();
                                  breedController.clear();
                                  ageInShelterController.clear();
                                  descriptionController.clear();
                                  personalityController.clear();
                                  pwdController.clear();
                                  setState(() {
                                    imageURL = '';
                                    isImageUploaded = false;
                                  });
                                }).catchError((error) {
                                  Fluttertoast.showToast(
                                      msg: "Failed to add pet profile: $error",
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.CENTER,
                                      timeInSecForIosWeb: 1,
                                      backgroundColor: Colors.red,
                                      textColor: Colors.white,
                                      fontSize: 16.0);
                                });
                              }
                            : null,
                        child: Text(
                          'Add Pet Profile',
                          style: TextStyle(
                              fontSize: 20.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
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
  bool isUploading = false;

  Future<void> pickAndUploadImage() async {
    setState(() {
      isUploading = true;
    });

    Uint8List? fileBytes;
    String fileName = '';

    if (kIsWeb) {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null) {
        fileBytes = result.files.first.bytes;
        fileName = result.files.first.name;
      }
    } else {
      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final File imageFile = File(image.path);
        fileName = imageFile.path.split('/').last;
        fileBytes = await imageFile.readAsBytes();
      }
    }

    if (fileBytes != null) {
      String downloadURL = await uploadImage(fileBytes, fileName);
      widget.onImageUploaded(downloadURL);
      setState(() {
        isUploading = false;
      });
    } else {
      setState(() {
        isUploading = false;
      });
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
        onPressed: isUploading
            ? null
            : () {
                pickAndUploadImage();
              },
        child: isUploading
            ? CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.photo),
      ),
    );
  }
}
