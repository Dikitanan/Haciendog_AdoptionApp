import 'dart:html' as html;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> generatePdf({bool preview = false}) async {
    final pdf = pw.Document();
    const double pageWidth = 595.27; // A4 width in points
    const double pageHeight = 841.89; // A4 height in points

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
                      alignment: pw.Alignment.center,
                      padding: pw.EdgeInsets.symmetric(vertical: 20),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'Animal Report',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          pw.Text(
                            'Status: $status',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.normal, // Light weight
                              color: PdfColors.black, // Adjust color if needed
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),
                // Table
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
                  columnWidths: {
                    0: pw.FlexColumnWidth(2),
                    1: pw.FlexColumnWidth(1.5),
                    2: pw.FlexColumnWidth(2),
                    3: pw.FlexColumnWidth(1.5),
                    4: pw.FlexColumnWidth(1.5),
                    5: pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8.0),
                          child: pw.Text('Name',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8.0),
                          child: pw.Text('Species',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8.0),
                          child: pw.Text('Breed',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8.0),
                          child: pw.Text('Gender',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8.0),
                          child: pw.Text('Health Status',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: pw.EdgeInsets.all(8.0),
                          child: pw.Text('Pet Status',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    for (var animal in animals)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8.0),
                            child: pw.Text(animal['Name'] ?? ''),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8.0),
                            child: pw.Text(animal['CatOrDog'] ?? ''),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8.0),
                            child: pw.Text(animal['Breed'] ?? ''),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8.0),
                            child: pw.Text(animal['Gender'] ?? ''),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8.0),
                            child: pw.Text(animal['PWD'] ?? ''),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8.0),
                            child: pw.Text(animal['Status'] ?? ''),
                          ),
                        ],
                      ),
                  ],
                ),
                pw.SizedBox(height: 20),
                // Footer
                pw.Align(
                  alignment: pw.Alignment.bottomCenter,
                  child: pw.Text(
                    'Generated on ${DateTime.now().toLocal().toLocal().toString().split(' ')[0]} ${DateTime.now().toLocal().hour % 12}:${DateTime.now().toLocal().minute.toString().padLeft(2, '0')} ${DateTime.now().toLocal().hour >= 12 ? 'PM' : 'AM'}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
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
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "generated_animal_report.pdf")
        ..click();
    }

    // Revoke the object URL after download or preview to free up resources
    html.Url.revokeObjectUrl(url);
  }
}

class MyHomePage extends StatelessWidget {
  final PdfGenerator pdfGenerator = PdfGenerator();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Web PDF Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                pdfGenerator.generatePdf(preview: true); // Preview PDF
              },
              child: Text('Preview PDF'),
            ),
            ElevatedButton(
              onPressed: () {
                pdfGenerator.generatePdf(preview: false); // Download PDF
              },
              child: Text('Download PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
