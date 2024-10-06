import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserListsPage extends StatefulWidget {
  @override
  _UserListsPageState createState() => _UserListsPageState();
}

class _UserListsPageState extends State<UserListsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUserRole;
  String _selectedRoleFilter = 'All'; // Add a variable for the role filter

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserRole();
  }

  Future<void> _fetchCurrentUserRole() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      final email = currentUser.email;
      final userDoc = await _firestore
          .collection('UserEmails')
          .where('email', isEqualTo: email)
          .get();

      if (userDoc.docs.isNotEmpty) {
        setState(() {
          _currentUserRole = userDoc.docs.first.data()['role'] ?? 'User';
        });
      }
    }
  }

  Stream<List<UserData>> _fetchUsersStream() {
    return _firestore.collection('UserEmails').snapshots().asyncMap(
      (userEmailsSnapshot) async {
        List<UserData> users = [];

        final List<Future<void>> userFetchFutures = userEmailsSnapshot.docs.map(
          (userEmailDoc) async {
            final userEmail = userEmailDoc.data() as Map<String, dynamic>;
            final email = userEmail['email'];
            final isBanned = userEmail['ban'] ?? false;
            final role = userEmail['role'] ?? 'User';

            final profileSnapshot = await _firestore
                .collection('Profiles')
                .where('email', isEqualTo: email)
                .get();

            String username = 'Profile Not Set';
            if (profileSnapshot.docs.isNotEmpty) {
              username = profileSnapshot.docs.first.data()['username'] ??
                  'Profile Not Set';
            }

            users.add(UserData(email, username, isBanned, role));
          },
        ).toList();

        await Future.wait(userFetchFutures);

        return users;
      },
    );
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
          'ban': !isBanned,
        });
      }
    } catch (e) {
      print('Error toggling user ban status: $e');
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditProfileModal(
      BuildContext context, String email, bool isBanned, String role) async {
    final profileData = await _fetchUserProfile(email);

    final userDoc = await _firestore
        .collection('UserEmails')
        .where('email', isEqualTo: email)
        .get();

    String currentRole = userDoc.docs.isNotEmpty
        ? userDoc.docs.first.data()['role'] ?? 'User'
        : 'User';

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
                    'assets/images/default_profile.jpg',
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
                if (_currentUserRole == 'Admin' &&
                    role !=
                        'Admin') // Only Admins can block/unblock, and Admins cannot be blocked
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBanned ? Colors.green : Colors.red,
                    ),
                    onPressed: () async {
                      await _toggleUserBan(email, isBanned);
                      Navigator.of(context).pop();
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isBanned
                              ? 'User unbanned successfully.'
                              : 'User banned successfully.'),
                        ),
                      );
                    },
                    child: Text(isBanned ? 'Unban User' : 'Ban User',
                        style: TextStyle(color: Colors.white)),
                  ),
                if (_currentUserRole == 'Admin' &&
                    role == 'Admin') // Admins cannot block other Admins
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    onPressed: () {
                      _showErrorDialog(
                        context,
                        'Admins cannot block other Admins.',
                      );
                    },
                    child: Text(
                      'Admin - Cannot Block',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                if (_currentUserRole !=
                    'Admin') // Non-admins cannot block anyone
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    onPressed: () {
                      _showErrorDialog(
                        context,
                        'Only admins can block or unblock users.',
                      );
                    },
                    child: Text('Block/Unblock',
                        style: TextStyle(color: Colors.white)),
                  ),
                SizedBox(height: 10),
                if (_currentUserRole == 'Admin' &&
                    currentRole !=
                        'Admin') // Only admin can change non-admin roles
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          currentRole == 'Staff' ? Colors.orange : Colors.blue,
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      textStyle: TextStyle(fontSize: 16),
                    ),
                    onPressed: () async {
                      String newRole =
                          currentRole == 'Staff' ? 'User' : 'Staff';
                      await _updateUserRole(email, newRole);
                      Navigator.of(context).pop();
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(newRole == 'Staff'
                              ? 'User promoted to Staff.'
                              : 'User demoted to User.'),
                        ),
                      );
                    },
                    child: Text(
                        currentRole == 'Staff' ? 'Remove Staff' : 'Make Staff',
                        style: TextStyle(color: Colors.white)),
                  ),
                if (_currentUserRole !=
                    'Admin') // Non-admin attempting to change roles
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    onPressed: () {
                      _showErrorDialog(
                        context,
                        'Only the admin can appoint or remove staff.',
                      );
                    },
                    child: Text('Make Staff/Remove Staff',
                        style: TextStyle(color: Colors.white)),
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

  Future<void> _updateUserRole(String email, String newRole) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('UserEmails')
          .where('email', isEqualTo: email)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final docId = snapshot.docs.first.id;
        await _firestore.collection('UserEmails').doc(docId).update({
          'role': newRole,
        });
      }
    } catch (e) {
      print('Error updating user role: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'User List',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color.fromARGB(255, 235, 232, 232),
          actions: [
            // Add DropdownButton inside the AppBar
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRoleFilter,
                  items: ['All', 'Admin', 'Staff', 'User'].map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedRoleFilter = value!;
                    });
                  },
                  icon: Icon(
                    Icons
                        .filter_list, // Add a filter icon to represent the dropdown
                    color: const Color.fromARGB(255, 0, 0, 0),
                  ),
                  dropdownColor: Colors.white,
                  style: TextStyle(
                    color: Colors.black, // Text color inside the dropdown
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: _fetchUsersStream(),
                builder: (context, AsyncSnapshot<List<UserData>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    final users = snapshot.data;
                    if (users == null || users.isEmpty) {
                      return Center(child: Text('No Users Yet'));
                    } else {
                      // Sort the users by role: Admin first, then Staff, then User
                      users.sort((a, b) {
                        const rolePriority = {
                          'Admin': 1,
                          'Staff': 2,
                          'User': 3,
                        };
                        return rolePriority[a.role]!
                            .compareTo(rolePriority[b.role]!);
                      });

                      // Apply the selected role filter
                      final filteredUsers = _selectedRoleFilter == 'All'
                          ? users
                          : users
                              .where((user) => user.role == _selectedRoleFilter)
                              .toList();

                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Color.fromARGB(255, 244, 217, 217),
                              Colors.white,
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ListView.builder(
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];

                              // Define the role color based on the user role
                              Color roleColor;
                              if (user.role == 'Admin') {
                                roleColor =
                                    Colors.amber[800]!; // Gold for Admin
                              } else if (user.role == 'Staff') {
                                roleColor = Colors.grey; // Silver for Staff
                              } else {
                                roleColor =
                                    Colors.brown[400]!; // Bronze for User
                              }

                              return ListTile(
                                title: Text(user.email),
                                subtitle: Text(user.username),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Display the user's role with the appropriate color
                                    Text(
                                      user.role == 'Admin'
                                          ? 'Admin'
                                          : user.role == 'Staff'
                                              ? 'Staff'
                                              : 'User',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: roleColor,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Icon(Icons.edit),
                                  ],
                                ),
                                leading: user.isBanned
                                    ? Chip(
                                        label: Text(
                                          'Banned',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        backgroundColor: Colors.red,
                                      )
                                    : null,
                                onTap: () => _showEditProfileModal(context,
                                    user.email, user.isBanned, user.role),
                              );
                            },
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserData {
  final String email;
  final String username;
  final bool isBanned;
  final String role;

  UserData(this.email, this.username, this.isBanned, this.role);
}
