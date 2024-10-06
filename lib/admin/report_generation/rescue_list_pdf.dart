import 'dart:html' as html;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> generateRescuePdf({
    required String selectedSpecies, // New parameter for species
    bool preview = false,
  }) async {
    final pdf = pw.Document();
    const double pageWidth = 595.27; // A4 width in points
    const double pageHeight = 841.89; // A4 height in points
    final Uint8List imageBytes =
        (await rootBundle.load('assets/icons/haciendoglogo.jpg'))
            .buffer
            .asUint8List();
    final image = pw.MemoryImage(imageBytes);
    // Query to fetch rescues
    final snapshot = await _firestore.collection('Rescue').get();
    final data = snapshot.docs.map((doc) => doc.data()).toList();

    // Filter data by species
    final filteredData = data.where((rescue) {
      final species = rescue['species'] ?? '';
      return selectedSpecies == 'All' || species == selectedSpecies;
    }).toList();

    // Group data by status
    final groupedData = <String, List<Map<String, dynamic>>>{};
    for (var rescue in filteredData) {
      final status = rescue['status'] ?? 'Unknown';
      if (!groupedData.containsKey(status)) {
        groupedData[status] = [];
      }
      groupedData[status]!.add(rescue);
    }

    // Define the desired order of statuses
    const statusOrder = ['Rescued', 'Accepted', 'Rejected', 'Pending'];

    // Sort the keys based on the defined order
    final sortedKeys =
        statusOrder.where((status) => groupedData.containsKey(status)).toList();

    // Create pages for each status group in the defined order
    for (var status in sortedKeys) {
      final chunk = groupedData[status]!;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(pageWidth, pageHeight),
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Container(
                  height: 90,
                  width: 90,
                  child: pw.Image(image),
                ),
                // Header
                pw.Text('Rescue Report - Status: $status',
                    style: pw.TextStyle(
                        fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                // Table with padding
                pw.Padding(
                  padding: pw.EdgeInsets.symmetric(horizontal: 20.0),
                  child: pw.Table(
                    border:
                        pw.TableBorder.all(width: 0.5, color: PdfColors.grey),
                    columnWidths: {
                      0: pw.FlexColumnWidth(2), // Rescuer Name
                      1: pw.FlexColumnWidth(2), // Rescuer Email
                      2: pw.FlexColumnWidth(2), // Rescuer Contact
                      3: pw.FlexColumnWidth(2), // Species
                      4: pw.FlexColumnWidth(2), // Animal Condition
                      5: pw.FlexColumnWidth(2), // Rescue Reason
                      6: pw.FlexColumnWidth(2), // Location
                      7: pw.FlexColumnWidth(2), // Timestamp
                      8: pw.FlexColumnWidth(2), // Status
                    },
                    children: [
                      // Header Row
                      pw.TableRow(
                        decoration: pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          pw.Padding(
                              padding: pw.EdgeInsets.all(8.0),
                              child: pw.Text('Rescuer Name',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8.5))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(8.0),
                              child: pw.Text('Rescuer Email',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8.5))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(8.0),
                              child: pw.Text('Rescuer Contact',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8.5))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(8.0),
                              child: pw.Text('Animal (Cat or Dog)',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8.5))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(8.0),
                              child: pw.Text('Animal Condition',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8.5))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(8.0),
                              child: pw.Text('Rescue Reason',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8.5))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(8.0),
                              child: pw.Text('Location',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8.5))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(8.0),
                              child: pw.Text('Request Date',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8.5))),
                          // Add "Rescue Date" header if status is "Rescued"
                          if (status == 'Rescued')
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text('Rescue Date',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 8.5))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(8.0),
                              child: pw.Text('Status',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 8.5))),
                        ],
                      ),
                      // Data Rows for each rescue in the chunk
                      for (var rescue in chunk)
                        pw.TableRow(
                          children: [
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text(rescue['rescuerName'] ?? '',
                                    style: pw.TextStyle(fontSize: 8.5))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text(rescue['rescuerEmail'] ?? '',
                                    style: pw.TextStyle(fontSize: 8.5))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text(rescue['rescuerContact'] ?? '',
                                    style: pw.TextStyle(fontSize: 8.5))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text(rescue['species'] ?? '',
                                    style: pw.TextStyle(fontSize: 8.5))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text(rescue['animalCondition'] ?? '',
                                    style: pw.TextStyle(fontSize: 8.5))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text(rescue['rescueReason'] ?? '',
                                    style: pw.TextStyle(fontSize: 8.5))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text(rescue['location'] ?? '',
                                    style: pw.TextStyle(fontSize: 8.5))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text(
                                    rescue['timestamp'] != null
                                        ? formatTimestamp(rescue['timestamp'])
                                        : 'Unknown',
                                    style: pw.TextStyle(fontSize: 8.5))),
                            // Add "Rescue Date" cell if status is "Rescued"
                            if (status == 'Rescued')
                              pw.Padding(
                                  padding: pw.EdgeInsets.all(8.0),
                                  child: pw.Text(
                                      rescue['rescueDate'] != null
                                          ? formatTimestamp(
                                              rescue['rescueDate'])
                                          : 'Unknown',
                                      style: pw.TextStyle(fontSize: 8.5))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text(rescue['status'] ?? '',
                                    style: pw.TextStyle(fontSize: 8.5))),
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
                pw.SizedBox(height: 25),
                // Signature line
                pw.Container(
                  width: 200,
                  child: pw.DecoratedBox(
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(width: 1, color: PdfColors.black),
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
        ..setAttribute("download", "generated_rescue_report.pdf")
        ..click();
    }

    // Revoke the object URL after download or preview to free up resources
    html.Url.revokeObjectUrl(url);
  }

  String formatTimestamp(Timestamp timestamp) {
    // Format the timestamp to a readable string
    final dateTime = timestamp.toDate();
    return '${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute}';
  }
}
