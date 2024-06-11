import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  late Stream<int> _messageCountStream;

  @override
  void initState() {
    super.initState();
    _selectedMenu = 'Analytics'; // Initially select "Blogs"
    _messageCountStream = _getMessageCountStream();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          for (var menu in _sortedMenus())
            Container(
              color: menu == _selectedMenu
                  ? Color.fromARGB(255, 239, 152, 149)
                      .withOpacity(0.3) // Color when selected
                  : null,
              child: ListTile(
                title: StreamBuilder<int>(
                  stream: menu.toLowerCase() == 'messages'
                      ? _messageCountStream
                      : Stream.value(0),
                  builder: (context, snapshot) {
                    final messageCount = snapshot.data ?? 0;
                    return Text(
                      menu.toLowerCase() == 'messages'
                          ? 'Messages ($messageCount)'
                          : menu,
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
                ),
                leading: _getMenuIcon(menu),
                onTap: () {
                  _updateSelectedMenu(menu);
                },
              ),
            ),
        ],
      ),
    );
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

  void _updateSelectedMenu(String menu) {
    setState(() {
      _selectedMenu = menu; // Update selected menu
    });
    widget.onMenuSelected(menu);
  }

  List<String> _sortedMenus() {
    List<String> sortedMenus = [...widget.menus];
    sortedMenus.remove('Analytics');
    sortedMenus.insert(0, 'Analytics');
    return sortedMenus;
  }

  Widget? _getMenuIcon(String menu) {
    switch (menu.toLowerCase()) {
      case 'analytics':
        return Container(
          child: Icon(
            Icons.analytics,
            color: Colors.grey[300],
          ),
        );
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
        return Icon(
          Icons.message,
          color: Colors.grey[300],
        );
      case 'settings':
        return Icon(
          Icons.settings,
          color: Colors.grey[300],
        );
      default:
        return null;
    }
  }
}
