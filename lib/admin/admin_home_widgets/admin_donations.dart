import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mad/admin/report_generation/donation_list_pdf.dart';

class AdminDonations extends StatefulWidget {
  const AdminDonations({Key? key}) : super(key: key);

  @override
  State<AdminDonations> createState() => _AdminDonationsState();
}

class _AdminDonationsState extends State<AdminDonations> {
  String _selectedFilter = 'All';
  DateTime _startDate =
      DateTime.now().subtract(Duration(days: 30)); // Default start date
  DateTime _endDate = DateTime.now(); // Default end date
  final PdfGenerator pdfGenerator = PdfGenerator();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donations'),
        actions: [
          // Print Icon Button with Tooltip
          Tooltip(
            message: 'Print',
            child: IconButton(
              icon: const Icon(Icons.print),
              onPressed: () => _handlePrintOrDownload(false),
            ),
          ),
          // Download Icon Button with Tooltip
          Tooltip(
            message: 'Download',
            child: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _handlePrintOrDownload(true),
            ),
          ),
          Tooltip(
            message: 'Filter By Date',
            child: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () {
                // Add your download logic here
                _selectDateRange();
              },
            ),
          ),
          SizedBox(
            width: 20,
          ),
          // Dropdown Button
          DropdownButton<String>(
            value: _selectedFilter,
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedFilter = newValue;
                });
              }
            },
            items: <String>['All', 'Pending', 'Accepted', 'Rejected']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          // Date Range Picker Button
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Donations').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching data'));
          }

          final donations = snapshot.data?.docs ?? [];
          final filteredDonations = donations.where((donation) {
            final status = donation['status'] ?? 'Pending';
            final dateOfDonation =
                (donation['DateOfDonation'] as Timestamp?)?.toDate();

            if (dateOfDonation == null) return false;

            if (_selectedFilter != 'All' && status != _selectedFilter) {
              return false;
            }

            return dateOfDonation.isAfter(_startDate) &&
                dateOfDonation.isBefore(_endDate);
          }).toList();

          // Sort the donations to place 'Pending' status at the top
          filteredDonations.sort((a, b) {
            final statusA = a['status'] ?? 'Pending';
            final statusB = b['status'] ?? 'Pending';
            if (statusA == 'Pending' && statusB != 'Pending') {
              return -1; // Move 'Pending' status to the top
            } else if (statusA != 'Pending' && statusB == 'Pending') {
              return 1; // Move 'Pending' status to the top
            } else {
              // If both statuses are the same or both are not 'Pending',
              // maintain their order
              return 0;
            }
          });

          if (filteredDonations.isEmpty) {
            return const Center(child: Text('No donations found'));
          }

          return ListView.builder(
            itemCount: filteredDonations.length,
            itemBuilder: (context, index) {
              final donation = filteredDonations[index];
              final name = donation['name'] ?? 'Unknown';
              final status = donation['status'] ?? 'Pending';

              Color statusColor;
              switch (status) {
                case 'Accepted':
                  statusColor = Colors.green;
                  break;
                case 'Rejected':
                  statusColor = Colors.red;
                  break;
                case 'Pending':
                default:
                  statusColor = Colors.blue;
                  break;
              }

              return ListTile(
                title: Text(name),
                trailing: Text(
                  status,
                  style: TextStyle(color: statusColor),
                ),
                onTap: () => _showDonationDetails(context, donation),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handlePrintOrDownload(bool isPrint) async {
    final donationsSnapshot =
        await FirebaseFirestore.instance.collection('Donations').get();

    final donations = donationsSnapshot.docs;
    final filteredDonations = donations.where((donation) {
      final status = donation['status'] ?? 'Pending';
      final dateOfDonation =
          (donation['DateOfDonation'] as Timestamp?)?.toDate();

      if (dateOfDonation == null) return false;

      if (_selectedFilter != 'All' && status != _selectedFilter) {
        return false;
      }

      return dateOfDonation.isAfter(_startDate) &&
          dateOfDonation.isBefore(_endDate);
    }).toList();

    if (filteredDonations.isEmpty) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('No Donations'),
            content: const Text(
                'No donations available for the selected filter and date range.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
      return;
    }

    pdfGenerator.generatePdf(
      preview: !isPrint,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  Future<void> _selectDateRange() async {
    final initialStartDate = _startDate;
    final initialEndDate = _endDate;

    final DateTimeRange? pickedDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange:
          DateTimeRange(start: initialStartDate, end: initialEndDate),
    );

    if (pickedDateRange != null) {
      setState(() {
        _startDate = pickedDateRange.start;
        _endDate = pickedDateRange.end;
      });
    }
  }

  void _showDonationDetails(
      BuildContext context, DocumentSnapshot donation) async {
    final email = donation['email'] ?? 'No email';
    final message = donation['message'] ?? 'No message';
    final name = donation['name'] ?? 'No name';
    final username = donation['username'] ?? 'No username';
    final proofOfDonation = donation['proofOfDonation'] ?? '';
    final amount = donation['amount'] ?? '';
    final DateOfDonation =
        (donation['DateOfDonation'] as Timestamp?)?.toDate() ?? DateTime.now();
    final status = donation['status'] ?? 'Pending';

    String imageUrl = '';
    if (proofOfDonation.isNotEmpty) {
      imageUrl =
          await FirebaseStorage.instance.ref(proofOfDonation).getDownloadURL();
    }

    // Function to add notification to the Notifications collection
    Future<void> _addNotification(String body) async {
      await FirebaseFirestore.instance.collection('Notifications').add({
        'body': body,
        'email': email,
        'isSeen': false,
        'timestamp': Timestamp.now(),
        'title': 'Donation Update',
      });
    }

    // Function to update or add a document in UserNewMessage collection
    Future<void> _updateUserNewMessage() async {
      final userMessageRef = FirebaseFirestore.instance
          .collection('UserNewMessage')
          .where('email', isEqualTo: email);

      final snapshot = await userMessageRef.get();

      if (snapshot.docs.isNotEmpty) {
        // If a document with the email exists, update the notificationCount
        final doc = snapshot.docs.first;
        await doc.reference.update({
          'notificationCount': FieldValue.increment(1),
        });
      } else {
        // If no document exists, create a new one
        await FirebaseFirestore.instance.collection('UserNewMessage').add({
          'notificationCount': 1,
          'LastMessage': ' ',
          'email': email,
          'messageCount': 0,
          'totalMessage': 0,
        });
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close),
              ),
            ],
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Email: $email'),
              Text('Message: $message'),
              Text('Username: $username'),
              Text('Amount: $amount'),
              Text(
                'Date: ${DateOfDonation.day}/${DateOfDonation.month}/${DateOfDonation.year} '
                '${DateOfDonation.hour % 12}:${DateOfDonation.minute.toString().padLeft(2, '0')} '
                '${DateOfDonation.hour >= 12 ? 'PM' : 'AM'}',
              ),
              const SizedBox(height: 10),
              imageUrl.isNotEmpty
                  ? Container(
                      height: 300,
                      width: 200,
                      child: Image.network(
                        imageUrl,
                        height: 200,
                        width: 150,
                        fit: BoxFit.fill,
                      ),
                    )
                  : const Text('No proof of donation provided'),
            ],
          ),
          actions: status == 'Pending'
              ? [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        child: const Text('Accept'),
                        onPressed: () async {
                          await donation.reference
                              .update({'status': 'Accepted'});
                          await _addNotification(
                              'Thank you for your Donation!');
                          await _updateUserNewMessage();

                          // Add to AdminBlogs Collection
                          await FirebaseFirestore.instance
                              .collection('AdminBlogs')
                              .add({
                            'title': 'New Donation!',
                            'description':
                                'Thank you $name for donating in our Shelter!',
                            'imageURL':
                                'https://firebasestorage.googleapis.com/v0/b/mads-df824.appspot.com/o/thank_you_donation.jpg?alt=media&token=9c04c165-9260-4de3-9f8d-297474ccb7a5',
                            'createdAt': FieldValue.serverTimestamp(),
                            'heartCount': 0,
                            'commentCount': 0,
                            'userEmail': email,
                            'profilePicture':
                                'https://firebasestorage.googleapis.com/v0/b/mads-df824.appspot.com/o/adminpic.jpg?alt=media&token=0fef831c-2c1f-451c-970e-9d264d8adbc5',
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('Reject'),
                        onPressed: () async {
                          await donation.reference
                              .update({'status': 'Rejected'});
                          await _addNotification(
                              'Your donation has been rejected. Reason: Invalid Donation');
                          await _updateUserNewMessage();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ]
              : [
                  TextButton(
                    child: const Text('Close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
        );
      },
    );
  }
}
