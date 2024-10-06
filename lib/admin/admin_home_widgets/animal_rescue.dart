import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mad/admin/report_generation/rescue_list_pdf.dart'; // For formatting timestamp

class AnimalRescue extends StatefulWidget {
  const AnimalRescue({super.key});

  @override
  State<AnimalRescue> createState() => _AnimalRescueState();
}

class _AnimalRescueState extends State<AnimalRescue> {
  final PdfGenerator pdfGenerator = PdfGenerator();

  String? _selectedFilter = 'All';
  final CollectionReference _rescueCollection =
      FirebaseFirestore.instance.collection('Rescue');

  // For formatting timestamp
  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('MMMM dd, yyyy - hh:mm a').format(dateTime);
  }

  Future<void> _sendMessage(
      String userEmail, String status, String rejectionReason) async {
    String messageText;

    if (status == 'Rejected') {
      messageText =
          'We would like to reject your request. Reason: $rejectionReason';
    } else if (status == 'Accepted') {
      messageText =
          'We accept your Rescue Request; we will contact you for more details.';
    } else if (status == 'Rescued') {
      messageText =
          'We successfully rescued the Animal, thank you for your cooperation.';
    } else {
      return; // No message to send for other statuses
    }

    // Prepare the message data
    Map<String, dynamic> messageData = {
      'receiverEmail': userEmail,
      'senderEmail': 'ivory@gmail.com',
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Send message to admin_messages collection
    FirebaseFirestore.instance
        .collection('admin_messages')
        .add(messageData)
        .then((_) {
      print("Message sent to user successfully");

      // Add to Notifications collection
      FirebaseFirestore.instance.collection('Notifications').add({
        'title': 'Rescue Update',
        'body': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'email': userEmail,
        'isSeen': false,
      }).then((_) {
        print("Notification added successfully");
      }).catchError((error) {
        print("Failed to add notification: $error");
      });

      // Update UserNewMessage collection
      DocumentReference userNewMessageDoc = FirebaseFirestore.instance
          .collection('UserNewMessage')
          .doc(userEmail);
      FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userNewMessageDoc);
        if (!snapshot.exists) {
          // If the document does not exist, create it with notificationCount set to 1 and LastMessage set
          transaction.set(userNewMessageDoc, {
            'notificationCount': 1,
            'email': userEmail,
            'LastMessage': 'You: $messageText',
            'ReceivedCount': 1,
          });
        } else {
          // If the document exists, increment the notificationCount field and update LastMessage
          Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
          int newCount = (data?['notificationCount'] ?? 0) + 1;
          int newCount1 = (data?['ReceivedCount'] ?? 0) + 1;

          transaction.update(userNewMessageDoc, {
            'notificationCount': newCount,
            'LastMessage': 'You: $messageText',
            'ReceivedCount': newCount1,
          });
        }
      });
    }).catchError((error) {
      print("Failed to send message: $error");
    });
  }

  // Show dialog for accepting/rejecting rescue request
  void _showResponseDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final docId = doc.id;

    String rejectionReason = '';
    bool isRejecting = false; // Track whether we are rejecting

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Accept or Reject Rescue Request'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Would you like to accept this rescue request?'),
                  const SizedBox(height: 20),

                  // Show the rejection reason text field only if rejecting
                  if (isRejecting)
                    TextField(
                      onChanged: (value) {
                        rejectionReason = value;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Rejection Reason',
                        hintText: 'Enter reason for rejection',
                      ),
                    ),
                ],
              ),
              actions: [
                // Show Accept and Reject buttons if not rejecting
                if (!isRejecting) ...[
                  ElevatedButton(
                    onPressed: () async {
                      // Update status to "Accepted"
                      await _rescueCollection.doc(docId).update({
                        'status': 'Accepted',
                      });
                      await _sendMessage(
                          data['rescuerEmail'], 'Accepted', ''); // Send message
                      Navigator.of(context).pop(); // Close dialog
                    },
                    child: const Text('Accept'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isRejecting = true; // Show rejection reason field
                      });
                    },
                    child: const Text('Reject'),
                  ),
                ],
                // Show Submit Rejection button if rejecting
                if (isRejecting)
                  ElevatedButton(
                    onPressed: () async {
                      // Update status to "Rejected" with reason
                      if (rejectionReason.isNotEmpty) {
                        await _rescueCollection.doc(docId).update({
                          'status': 'Rejected',
                          'reasonForReject': rejectionReason,
                        });
                        await _sendMessage(data['rescuerEmail'], 'Rejected',
                            rejectionReason); // Send message
                        Navigator.of(context).pop(); // Close dialog
                      } else {
                        // Show error if reason is not provided
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Please enter a reason for rejection'),
                          ),
                        );
                      }
                    },
                    child: const Text('Submit Rejection'),
                  ),

                // Cancel button to reset rejecting state
                if (isRejecting)
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isRejecting = false; // Reset to not rejecting
                        rejectionReason = ''; // Clear rejection reason
                      });
                    },
                    child: const Text('Cancel'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rescue Animal Requests'),
        centerTitle: true,
        titleSpacing: 0,
        actions: <Widget>[
          Tooltip(
            message: 'Print Requests List',
            child: IconButton(
              icon: Icon(Icons.print),
              onPressed: () {
                pdfGenerator.generateRescuePdf(
                    selectedSpecies: _selectedFilter!, preview: true);
              },
            ),
          ),
          Tooltip(
            message: 'Download Requests List',
            child: IconButton(
              icon: Icon(Icons.download),
              onPressed: () {
                pdfGenerator.generateRescuePdf(
                    selectedSpecies: _selectedFilter!, preview: false);
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
                      style:
                          const TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _rescueCollection.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No rescue requests available.'));
          }

          // Retrieve the documents from the Firestore snapshot
          final rescueDocs = snapshot.data!.docs;

          // Sort the documents based on the timestamp in descending order
          final sortedRescueDocs = List.from(rescueDocs)
            ..sort((a, b) {
              final aTimestamp =
                  (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
              final bTimestamp =
                  (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp;
              return bTimestamp
                  .compareTo(aTimestamp); // Sort from newest to oldest
            });

          // Filter the sorted documents based on the selected filter
          final filteredRescueDocs = sortedRescueDocs.where((doc) {
            final species = (doc.data() as Map<String, dynamic>)['species'];
            return _selectedFilter == 'All' || species == _selectedFilter;
          }).toList();

          return Center(
            child: Container(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal, // Allow horizontal scrolling
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical, // Allow vertical scrolling
                  child: DataTable(
                    columnSpacing: 10.0, // Adjust column spacing as needed
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: const Color(0xFFE96560), // Border color
                        width: 0.5, // Border width
                      ),
                    ),
                    headingRowColor: MaterialStateColor.resolveWith(
                      (states) => const Color(0xFFE96560), // Header row color
                    ),
                    dataRowHeight: 80.0, // Adjust row height as needed
                    columns: const [
                      DataColumn(
                          label: Center(
                        child: Text('Image',
                            style: TextStyle(color: Colors.white)),
                      )),
                      DataColumn(
                          label: Center(
                        child: Text('Rescuer Name',
                            style: TextStyle(color: Colors.white)),
                      )),
                      DataColumn(
                          label: Center(
                        child: Text('Rescuer Email',
                            style: TextStyle(color: Colors.white)),
                      )),
                      DataColumn(
                          label: Center(
                        child: Text('Rescuer Number',
                            style: TextStyle(color: Colors.white)),
                      )),
                      DataColumn(
                          label: Center(
                        child: Text('Animal',
                            style: TextStyle(color: Colors.white)),
                      )),
                      DataColumn(
                          label: Center(
                        child: Text('Animal Condition',
                            style: TextStyle(color: Colors.white)),
                      )),
                      DataColumn(
                          label: Center(
                        child: Text('Rescue Reason',
                            style: TextStyle(color: Colors.white)),
                      )),
                      DataColumn(
                          label: Center(
                        child: Text('Location',
                            style: TextStyle(color: Colors.white)),
                      )),
                      DataColumn(
                          label: Center(
                        child: Text('Timestamp',
                            style: TextStyle(color: Colors.white)),
                      )),
                      DataColumn(
                          label: Center(
                        child: Text('Status',
                            style: TextStyle(color: Colors.white)),
                      )),
                      DataColumn(
                          label: Center(
                        child: Text('Action',
                            style: TextStyle(color: Colors.white)),
                      )),
                    ],
                    rows: filteredRescueDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      return DataRow(cells: [
                        // Image
                        DataCell(
                          Padding(
                            padding: const EdgeInsets.all(
                                4.0), // Less padding for the image
                            child: data['imageUrl'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      data['imageUrl'],
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.fill,
                                    ),
                                  )
                                : Text('No image'),
                          ),
                        ),
                        // Rescuer Name
                        DataCell(
                          Container(
                            constraints:
                                BoxConstraints(maxWidth: 100), // Set max width
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4.0), // Less vertical padding
                              child: Text(data['rescuerName'] ?? 'Unknown',
                                  overflow: TextOverflow.visible,
                                  maxLines: 2, // Allow wrapping to two lines
                                  style: TextStyle(
                                      height: 1.2)), // Adjust line height
                            ),
                          ),
                        ),
                        // Rescuer Email
                        DataCell(
                          Container(
                            constraints:
                                BoxConstraints(maxWidth: 150), // Set max width
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4.0), // Less vertical padding
                              child: Text(data['rescuerEmail'] ?? 'Unknown',
                                  overflow: TextOverflow.visible,
                                  maxLines: 2, // Allow wrapping to two lines
                                  style: TextStyle(
                                      height: 1.2)), // Adjust line height
                            ),
                          ),
                        ),
                        // Rescuer Contact
                        DataCell(
                          Container(
                            constraints:
                                BoxConstraints(maxWidth: 100), // Set max width
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4.0), // Less vertical padding
                              child: Text(data['rescuerContact'] ?? 'Unknown',
                                  overflow: TextOverflow.visible,
                                  maxLines: 2, // Allow wrapping to two lines
                                  style: TextStyle(
                                      height: 1.2)), // Adjust line height
                            ),
                          ),
                        ),
                        // Animal
                        DataCell(
                          Container(
                            constraints:
                                BoxConstraints(maxWidth: 100), // Set max width
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4.0), // Less vertical padding
                              child: Text(data['species'] ?? 'Unknown',
                                  overflow: TextOverflow.visible,
                                  maxLines: 2, // Allow wrapping to two lines
                                  style: TextStyle(
                                      height: 1.2)), // Adjust line height
                            ),
                          ),
                        ),
                        // Animal Condition
                        DataCell(
                          Container(
                            constraints:
                                BoxConstraints(maxWidth: 150), // Set max width
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4.0), // Less vertical padding
                              child: Text(data['animalCondition'] ?? 'Unknown',
                                  overflow: TextOverflow.visible,
                                  maxLines: 2, // Allow wrapping to two lines
                                  style: TextStyle(
                                      height: 1.2)), // Adjust line height
                            ),
                          ),
                        ),
                        // Rescue Reason
                        DataCell(
                          Container(
                            constraints:
                                BoxConstraints(maxWidth: 150), // Set max width
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4.0), // Less vertical padding
                              child: Text(data['rescueReason'] ?? 'Unknown',
                                  overflow: TextOverflow.visible,
                                  maxLines: 2, // Allow wrapping to two lines
                                  style: TextStyle(
                                      height: 1.2)), // Adjust line height
                            ),
                          ),
                        ),
                        // Location
                        DataCell(
                          Container(
                            constraints:
                                BoxConstraints(maxWidth: 100), // Set max width
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4.0), // Less vertical padding
                              child: Text(data['location'] ?? 'Unknown',
                                  overflow: TextOverflow.visible,
                                  maxLines: 2, // Allow wrapping to two lines
                                  style: TextStyle(
                                      height: 1.2)), // Adjust line height
                            ),
                          ),
                        ),
                        // Timestamp
                        DataCell(
                          Center(
                            child: Container(
                              constraints: BoxConstraints(
                                  maxWidth: 150), // Set max width
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4.0), // Less vertical padding
                                child: Text(
                                    data['timestamp'] != null
                                        ? formatTimestamp(data['timestamp'])
                                        : 'Unknown',
                                    overflow: TextOverflow.visible,
                                    maxLines: 2, // Allow wrapping to two lines
                                    style: TextStyle(
                                        height: 1.2)), // Adjust line height
                              ),
                            ),
                          ),
                        ),
                        // Status
                        DataCell(
                          Container(
                            constraints:
                                BoxConstraints(maxWidth: 100), // Set max width
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4.0), // Less vertical padding
                              child: Text(data['status'] ?? 'Unknown',
                                  overflow: TextOverflow.visible,
                                  maxLines: 2, // Allow wrapping to two lines
                                  style: TextStyle(
                                      height: 1.2)), // Adjust line height
                            ),
                          ),
                        ),
                        // Action Button
                        DataCell(
                          Center(
                            child: data['status'] == 'Rejected'
                                ? ElevatedButton(
                                    onPressed: null, // Disable button
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent
                                          .withOpacity(0.5), // Faded red
                                    ),
                                    child: const Text('Rejected'),
                                  )
                                : data['status'] == 'Rescued'
                                    ? ElevatedButton(
                                        onPressed: null, // Disable button
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.greenAccent
                                              .withOpacity(0.5), // Faded green
                                        ),
                                        child: const Text('Rescued'),
                                      )
                                    : ElevatedButton(
                                        onPressed: () async {
                                          // Check the status and respond accordingly
                                          if (data['status'] == 'Accepted') {
                                            // Update status to "Rescued"
                                            await _rescueCollection
                                                .doc(doc.id)
                                                .update({
                                              'status': 'Rescued',
                                              'rescueDate': Timestamp.now(),
                                            });
                                            // Send message for "Rescued" status
                                            await _sendMessage(
                                                data['rescuerEmail'],
                                                'Rescued',
                                                '');
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Status updated to Rescued'),
                                              ),
                                            );
                                          } else {
                                            // Show response dialog for other statuses
                                            _showResponseDialog(doc);
                                          }
                                        },
                                        child: Text(data['status'] == 'Accepted'
                                            ? 'Finish Up'
                                            : 'Respond'),
                                      ),
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
