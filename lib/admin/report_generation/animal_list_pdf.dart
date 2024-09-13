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

    // Fetch data from Firebase
    final snapshot = await _firestore.collection('Animal').get();
    final data = snapshot.docs.map((doc) => doc.data()).toList();

    // Group data by Status
    final groupedData = <String, List<Map<String, dynamic>>>{};
    for (var animal in data) {
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
                              fontSize: 24, fontWeight: pw.FontWeight.bold)),
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
                                        fontWeight: pw.FontWeight.bold))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text('Species',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text('Breed',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text('Gender',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text('Health Status',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text('Pet Status',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold))),
                          ],
                        ),
                        // Data Rows
                        for (var animal in chunk)
                          pw.TableRow(
                            children: [
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(8.0),
                                  child: pw.Text(animal['Name'] ?? '')),
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(8.0),
                                  child: pw.Text(animal['CatOrDog'] ?? '')),
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(8.0),
                                  child: pw.Text(animal['Breed'] ?? '')),
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(8.0),
                                  child: pw.Text(animal['Gender'] ?? '')),
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(8.0),
                                  child: pw.Text(animal['PWD'] ?? '')),
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(8.0),
                                  child: pw.Text(animal['Status'] ?? '')),
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
      // ignore: unused_local_variable
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "generated_animalList_report.pdf")
        ..click();
    }

    // Revoke the object URL after download or preview to free up resources
    html.Url.revokeObjectUrl(url);
  }
}
