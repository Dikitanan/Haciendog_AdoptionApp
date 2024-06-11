import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:mad/admin/admin_settings_page/accountsettings.dart';
import 'package:mad/admin/admin_settings_page/sheltersettings.dart';
import 'package:mad/admin/admin_settings_page/userlist.dart';
import 'package:mad/features/user_auth/presentation/pages/login_page.dart';

class AdminSettingsForm extends StatefulWidget {
  const AdminSettingsForm({Key? key}) : super(key: key);

  @override
  _AdminSettingsFormState createState() => _AdminSettingsFormState();
}

class _AdminSettingsFormState extends State<AdminSettingsForm> {
  int _selectedPage = 0; // Default to the first page
  List<bool> _isSelected = [true, false, false, false]; // Track selected state

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
    ShelterSettingsForm(),
    UserListsPage(),
    SizedBox.shrink(), // Placeholder for no content on logout
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Settings'),
        actions: [
          SizedBox(width: 25),
          _buildIconButton(0, Icons.account_circle, 'Account Settings'),
          SizedBox(width: 25),
          _buildIconButton(1, Icons.home, 'Shelter Settings'),
          SizedBox(width: 25),
          _buildIconButton(2, Icons.list, 'User Lists'),
          SizedBox(width: 25),
          _buildIconButton(3, Icons.exit_to_app, 'Logout'),
        ],
      ),
      body: _pages[_selectedPage],
    );
  }

  Widget _buildIconButton(int index, IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {
          if (index != 3) {
            setState(() {
              _selectedPage = index;
              _updateSelectedState(index);
            });
          } else {
            _signOut(context);
          }
        },
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _isSelected[index] ? Color(0xFFE96560) : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(
            icon,
            size: 30,
            color: _isSelected[index] ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  void _updateSelectedState(int index) {
    for (int i = 0; i < _isSelected.length; i++) {
      _isSelected[i] = i == index;
    }
  }
}
