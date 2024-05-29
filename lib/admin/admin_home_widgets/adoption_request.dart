import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

class AdoptionLists extends StatefulWidget {
  @override
  _AdoptionListsState createState() => _AdoptionListsState();
}

class _AdoptionListsState extends State<AdoptionLists> {
  String _selectedStatus = 'All';
  Stream<Map<String, int>> statusCountsStream = (() {
    return FirebaseFirestore.instance
        .collection('AdoptionForms')
        .snapshots()
        .map((snapshot) {
      final statuses = [
        'Pending',
        'Accepted',
        'Rejected',
        'Shipped',
        'Adopted',
        'Cancelled',
        'Archived'
      ];
      Map<String, int> counts = {for (var status in statuses) status: 0};
      for (var doc in snapshot.docs) {
        final status = doc['status'];
        if (counts.containsKey(status)) {
          counts[status] = counts[status]! + 1;
        }
      }
      return counts;
    });
  })();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adoption Requests'),
        actions: [
          StreamBuilder<Map<String, int>>(
            stream: statusCountsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return DropdownButton<String>(
                  value: _selectedStatus,
                  items: [DropdownMenuItem(value: 'All', child: Text('All'))],
                  onChanged: null,
                );
              }
              final statusCounts = snapshot.data!;
              return DropdownButton<String>(
                value: _selectedStatus,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedStatus = newValue!;
                  });
                },
                items: <String>[
                  'All',
                  ...statusCounts.keys.toList(),
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value == 'All'
                          ? 'All'
                          : '$value (${statusCounts[value] ?? 0})',
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _selectedStatus == 'All'
            ? FirebaseFirestore.instance
                .collection('AdoptionForms')
                .where('status', isNotEqualTo: 'Archived')
                .snapshots()
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

          // Filter out 'Adopted' status if _selectedStatus is 'All'
          final documents = _selectedStatus == 'All'
              ? snapshot.data!.docs
                  .where((doc) => doc['status'] != 'Adopted')
                  .toList()
              : snapshot.data!.docs;

          return ListView(
            children: documents.map((document) {
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
                        : document['status'] == 'Rejected' ||
                                document['status'] == 'Cancelled'
                            ? Colors.red
                            : document['status'] == 'Archived'
                                ? Colors.yellow
                                : document['status'] == 'Shipped' ||
                                        document['status'] == 'Adopted'
                                    ? Colors.green
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
                                Flexible(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Email: ',
                                          style: TextStyle(
                                              fontSize: 16, color: Colors.grey),
                                        ),
                                        TextSpan(
                                          text: document['email'].length > 12
                                              ? document['email']
                                                  .substring(0, 12)
                                              : document['email'],
                                          style: TextStyle(
                                              fontSize: 16, color: Colors.grey),
                                        ),
                                        if (document['email'].length > 12)
                                          TextSpan(
                                            text:
                                                '\n${document['email'].substring(12)}',
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
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
                            Text('Reason for Adopting:',
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
              children: document['status'] != 'Archived'
                  ? [
                      if (document['status'] == 'Pending')
                        ElevatedButton(
                          onPressed: () {
                            _updateAdoptionStatus(
                              context,
                              document.id,
                              'Rejected',
                              document['email'], // Pass user's email
                              document['petId'], // Pass pet ID
                            );
                          },
                          child: Text('Decline'),
                        ),
                      if (document['status'] == 'Pending')
                        ElevatedButton(
                          onPressed: () {
                            _updateAdoptionStatus(
                              context,
                              document.id,
                              'Accepted',
                              document['email'], // Pass user's email
                              document['petId'], // Pass pet ID
                            );
                          },
                          child: Text('Accept'),
                        ),
                      if (document['status'] == 'Accepted')
                        ElevatedButton(
                          onPressed: () {
                            _updateAdoptionStatus(
                              context,
                              document.id,
                              'Shipped',
                              document['email'], // Pass user's email
                              document['petId'], // Pass pet ID
                            );
                          },
                          child: Text('Ship'),
                        ),
                      if (document['status'] == 'Cancelled') Container(),
                      if (document['status'] == 'Shipped')
                        ElevatedButton(
                          onPressed: () {
                            _updateAdoptionStatus(
                              context,
                              document.id,
                              'Adopted',
                              document['email'], // Pass user's email
                              document['petId'], // Pass pet ID
                            );
                          },
                          child: Text('Done'),
                        ),
                      if (document['status'] != 'Pending' &&
                          document['status'] != 'Adopted' &&
                          document['status'] != 'Cancelled')
                        ElevatedButton(
                          onPressed: () {
                            _updateAdoptionStatus(
                              context,
                              document.id,
                              'Pending',
                              document['email'],
                              document['petId'],
                            );
                          },
                          child: Text('Cancel'),
                        ),
                    ]
                  : [], // Empty list if status is "Archived"
            ),
          ],
        ),
      ),
    );
  }

  void _updateAdoptionStatus(BuildContext context, String documentId,
      String status, String userEmail, String petId) {
    FirebaseFirestore.instance
        .collection('AdoptionForms')
        .doc(documentId)
        .update({'status': status}).then((_) {
      print("Status updated successfully");

      // Update the animal's status based on the adoption form status
      String animalStatus = '';
      if (status == 'Accepted') {
        animalStatus = 'Reserved';
      } else if (status == 'Shipped') {
        animalStatus = 'Shipped';
      } else if (status == 'Adopted') {
        animalStatus = 'Adopted';
      } else if (status == 'Pending') {
        animalStatus = 'Unadopted';
      }

      if (animalStatus.isNotEmpty) {
        FirebaseFirestore.instance
            .collection('Animal')
            .doc(petId)
            .update({'Status': animalStatus}).then((_) {
          print("Animal status updated to $animalStatus");
        }).catchError((error) {
          print("Failed to update animal status: $error");
          _showDialog(context, 'Failed to update animal status');
        });
      }

      // Get the name of the animal
      String animalName = "";
      FirebaseFirestore.instance
          .collection('Animal')
          .doc(petId)
          .get()
          .then((animalSnapshot) {
        animalName = animalSnapshot.data()?['Name'];

        // Construct message text based on status
        String messageText = status == 'Accepted'
            ? "We would like to inform you that your adoption form for $animalName is accepted."
            : (status == 'Pending'
                ? "We would like to inform you that your adoption form for $animalName is cancelled."
                : (status == 'Shipped'
                    ? "We would like to inform you that your pet $animalName is shipped."
                    : (status == 'Adopted'
                        ? "We would like to inform you that your adoption process with $animalName is done."
                        : "We would like to inform you that your adoption form for $animalName is rejected.")));

        // Send message to user
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

          // Add to Notifications collection
          FirebaseFirestore.instance.collection('Notifications').add({
            'title': 'Adoption Update',
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
            DocumentSnapshot snapshot =
                await transaction.get(userNewMessageDoc);
            if (!snapshot.exists) {
              // If the document does not exist, create it with notificationCount set to 1
              transaction.set(userNewMessageDoc, {'notificationCount': 1});
            } else {
              // If the document exists, increment the notificationCount field
              Map<String, dynamic>? data =
                  snapshot.data() as Map<String, dynamic>?;
              int newCount = (data?['notificationCount'] ?? 0) + 1;
              transaction
                  .update(userNewMessageDoc, {'notificationCount': newCount});
            }
          }).then((_) {
            print("UserNewMessage notification count updated successfully");
          }).catchError((error) {
            print("Failed to update UserNewMessage notification count: $error");
          });

          // Close the AdoptionForm details dialog first
          Navigator.pop(context);
          // Show the feedback dialog
          _showDialog(context, 'Form status is $status');
        }).catchError((error) {
          print("Failed to send message to user: $error");
          _showDialog(context, 'Failed to send message to user');
        });
      }).catchError((error) {
        print("Failed to get animal name: $error");
        _showDialog(context, 'Failed to get animal name');
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
