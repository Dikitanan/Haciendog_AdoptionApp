import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:mad/screens/screens.dart/petdetails.dart';
import 'package:mad/theme/color.dart';
import 'package:mad/widgets/custom_image.dart';
import 'package:mad/widgets/favorite_box.dart'; // Import FavoriteBox widget

class PetItem extends StatefulWidget {
  const PetItem({
    Key? key,
    required this.docId,
    this.width = 350,
    this.height = 400,
    this.radius = 40,
    this.onTap,
    required this.category,
    this.onFavoriteTap,
    required Map<String, dynamic> data,
  }) : super(key: key);

  final String docId;
  final String category;
  final double width;
  final double height;
  final double radius;
  final GestureTapCallback? onTap;
  final GestureTapCallback? onFavoriteTap;

  @override
  _PetItemState createState() => _PetItemState();
}

class _PetItemState extends State<PetItem>
    with AutomaticKeepAliveClientMixin<PetItem>, TickerProviderStateMixin {
  // Keep track of the previously displayed pet's ID
  static String? previousPetId;

  late Future<List<DocumentSnapshot>> _fetchPetsFuture; // Add this variable

  @override
  void initState() {
    super.initState();
    _fetchPetsFuture = _fetchRandomPets(
        widget.category, previousPetId); // Fetch pets when initializing state
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Ensure build method is called

    return FutureBuilder<List<DocumentSnapshot>>(
      future: _fetchPetsFuture, // Use the fetched future here
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        final petList = snapshot.data ?? [];
        if (petList.isEmpty) {
          // Return a message if no favorites are found
          return Center(
            child: Text(
              "There's no Favorites yet",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        // Find the next pet index to display
        int nextPetIndex = 0;
        if (previousPetId != null) {
          nextPetIndex =
              (petList.indexWhere((pet) => pet.id == previousPetId) + 1) %
                  petList.length;
        }

        final randomPetData =
            petList[nextPetIndex].data() as Map<String, dynamic>;
        final currentPetId =
            petList[nextPetIndex].id; // Store the current pet's ID

        previousPetId =
            currentPetId; // Update previousPetId with the current pet's ID

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      PetDetailsDialog(currentPetId: currentPetId)),
            );
          },
          // Use the onTap callback passed from _buildPets
          child: Container(
            width: widget.width,
            height: widget.height,
            margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
            ),
            child: Stack(
              children: [
                _buildImage(randomPetData['Image']),
                Positioned(
                  top: 5,
                  right: 5,
                  child: Tooltip(
                    message: 'Click the image to see the pet details',
                    child: IconButton(
                      icon: Icon(Icons.info),
                      onPressed: () {},
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: _buildInfoGlass(randomPetData,
                      currentPetId), // Pass currentPetId to _buildInfoGlass
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<DocumentSnapshot>> _fetchRandomPets(
      String category, String? previousPetId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return []; // Return empty list if the user is not signed in
    }

    String userEmail = user.email!;

    // Fetch user favorites from AnimalHearted
    QuerySnapshot favoriteSnapshot = await FirebaseFirestore.instance
        .collection('AnimalHearted')
        .where('email', isEqualTo: userEmail)
        .where('is_favorited', isEqualTo: true) // Only fetch favorited pets
        .get();

    List<String> favoritePetIds = favoriteSnapshot.docs
        .map((doc) => doc['currentPetId'] as String)
        .toList();

    if (favoritePetIds.isEmpty) {
      return []; // If there are no favorited pets, return an empty list to avoid error
    }

    // Now fetch pets from Animal collection that are also favorited by the user
    QuerySnapshot animalSnapshot;
    if (category == 'All') {
      animalSnapshot = await FirebaseFirestore.instance
          .collection('Animal')
          .where(FieldPath.documentId, whereIn: favoritePetIds)
          .get();
    } else {
      animalSnapshot = await FirebaseFirestore.instance
          .collection('Animal')
          .where('CatOrDog', isEqualTo: category)
          .where(FieldPath.documentId, whereIn: favoritePetIds)
          .get();
    }

    List<DocumentSnapshot> pets = animalSnapshot.docs.toList();

    // Return all pets without shuffling or removing any
    return pets;
  }

  Widget _buildInfoGlass(Map<String, dynamic> data, String currentPetId) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(25),
      blur: 10,
      opacity: 0.15,
      child: Container(
        width: widget.width,
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
            _buildInfo(data, currentPetId),
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

  Widget _buildInfo(Map<String, dynamic> data, String currentPetId) {
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
        FavoriteBoxStatefulWidget(
          currentPetId: currentPetId,
          onFavoriteChanged: refresh, // Pass the callback here
        ),
      ],
    );
  }

  Widget _buildImage(String? imageUrl) {
    return CustomImage(
      imageUrl ?? "", // Using "Image" field for image URL
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(widget.radius),
        bottom: Radius.zero,
      ),
      isShadow: false,
      width: widget.width,
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

  void refresh() {
    setState(() {});
  }

  @override
  bool get wantKeepAlive => true; // Keep the state alive
}

class FavoriteBoxStatefulWidget extends StatefulWidget {
  final String currentPetId;
  final VoidCallback onFavoriteChanged;

  const FavoriteBoxStatefulWidget({
    Key? key,
    required this.currentPetId,
    required this.onFavoriteChanged,
  }) : super(key: key);

  @override
  _FavoriteBoxStatefulWidgetState createState() =>
      _FavoriteBoxStatefulWidgetState();
}

class _FavoriteBoxStatefulWidgetState extends State<FavoriteBoxStatefulWidget> {
  late Future<bool> _isFavorited;

  @override
  void initState() {
    super.initState();
    _isFavorited = _checkIsFavorited(widget.currentPetId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isFavorited,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container();
        }
        bool isFavorited = snapshot.data ?? false;
        return FavoriteBox(
          isFavorited: isFavorited,
          onTap: () async {
            // Fetch the current user's email using Firebase Authentication
            User? user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              String currentUserEmail = user.email!;
              String collectionName = "AnimalHearted";

              // Check if there's a match for the current user's email and currentPetId
              QuerySnapshot snapshot = await FirebaseFirestore.instance
                  .collection(collectionName)
                  .where("email", isEqualTo: currentUserEmail)
                  .where("currentPetId", isEqualTo: widget.currentPetId)
                  .get();

              // Toggle favorite status and update Firestore
              bool isFavorited = snapshot.docs.isNotEmpty
                  ? snapshot.docs[0]["is_favorited"]
                  : false;
              if (snapshot.docs.isEmpty) {
                await FirebaseFirestore.instance
                    .collection(collectionName)
                    .add({
                  "email": currentUserEmail,
                  "is_favorited": !isFavorited,
                  "currentPetId": widget.currentPetId,
                });
              } else {
                await snapshot.docs[0].reference.update({
                  "is_favorited": !isFavorited,
                });
              }
              // Update favorite status in the widget state
              setState(() {
                _isFavorited = Future.value(!isFavorited);
              });

              widget.onFavoriteChanged(); // Call the callback here
            } else {
              // Handle case where user is not signed in
              // You can show a message or prompt the user to sign in
            }
          },
        );
      },
    );
  }

  Future<bool> _checkIsFavorited(String currentPetId) async {
    // Fetch the current user's email using Firebase Authentication
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String currentUserEmail = user.email!;
      String collectionName = "AnimalHearted";

      // Check if there's a match for the current user's email and currentPetId
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .where("email", isEqualTo: currentUserEmail)
          .where("currentPetId", isEqualTo: currentPetId)
          .get();

      return snapshot.docs.isNotEmpty
          ? snapshot.docs[0]["is_favorited"]
          : false;
    }
    return false; // Return false if user is not signed in
  }
}
