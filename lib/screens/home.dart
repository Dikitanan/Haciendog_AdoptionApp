import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mad/admin/post_provider.dart';
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
  bool _showPets = true; // Define _showPets variable
  LikeState likeState = LikeState();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.appBgColor,
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
                              color: AppColor.labelColor,
                              size: 20,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(
                              'Location',
                              style: TextStyle(
                                color: AppColor.labelColor,
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
                            color: AppColor.textColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  NotificationBox(
                    notifiedNumber: 1,
                    onTap: null,
                  )
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
                              color: AppColor.labelColor,
                              size: 20,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(
                              "Location",
                              style: TextStyle(
                                color: AppColor.labelColor,
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
                            color: AppColor.textColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(
                          0xFFE96560), // Set the background color of the dropdown button
                      borderRadius: BorderRadius.circular(
                          8), // Optional: Add border radius for rounded corners
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
                        // Set the background color of the dropdown list
                        dropdownColor: Color(0xFFE96560),
                        items: <String>['Pets', 'Blogs'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                fontWeight: FontWeight
                                    .bold, // Emphasize the dropdown item text
                                fontSize:
                                    16, // Increase the font size for visibility
                                color: Colors
                                    .white, // Change the text color to white
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
                    notifiedNumber: 1,
                    onTap: null,
                  )
                ],
              );
            }
          },
        ),
      ],
    );
  }

  _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 25),
            _buildCategories(),
            SizedBox(height: 10),
            // Check if _showPets is true
            if (_showPets)
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 25),
                child: Text(
                  "Haciendog",
                  style: TextStyle(
                    color: AppColor.textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              )
            else
              Container(), // Empty container if _showPets is false
            // Conditional rendering based on _showPets
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
