import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mad/admin/admin_home_widgets/admin_donations.dart';
import 'package:mad/admin/admin_home_widgets/admin_messages.dart';
import 'package:mad/admin/admin_home_widgets/adoption_request.dart';
import 'package:mad/admin/admin_home_widgets/blogsPart.dart';
import 'package:mad/admin/admin_home_widgets/leftsidebar.dart';
import 'package:mad/admin/admin_settings.dart';
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

  @override
  LikeState likeState = LikeState();

  void initState() {
    super.initState();
    selectedMenu = 'Analytics';
    middleContent = middleContent = Center(
      child: Text('Analytics Content'),
    );
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
          userProfilePicture = userData['profilePicture'];
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
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
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
                        'Settings'
                      ],
                      onMenuSelected: (menu) {
                        setState(() {
                          selectedMenu = menu;
                          // Update middleContent based on selected menu
                          if (menu == 'Analytics') {
                            middleContent = Center(
                              child: Text('Analytics Content'),
                            );
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
                            middleContent = AdminSettingsForm();
                          }
                        });
                      },
                    ),
                    SizedBox(width: 20),
                    Expanded(child: middleContent),
                    SizedBox(width: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
