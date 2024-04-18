import 'package:flutter/material.dart';
import 'package:mad/admin/admin_settings.dart';
import 'package:mad/admin/blogs_admin.dart';
import 'pet_profile_form.dart';
import 'animal_list.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _currentBody = 'welcome';

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            color: Colors.blue, // Set navigation bar background color
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
      drawer: MediaQuery.of(context).size.width <= 600 ? _buildDrawer() : null,
    );
  }

  List<Widget> _buildWideScreenNavButtons() {
    return [
      _buildNavButton(
        onPressed: _resetBody, // Reset the body
        icon: Icons.home, // Use home icon for resetting
        label: 'Home',
        isFirst: true,
      ),
      _buildNavButton(
        onPressed: _navigateToCreatePetProfile,
        icon: Icons.pets,
        label: 'Create Pet Profile',
      ),
      _buildNavButton(
        onPressed: _navigateToAnimalList,
        icon: Icons.list,
        label: 'Animal Lists',
      ),
      _buildNavButton(
        onPressed: _navigateToBlogsAdmin,
        icon: Icons.post_add,
        label: 'Post Blogs',
      ),
      _buildNavButton(
        onPressed: () {
          _navigateToSettings(); // Update to navigate to Settings
        },
        icon: Icons.settings,
        label: 'Settings',
      ),
    ];
  }

  Widget _buildNavButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool isFirst = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.blue,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.white), // Add border
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 40,
            color: Colors.white,
          ),
          SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.white),
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
              color: Colors.blue,
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
              _navigateToSettings(); // Update to navigate to Settings
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
      case 'settings': // Add case for settings
        return AdminSettingsForm();
      case 'blogs_admin':
        return BlogsAdmin();
      default:
        return Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to Pet Adoption App',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Flexible(
                fit: FlexFit.loose,
                child: Image.network(
                  'https://img.freepik.com/free-vector/adopt-pet-from-shelter-landing-page-template_23-2148763333.jpg?size=626&ext=jpg&ga=GA1.1.1700460183.1708128000&semt=ais',
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        );
    }
  }

  void _navigateToSettings() {
    setState(() {
      _currentBody = 'settings';
    });
  }
}
