import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminDonations extends StatefulWidget {
  const AdminDonations({super.key});

  @override
  State<AdminDonations> createState() => _AdminDonationsState();
}

class _AdminDonationsState extends State<AdminDonations> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donations'),
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

          if (donations.isEmpty) {
            return const Center(child: Text('No donations found'));
          }

          return ListView.builder(
            itemCount: donations.length,
            itemBuilder: (context, index) {
              final donation = donations[index];
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

  void _showDonationDetails(
      BuildContext context, DocumentSnapshot donation) async {
    final email = donation['email'] ?? 'No email';
    final message = donation['message'] ?? 'No message';
    final name = donation['name'] ?? 'No name';
    final username = donation['username'] ?? 'No username';
    final proofOfDonation = donation['proofOfDonation'] ?? '';
    final amount = donation['amount'] ?? '';
    final status = donation['status'] ?? 'Pending';

    String imageUrl = '';
    if (proofOfDonation.isNotEmpty) {
      imageUrl =
          await FirebaseStorage.instance.ref(proofOfDonation).getDownloadURL();
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
              const SizedBox(height: 10),
              imageUrl.isNotEmpty
                  ? Image.network(imageUrl, height: 200)
                  : const Text('No proof of donation provided'),
            ],
          ),
          actions: status == 'Pending'
              ? [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () async {
                          // Function for accepting donation
                          await FirebaseFirestore.instance
                              .collection('Donations')
                              .doc(donation.id)
                              .update({'status': 'Accepted'});

                          // Add to AdminBlogs Collection
                          await FirebaseFirestore.instance
                              .collection('AdminBlogs')
                              .add({
                            'title': 'New Donation!',
                            'description':
                                'Thank you $name for donating in our Shelter!',
                            'imageURL':
                                'https://firebasestorage.googleapis.com/v0/b/mads-df824.appspot.com/o/thank_you_donation.jpg?alt=media&token=c457ecd4-275d-4517-986d-42c3997ba988', // Using proofOfDonation as imageURL
                            'createdAt': FieldValue.serverTimestamp(),
                            'heartCount': 0,
                            'commentCount': 0,
                            'userEmail': email,
                            'profilePicture':
                                'https://firebasestorage.googleapis.com/v0/b/mads-df824.appspot.com/o/adminpic.jpg?alt=media&token=0690002b-83e0-49c1-8c43-c55336b5bde0',
                            'username': 'Donation Bot',
                          });

                          Navigator.of(context)
                              .pop(); // Close dialog after updating
                        },
                        icon: Icon(Icons.check, color: Colors.green),
                      ),
                      IconButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('Donations')
                              .doc(donation.id)
                              .update({'status': 'Rejected'});

                          Navigator.of(context).pop();
                        },
                        icon: Icon(Icons.close, color: Colors.red),
                      ),
                    ],
                  ),
                ]
              : [], // Empty list if status is not "Pending"
        );
      },
    );
  }
}
