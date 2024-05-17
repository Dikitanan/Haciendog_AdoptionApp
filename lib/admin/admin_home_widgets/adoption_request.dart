import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

class AdoptionLists extends StatefulWidget {
  @override
  _AdoptionListsState createState() => _AdoptionListsState();
}

class _AdoptionListsState extends State<AdoptionLists> {
  String _selectedStatus = 'All'; // Default selected status

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adoption Requests'),
        actions: [
          DropdownButton<String>(
            value: _selectedStatus,
            onChanged: (String? newValue) {
              setState(() {
                _selectedStatus = newValue!;
              });
            },
            items: <String>[
              'All',
              'Pending',
              'Accepted',
              'Rejected',
              'Archived',
              'Cancelled'
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _selectedStatus == 'All'
            ? FirebaseFirestore.instance.collection('AdoptionForms').snapshots()
            : FirebaseFirestore.instance
                .collection('AdoptionForms')
                .where('status', isEqualTo: _selectedStatus)
                .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          return ListView(
            children: snapshot.data!.docs.map((document) {
              return ListTile(
                title: Text(
                  document['name'],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('Animal')
                      .doc(document['petId'])
                      .get(),
                  builder: (BuildContext context,
                      AsyncSnapshot<DocumentSnapshot> animalSnapshot) {
                    if (animalSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Text('Loading...');
                    }
                    if (animalSnapshot.hasError) {
                      return Text('Error: ${animalSnapshot.error}');
                    }
                    if (!animalSnapshot.hasData ||
                        !animalSnapshot.data!.exists) {
                      return Text('Pet not found');
                    }
                    var animalData = animalSnapshot.data!;
                    return Text('Pet: ${animalData['Name']}');
                  },
                ),
                trailing: Text(
                  document['status'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: document['status'] == 'Accepted'
                        ? Colors.green
                        : document['status'] == 'Rejected'
                            ? Colors.red
                            : document['status'] == 'Cancelled'
                                ? Colors.red
                                : document['status'] == 'Archived'
                                    ? Colors.yellow
                                    : Colors.blue,
                  ),
                ),
                onTap: () {
                  // Display detailed adoption request form as a dialog
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return WebAdoptionRequestDialog(document: document);
                    },
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class WebAdoptionRequestDialog extends StatelessWidget {
  final QueryDocumentSnapshot<Object?> document;

  const WebAdoptionRequestDialog({Key? key, required this.document})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 50),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 550,
        height: 700,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Adoption Request Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 10),
            SingleChildScrollView(
              child: Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.only(right: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person, color: Colors.grey),
                                SizedBox(width: 5),
                                Text('Name: ${document['name']}',
                                    style: TextStyle(fontSize: 16)),
                              ],
                            ),
                            SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(Icons.work, color: Colors.grey),
                                SizedBox(width: 5),
                                Text('Occupation: ${document['occupation']}',
                                    style: TextStyle(fontSize: 16)),
                              ],
                            ),
                            SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(Icons.cake, color: Colors.grey),
                                SizedBox(width: 5),
                                Text('Age: ${document['age']}',
                                    style: TextStyle(fontSize: 16)),
                              ],
                            ),
                            SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.grey),
                                SizedBox(width: 5),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (document['address'] != null)
                                        Text(
                                          'Address:',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      SizedBox(height: 2),
                                      if (document['address'] != null)
                                        Text(
                                          _formatAddress(document['address']),
                                          style: TextStyle(fontSize: 16),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(Icons.email, color: Colors.grey),
                                SizedBox(width: 5),
                                Text('Email: ${document['email']}',
                                    style: TextStyle(fontSize: 16)),
                              ],
                            ),
                            SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(Icons.info, color: Colors.grey),
                                SizedBox(width: 5),
                                Text('Status: ${document['status']}',
                                    style: TextStyle(fontSize: 16)),
                              ],
                            ),
                            SizedBox(height: 10),
                            Text('Self Description:',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 5),
                            Text(document['selfDescription'],
                                style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Proof of Capability',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 5),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 200,
                              height: 200,
                              child: Image.network(
                                document['proofOfCapabilityURL'],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40),
            Text(
              'Animal Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.only(right: 20),
                      child: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('Animal')
                            .doc(document['petId'])
                            .get(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot> animalSnapshot) {
                          if (animalSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (animalSnapshot.hasError ||
                              !animalSnapshot.hasData ||
                              !animalSnapshot.data!.exists) {
                            return Text('Animal details not found',
                                style: TextStyle(fontSize: 18));
                          }
                          var animalData = animalSnapshot.data!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Name: ${animalData['Name']}',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(Icons.pets, color: Colors.grey),
                                  SizedBox(width: 5),
                                  Text('Gender: ${animalData['Gender']}',
                                      style: TextStyle(fontSize: 18)),
                                ],
                              ),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(Icons.category, color: Colors.grey),
                                  SizedBox(width: 5),
                                  Text('Breed: ${animalData['Breed']}',
                                      style: TextStyle(fontSize: 18)),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('Animal')
                            .doc(document['petId'])
                            .get(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot> animalSnapshot) {
                          if (animalSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (animalSnapshot.hasError ||
                              !animalSnapshot.hasData ||
                              !animalSnapshot.data!.exists) {
                            return Text('Animal image not found',
                                style: TextStyle(fontSize: 18));
                          }
                          var animalData = animalSnapshot.data!;
                          return Image.network(
                            animalData['Image'],
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: document['status'] == 'Pending'
                  ? [
                      ElevatedButton(
                        onPressed: () {
                          _updateAdoptionStatus(
                            context,
                            document.id,
                            'Rejected',
                            document['email'], // Pass user's email
                          );
                        },
                        child: Text('Decline'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _updateAdoptionStatus(
                            context,
                            document.id,
                            'Accepted',
                            document['email'], // Pass user's email
                          );
                        },
                        child: Text('Accept'),
                      ),
                    ]
                  : [
                      ElevatedButton(
                        onPressed: () {
                          _updateAdoptionStatus(context, document.id, 'Pending',
                              document['email']);
                        },
                        child: Text('Cancel'),
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateAdoptionStatus(BuildContext context, String documentId,
      String status, String userEmail) {
    FirebaseFirestore.instance
        .collection('AdoptionForms')
        .doc(documentId)
        .update({'status': status}).then((_) {
      print("Status updated successfully");

      // Send message to user
      String messageText = status == 'Accepted'
          ? "We would like to inform you that your adoption form is accepted."
          : "We would like to inform you that your adoption form is rejected.";

      Map<String, dynamic> messageData = {
        'receiverEmail': userEmail,
        'senderEmail': 'ivory@gmail.com',
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
      };

      FirebaseFirestore.instance
          .collection('admin_messages')
          .add(messageData)
          .then((_) {
        print("Message sent to user successfully");
        // Close the AdoptionForm details dialog first
        Navigator.pop(context);
        // Show the feedback dialog
        _showDialog(context, 'Form is $status');
      }).catchError((error) {
        print("Failed to send message to user: $error");
        _showDialog(context, 'Failed to send message to user');
      });
    }).catchError((error) {
      print("Failed to update status: $error");
      _showDialog(context, 'Failed to update status');
    });
  }

  void _showDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          title: Text(
            'Status',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16.0,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 18.0,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

String _formatAddress(String address) {
  List<String> words = address.split(' ');
  if (words.length > 4) {
    return '${words.take(4).join(' ')}\n${words.skip(4).join(' ')}';
  } else {
    return address;
  }
}
