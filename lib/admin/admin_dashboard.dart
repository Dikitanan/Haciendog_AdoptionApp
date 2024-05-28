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

  void _navigateToBlogsAdmin() {
    setState(() {
      _currentBody = 'blogs_admin';
    });
  }

  void _navigateToCreatePetProfile() {
    setState(() {
      _currentBody = 'create_pet_profile';
    });
  }

  void _navigateToAnimalList() {
    setState(() {
      _currentBody = 'animal_list';
    });
  }

  void _resetBody() {
    setState(() {
      _currentBody = 'welcome';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              color: Color(0xFFE96560), // Set navigation bar background color
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (MediaQuery.of(context).size.width > 600)
                    ..._buildWideScreenNavButtons(),
                  if (MediaQuery.of(context).size.width <= 600)
                    Builder(
                      builder: (context) => IconButton(
                        icon: Icon(Icons.menu),
                        onPressed: () {
                          Scaffold.of(context).openDrawer();
                        },
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.all(20),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
      drawer: MediaQuery.of(context).size.width <= 600 ? _buildDrawer() : null,
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
      _buildNavButton(
        onPressed: _navigateToCreatePetProfile,
        icon: Icons.pets,
        label: 'Create Pet Profile',
        isActive: _currentBody ==
            'create_pet_profile', // Check if create pet profile is active
      ),
      _buildNavButton(
        onPressed: _navigateToAnimalList,
        icon: Icons.list,
        label: 'Animal Lists',
        isActive:
            _currentBody == 'animal_list', // Check if animal list is active
      ),
      _buildNavButton(
        onPressed: _navigateToBlogsAdmin,
        icon: Icons.post_add,
        label: 'Post Blogs',
        isActive:
            _currentBody == 'blogs_admin', // Check if blogs admin is active
      ),
      _buildNavButton(
        onPressed: () {
          _navigateToSettings();
        },
        icon: Icons.settings,
        label: 'Settings',
        isActive: _currentBody == 'settings', // Check if settings is active
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

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            title: Text('Home'),
            onTap: () {
              _resetBody();
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Create Pet Profile'),
            onTap: () {
              _navigateToCreatePetProfile();
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Animal Lists'),
            onTap: () {
              _navigateToAnimalList();
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Post Blogs'),
            onTap: () {
              _navigateToBlogsAdmin();
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Settings'),
            onTap: () {
              _navigateToSettings();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentBody) {
      case 'create_pet_profile':
        return PetProfileForm();
      case 'animal_list':
        return AnimalList();
      case 'settings':
        return AdminSettingsForm();
      case 'blogs_admin':
        return BlogsAdmin();
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
