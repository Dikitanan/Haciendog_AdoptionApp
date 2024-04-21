import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserListsPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<User>> _fetchUsers() async {
    List<User> users = [];
    try {
      final QuerySnapshot userEmailsSnapshot =
          await _firestore.collection('UserEmails').get();

      for (var userEmailDoc in userEmailsSnapshot.docs) {
        final userEmail = userEmailDoc.data() as Map<String, dynamic>;
        final email = userEmail['email'];

        final QuerySnapshot profileSnapshot = await _firestore
            .collection('Profiles')
            .where('email', isEqualTo: email)
            .get();

        if (profileSnapshot.docs.isNotEmpty) {
          final username = (profileSnapshot.docs.first.data()
                  as Map<String, dynamic>)['username'] as String? ??
              'Profile Not Set';
          users.add(User(email, username));
        } else {
          users.add(User(email, 'Profile Not Set'));
        }
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
    return users;
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
            // Display "No Users Yet" message
            return Center(
              child: Text('No Users Yet'),
            );
          } else {
            // Display the list of users
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(users[index].email),
                  subtitle: Text(users[index].username),
                  trailing: Icon(Icons.edit),
                  onTap: () {
                    // Implement user edit functionality
                  },
                ),
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

  User(this.email, this.username);
}
