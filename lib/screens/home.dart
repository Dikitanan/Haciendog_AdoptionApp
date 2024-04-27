import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  String _category = 'All'; // Add this field
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
                "Phnom Penh, Cambodia",
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
  }

  _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 0, bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(
            height: 25,
          ),
          _buildCategories(),
          const SizedBox(
            height: 25,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 25),
            child: Text(
              "Adopt Me",
              style: TextStyle(
                color: AppColor.textColor,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
          ),
          _buildPets(),
        ]),
      ),
    );
  }

  _buildCategories() {
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
              onTap: null,
              onFavoriteTap: () {
                // Update Firestore document when favorite status changes
              },
            );
          }).toList(),
        );
      },
    );
  }
}
