import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mad/admin/admin_settings_page/accountsettings.dart';
import 'package:mad/features/user_auth/presentation/pages/login_page.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class AdminSettingsForm extends StatefulWidget {
  const AdminSettingsForm({Key? key}) : super(key: key);

  @override
  _AdminSettingsFormState createState() => _AdminSettingsFormState();
}

class _AdminSettingsFormState extends State<AdminSettingsForm> {
  int _selectedPage = 0; // Default to the first page

  Future<void> _signOut(BuildContext context) async {
    bool confirmLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Logout"),
          content: Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancel
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm
              },
              child: Text("Logout"),
            ),
          ],
        );
      },
    );

    if (confirmLogout ?? false) {
      // User confirmed logout
      try {
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error signing out. Please try again.")),
        );
      }
    }
  }

  List<Widget> _pages = [
    AccountSettingsPage(),
    ShelterSettingsPage(),
    UserListsPage(),
    SizedBox.shrink(), // Placeholder for no content on logout
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 200, // Adjust the width of the NavigationRail
            child: NavigationRail(
              selectedIndex: _selectedPage,
              onDestinationSelected: (index) {
                if (index == 3) {
                  // Logout
                  _signOut(context);
                } else {
                  setState(() {
                    _selectedPage = index;
                  });
                }
              },
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.blue, // Change background color
              selectedIconTheme: IconThemeData(
                  color: Colors.white, size: 30), // Increase icon size
              unselectedIconTheme: IconThemeData(
                  color: Colors.white, size: 30), // Increase icon size
              selectedLabelTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 16), // Increase label font size
              unselectedLabelTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 16), // Increase label font size
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.account_circle),
                  selectedIcon: Icon(Icons.account_circle),
                  label: Text('Account Settings'),
                  padding: EdgeInsets.symmetric(vertical: 25),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Shelter Settings'),
                  padding: EdgeInsets.symmetric(vertical: 25),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.list),
                  selectedIcon: Icon(Icons.list),
                  label: Text('User Lists'),
                  padding: EdgeInsets.symmetric(vertical: 25),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.exit_to_app),
                  selectedIcon: Icon(Icons.exit_to_app),
                  label: Text('Logout'),
                  padding: EdgeInsets.symmetric(vertical: 25),
                ),
              ],
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(
              index: _selectedPage,
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }
}

class ShelterSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Shelter Settings",
              style: Theme.of(context).textTheme.headline5),
          TextFormField(
            decoration: InputDecoration(
              labelText: "Shelter Name",
              helperText: "Change the shelter's name",
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(onPressed: () {}, child: Text("Update Settings")),
        ],
      ),
    );
  }
}

class UserListsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: 20, // Example count
        itemBuilder: (context, index) => ListTile(
          title: Text("User ${index + 1}"),
          subtitle: Text("User details here"),
          trailing: Icon(Icons.edit),
          onTap: () {
            // Implement user edit functionality
          },
        ),
      ),
    );
  }
}
