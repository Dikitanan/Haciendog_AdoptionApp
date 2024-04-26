import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:mad/theme/color.dart';
import 'package:mad/widgets/favorite_box.dart';

import 'custom_image.dart';

import 'dart:math'; // Import dart math library for randomization

class PetItem extends StatelessWidget {
  const PetItem({
    Key? key,
    required this.docId,
    this.width = 350,
    this.height = 400,
    this.radius = 40,
    this.onTap,
    this.onFavoriteTap,
    required Map<String, dynamic> data,
  }) : super(key: key);

  final String docId;
  final double width;
  final double height;
  final double radius;
  final GestureTapCallback? onTap;
  final GestureTapCallback? onFavoriteTap;

  // Keep track of the previously displayed pet's ID
  static String? previousPetId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: _fetchRandomPets(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        final petList = snapshot.data ?? [];
        if (petList.isEmpty) {
          return Text('No pets found');
        }

        // Shuffle the list excluding the previous pet
        petList.removeWhere((pet) => pet.id == previousPetId);
        petList.shuffle();

        if (petList.isEmpty) {
          return Text('No other pets found');
        }

        final randomPetData = petList.first.data() as Map<String, dynamic>;
        previousPetId =
            petList.first.id; // Update previousPetId with the current pet's ID

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: width,
            height: height,
            margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Stack(
              children: [
                _buildImage(randomPetData['Image']),
                Positioned(
                  bottom: 0,
                  child: _buildInfoGlass(randomPetData),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<DocumentSnapshot>> _fetchRandomPets() async {
    final QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('Animal').get();
    final List<DocumentSnapshot> pets = snapshot.docs.toList();
    return pets;
  }

  Widget _buildInfoGlass(Map<String, dynamic> data) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(25),
      blur: 10,
      opacity: 0.15,
      child: Container(
        width: width,
        height: 110,
        padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: AppColor.shadowColor.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 1,
              offset: Offset(0, 2), // changes position of shadow
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfo(data),
            SizedBox(
              height: 5,
            ),
            _buildLocation(data),
            SizedBox(
              height: 15,
            ),
            _buildAttributes(data),
          ],
        ),
      ),
    );
  }

  Widget _buildLocation(Map<String, dynamic> data) {
    return Text(
      "Disability: ${data["PWD"] ?? ""}", // Using "PWD" field for location
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: AppColor.glassLabelColor,
        fontSize: 13,
      ),
    );
  }

  Widget _buildInfo(Map<String, dynamic> data) {
    return Row(
      children: [
        Expanded(
          child: Text(
            data["Name"] ?? "", // Using "Name" field for pet name
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColor.glassTextColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        FavoriteBox(
          isFavorited:
              data["is_favorited"] ?? false, // Keep is_favorited static
          onTap: onFavoriteTap,
        )
      ],
    );
  }

  Widget _buildImage(String? imageUrl) {
    return CustomImage(
      imageUrl ?? "", // Using "Image" field for image URL
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(radius),
        bottom: Radius.zero,
      ),
      isShadow: false,
      width: width,
      height: 350,
    );
  }

  Widget _buildAttributes(Map<String, dynamic> data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _getAttribute(
          Icons.assignment_ind,
          data["Personality"] ?? "", // Using "AgeInShelter" field for age
        ),
        _getAttribute(
          Icons.transgender,
          data["Gender"] ?? "", // Using "Personality" field for color
        ),
        _getAttribute(
          Icons.query_builder,
          data["AgeInShelter"] ?? "", // Using "AgeInShelter" field for age
        ),
      ],
    );
  }

  Widget _getAttribute(IconData icon, String info) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
        ),
        SizedBox(
          width: 3,
        ),
        Text(
          info,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColor.textColor, fontSize: 13),
        ),
      ],
    );
  }
}
