import 'package:flutter/material.dart';

class LeftSideBar extends StatelessWidget {
  final String? userName;
  final String? userProfilePicture;
  final List<String> requests;

  const LeftSideBar({
    Key? key,
    required this.userName,
    required this.userProfilePicture,
    required this.requests,
  }) : super(key: key);

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
              userName ?? 'User Name not available',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            leading: CircleAvatar(
              backgroundImage: userProfilePicture != null
                  ? NetworkImage(userProfilePicture!)
                  : AssetImage('assets/profile.jpg') as ImageProvider<Object>,
            ),
          ),
          ListTile(
            title: Text('Adoption Requests',
                style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () {
              // Placeholder action for Adoption Requests
            },
          ),
          for (var request in requests)
            ListTile(
              title: Text(request),
              leading: Icon(Icons.article),
            ),
        ],
      ),
    );
  }
}
