import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mad/admin/post_provider.dart';
import 'package:mad/screens/screens.dart/notifications.dart';
import 'package:mad/screens/screens.dart/userBlogs.dart';
import 'package:mad/theme/color.dart';
import 'package:mad/utils/data.dart';
import 'package:mad/widgets/category_item.dart';
import 'package:mad/widgets/notification_box.dart';

import 'package:mad/widgets/pet_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedCategory = 0;
  String _category = 'All';
  String _selectedScreen = 'Pets';
  bool _showPets = true;
  bool _notificationClicked = false;
  LikeState likeState = LikeState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColor.appBarColor,
            pinned: true,
            snap: true,
            floating: true,
            title: _buildAppBar(),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildBody(),
              childCount: 1,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('ShelterSettings')
              .get()
              .then((querySnapshot) => querySnapshot.docs.first),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 20,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(
                              'Location',
                              style: TextStyle(
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          'Loading Location...',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data == null) {
              return Text('No data available');
            } else {
              final data = snapshot.data!.data();
              final location =
                  (data as Map<String, dynamic>)['ShelterLocation'] ??
                      'Location not available';

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.place_outlined,
                              size: 20,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(
                              "Location",
                              style: TextStyle(
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          location,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _notificationClicked
                      ? Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(0xFFE96560),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'Notification',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(0xFFE96560),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: DropdownButton<String>(
                              value: _selectedScreen,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedScreen = newValue!;
                                  _showPets = newValue == 'Pets';
                                });
                              },
                              dropdownColor: Color(0xFFE96560),
                              items:
                                  <String>['Pets', 'Blogs'].map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                  SizedBox(
                    width: 15,
                  ),
                  NotificationBox(
                    onTap: () {
                      setState(() {
                        _notificationClicked = !_notificationClicked;
                      });
                    },
                    notificationClicked: _notificationClicked,
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 25),
            if (!_notificationClicked) _buildCategories(),
            SizedBox(height: 10),
            if (_notificationClicked)
              UserNotifications()
            else
              _showPets ? _buildPets() : _buildBlogs(),
          ],
        ),
      ),
    );
  }

  _buildBlogs() {
    return MiddlePart(likeState: likeState);
  }

  _buildCategories() {
    // Conditionally render categories only if _selectedScreen is "Pets"
    if (_selectedScreen == 'Pets') {
      List<Widget> lists = List.generate(
        categories.length,
        (index) => CategoryItem(
          data: categories[index],
          selected: index == _selectedCategory,
          onTap: () {
            setState(() {
              _selectedCategory = index;
              _category = categories[index]['name']; // Update the category
            });
          },
        ),
      );
      return Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.only(bottom: 5, left: 15),
          child: Row(children: lists),
        ),
      );
    } else {
      // If _selectedScreen is not "Pets", return an empty container
      return Container();
    }
  }

  _buildPets() {
    double width = MediaQuery.of(context).size.width * .8;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _category == 'All'
          ? FirebaseFirestore.instance.collection('Animal').snapshots()
          : FirebaseFirestore.instance
              .collection('Animal')
              .where('CatOrDog', isEqualTo: _category)
              .snapshots(),
      builder: (context,
          AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Show loading indicator while fetching data
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text('No pets available');
        }
        return CarouselSlider(
          options: CarouselOptions(
            height: 400,
            enlargeCenterPage: true,
            disableCenter: true,
            viewportFraction: .8,
          ),
          items: snapshot.data!.docs.map((doc) {
            final petData = doc.data();
            return PetItem(
              docId: doc.id,
              data: petData,
              width: width,
              category: _category,
              onTap: () {
                //
              },
              onFavoriteTap: () {
                //
              },
            );
          }).toList(),
        );
      },
    );
  }
}
