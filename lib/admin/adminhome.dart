import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mad/admin/admin_home_widgets/blogsPart.dart';
import 'package:mad/admin/admin_home_widgets/leftsidebar.dart';
import 'package:mad/admin/post_provider.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({Key? key}) : super(key: key);

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  // Placeholder data for lists
  List<String> blogsPosted = [
    'Blog Post 1',
    'Blog Post 2',
    'Blog Post 3',
  ];

  List<String> donations = [
    'Donation 1',
    'Donation 2',
    'Donation 3',
  ];

  List<String> messages = [
    'Message 1',
    'Message 2',
    'Message 3',
  ];

  List<String> requests = [
    'Request 1',
    'Request 2',
    'Request 3',
  ];

  // Variables to track which section to display
  bool showingDonations = false;
  late String? userEmail;
  late String? userName;
  late String? userProfilePicture;
  bool isLoading = true; // New variable to track loading state

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userEmail = user.email;
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Profiles')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        setState(() {
          userName = userData['username'];
          userProfilePicture = userData['profilePicture'];
          isLoading = false; // Data fetching complete, set isLoading to false
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    LikeState likeState = LikeState();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        title: Text('Admin Dashboard'),
        bottomOpacity: 100,
      ),
      body: isLoading // Check if data is still loading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : Row(
              children: [
                // Left Sidebar for Adoption Requests
                LeftSideBar(
                  userName: userName,
                  userProfilePicture: userProfilePicture,
                  requests: requests,
                ),
                SizedBox(
                  height: 300,
                ),
                // Middle Content Area for Blogs/Messages
                Expanded(
                  child: MiddlePart(
                      likeState: likeState), // Pass LikeState to MiddlePart
                ),

                // Right Sidebar for Donations/Messages
                Container(
                  width: 250,
                  color: Colors.grey[200],
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        title: Text(
                          showingDonations ? 'Donations' : 'Messages',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          children: <Widget>[
                            if (showingDonations)
                              for (var donation in donations)
                                ListTile(
                                  title: Text(donation),
                                  leading: Icon(Icons.attach_money),
                                ),
                            if (!showingDonations)
                              for (var message in messages)
                                ListTile(
                                  title: Text(message),
                                  leading: Icon(Icons.mail),
                                ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  showingDonations = true;
                                });
                              },
                              child: Text('Donations'),
                            ),
                          ),
                          SizedBox(width: 1),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  showingDonations = false;
                                });
                              },
                              child: Text('Messages'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
