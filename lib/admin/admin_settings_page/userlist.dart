import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserListsPage extends StatefulWidget {
  @override
  _UserListsPageState createState() => _UserListsPageState();
}

class _UserListsPageState extends State<UserListsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<User>> _fetchUsers() async {
    List<User> users = [];
    try {
      final QuerySnapshot userEmailsSnapshot =
          await _firestore.collection('UserEmails').get();

      for (var userEmailDoc in userEmailsSnapshot.docs) {
        final userEmail = userEmailDoc.data() as Map<String, dynamic>;
        final email = userEmail['email'];
        final isBanned = userEmail['ban'] ?? false; // Get ban status

        final QuerySnapshot profileSnapshot = await _firestore
            .collection('Profiles')
            .where('email', isEqualTo: email)
            .get();

        if (profileSnapshot.docs.isNotEmpty) {
          final username = (profileSnapshot.docs.first.data()
                  as Map<String, dynamic>)['username'] as String? ??
              'Profile Not Set';
          users.add(User(email, username, isBanned));
        } else {
          users.add(User(email, 'Profile Not Set', isBanned));
        }
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
    return users;
  }

  Future<Map<String, dynamic>?> _fetchUserProfile(String email) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('Profiles')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data() as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
    return null;
  }

  Future<void> _toggleUserBan(String email, bool isBanned) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('UserEmails')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs.first.id;
        await _firestore.collection('UserEmails').doc(docId).update({
          'ban': !isBanned, // Toggle ban status
        });
      }
    } catch (e) {
      print('Error toggling user ban status: $e');
    }
  }

  void _showEditProfileModal(
      BuildContext context, String email, bool isBanned) async {
    final profileData = await _fetchUserProfile(email);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('User Details'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Image.network(
                  profileData?['profilePicture'] ??
                      'https://via.placeholder.com/150',
                  height: 150,
                  width: 150,
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/default_profile.jpg', // Placeholder if URL fails
                    height: 150,
                    width: 150,
                  ),
                ),
                SizedBox(height: 10),
                Text('Email: $email'),
                Text(
                    'Username: ${profileData?['username'] ?? 'Profile Not Set'}'),
                Text('First Name: ${profileData?['firstName'] ?? 'Not Set'}'),
                Text('Last Name: ${profileData?['lastName'] ?? 'Not Set'}'),
                Text('Address: ${profileData?['address'] ?? 'Not Set'}'),
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBanned ? Colors.green : Colors.red,
                  ),
                  onPressed: () async {
                    await _toggleUserBan(email, isBanned);
                    Navigator.of(context).pop();
                    // Refresh the UI after updating ban status
                    setState(() {});
                    // Show SnackBar for feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isBanned
                            ? 'User unbanned successfully.'
                            : 'User banned successfully.'),
                      ),
                    );
                  },
                  child: Text(isBanned ? 'Unban User' : 'Ban User'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fetchUsers(),
      builder: (context, AsyncSnapshot<List<User>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final users = snapshot.data;
          if (users == null || users.isEmpty) {
            return Center(
              child: Text('No Users Yet'),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return ListTile(
                    title: Text(user.email),
                    subtitle: Text(user.username),
                    trailing: Icon(Icons.edit),
                    leading: user.isBanned
                        ? Chip(
                            label: Text('Banned'),
                            backgroundColor: Colors.red,
                          )
                        : null,
                    onTap: () => _showEditProfileModal(
                        context, user.email, user.isBanned),
                  );
                },
              ),
            );
          }
        }
      },
    );
  }
}

class User {
  final String email;
  final String username;
  final bool isBanned;

  User(this.email, this.username, this.isBanned);
}
