import 'dart:html' as html;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: unused_import
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

  Future<void> generatePdf(
      {bool preview = false, String filter = 'All'}) async {
    final pdf = pw.Document();
    const double pageWidth = 595.27; // A4 width in points
    const double pageHeight = 841.89; // A4 height in points

    // Load the image bytes from assets
    final Uint8List imageBytes =
        (await rootBundle.load('assets/icons/haciendoglogo.jpg'))
            .buffer
            .asUint8List();
    final image = pw.MemoryImage(imageBytes);

    // Fetch data from Firebase
    final snapshot = await _firestore.collection('Animal').get();
    final data = snapshot.docs.map((doc) => doc.data()).toList();

    data.sort((a, b) => (b['dateCreated'] as Timestamp)
        .compareTo(a['dateCreated'] as Timestamp));

    // Filter data based on the selected filter
    List<Map<String, dynamic>> filteredData;
    if (filter == 'All') {
      filteredData = data;
    } else {
      filteredData =
          data.where((animal) => animal['CatOrDog'] == filter).toList();
    }

    // Group filtered data by Status
    final groupedData = <String, List<Map<String, dynamic>>>{};
    for (var animal in filteredData) {
      final status = animal['Status'] ?? 'Unknown';
      if (!groupedData.containsKey(status)) {
        groupedData[status] = [];
      }
      groupedData[status]!.add(animal);
    }

    // Generate pages for each status
    for (var status in groupedData.keys) {
      final animals = groupedData[status]!;

      // Split animals into chunks of 17
      for (var i = 0; i < animals.length; i += 17) {
        final chunk = animals.sublist(
            i, (i + 17 < animals.length) ? i + 17 : animals.length);

        // Add a new page for each chunk
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(pageWidth, pageHeight),
            build: (pw.Context context) {
              return pw.Column(
                children: [
                  // Header
                  pw.Column(
                    children: [
                      pw.Container(
                        height: 90,
                        width: 90,
                        child: pw.Image(image),
                      ),
                      pw.Text('Animal Report',
                          style: pw.TextStyle(
                              fontSize: 22, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Status: $status',
                          style: pw.TextStyle(
                              fontSize: 16, color: PdfColors.black)),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  // Table with padding
                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(horizontal: 20.0),
                    child: pw.Table(
                      border:
                          pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
                      columnWidths: {
                        0: pw.FlexColumnWidth(2),
                        1: pw.FlexColumnWidth(1.5),
                        2: pw.FlexColumnWidth(2),
                        3: pw.FlexColumnWidth(1.5),
                        4: pw.FlexColumnWidth(1.5),
                        5: pw.FlexColumnWidth(1.5),
                      },
                      children: [
                        // Header Row
                        pw.TableRow(
                          decoration:
                              pw.BoxDecoration(color: PdfColors.grey200),
                          children: [
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text('Name',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 10))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text('Breed',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 10))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text('Age in Shelter',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 10))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text('Behavior',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 10))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text('Gender',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 10))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text('Health Status',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 10))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text('Cat or Dog',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 10))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text('Pet Status',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 10))),
                          ],
                        ),
                        // Data Rows
                        for (var animal in chunk)
                          pw.TableRow(
                            children: [
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(8.0),
                                  child: pw.Text(animal['Name'] ?? '',
                                      style: pw.TextStyle(fontSize: 9))),
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(8.0),
                                  child: pw.Text(animal['Breed'] ?? '',
                                      style: pw.TextStyle(fontSize: 9))),
                              pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text(
                                  calculateUpdatedAgeInShelter(
                                    animal['AgeInShelter'] ?? '',
                                    animal[
                                        'dateCreated'], // Ensure this is a Timestamp
                                  ),
                                  style: pw.TextStyle(fontSize: 9),
                                ),
                              ),
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(8.0),
                                  child: pw.Text(animal['Personality'] ?? '',
                                      style: pw.TextStyle(fontSize: 9))),
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(8.0),
                                  child: pw.Text(animal['Gender'] ?? '',
                                      style: pw.TextStyle(fontSize: 9))),
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(8.0),
                                  child: pw.Text(animal['PWD'] ?? '',
                                      style: pw.TextStyle(fontSize: 9))),
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(8.0),
                                  child: pw.Text(animal['CatOrDog'] ?? '',
                                      style: pw.TextStyle(fontSize: 9))),
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(8.0),
                                  child: pw.Text(animal['Status'] ?? '',
                                      style: pw.TextStyle(fontSize: 9))),
                            ],
                          ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  // Footer
                  pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      'Generated on ${DateTime.now().toLocal().toString().split(' ')[0]} ${DateTime.now().toLocal().hour % 12}:${DateTime.now().toLocal().minute.toString().padLeft(2, '0')} ${DateTime.now().toLocal().hour >= 12 ? 'PM' : 'AM'}',
                      style:
                          pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ),
                  pw.SizedBox(height: 25),
                  // Signature line
                  pw.Container(
                    width: 200,
                    child: pw.DecoratedBox(
                      decoration: pw.BoxDecoration(
                        border: pw.Border(
                          bottom:
                              pw.BorderSide(width: 1, color: PdfColors.black),
                        ),
                      ),
                      child: pw.Padding(
                        padding: pw.EdgeInsets.only(bottom: 5.0),
                        child: pw.Text('', style: pw.TextStyle(fontSize: 10)),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  // Printed name
                  pw.Text('Prepared By', style: pw.TextStyle(fontSize: 10)),
                ],
              );
            },
          ),
        );
      }
    }

    // Generate PDF in byte format
    Uint8List pdfBytes = await pdf.save();

    // Create a blob from the byte data
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);

    if (preview) {
      // Open PDF in a new window for preview
      html.window.open(url, 'Preview');
    } else {
      // Trigger download
      final anchor = html.AnchorElement(href: url);
      anchor.download = 'animal_report.pdf';
      anchor.click();
      html.Url.revokeObjectUrl(url);
    }
  }
}
