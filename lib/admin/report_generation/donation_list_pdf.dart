import 'dart:html' as html;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfGenerator {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> generatePdf({
    required DateTime startDate,
    required DateTime endDate,
    required String selectedModeOfPayment, // New parameter for payment mode
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

    // Query to fetch donations
    final snapshot = await _firestore.collection('Donations').get();

    final data = snapshot.docs.map((doc) => doc.data()).toList();

    // Filter data by date range and selected mode of payment
    final filteredData = data.where((donation) {
      final dateOfDonation = donation['DateOfDonation'];
      if (dateOfDonation == null) return false;

      DateTime donationDate;
      if (dateOfDonation is Timestamp) {
        donationDate = dateOfDonation.toDate();
      } else {
        try {
          donationDate = DateTime.parse(dateOfDonation.toString()).toLocal();
        } catch (_) {
          return false;
        }
      }

      // Check if the donation matches the selected mode of payment
      final modeOfPayment = donation['modeOfPayment'] ?? '';

      // Modify this line to check for "All" payment mode
      return donationDate.isAfter(startDate) &&
          donationDate.isBefore(endDate) && // Fix the placement of parentheses
          (selectedModeOfPayment == 'All' ||
              modeOfPayment == selectedModeOfPayment);
    }).toList();

    // Generate pages for donations
    for (var i = 0; i < filteredData.length; i += 13) {
      final chunk = filteredData.sublist(
          i, (i + 13 < filteredData.length) ? i + 13 : filteredData.length);

      // Calculate total amount for this chunk
      final totalAmount = chunk.fold<double>(0, (sum, donation) {
        final amountStr = donation['amount']?.toString() ?? '0';
        final amount = double.tryParse(amountStr) ?? 0;
        return sum + amount;
      });

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
                    pw.Text('Donation Report',
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
                      0: pw.FlexColumnWidth(1.5),
                      1: pw.FlexColumnWidth(2.3),
                      2: pw.FlexColumnWidth(2),
                      3: pw.FlexColumnWidth(1.3),
                      4: pw.FlexColumnWidth(1.3),
                      5: pw.FlexColumnWidth(2.5),
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
                              child: pw.Text('Email',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(8.0),
                              child: pw.Text('Date Of Donation',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(8.0),
                              child: pw.Text('Amount',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(8.0),
                              child: pw.Text('Mode of Donation',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10))),
                          pw.Padding(
                              padding: pw.EdgeInsets.all(8.0),
                              child: pw.Text('Donor Message',
                                  style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 10))),
                        ],
                      ),
                      // Data Rows
                      for (var donation in chunk)
                        pw.TableRow(
                          children: [
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text(donation['name'] ?? '',
                                    style: pw.TextStyle(fontSize: 10))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text(donation['email'] ?? '',
                                    style: pw.TextStyle(fontSize: 10))),
                            pw.Padding(
                              padding: pw.EdgeInsets.all(8.0),
                              child: pw.Text(
                                  donation['DateOfDonation'] != null
                                      ? formatDonationDate(
                                          donation['DateOfDonation'])
                                      : 'Invalid Date',
                                  style: pw.TextStyle(fontSize: 10)),
                            ),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text(donation['amount'] ?? '',
                                    style: pw.TextStyle(fontSize: 10))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text(donation['modeOfPayment'] ?? '',
                                    style: pw.TextStyle(fontSize: 10))),
                            pw.Padding(
                                padding: pw.EdgeInsets.all(8.0),
                                child: pw.Text(donation['message'] ?? '',
                                    style: pw.TextStyle(fontSize: 10))),
                          ],
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                // Total Amount Row
                pw.Padding(
                  padding: pw.EdgeInsets.symmetric(horizontal: 20.0),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Text('TOTAL:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(width: 13),
                      pw.Text(
                        'Php ${totalAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
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
      // ignore: unused_local_variable
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "generated_donation_report.pdf")
        ..click();
    }

    // Revoke the object URL after download or preview to free up resources
    html.Url.revokeObjectUrl(url);
  }

  String formatDonationDate(dynamic dateTime) {
    if (dateTime == null || dateTime.toString().isEmpty) return 'Invalid Date';

    if (dateTime is Timestamp) {
      return "${dateTime.toDate().month.toString().padLeft(2, '0')}/${dateTime.toDate().day.toString().padLeft(2, '0')}/${dateTime.toDate().year} "
          "${dateTime.toDate().hour % 12}:${dateTime.toDate().minute.toString().padLeft(2, '0')} ${dateTime.toDate().hour >= 12 ? 'PM' : 'AM'}";
    }

    try {
      final date = DateTime.parse(dateTime.toString());
      return "${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year} "
          "${date.hour % 12}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}";
    } catch (e) {
      return 'Invalid Date';
    }
  }
}
