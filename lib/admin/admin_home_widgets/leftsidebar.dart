import 'package:flutter/material.dart';

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
    _selectedMenu = 'Blogs'; // Initially select "Blogs"
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.grey[200],
      child: ListView(
        padding: EdgeInsets.symmetric(vertical: 20),
        children: <Widget>[
          ListTile(
            title: Text(
              widget.userName ?? 'User Name not available',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                  ? Colors.blue.withOpacity(0.3) // Color when selected
                  : null,
              child: ListTile(
                title: Text(
                  menu,
                  style: TextStyle(
                    fontSize: 16,
                    color: menu == _selectedMenu
                        ? Colors.blue // Text color when selected
                        : null, // Default text color
                  ),
                ),
                leading: _getMenuIcon(menu),
                onTap: () {
                  setState(() {
                    _selectedMenu = menu; // Update selected menu
                  });
                  widget.onMenuSelected(menu);
                },
              ),
            ),
        ],
      ),
    );
  }

  List<String> _sortedMenus() {
    List<String> sortedMenus = [...widget.menus];
    sortedMenus.remove('Blogs');
    sortedMenus.insert(0, 'Blogs');
    return sortedMenus;
  }

  Widget? _getMenuIcon(String menu) {
    switch (menu.toLowerCase()) {
      case 'statistics':
        return Icon(Icons.analytics);
      case 'blogs':
        return Icon(Icons.article);
      case 'donations':
        return Icon(Icons.attach_money);
      case 'adoption requests':
        return Icon(Icons.pets);
      case 'messages':
        return Icon(Icons.message);
      default:
        return null;
    }
  }
}
