import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AdminHome(),
    );
  }
}

class AdminHome extends StatefulWidget {
  const AdminHome({Key? key}) : super(key: key);

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  // Placeholder data for lists
  List<String> blogsPosted = [
    'Blog Post 1',
    'Blog Post 2',
    'Blog Post 3',
  ];

  List<String> donations = [
    'Donation 1',
    'Donation 2',
    'Donation 3',
  ];

  List<String> messages = [
    'Message 1',
    'Message 2',
    'Message 3',
  ];

  List<String> requests = [
    'Request 1',
    'Request 2',
    'Request 3',
  ];

  // Variables to track which section to display
  bool showingDonations = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
      ),
      body: Row(
        children: [
          // Left Sidebar for Adoption Requests
          Container(
            width: 250,
            color: Colors.grey[200],
            child: ListView(
              padding: EdgeInsets.symmetric(vertical: 20),
              children: <Widget>[
                ListTile(
                  title: Text(
                    'Admin Name',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  leading: CircleAvatar(
                    backgroundImage:
                        AssetImage('assets/profile.jpg'), // Placeholder image
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
          ),
          // Middle Content Area for Blogs/Messages
          Expanded(
            child: Container(
              padding: EdgeInsets.all(20),
              color: Colors.white,
              child: ListView.builder(
                itemCount: blogsPosted.length,
                itemBuilder: (context, index) {
                  return _buildPostCard(
                    name: 'John Doe',
                    profileImage: 'assets/profile.jpg',
                    timePosted: '2 hours ago',
                    title: 'Blog Post Title',
                    description:
                        'This is a description of the blog post. It can be quite long if needed.',
                    image: 'assets/blog_image.jpg', // Placeholder image
                  );
                },
              ),
            ),
          ),
          // Right Sidebar for Donations/Messages
          Container(
            width: 250,
            color: Colors.grey[200],
            child: Column(
              children: <Widget>[
                ListTile(
                  title: Text(
                    showingDonations ? 'Donations' : 'Messages',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    children: <Widget>[
                      if (showingDonations)
                        for (var donation in donations)
                          ListTile(
                            title: Text(donation),
                            leading: Icon(Icons.attach_money),
                          ),
                      if (!showingDonations)
                        for (var message in messages)
                          ListTile(
                            title: Text(message),
                            leading: Icon(Icons.mail),
                          ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            showingDonations = true;
                          });
                        },
                        style: ButtonStyle(
                          shape: MaterialStateProperty.all<OutlinedBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        child: Text('Donations'),
                      ),
                    ),
                    SizedBox(width: 1),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            showingDonations = false;
                          });
                        },
                        style: ButtonStyle(
                          shape: MaterialStateProperty.all<OutlinedBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        child: Text('Messages'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildPostCard({
  required String name,
  required String profileImage,
  required String timePosted,
  required String title,
  required String description,
  required String image,
}) {
  return Card(
    elevation: 3,
    margin: EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage: AssetImage(profileImage),
          ),
          title: Text(
            name,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(timePosted),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 10),
              Text(
                description,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 10),
              Image.asset(
                image,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      // Placeholder for like functionality
                    },
                    icon: Icon(Icons.favorite_border),
                  ),
                  IconButton(
                    onPressed: () {
                      // Placeholder for comment functionality
                    },
                    icon: Icon(Icons.comment),
                  ),
                ],
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ],
    ),
  );
}
