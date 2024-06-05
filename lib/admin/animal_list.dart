import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

class AnimalList extends StatefulWidget {
  @override
  _AnimalListState createState() => _AnimalListState();
}

class _AnimalListState extends State<AnimalList> {
  late TextEditingController _searchController;
  late Timer _debounce;
  late TextEditingController nameController;
  late TextEditingController breedController;
  late TextEditingController ageInShelterController;
  late TextEditingController descriptionController;
  late TextEditingController personalityController;
  late TextEditingController pwdController;
  late TextEditingController catOrDogController;
  late TextEditingController statusController;

  bool _imageUploaded = false;
  bool _isUploading = false; // Add this state variable

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _debounce = Timer(Duration(milliseconds: 500), () {});

    // Initialize the controllers here
    nameController = TextEditingController();
    breedController = TextEditingController();
    ageInShelterController = TextEditingController();
    descriptionController = TextEditingController();
    personalityController = TextEditingController();
    pwdController = TextEditingController();
    catOrDogController = TextEditingController();
    statusController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    // Check if it's a web view
    bool isWeb = MediaQuery.of(context).size.width > 600;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Animal').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No data available'),
          );
        }

        List<DocumentSnapshot> animals = snapshot.data!.docs;
        animals.sort((a, b) => (b['dateCreated'] as Timestamp)
            .compareTo(a['dateCreated'] as Timestamp));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Animal List'),
            centerTitle: true,
            titleSpacing: 0, // Set title spacing to 0
          ),
          body: Container(
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
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    child: SizedBox(
                      height: 40.0,
                      width: 500,
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search',
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16.0),
                          suffixIcon: IconButton(
                            iconSize: 20.0,
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          ),
                        ),
                        onChanged: (value) {
                          _debounce.cancel();
                          _debounce =
                              Timer(const Duration(milliseconds: 500), () {
                            setState(() {});
                          });
                        },
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Center(
                      child: Container(
                        alignment: Alignment.topCenter,
                        child: isWeb
                            ? SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                    child: DataTable(
                                      columnSpacing: 20.0,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color:
                                              Color(0xFFE96560), // Border color
                                          width: 0.5, // Border width
                                        ),
                                      ),
                                      headingRowColor: MaterialStateColor
                                          .resolveWith((states) => Color(
                                              0xFFE96560)!), // Header row color
                                      dataRowHeight:
                                          120.0, // Adjust row height as needed
                                      columns: const [
                                        DataColumn(
                                          label: Center(
                                            child: Text(
                                              'Image',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                          tooltip: 'Image',
                                          numeric: false,
                                        ),
                                        DataColumn(
                                          label: Center(
                                            child: Text(
                                              'Pet Name',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                          tooltip: 'Pet Name',
                                          numeric: false,
                                        ),
                                        DataColumn(
                                          label: Center(
                                            child: Text(
                                              'Breed',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                          tooltip: 'Breed',
                                          numeric: false,
                                        ),
                                        DataColumn(
                                          label: Center(
                                            child: Text(
                                              'Age on Shelter',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                          tooltip: 'Age on Shelter',
                                          numeric: false,
                                        ),
                                        DataColumn(
                                          label: Center(
                                            child: Text(
                                              'Personality',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                          tooltip: 'Personality',
                                          numeric: false,
                                        ),
                                        DataColumn(
                                          label: Center(
                                            child: Text(
                                              'Gender',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                          tooltip: 'Gender',
                                          numeric: false,
                                        ),
                                        DataColumn(
                                          label: Center(
                                            child: Text(
                                              'Health Status',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                          tooltip: 'Health Status',
                                          numeric: false,
                                        ),
                                        DataColumn(
                                          label: Center(
                                            child: Text(
                                              'Cat or Dog',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                          tooltip: 'Cat or Dog',
                                          numeric: false,
                                        ),
                                        DataColumn(
                                          label: Center(
                                            child: Text(
                                              'Status',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                          tooltip: 'Status',
                                          numeric: false,
                                        ),
                                        DataColumn(
                                          label: Center(
                                            child: Text(
                                              'Action',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                          tooltip: 'Action',
                                          numeric: false,
                                        ),
                                        DataColumn(
                                          label: Center(
                                            child: Text(
                                              'Action',
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                          tooltip: 'Action',
                                          numeric: false,
                                        ),
                                      ],
                                      rows: _filteredAnimals(animals)
                                          .map((animal) {
                                        return DataRow(cells: [
                                          DataCell(
                                            SizedBox(
                                              width: 100,
                                              height: 100,
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                child: Image.network(
                                                  animal['Image'],
                                                  fit: BoxFit.fill,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Center(
                                              child: Text(animal['Name']),
                                            ),
                                          ),
                                          DataCell(
                                            Center(
                                              child: Text(animal['Breed']),
                                            ),
                                          ),
                                          DataCell(
                                            Center(
                                              child:
                                                  Text(animal['AgeInShelter']),
                                            ),
                                          ),
                                          DataCell(
                                            Center(
                                              child:
                                                  Text(animal['Personality']),
                                            ),
                                          ),
                                          DataCell(
                                            Center(
                                              child: Text(animal['Gender']),
                                            ),
                                          ),
                                          DataCell(
                                            Center(
                                              child: Text(animal['PWD']),
                                            ),
                                          ),
                                          DataCell(
                                            Center(
                                              child: Text(animal['CatOrDog']),
                                            ),
                                          ),
                                          DataCell(
                                            Center(
                                              child: Text(animal['Status']),
                                            ),
                                          ),
                                          DataCell(
                                            Center(
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  // Call edit function when edit button is clicked
                                                  editAnimalDetails(animal);
                                                },
                                                child: Container(
                                                  height: 25,
                                                  width: 50,
                                                  child: const Center(
                                                    child: Text('Edit'),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Center(
                                              child: ElevatedButton(
                                                onPressed: _isUploading
                                                    ? null
                                                    : () {
                                                        // Disable button if uploading is in progress
                                                        // Show modal bottom sheet
                                                        showModalBottomSheet(
                                                          context: context,
                                                          builder: (BuildContext
                                                              context) {
                                                            return StatefulBuilder(
                                                              builder: (BuildContext
                                                                      context,
                                                                  StateSetter
                                                                      setState) {
                                                                return Container(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          20.0),
                                                                  child: Column(
                                                                    mainAxisSize:
                                                                        MainAxisSize
                                                                            .min,
                                                                    children: <Widget>[
                                                                      _uploadedImageURL !=
                                                                              null
                                                                          ? Image
                                                                              .network(
                                                                              _uploadedImageURL!,
                                                                              width: 200,
                                                                              height: 200,
                                                                            )
                                                                          : const SizedBox(), // Display uploaded image if available
                                                                      ElevatedButton(
                                                                        onPressed: _isUploading
                                                                            ? null
                                                                            : () async {
                                                                                // Disable button if uploading is in progress
                                                                                setState(() {
                                                                                  _isUploading = true; // Set uploading flag
                                                                                });
                                                                                await _uploadImage(); // Wait for image upload
                                                                                setState(() {
                                                                                  _isUploading = false; // Reset uploading flag
                                                                                  _imageUploaded = true; // Set image uploaded flag
                                                                                });
                                                                                // Don't close the modal here
                                                                              },
                                                                        child: const Text(
                                                                            'Upload Image'),
                                                                      ),
                                                                      const SizedBox(
                                                                          height:
                                                                              10),
                                                                      ElevatedButton(
                                                                        onPressed: _imageUploaded
                                                                            ? () {
                                                                                // Enable button only if image is uploaded
                                                                                // Handle submit logic here
                                                                                // This function will be called when the submit button is pressed
                                                                                _updateAnimalDetails(animal);
                                                                                // Close the modal
                                                                                Navigator.pop(context);
                                                                              }
                                                                            : null,
                                                                        child: const Text(
                                                                            'Submit'),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              },
                                                            );
                                                          },
                                                        );
                                                      },
                                                child: Container(
                                                  height: 25,
                                                  width: 100,
                                                  child: const Center(
                                                    child: Text('Change Photo'),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ]);
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 600),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20.0),
                                  itemCount: _filteredAnimals(animals).length,
                                  itemBuilder: (context, index) {
                                    var animal =
                                        _filteredAnimals(animals)[index];
                                    return Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.all(12.0),
                                        leading: SizedBox(
                                          width: 100,
                                          height: 100,
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
                                            child: Image.network(
                                              animal['Image'],
                                              fit: BoxFit.fill,
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          animal['Name'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[900],
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 8.0),
                                            Text('Breed: ${animal['Breed']}'),
                                            const SizedBox(height: 4.0),
                                            Text(
                                              'Age on Shelter: ${animal['AgeInShelter']}',
                                            ),
                                            const SizedBox(height: 4.0),
                                            Text(
                                              'Description: ${animal['Description']}',
                                              style: const TextStyle(
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                            const SizedBox(height: 4.0),
                                            Text(
                                              'Personality: ${animal['Personality']}',
                                            ),
                                            const SizedBox(height: 4.0),
                                            Text(
                                              'Gender: ${animal['Gender']}',
                                            ),
                                            const SizedBox(height: 4.0),
                                            Text(
                                              'PWD: ${animal['PWD']}',
                                            ),
                                            const SizedBox(height: 4.0),
                                            Text(
                                              'Cat or Dog: ${animal['CatOrDog']}',
                                            ),
                                            const SizedBox(height: 4.0),
                                            Text(
                                              'Status: ${animal['Status']}',
                                            ),
                                          ],
                                        ),
                                        trailing: ElevatedButton(
                                          onPressed: () {
                                            // Call edit function when edit button is clicked
                                            editAnimalDetails(animal);
                                          },
                                          child: const Text('Edit'),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<DocumentSnapshot> _filteredAnimals(List<DocumentSnapshot> animals) {
    final query = _searchController.text.toLowerCase();
    return animals.where((animal) {
      final name = animal['Name'].toString().toLowerCase();
      return name.contains(query);
    }).toList();
  }

  void editAnimalDetails(DocumentSnapshot animal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String name = animal['Name'];
        String breed = animal['Breed'];
        String ageInShelter = animal['AgeInShelter'];
        String description = animal['Description'];
        String personality = animal['Personality'];
        String gender = animal['Gender'];
        String pwd = animal['PWD'];
        String catOrDog = animal['CatOrDog'];
        String status = animal['Status'];

        nameController.text = name;
        breedController.text = breed;
        ageInShelterController.text = ageInShelter;
        descriptionController.text = description;
        personalityController.text = personality;
        pwdController.text = pwd;
        catOrDogController.text = catOrDog;
        statusController.text = status;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            width: 700,
            child: SingleChildScrollView(
              child: Center(
                child: Container(
                  width: 700,
                  margin: const EdgeInsets.symmetric(
                    vertical: 25,
                    horizontal: 25,
                  ),
                  padding: const EdgeInsets.symmetric(
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
                        offset: const Offset(0, 3),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EDIT PET FORM',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                      ),
                      const SizedBox(
                        height: 35,
                      ),
                      const Text(
                        'Pet Name:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter pet name',
                        ),
                      ),
                      const SizedBox(height: 35),
                      const Text(
                        'Age in Shelter:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        controller: ageInShelterController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter age in shelter',
                        ),
                      ),
                      const SizedBox(height: 35),
                      const Text(
                        'Personality:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        controller: personalityController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter personality',
                        ),
                      ),
                      const SizedBox(height: 35),
                      const Text(
                        'Breed:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        controller: breedController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter breed',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
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
                          const SizedBox(width: 200),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Cat or Dog:',
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
                      const SizedBox(height: 35),
                      const Text(
                        'PWD (Person With Disability) or not:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        controller: pwdController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter PWD status',
                        ),
                      ),
                      const SizedBox(height: 35),
                      const Text(
                        'Status:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        controller: statusController,
                        enabled:
                            false, // Set enabled to false to disable the TextField
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter status',
                        ),
                      ),
                      const SizedBox(height: 35),
                      const Text(
                        'Description:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter description',
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 35),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment
                              .spaceEvenly, // Centers the buttons horizontally
                          children: <Widget>[
                            ElevatedButton(
                              onPressed: () {
                                // Extract the ID from the DocumentSnapshot and pass it to deleteAnimal
                                deleteAnimal(animal.id);
                                Navigator.pop(context);
                              },
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.red),
                              ),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // Call update function when update button is clicked
                                _updateAnimalDetails(animal);
                                Navigator.pop(context);
                              },
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.green),
                              ),
                              child: const Text(
                                'Update',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String? _uploadedImageURL;

  Future<void> _uploadImage() async {
    if (kIsWeb) {
      FilePickerResult? result =
          await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null) {
        Uint8List fileBytes = result.files.first.bytes!;
        String fileName = result.files.first.name;
        _uploadedImageURL = await _uploadImageToFirebase(fileBytes, fileName);
      }
    } else {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        File imageFile = File(image.path);
        String fileName = imageFile.path.split('/').last;
        Uint8List fileBytes = await imageFile.readAsBytes();
        _uploadedImageURL = await _uploadImageToFirebase(fileBytes, fileName);
      }
    }
  }

  Future<String> _uploadImageToFirebase(
      Uint8List fileBytes, String fileName) async {
    Reference ref = FirebaseStorage.instance.ref().child('images/$fileName');
    await ref.putData(fileBytes);
    return await ref.getDownloadURL();
  }

  void _updateAnimalDetails(DocumentSnapshot animal) async {
    String? name = nameController.text.isNotEmpty ? nameController.text : null;
    String? breed =
        breedController.text.isNotEmpty ? breedController.text : null;
    String? ageInShelter = ageInShelterController.text.isNotEmpty
        ? ageInShelterController.text
        : null;
    String? description = descriptionController.text.isNotEmpty
        ? descriptionController.text
        : null;
    String? personality = personalityController.text.isNotEmpty
        ? personalityController.text
        : null;
    String? pwd = pwdController.text.isNotEmpty ? pwdController.text : null;
    String? catOrDog =
        catOrDogController.text.isNotEmpty ? catOrDogController.text : null;
    String? status =
        statusController.text.isNotEmpty ? statusController.text : null;

    Map<String, dynamic> updateData = {};

    // Add fields to update only if they have new values
    if (name != null) updateData['Name'] = name;
    if (breed != null) updateData['Breed'] = breed;
    if (ageInShelter != null) updateData['AgeInShelter'] = ageInShelter;
    if (description != null) updateData['Description'] = description;
    if (personality != null) updateData['Personality'] = personality;
    if (pwd != null) updateData['PWD'] = pwd;
    if (catOrDog != null) updateData['CatOrDog'] = catOrDog;
    if (status != null) updateData['Status'] = status;

    // Only add the image to the update data if a new image was uploaded
    if (_uploadedImageURL != null) {
      updateData['Image'] = _uploadedImageURL;
    }

    try {
      await FirebaseFirestore.instance
          .collection('Animal')
          .doc(animal.id)
          .update(updateData);
      Fluttertoast.showToast(msg: 'Animal details updated successfully');
    } catch (e) {
      print(e);
      Fluttertoast.showToast(msg: 'Failed to update animal details');
    }
  }

  void _clearFields() {
    nameController.clear();
    breedController.clear();
    ageInShelterController.clear();
    descriptionController.clear();
    personalityController.clear();
    pwdController.clear();
    catOrDogController.clear();
    statusController.clear();
  }
}

Future<void> deleteAnimal(String id) async {
  await FirebaseFirestore.instance.collection('Animal').doc(id).delete();
}
