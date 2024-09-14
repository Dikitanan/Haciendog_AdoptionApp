import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mad/features/user_auth/presentation/pages/login_page.dart';
import 'package:provider/provider.dart';

class MessageCount extends ChangeNotifier {
  final int count;
  MessageCount(this.count);
}

class PendingAdoptionCount extends ChangeNotifier {
  final int count;
  PendingAdoptionCount(this.count);
}

class LeftSideBar extends StatefulWidget {
  final String? userName;
  final String? userProfilePicture;
  final List<String> menus;
  final Function(String) onMenuSelected;

  const LeftSideBar({
    Key? key,
    required this.userName,
    required this.userProfilePicture,
    required this.menus,
    required this.onMenuSelected,
  }) : super(key: key);

  @override
  _LeftSideBarState createState() => _LeftSideBarState();
}

class _LeftSideBarState extends State<LeftSideBar> {
  late String _selectedMenu;

  @override
  void initState() {
    super.initState();
    _selectedMenu = 'Analytics'; // Initially select "Analytics"
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider<MessageCount>(
          create: (_) =>
              _getMessageCountStream().map((count) => MessageCount(count)),
          initialData: MessageCount(0),
        ),
        StreamProvider<PendingAdoptionCount>(
          create: (_) => _getPendingAdoptionRequestsStream()
              .map((count) => PendingAdoptionCount(count)),
          initialData: PendingAdoptionCount(0),
        ),
      ],
      child: Container(
        width: 250,
        color: Color(0xFFE96560),
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 20),
          children: <Widget>[
            ListTile(
              title: Text(
                widget.userName ?? 'User Name not available',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey[300],
                ),
              ),
              leading: CircleAvatar(
                backgroundImage: widget.userProfilePicture != null
                    ? NetworkImage(widget.userProfilePicture!)
                    : AssetImage('assets/profile.jpg') as ImageProvider<Object>,
              ),
            ),
            Divider(),
            ..._buildMenuItems(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    List<Widget> menuItems = [];
    for (var menu in _sortedMenus()) {
      if (menu.toLowerCase() == 'settings') {
        menuItems.add(_buildSettingsDropdown());
      } else if (menu.toLowerCase() != 'account settings' &&
          menu.toLowerCase() != 'shelter settings' &&
          menu.toLowerCase() != 'user list' &&
          menu.toLowerCase() != 'logout') {
        menuItems.add(
          Container(
            color: menu == _selectedMenu
                ? Color.fromARGB(255, 239, 152, 149)
                    .withOpacity(0.3) // Color when selected
                : null,
            child: ListTile(
              title: _buildMenuTitle(menu),
              leading: _getMenuIcon(menu),
              onTap: () {
                if (menu == 'Logout') {
                  _signOut(context);
                } else {
                  _updateSelectedMenu(menu);
                }
              },
            ),
          ),
        );
      }
    }
    return menuItems;
  }

  Widget _buildSettingsDropdown() {
    return Container(
      color: _selectedMenu == 'Settings'
          ? Color.fromARGB(255, 239, 152, 149).withOpacity(0.3)
          : null,
      child: ExpansionTile(
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 16,
            color: _selectedMenu == 'Settings'
                ? const Color.fromARGB(
                    255, 255, 255, 255) // Text color when selected
                : const Color.fromARGB(
                    255, 255, 255, 255), // Default text color
          ),
        ),
        leading: Icon(
          Icons.settings,
          color: Colors.grey[300],
        ),
        collapsedIconColor: Colors.white, // Arrow color when collapsed
        shape: RoundedRectangleBorder(
          side:
              BorderSide(color: Colors.transparent), // Transparent border color
        ),
        children: <Widget>[
          ListTile(
            title: Text(
              'Account Settings',
              style: TextStyle(
                fontSize: 16,
                color: _selectedMenu == 'Account Settings'
                    ? const Color.fromARGB(
                        255, 255, 255, 255) // Text color when selected
                    : const Color.fromARGB(
                        255, 255, 255, 255), // Default text color
              ),
            ),
            leading: Icon(
              Icons.person,
              color: Colors.grey[300],
            ),
            onTap: () {
              _updateSelectedMenu('Account Settings');
              widget.onMenuSelected('Account Settings');
            },
          ),
          ListTile(
            title: Text(
              'Shelter Settings',
              style: TextStyle(
                fontSize: 16,
                color: _selectedMenu == 'Shelter Settings'
                    ? const Color.fromARGB(
                        255, 255, 255, 255) // Text color when selected
                    : const Color.fromARGB(
                        255, 255, 255, 255), // Default text color
              ),
            ),
            leading: Icon(
              Icons.settings,
              color: Colors.grey[300],
            ),
            onTap: () {
              _updateSelectedMenu('Shelter Settings');
              widget.onMenuSelected('Shelter Settings');
            },
          ),
          ListTile(
            title: Text(
              'User List',
              style: TextStyle(
                fontSize: 16,
                color: _selectedMenu == 'User List'
                    ? const Color.fromARGB(
                        255, 255, 255, 255) // Text color when selected
                    : const Color.fromARGB(
                        255, 255, 255, 255), // Default text color
              ),
            ),
            leading: Icon(
              Icons.people,
              color: Colors.grey[300],
            ),
            onTap: () {
              _updateSelectedMenu('User List');
              widget.onMenuSelected('User List');
            },
          ),
          ListTile(
            title: Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                color: _selectedMenu == 'Logout'
                    ? const Color.fromARGB(
                        255, 255, 255, 255) // Text color when selected
                    : const Color.fromARGB(
                        255, 255, 255, 255), // Default text color
              ),
            ),
            leading: Icon(
              Icons.logout,
              color: Colors.grey[300],
            ),
            onTap: () {
              _signOut(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTitle(String menu) {
    if (menu.toLowerCase() == 'messages') {
      return Consumer<MessageCount>(
        builder: (context, messageCount, _) {
          return Text(
            'Messages (${messageCount.count})',
            style: TextStyle(
              fontSize: 16,
              color: menu == _selectedMenu
                  ? const Color.fromARGB(
                      255, 255, 255, 255) // Text color when selected
                  : const Color.fromARGB(
                      255, 255, 255, 255), // Default text color
            ),
          );
        },
      );
    } else if (menu.toLowerCase() == 'adoption requests') {
      return Consumer<PendingAdoptionCount>(
        builder: (context, pendingAdoptionCount, _) {
          return Text(
            'Adoption Requests (${pendingAdoptionCount.count})',
            style: TextStyle(
              fontSize: 16,
              color: menu == _selectedMenu
                  ? const Color.fromARGB(
                      255, 255, 255, 255) // Text color when selected
                  : const Color.fromARGB(
                      255, 255, 255, 255), // Default text color
            ),
          );
        },
      );
    } else {
      return Text(
        menu,
        style: TextStyle(
          fontSize: 16,
          color: menu == _selectedMenu
              ? const Color.fromARGB(
                  255, 255, 255, 255) // Text color when selected
              : const Color.fromARGB(255, 255, 255, 255), // Default text color
        ),
      );
    }
  }

  Stream<int> _getMessageCountStream() {
    return FirebaseFirestore.instance
        .collection('UserNewMessage')
        .snapshots()
        .map((snapshot) {
      int totalCount = 0;
      snapshot.docs.forEach((doc) {
        totalCount += int.parse((doc['messageCount'] ?? 0).toString());
      });
      return totalCount;
    });
  }

  Stream<int> _getPendingAdoptionRequestsStream() {
    return FirebaseFirestore.instance
        .collection('AdoptionForms')
        .where('status',
            whereNotIn: ['Rejected', 'Adopted', 'Cancelled', 'Archived'])
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  void _updateSelectedMenu(String menu) {
    setState(() {
      _selectedMenu = menu; // Update selected menu
    });
    widget.onMenuSelected(menu);
  }

  Future<void> _signOut(BuildContext context) async {
    bool confirmLogout = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Confirm Logout'),
              content: Text('Are you sure you want to log out?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Logout'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmLogout) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  List<String> _sortedMenus() {
    List<String> sortedMenus = [...widget.menus];
    // Ensure only one 'Analytics' entry
    sortedMenus.remove('Analytics');
    // Ensure 'Settings' and related items are properly handled
    sortedMenus.remove('Settings');
    sortedMenus.remove('Account Settings');
    sortedMenus.remove('Shelter Settings');
    sortedMenus.remove('User List');

    // Add 'Analytics' at the start
    sortedMenus.insert(0, 'Analytics');
    // Add 'Settings' at the end
    sortedMenus.add('Settings');

    return sortedMenus;
  }

  Widget _getMenuIcon(String menu) {
    switch (menu.toLowerCase()) {
      case 'analytics':
        return Icon(Icons.analytics, color: Colors.grey[300]);
      case 'blogs':
        return Icon(
          Icons.article,
          color: Colors.grey[300],
        );
      case 'add pet':
        return Icon(
          Icons.pets,
          color: Colors.grey[300],
        );
      case 'animal list':
        return Icon(
          Icons.list,
          color: Colors.grey[300],
        );
      case 'donations':
        return Icon(
          Icons.attach_money,
          color: Colors.grey[300],
        );
      case 'adoption requests':
        return Icon(
          Icons.pets,
          color: Colors.grey[300],
        );
      case 'messages':
        return Icon(Icons.message, color: Colors.grey[300]);
      case 'adoption requests':
        return Icon(Icons.pets, color: Colors.grey[300]);
      case 'settings':
        return Icon(Icons.settings, color: Colors.grey[300]);
      default:
        return Icon(Icons.help, color: Colors.grey[300]);
    }
  }
}
