import 'dart:html' as html;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: unused_import
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
// Import statements remain the same

class PdfGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> generatePdf({
    required String status, // Added status parameter
    required DateTime startDate,
    required DateTime endDate,
    bool preview = false,
  }) async {
    final pdf = pw.Document();
    const double pageWidth = 595.27; // A4 width in points
    const double pageHeight = 841.89; // A4 height in points

    // Load the image bytes from assets
    final Uint8List imageBytes =
        (await rootBundle.load('assets/icons/haciendoglogo.jpg'))
            .buffer
            .asUint8List();
    final image = pw.MemoryImage(imageBytes);

    // Fetch all adoption forms initially
    final adoptionSnapshot = await _firestore
        .collection('AdoptionForms')
        .where('status', isNotEqualTo: 'Archived')
        .get();

    // Create a map to hold the adoption data grouped by status
    Map<String, List<Map<String, dynamic>>> groupedData = {};

    // Process and filter the data
    final adoptionData =
        adoptionSnapshot.docs.map((doc) => doc.data()).toList();
    for (var adoption in adoptionData) {
      // Filter by date range
      final dateAdopted = adoption['dateCreated'];
      if (dateAdopted == null) continue;

      DateTime donationDate;
      if (dateAdopted is Timestamp) {
        donationDate = dateAdopted.toDate();
      } else {
        try {
          donationDate = DateTime.parse(dateAdopted.toString()).toLocal();
        } catch (_) {
          continue;
        }
      }

      // Check status filter
      if (status != "All" && adoption['status'] != status) {
        continue;
      }

      // Check date range
      if (donationDate.isAfter(startDate) &&
          donationDate.isBefore(endDate.add(Duration(days: 1)))) {
        final adoptionStatus = adoption['status'] ?? 'Unknown';
        // Group by status
        if (!groupedData.containsKey(adoptionStatus)) {
          groupedData[adoptionStatus] = [];
        }
        groupedData[adoptionStatus]!.add(adoption);
      }
    }

    // Sort the keys (statuses) to maintain a consistent order
    final sortedStatuses = groupedData.keys.toList()..sort();

    // Fetch pet names from Animal collection
    final petIds = adoptionData.map((doc) => doc['petId']).toSet();
    final animalSnapshot = await _firestore
        .collection('Animal')
        .where(FieldPath.documentId, whereIn: petIds.toList())
        .get();

    final animalData = Map<String, String>.fromEntries(animalSnapshot.docs
        .map((doc) => MapEntry(doc.id, doc['Name'] ?? 'Unknown')));

    // Generate pages for each status group
    // Inside the generatePdf method
    for (var statusKey in sortedStatuses) {
      final filteredData = groupedData[statusKey] ?? [];

      // Sort the filtered data by DateAdopted in descending order
      filteredData.sort((a, b) {
        Timestamp dateA = a['dateCreated'] as Timestamp;
        Timestamp dateB = b['dateCreated'] as Timestamp;
        return dateB.compareTo(dateA); // Newest first
      });

      for (var i = 0; i < filteredData.length; i += 16) {
        final chunk = filteredData.sublist(
            i, (i + 16 < filteredData.length) ? i + 16 : filteredData.length);

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
                      pw.Text('Adoption Report for Status: $statusKey',
                          style: pw.TextStyle(
                              fontSize: 22, fontWeight: pw.FontWeight.bold)),
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
                        1: pw.FlexColumnWidth(1.3),
                        2: pw.FlexColumnWidth(2.5),
                        3: pw.FlexColumnWidth(2),
                        4: pw.FlexColumnWidth(2.5),
                        5: pw.FlexColumnWidth(1.3),
                        6: pw.FlexColumnWidth(1.7),
                      },
                      children: [
                        // Header Row
                        pw.TableRow(
                          decoration:
                              pw.BoxDecoration(color: PdfColors.grey200),
                          children: [
                            pw.Padding(
                                padding: pw.EdgeInsets.all(6.0),
                                child: pw.Text('Name',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 9))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(6.0),
                                child: pw.Text('Age',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 9))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(6.0),
                                child: pw.Text('Address',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 9))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(6.0),
                                child: pw.Text('Occupation',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 9))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(6.0),
                                child: pw.Text('Email',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 9))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(6.0),
                                child: pw.Text('Pet Name',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 9))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(6.0),
                                child: pw.Text('Pet ID',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 9))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(6.0),
                                child: pw.Text('Date Form Created',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 9))),
                            // Add this condition to include the DateAdopted column
                            if (statusKey == 'Adopted')
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(6.0),
                                  child: pw.Text('Date Adopted',
                                      style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 9))),
                          ],
                        ),
                        // Data Rows
                        for (var adoption in chunk)
                          pw.TableRow(
                            children: [
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(6.0),
                                  child: pw.Text(adoption['name'] ?? '',
                                      style: pw.TextStyle(fontSize: 9))),
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(6.0),
                                  child: pw.Text(
                                      adoption['age']?.toString() ?? '',
                                      style: pw.TextStyle(fontSize: 9))),
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(6.0),
                                  child: pw.Text(adoption['address'] ?? '',
                                      style: pw.TextStyle(fontSize: 9))),
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(6.0),
                                  child: pw.Text(adoption['occupation'] ?? '',
                                      style: pw.TextStyle(fontSize: 9))),
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(6.0),
                                  child: pw.Text(adoption['email'] ?? '',
                                      style: pw.TextStyle(fontSize: 9))),
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(6.0),
                                  child: pw.Text(
                                      animalData[adoption['petId']] ??
                                          'Unknown',
                                      style: pw.TextStyle(fontSize: 9))),
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(6.0),
                                  child: pw.Text(adoption['petId'] ?? 'Unknown',
                                      style: pw.TextStyle(fontSize: 9))),
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(6.0),
                                  child: pw.Text(
                                      adoption['dateCreated'] != null
                                          ? formatDonationDate(
                                              adoption['dateCreated'])
                                          : 'Invalid Date',
                                      style: pw.TextStyle(fontSize: 9))),
                              // Add this condition to display DateAdopted only for adopted statuses
                              if (statusKey == 'Adopted')
                                pw.Padding(
                                    padding: pw.EdgeInsets.all(6.0),
                                    child: pw.Text(
                                        adoption['DateAdopted'] != null
                                            ? formatDonationDate(
                                                adoption['DateAdopted'])
                                            : 'Invalid Date',
                                        style: pw.TextStyle(fontSize: 9))),
                            ],
                          ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  // Footer (remains unchanged)
                  pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'Generated on ${DateTime.now().toLocal().toString().split(' ')[0]} ${DateTime.now().toLocal().hour % 12}:${DateTime.now().toLocal().minute.toString().padLeft(2, '0')} ${DateTime.now().toLocal().hour >= 12 ? 'PM' : 'AM'}',
                          style: pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey700),
                        ),
                        pw.SizedBox(height: 25),
                        // Signature line
                        pw.Container(
                          width: 200,
                          child: pw.DecoratedBox(
                            decoration: pw.BoxDecoration(
                              border: pw.Border(
                                bottom: pw.BorderSide(
                                    width: 1, color: PdfColors.black),
                              ),
                            ),
                            child: pw.Padding(
                              padding: pw.EdgeInsets.only(bottom: 5.0),
                              child: pw.Text('',
                                  style: pw.TextStyle(fontSize: 10)),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        // Printed name
                        pw.Text('Prepared By',
                            style: pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }
    }

    // Generate PDF in byte format
    Uint8List pdfBytes = await pdf.save();

    // Create a blob from the Uint8List bytes
    final blob = html.Blob([pdfBytes], 'application/pdf');

    // Create a URL from the blob
    final url = html.Url.createObjectUrlFromBlob(blob);

    if (preview) {
      // Open the PDF in a new tab for preview
      html.window.open(url, '_blank');
    } else {
      // Create a downloadable anchor element
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "generated_adoption_report.pdf")
        ..click();
    }

    // Revoke the object URL after download or preview to free up resources
    html.Url.revokeObjectUrl(url);
  }

  String formatDonationDate(dynamic dateTime) {
    if (dateTime == null || dateTime.toString().isEmpty) {
      return 'Invalid Date'; // Return placeholder for invalid date
    }

    DateTime donationDate;
    if (dateTime is Timestamp) {
      donationDate = dateTime.toDate();
    } else {
      donationDate = DateTime.parse(dateTime.toString());
    }

    // Format the date into MM/DD/YYYY HH:MM AM/PM format
    return "${donationDate.month.toString().padLeft(2, '0')}/${donationDate.day.toString().padLeft(2, '0')}/${donationDate.year} ${donationDate.hour > 12 ? donationDate.hour - 12 : donationDate.hour}:${donationDate.minute.toString().padLeft(2, '0')} ${donationDate.hour >= 12 ? 'PM' : 'AM'}";
  }
}
