import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mad/admin/report_generation/animal_list_pdf.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:html' as html;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:pdf/widgets.dart' as pw;

class AnimalList extends StatefulWidget {
  @override
  _AnimalListState createState() => _AnimalListState();
}

class _AnimalListState extends State<AnimalList> {
  final GlobalKey _qrKey = GlobalKey();

  late TextEditingController _searchController;
  String _selectedFilter = 'All'; // State variable for the filter
  bool isCustomBreedSelected =
      false; // To track if custom breed option is selected

  late Timer _debounce;
  late TextEditingController nameController;
  late TextEditingController breedController;
  late TextEditingController ageInShelterController;
  late TextEditingController descriptionController;
  late TextEditingController personalityController;
  late TextEditingController pwdController;
  late TextEditingController catOrDogController;
  late TextEditingController statusController;
  final PdfGenerator pdfGenerator = PdfGenerator();
  String selectedHealthStatus = 'Healthy'; // Default value
  String selectedVaccineShot = 'None'; // Default value

  String catOrDog = 'Cat'; // Set this based on your logic

  bool _imageUploaded = false;
  bool _isUploading = false; // Add this state variable

  String calculateExactDifference(DateTime startDate, DateTime endDate) {
    int years = endDate.year - startDate.year;
    int months = endDate.month - startDate.month;
    int days = endDate.day - startDate.day;
    int hours = endDate.hour - startDate.hour;
    int minutes = endDate.minute - startDate.minute;

    // Handle cases where months, days, hours, or minutes might go negative
    if (minutes < 0) {
      minutes += 60;
      hours -= 1;
    }
    if (hours < 0) {
      hours += 24;
      days -= 1;
    }
    if (days < 0) {
      final previousMonth = DateTime(endDate.year, endDate.month, 0);
      days += previousMonth.day;
      months -= 1;
    }
    if (months < 0) {
      months += 12;
      years -= 1;
    }

    // Determine the largest unit of time that has passed
    if (years > 0) {
      return '$years year${years > 1 ? 's' : ''}';
    } else if (months > 0) {
      return '$months month${months > 1 ? 's' : ''}';
    } else if (days > 0) {
      return '$days day${days > 1 ? 's' : ''}';
    } else if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''}';
    }

    return 'Just now'; // If no time has passed
  }

  Future<void> _downloadQR(String id) async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: id,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L,
      );
      final qrCode = qrValidationResult.qrCode;

      // Create a new PDF document
      final pdf = pw.Document();

      // Create a QR code image
      final painter = QrPainter.withQr(
        qr: qrCode!,
        color: const Color(0xFF000000),
        emptyColor: const Color(0xFFFFFFFF),
        gapless: true,
      );

      // Render the QR code as an image data
      final picData =
          await painter.toImageData(300.0); // You can adjust the size as needed
      if (picData != null) {
        final buffer = picData.buffer.asUint8List();

        // Add the QR code image to the PDF
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(
                  pw.MemoryImage(buffer),
                  width: 300, // Adjust width as necessary
                  height: 300, // Adjust height as necessary
                ),
              );
            },
          ),
        );

        // Save the PDF
        final pdfBytes = await pdf.save();
        final blob = html.Blob([pdfBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "qr_code.pdf")
          ..click();
        html.Url.revokeObjectUrl(url); // Clean up
      }
    } catch (e) {
      print('Error downloading QR code: $e');
    }
  }

  String calculateUpdatedAgeInShelter(
      String currentAgeInShelter, Timestamp dateCreated) {
    // Calculate the time difference
    DateTime createdDate = dateCreated.toDate();
    Duration difference = DateTime.now().difference(createdDate);

    // Parse the current age in shelter
    int currentYears = 0;
    int currentMonths = 0;
    int currentDays = 0;

    if (currentAgeInShelter.contains('year')) {
      currentYears += int.parse(currentAgeInShelter.split(' ')[0]);
    }
    if (currentAgeInShelter.contains('month')) {
      currentMonths += int.parse(currentAgeInShelter.split(' ')[0]);
    }
    if (currentAgeInShelter.contains('day')) {
      currentDays += int.parse(currentAgeInShelter.split(' ')[0]);
    }

    // Total elapsed time in days
    int totalElapsedDays = difference.inDays;

    // Update the years based on full years passed
    int yearsToAdd = totalElapsedDays ~/ 365;
    if (yearsToAdd > 0) {
      currentYears += yearsToAdd;
      return '$currentYears year${currentYears > 1 ? 's' : ''}'; // Return immediately if years are updated
    }

    // Update the months based on full months passed
    int monthsToAdd = (totalElapsedDays % 365) ~/ 30;
    if (monthsToAdd > 0 && currentYears == 0) {
      currentMonths += monthsToAdd;
      return '$currentMonths month${currentMonths > 1 ? 's' : ''}'; // Return immediately if months are updated
    }

    // If we only have days to consider
    if (currentYears == 0 && currentMonths == 0) {
      currentDays +=
          totalElapsedDays; // Add all days if there are no years or months
    }

    // Construct the result string
    String result = '';
    if (currentYears > 0) {
      result += '$currentYears year${currentYears > 1 ? 's' : ''}';
    }
    if (currentMonths > 0) {
      result += (result.isNotEmpty ? ' ' : '') +
          '$currentMonths month${currentMonths > 1 ? 's' : ''}';
    }
    if (currentDays > 0) {
      result += (result.isNotEmpty ? ' ' : '') +
          '$currentDays day${currentDays > 1 ? 's' : ''}';
    }

    return result.isNotEmpty ? result : '0 days';
  }

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

  String truncateText(String text, int wordLimit) {
    List<String> words = text.split(' ');
    if (words.length <= wordLimit) {
      return text;
    } else {
      return words.take(wordLimit).join(' ') + '...';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if it's a web view

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('Animal').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No data available'));
        }

        List<DocumentSnapshot> animals = snapshot.data!.docs;

        // Filter based on selected filter
        if (_selectedFilter == 'Cat') {
          animals =
              animals.where((animal) => animal['CatOrDog'] == 'Cat').toList();
        } else if (_selectedFilter == 'Dog') {
          animals =
              animals.where((animal) => animal['CatOrDog'] == 'Dog').toList();
        }

        // Sort animals by dateCreated
        animals.sort((a, b) => (b['dateCreated'] as Timestamp)
            .compareTo(a['dateCreated'] as Timestamp));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Animal List'),
            centerTitle: true,
            titleSpacing: 0,
            actions: <Widget>[
              Tooltip(
                message: 'Print Animal List',
                child: IconButton(
                  icon: Icon(Icons.print),
                  onPressed: () {
                    pdfGenerator.generatePdf(
                        preview: true, filter: _selectedFilter);
                  },
                ),
              ),
              Tooltip(
                message: 'Download Animal List',
                child: IconButton(
                  icon: Icon(Icons.download),
                  onPressed: () {
                    pdfGenerator.generatePdf(
                        preview: false, filter: _selectedFilter);
                  },
                ),
              ),
              // Dropdown filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButton<String>(
                  value: _selectedFilter,
                  icon: const Icon(Icons.filter_list,
                      color: Color.fromARGB(255, 0, 0, 0)),
                  dropdownColor: const Color.fromARGB(255, 255, 255, 255),
                  underline: SizedBox(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedFilter = newValue!;
                    });
                  },
                  items: <String>['All', 'Cat', 'Dog']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value,
                          style: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0))),
                    );
                  }).toList(),
                ),
              ),
            ],
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
                          labelText: 'Search Animal Name',
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
                        width: 1200,
                        alignment: Alignment.topCenter,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                              child: DataTable(
                                columnSpacing: 15.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: Color(0xFFE96560), // Border color
                                    width: 0.5, // Border width
                                  ),
                                ),
                                headingRowColor: MaterialStateColor.resolveWith(
                                    (states) =>
                                        Color(0xFFE96560)!), // Header row color
                                dataRowHeight:
                                    120.0, // Adjust row height as needed
                                columns: [
                                  DataColumn(
                                    label: Center(
                                      child: Text(
                                        'Image',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    tooltip: 'Image',
                                    numeric: false,
                                  ),
                                  DataColumn(
                                    label: Center(
                                      child: Text(
                                        'Pet Name',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    tooltip: 'Pet Name',
                                    numeric: false,
                                  ),
                                  DataColumn(
                                    label: Center(
                                      child: Text(
                                        'Breed',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    tooltip: 'Breed',
                                    numeric: false,
                                  ),
                                  DataColumn(
                                    label: Center(
                                      child: Text(
                                        'Age on Shelter',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    tooltip: 'Age on Shelter',
                                    numeric: false,
                                  ),
                                  DataColumn(
                                    label: Center(
                                      child: Text(
                                        'Behavior',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    tooltip: 'Behavior',
                                    numeric: false,
                                  ),
                                  DataColumn(
                                    label: Center(
                                      child: Text(
                                        'Gender',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    tooltip: 'Gender',
                                    numeric: false,
                                  ),
                                  DataColumn(
                                    label: Center(
                                      child: Text(
                                        'Health Status',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    tooltip: 'Health Status',
                                    numeric: false,
                                  ),
                                  DataColumn(
                                    label: Center(
                                      child: Text(
                                        'Cat or Dog',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    tooltip: 'Cat or Dog',
                                    numeric: false,
                                  ),
                                  DataColumn(
                                    label: Center(
                                      child: Text(
                                        'Status',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    tooltip: 'Status',
                                    numeric: false,
                                  ),
                                  DataColumn(
                                    label: Center(
                                      child: Text(
                                        'Action',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    tooltip: 'Action',
                                    numeric: false,
                                  ),
                                  DataColumn(
                                    label: Center(
                                      child: Text(
                                        'Action',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    tooltip: 'Action',
                                    numeric: false,
                                  ),
                                ],
                                rows: _filteredAnimals(animals).map((animal) {
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
                                        child: Text(
                                            calculateUpdatedAgeInShelter(
                                                animal['AgeInShelter'],
                                                animal['dateCreated'])),
                                      ),
                                    ),
                                    DataCell(
                                      Center(
                                        child: Text(animal['Personality']),
                                      ),
                                    ),
                                    DataCell(
                                      Center(
                                        child: Text(animal['Gender']),
                                      ),
                                    ),
                                    DataCell(
                                      Center(
                                        child: Text(
                                          truncateText(animal['PWD'], 2),
                                          overflow: TextOverflow.ellipsis,
                                        ),
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
                                                    builder:
                                                        (BuildContext context) {
                                                      return StatefulBuilder(
                                                        builder: (BuildContext
                                                                context,
                                                            StateSetter
                                                                setState) {
                                                          return Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(20.0),
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
                                                                        width:
                                                                            200,
                                                                        height:
                                                                            200,
                                                                      )
                                                                    : const SizedBox(), // Display uploaded image if available
                                                                ElevatedButton(
                                                                  onPressed:
                                                                      _isUploading
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
                                                                    height: 10),
                                                                ElevatedButton(
                                                                  onPressed:
                                                                      _imageUploaded
                                                                          ? () {
                                                                              // Enable button only if image is uploaded
                                                                              // Handle submit logic here
                                                                              // This function will be called when the submit button is pressed
                                                                              _updateAnimalDetails(animal);
                                                                              // Close the modal
                                                                              Navigator.pop(context);
                                                                              setState(() {
                                                                                _imageUploaded = false;
                                                                              });
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
                                              child: Text('Photo'),
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
        String id = animal.id;
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment
                            .spaceBetween, // Align items to the edges
                        children: [
                          const Text(
                            'EDIT PET FORM',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 25,
                            ),
                          ),
                          Row(
                            children: [
                              Tooltip(
                                message: 'Generate QR',
                                child: IconButton(
                                  icon: const Icon(Icons.qr_code), // QR icon
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text('QR Code'),
                                          content: SizedBox(
                                            width: 270,
                                            height: 300,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Wrap the QrImageView with RepaintBoundary
                                                RepaintBoundary(
                                                  key: _qrKey,
                                                  child: QrImageView(
                                                    data: id,
                                                    version: QrVersions.auto,
                                                    size: 200.0,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  id,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    TextButton(
                                                      onPressed: () async {
                                                        await _downloadQR(id);
                                                      },
                                                      child: Text('Download'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: Text('Close'),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Age in Shelter:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextFormField(
                            controller: ageInShelterController,
                            readOnly: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Select Date and Time',
                            ),
                            onTap: () async {
                              DateTime? selectedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                                builder: (BuildContext context, Widget? child) {
                                  return SimpleDialog(
                                    title: Text(
                                        'Select when the Pet Arrived at the Shelter?'),
                                    children: <Widget>[
                                      SizedBox(
                                        child: child,
                                        width: 300,
                                        height: 400,
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (selectedDate != null) {
                                // Show the Time Picker with a title
                                TimeOfDay? selectedTime = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                  builder:
                                      (BuildContext context, Widget? child) {
                                    return SimpleDialog(
                                      title: Text(
                                          'Select when the Pet Arrived at the Shelter?'),
                                      children: <Widget>[
                                        SizedBox(
                                          child: child,
                                          width: 300, // Adjust width as needed
                                          height:
                                              400, // Adjust height as needed
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (selectedTime != null) {
                                  // Combine selected date and time into a single DateTime object
                                  DateTime finalDateTime = DateTime(
                                    selectedDate.year,
                                    selectedDate.month,
                                    selectedDate.day,
                                    selectedTime.hour,
                                    selectedTime.minute,
                                  );

                                  // Calculate the difference between now and the selected date-time
                                  DateTime now = DateTime.now();
                                  String timePassed = calculateExactDifference(
                                      finalDateTime, now);

                                  // Update the text field with the exact difference
                                  ageInShelterController.text = timePassed;
                                }
                              }
                            },
                          ),
                        ],
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Breed:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            width: double.infinity,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Color.fromARGB(255, 174, 174, 174)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: isCustomBreedSelected
                                    ? null
                                    : (breedController.text.isEmpty
                                        ? null
                                        : breedController.text),
                                hint: Text('Select breed'),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    if (newValue == 'Other') {
                                      isCustomBreedSelected =
                                          true; // Show the custom breed input
                                      breedController
                                          .clear(); // Clear selected breed
                                    } else {
                                      isCustomBreedSelected =
                                          false; // Hide custom input
                                      breedController.text = newValue ?? '';
                                    }
                                  });
                                },
                                items: [
                                  ...((catOrDog == 'Cat')
                                      ? [
                                          'Siamese',
                                          'Persian',
                                          'Maine Coon',
                                          'Scottish Fold',
                                          'British Shorthair',
                                          'Sphynx',
                                          'Bengal',
                                          'Ragdoll',
                                          'American Shorthair',
                                          'Exotic Shorthair',
                                          'Puspin',
                                          'Other' // Option to enter custom breed
                                        ]
                                      : [
                                          'Labrador Retriever',
                                          'Shih Tzu',
                                          'Beagle',
                                          'German Shepherd',
                                          'Golden Retriever',
                                          'Chihuahua',
                                          'Siberian Husky',
                                          'Pomeranian',
                                          'Dachshund',
                                          'Doberman Pinscher',
                                          'Aspin',
                                          'Other' // Option to enter custom breed
                                        ]),
                                  // Add the custom breed if it is not already in the dropdown
                                  if (isCustomBreedSelected ||
                                      ![
                                            'Siamese',
                                            'Persian',
                                            'Maine Coon',
                                            'Scottish Fold',
                                            'British Shorthair',
                                            'Sphynx',
                                            'Bengal',
                                            'Ragdoll',
                                            'American Shorthair',
                                            'Exotic Shorthair',
                                            'Puspin',
                                            'Labrador Retriever',
                                            'Shih Tzu',
                                            'Beagle',
                                            'German Shepherd',
                                            'Golden Retriever',
                                            'Chihuahua',
                                            'Siberian Husky',
                                            'Pomeranian',
                                            'Dachshund',
                                            'Doberman Pinscher',
                                            'Aspin'
                                          ].contains(breedController.text) &&
                                          breedController.text.isNotEmpty)
                                    breedController.text // Add the custom breed
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                icon: Icon(Icons.arrow_drop_down,
                                    color: Colors.black),
                                iconSize: 24,
                                isExpanded: true,
                                padding: EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ),
                          // Show TextField for custom breed input if selected
                          if (isCustomBreedSelected)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 8.0),
                              child: TextField(
                                controller: breedController,
                                decoration: InputDecoration(
                                  hintText: 'Enter custom breed',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    // Always set isCustomBreedSelected to true when typing in the TextField
                                    isCustomBreedSelected = true;
                                  });
                                },
                              ),
                            ),
                        ],
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Health Status:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          DropdownButtonFormField<String>(
                            value: selectedHealthStatus = animal['PWD'],
                            items: (catOrDog == 'Cat'
                                    ? [
                                        'Healthy',
                                        'Blindness',
                                        'Deafness',
                                        'Feline Lower Urinary Tract Diseases (FLUTD)',
                                        'Chronic Kidney Disease (CKD)',
                                        'Diabetes',
                                        'Arthritis',
                                        'Asthma',
                                        'Hypertrophic Cardiomyopathy'
                                      ]
                                    : [
                                        'Healthy',
                                        'Blindness',
                                        'Deafness',
                                        'Hip Dysplasia',
                                        'Elbow Dysplasia',
                                        'Intervertebral Disc Disease (IVDD)',
                                        'Arthritis',
                                        'Paralysis',
                                        'Cognitive Dysfunction Syndrome'
                                      ])
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedHealthStatus = newValue!;
                              });
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Select Health Status',
                            ),
                          ),
                          const SizedBox(height: 35),
                          const Text(
                            'Vaccine Shots Taken:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          DropdownButtonFormField<String>(
                            value: animal['ShotTaken'] ??
                                'None', // Use null-aware operator to provide default
                            items: (catOrDog == 'Cat'
                                    ? [
                                        'None',
                                        'FVRCP (Feline Viral Rhinotracheitis, Calicivirus, Panleukopenia)',
                                        'Rabies Vaccine',
                                        'FeLV Vaccine (Feline Leukemia Virus)',
                                        'FIV Vaccine (Feline Immunodeficiency Virus)',
                                        'FVRCP and Rabies Vaccine',
                                        'FVRCP, Rabies, and FeLV Vaccine',
                                        'FVRCP, Rabies, FeLV, and FIV Vaccine',
                                      ]
                                    : [
                                        'None',
                                        'DHPP/DAPP (Distemper, Adenovirus/Hepatitis, Parvovirus, Parainfluenza)',
                                        'Rabies Vaccine',
                                        'Leptospirosis Vaccine',
                                        'Bordetella Vaccine',
                                        'Lyme Disease Vaccine',
                                        'Canine Influenza Vaccine',
                                        'DHPP/DAPP and Rabies Vaccine',
                                        'DHPP/DAPP, Rabies, and Leptospirosis Vaccine',
                                        'DHPP/DAPP, Rabies, Leptospirosis, and Bordetella Vaccine',
                                        'DHPP/DAPP, Rabies, Leptospirosis, Bordetella, and Lyme Disease Vaccine',
                                        'DHPP/DAPP, Rabies, Leptospirosis, Bordetella, Lyme Disease, Canine Influenza Vaccine',
                                      ])
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedVaccineShot = newValue!;
                              });
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Select Vaccine Shots Taken',
                            ),
                            style: const TextStyle(
                              fontSize: 12, // Set your desired font size here
                            ),
                          ),
                          const SizedBox(height: 35),
                          const Text(
                            'Status:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          // Keeping the TextField for Status
                          TextField(
                            controller: statusController,
                            enabled:
                                false, // Set enabled to false to disable the TextField
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Enter status',
                            ),
                          ),
                        ],
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
                                        Colors.yellow.shade700),
                              ),
                              child: const Text(
                                'Archive',
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
    String? health = selectedHealthStatus.isNotEmpty
        ? selectedHealthStatus
        : null; // Use selectedHealthStatus
    String? shots = selectedVaccineShot.isNotEmpty
        ? selectedVaccineShot
        : null; // Use selectedHealthStatus

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
    if (health != null) updateData['PWD'] = health;
    if (shots != null) updateData['ShotTaken'] = shots;
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
    catOrDogController.clear();
    statusController.clear();
  }
}

Future<void> deleteAnimal(String id) async {
  await FirebaseFirestore.instance.collection('Animal').doc(id).delete();
}
