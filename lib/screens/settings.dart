import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mad/features/user_auth/presentation/pages/login_page.dart';
import 'package:mad/screens/user_settings_page/personalDetails.dart';
import 'package:mad/screens/user_settings_page/securityPassword.dart';

import 'user_settings_page/userDonation.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool _isMenuOpen = true;
  String _selectedMenuItem = 'Personal Details'; // Default menu item

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  void _selectMenuItem(String menuItem) {
    setState(() {
      _selectedMenuItem = menuItem;
    });
    Navigator.pop(context); // Close the drawer
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to login page after sign-out
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      print('Error signing out: $e');
      // Handle sign-out errors
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyWidget;

    switch (_selectedMenuItem) {
      case 'Personal Details':
        bodyWidget = PersonalDetailsPage();
        break;
      case 'Password and Security':
        bodyWidget = PasswordSecurityPage();
        break;
      case 'Donate':
        bodyWidget = DonatePage();
        break;
      default:
        bodyWidget = Container();
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      drawer: _buildSideMenu(),
      body: bodyWidget,
    );
  }

  Widget _buildSideMenu() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white),
            ),
            decoration: BoxDecoration(
              color: Color(0xFFE96560),
            ),
          ),
          ListTile(
            title: Text('Personal Details'),
            onTap: () => _selectMenuItem('Personal Details'),
            selected: _selectedMenuItem == 'Personal Details',
          ),
          ListTile(
            title: Text('Password and Security'),
            onTap: () => _selectMenuItem('Password and Security'),
            selected: _selectedMenuItem == 'Password and Security',
          ),
          ListTile(
            title: Text('Donate'),
            onTap: () => _selectMenuItem('Donate'),
            selected: _selectedMenuItem == 'Donate',
          ),
          // Add more menu items here
          ListTile(
            title: Text('Logout'),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Confirm Logout"),
                    content: Text("Are you sure you want to log out?"),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false); // Close the dialog
                          _signOut(context); // Perform logout
                        },
                        child: Text("Logout"),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
