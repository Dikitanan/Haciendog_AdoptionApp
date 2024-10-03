import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mad/admin/admin_home_widgets/admin_analytics.dart';
import 'package:mad/admin/admin_home_widgets/admin_donations.dart';
import 'package:mad/admin/admin_home_widgets/admin_messages.dart';
import 'package:mad/admin/admin_home_widgets/adoption_request.dart';
import 'package:mad/admin/admin_home_widgets/blogsPart.dart';
import 'package:mad/admin/admin_home_widgets/leftsidebar.dart';
import 'package:mad/admin/admin_settings.dart';
import 'package:mad/admin/admin_settings_page/accountsettings.dart';
import 'package:mad/admin/admin_settings_page/sheltersettings.dart';
import 'package:mad/admin/admin_settings_page/userlist.dart';
import 'package:mad/admin/animal_list.dart';
import 'package:mad/admin/pet_profile_form.dart';
import 'package:mad/admin/post_provider.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({Key? key}) : super(key: key);

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  late String selectedMenu;
  late Widget middleContent;
  late String? userEmail;
  late String? userName;
  late String? userProfilePicture;
  bool isLoading = true;

  LikeState likeState = LikeState();

  @override
  void initState() {
    super.initState();
    selectedMenu = 'Analytics';
    middleContent = Center(child: AdminAnalytics());
    getUserData();
  }

  Future<void> getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userEmail = user.email;
      final querySnapshot = await FirebaseFirestore.instance
          .collection('Profiles')
          .where('email', isEqualTo: userEmail)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        setState(() {
          userName = userData['username'];
          userProfilePicture = userData['profilePicture'] ?? '';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 247, 210, 209),
      appBar: AppBar(
        backgroundColor: Color(0xFFE96560),
        title: Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        bottomOpacity: 100,
        leading: Builder(
          builder: (context) {
            final width = MediaQuery.of(context).size.width;
            if (width < 1200) {
              return IconButton(
                icon: Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            } else {
              return Container();
            }
          },
        ),
      ),
      drawer: isLoading
          ? null
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 1200) {
                  return Drawer(
                    child: LeftSideBar(
                      userName: userName,
                      userProfilePicture: userProfilePicture,
                      menus: [
                        'Analytics',
                        'Blogs',
                        'Add Pet',
                        'Animal List',
                        'Donations',
                        'Adoption Requests',
                        'Messages',
                        'Settings' // Single Settings menu for small screens
                      ],
                      onMenuSelected: (menu) {
                        setState(() {
                          selectedMenu = menu;
                          Navigator.pop(context); // Close drawer on selection
                          updateMiddleContent(menu);
                        });
                      },
                    ),
                  );
                } else {
                  return Container();
                }
              },
            ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 1200) {
                  return Container(
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          LeftSideBar(
                            userName: userName,
                            userProfilePicture: userProfilePicture,
                            menus: [
                              'Analytics',
                              'Blogs',
                              'Add Pet',
                              'Animal List',
                              'Donations',
                              'Adoption Requests',
                              'Messages',
                              'Account Settings',
                              'Shelter Settings',
                              'User List'
                            ],
                            onMenuSelected: (menu) {
                              setState(() {
                                selectedMenu = menu;
                                updateMiddleContent(menu);
                              });
                            },
                          ),
                          SizedBox(width: 20),
                          Expanded(child: middleContent),
                          SizedBox(width: 20),
                        ],
                      ),
                    ),
                  );
                } else {
                  // Show AdminSettingsForm for small screens when "Settings" is selected
                  return middleContent;
                }
              },
            ),
    );
  }

  void updateMiddleContent(String menu) {
    if (menu == 'Analytics') {
      middleContent = AdminAnalytics();
    } else if (menu == 'Blogs') {
      middleContent = MiddlePart(likeState: likeState);
    } else if (menu == 'Add Pet') {
      middleContent = PetProfileForm();
    } else if (menu == 'Animal List') {
      middleContent = AnimalList();
    } else if (menu == 'Donations') {
      middleContent = AdminDonations();
    } else if (menu == 'Adoption Requests') {
      middleContent = AdoptionLists();
    } else if (menu == 'Messages') {
      middleContent = AdminSideMessage();
    } else if (menu == 'Settings') {
      // Show AdminSettingsForm when "Settings" is selected on smaller screens
      middleContent = AdminSettingsForm();
    } else if (menu == 'Account Settings') {
      middleContent = AccountSettingsPage();
    } else if (menu == 'Shelter Settings') {
      middleContent = ShelterSettingsForm();
    } else if (menu == 'User List') {
      middleContent = UserListsPage();
    }
  }
}
