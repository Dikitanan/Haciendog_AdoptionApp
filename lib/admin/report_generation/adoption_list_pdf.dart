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

  Future<void> generatePdf({bool preview = false}) async {
    final pdf = pw.Document();
    const double pageWidth = 595.27; // A4 width in points
    const double pageHeight = 841.89; // A4 height in points

    // Load the image bytes from assets
    final Uint8List imageBytes =
        (await rootBundle.load('assets/icons/haciendoglogo.jpg'))
            .buffer
            .asUint8List();
    final image = pw.MemoryImage(imageBytes);

    final adoptionSnapshot = await _firestore
        .collection('AdoptionForms')
        .where('status', isEqualTo: 'Adopted')
        .get();

    final adoptionData =
        adoptionSnapshot.docs.map((doc) => doc.data()).toList();

    // Sort the data by DateAdopted in descending order
    adoptionData.sort((a, b) {
      Timestamp dateA = a['DateAdopted'] as Timestamp;
      Timestamp dateB = b['DateAdopted'] as Timestamp;
      return dateB.compareTo(dateA); // Newest first
    });

    // Fetch pet names from Animal collection
    final petIds = adoptionData.map((doc) => doc['petId']).toSet();
    final animalSnapshot = await _firestore
        .collection('Animal')
        .where(FieldPath.documentId, whereIn: petIds.toList())
        .get();

    final animalData = Map<String, String>.fromEntries(animalSnapshot.docs
        .map((doc) => MapEntry(doc.id, doc['Name'] ?? 'Unknown')));

    // Generate pages for adoption forms
    for (var i = 0; i < adoptionData.length; i += 16) {
      final chunk = adoptionData.sublist(
          i, (i + 16 < adoptionData.length) ? i + 16 : adoptionData.length);

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
                    pw.Text('Adoption Report',
                        style: pw.TextStyle(
                            fontSize: 24, fontWeight: pw.FontWeight.bold)),
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
                        decoration: pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          pw.Padding(
                              padding: pw.EdgeInsets.all(8.0),
                              child: pw.Text('Name',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(8.0),
                              child: pw.Text('Age',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(8.0),
                              child: pw.Text('Address',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(8.0),
                              child: pw.Text('Occupation',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(8.0),
                              child: pw.Text('Email',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(8.0),
                              child: pw.Text('Pet Name',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(8.0),
                              child: pw.Text('Date Adopted',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10))),
                        ],
                      ),
                      // Data Rows
                      for (var adoption in chunk)
                        pw.TableRow(
                          children: [
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text(adoption['name'] ?? '',
                                    style: pw.TextStyle(fontSize: 10))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text(
                                    adoption['age']?.toString() ?? '',
                                    style: pw.TextStyle(fontSize: 10))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text(adoption['address'] ?? '',
                                    style: pw.TextStyle(fontSize: 10))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text(adoption['occupation'] ?? '',
                                    style: pw.TextStyle(fontSize: 10))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text(adoption['email'] ?? '',
                                    style: pw.TextStyle(fontSize: 10))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text(
                                    animalData[adoption['petId']] ?? 'Unknown',
                                    style: pw.TextStyle(fontSize: 10))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text(
                                    adoption['DateAdopted'] != null
                                        ? formatDonationDate(
                                            adoption['DateAdopted'])
                                        : 'Invalid Date',
                                    style: pw.TextStyle(fontSize: 10))),
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
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ),
              ],
            );
          },
        ),
      );
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
      // ignore: unused_local_variable
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "generated_adoption_report.pdf")
        ..click();
    }

    // Revoke the object URL after download or preview to free up resources
    html.Url.revokeObjectUrl(url);
  }

  String formatDonationDate(dynamic dateTime) {
    if (dateTime == null || dateTime.toString().isEmpty) {
      return 'Invalid Date'; // Return a default message if null or empty
    }

    try {
      // Check if the input is a valid Firestore Timestamp and convert it
      DateTime parsedDate;
      if (dateTime is Timestamp) {
        parsedDate = dateTime.toDate();
      } else {
        // Parse the date string into DateTime
        parsedDate = DateTime.parse(dateTime.toString()).toLocal();
      }

      // Extract date components
      final formattedDate = '${parsedDate.month.toString().padLeft(2, '0')}/'
          '${parsedDate.day.toString().padLeft(2, '0')}/'
          '${parsedDate.year}';

      // Extract time components and format AM/PM
      final hour = parsedDate.hour % 12 == 0 ? 12 : parsedDate.hour % 12;
      final minute = parsedDate.minute.toString().padLeft(2, '0');
      final period = parsedDate.hour >= 12 ? 'PM' : 'AM';

      return '$formattedDate $hour:$minute $period';
    } catch (e) {
      // Handle any parsing error
      return 'Invalid Date';
    }
  }
}
