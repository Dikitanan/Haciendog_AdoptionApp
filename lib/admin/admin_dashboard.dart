import 'package:flutter/material.dart';
import 'package:mad/admin/admin_settings.dart';
import 'package:mad/admin/adminhome.dart';
import 'package:mad/admin/blogs_admin.dart';
import 'pet_profile_form.dart';
import 'animal_list.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _currentBody = 'welcome';
  Color _activeColor =
      Color.fromARGB(255, 239, 152, 149); // Define active button color

  void _resetBody() {
    setState(() {
      _currentBody = 'welcome';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdminHome(),
    );
  }

  List<Widget> _buildWideScreenNavButtons() {
    return [
      _buildNavButton(
        onPressed: _resetBody,
        icon: Icons.home,
        label: 'Home',
        isFirst: true,
        isActive: _currentBody == 'welcome', // Check if home is active
      ),
    ];
  }

  Widget _buildNavButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool isFirst = false,
    bool isActive = false, // Added isActive parameter
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: _activeColor,
        backgroundColor: isActive
            ? _activeColor
            : Color(0xFFE96560), // Set text color based on isActive
        padding: EdgeInsets.symmetric(vertical: 17, horizontal: 25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.white),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 30,
            color: isActive
                ? Colors.white
                : Colors.white, // Set icon color based on isActive
          ),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isActive
                  ? Colors.white
                  : Colors.white, // Set text color based on isActive
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentBody) {
      default:
        return AdminHome();
    }
  }

  void _navigateToSettings() {
    setState(() {
      _currentBody = 'settings';
    });
  }
}
