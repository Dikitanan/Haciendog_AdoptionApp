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
              backgroundColor: Color(0xFFE96560), // Change background color
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
