import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
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

class _PetItemState extends State<PetItem> {
  // Keep track of the previously displayed pet's ID
  static String? previousPetId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: _fetchRandomPets(widget.category, previousPetId),
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
        final currentPetId = petList.first.id; // Store the current pet's ID

        previousPetId =
            currentPetId; // Update previousPetId with the current pet's ID

        return GestureDetector(
          onTap: widget.onTap, // Use the onTap callback passed from _buildPets
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
    QuerySnapshot snapshot;
    if (category == 'All') {
      snapshot = await FirebaseFirestore.instance.collection('Animal').get();
    } else {
      snapshot = await FirebaseFirestore.instance
          .collection('Animal')
          .where('CatOrDog', isEqualTo: category)
          .get();
    }

    List<DocumentSnapshot> pets = snapshot.docs.toList();

    // Filter out pets with status "Adopted"
    pets = pets.where((pet) => pet['Status'] != 'Adopted').toList();

    // Shuffle the list initially
    pets.shuffle();

    // Remove the previousPetId from the list of pets and shuffle again if necessary
    while (pets.isNotEmpty && pets.first.id == previousPetId) {
      pets.removeAt(0);
      pets.shuffle();
    }

    // Return a maximum of 1 pet (or an empty list if no pets remain)
    return pets.isNotEmpty ? [pets.first] : [];
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
      "Health Status: ${data["PWD"] ?? ""}", // Using "PWD" field for location
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: AppColor.glassLabelColor,
        fontSize: 13,
      ),
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
}

class FavoriteBoxStatefulWidget extends StatefulWidget {
  final String currentPetId;

  const FavoriteBoxStatefulWidget({
    Key? key,
    required this.currentPetId,
  }) : super(key: key);

  @override
  _FavoriteBoxStatefulWidgetState createState() =>
      _FavoriteBoxStatefulWidgetState();
}

class _FavoriteBoxStatefulWidgetState extends State<FavoriteBoxStatefulWidget> {
  late Stream<bool> _isFavoritedStream;

  @override
  void initState() {
    super.initState();
    _isFavoritedStream = _checkIsFavorited(widget.currentPetId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _isFavoritedStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container();
        }
        bool isFavorited = snapshot.data!;
        return FavoriteBox(
          isFavorited: isFavorited,
          onTap: () async {
            // Fetch the current user's email using Firebase Authentication
            User? user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              String currentUserEmail = user.email!;
              String collectionName = "AnimalHearted";

              // Check if the pet is already adopted or in the process
              String adoptionFormsCollection = "AdoptionForms";
              QuerySnapshot adoptionSnapshot = await FirebaseFirestore.instance
                  .collection(adoptionFormsCollection)
                  .where("email", isEqualTo: currentUserEmail)
                  .where("petId", isEqualTo: widget.currentPetId)
                  .get();

              if (adoptionSnapshot.docs.isNotEmpty) {
                String status = adoptionSnapshot.docs[0]["status"];
                if (status == "Accepted" ||
                    status == "Shipped" ||
                    status == "Adopted") {
                  // Pet cannot be unfavorited, send a message to the user
                  Fluttertoast.showToast(
                      msg:
                          "Pet cannot be unfavorited because it is already adopted or in the process.",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.CENTER,
                      timeInSecForIosWeb: 1,
                      backgroundColor: Colors.red,
                      textColor: Colors.white,
                      fontSize: 16.0);
                  return; // Exit the onTap function without toggling favorite status
                }
              }

              // Proceed with toggling favorite status and updating Firestore
              _unfavoritePet(currentUserEmail);
            } else {
              // Handle case where user is not signed in
              Fluttertoast.showToast(
                  msg: "You need to sign in to use this feature!",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0);
            }
          },
        );
      },
    );
  }

  void _unfavoritePet(String userEmail) async {
    // Update status to "Archived" for the pet
    await FirebaseFirestore.instance
        .collection('AdoptionForms')
        .where('petId', isEqualTo: widget.currentPetId)
        .where('email', isEqualTo: userEmail)
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        doc.reference.update({'status': 'Archived'});
      });
    }).catchError((error) {
      print("Error updating document status: $error");
    });

    // Toggle favorite status and update Firestore
    String collectionName = "AnimalHearted";
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection(collectionName)
        .where("email", isEqualTo: userEmail)
        .where("currentPetId", isEqualTo: widget.currentPetId)
        .get();

    bool isFavorited =
        snapshot.docs.isNotEmpty ? snapshot.docs[0]["is_favorited"] : false;
    String toastMessage;
    if (snapshot.docs.isEmpty) {
      await FirebaseFirestore.instance.collection(collectionName).add({
        "email": userEmail,
        "is_favorited": !isFavorited,
        "currentPetId": widget.currentPetId,
      });
      toastMessage = !isFavorited
          ? "Pet Added to Favorites"
          : "Pet Removed from Favorites";
    } else {
      await snapshot.docs[0].reference.update({
        "is_favorited": !isFavorited,
      });
      toastMessage = !isFavorited
          ? "Pet Added to Favorites"
          : "Pet Removed from Favorites";
    }
    Fluttertoast.showToast(
        msg: toastMessage,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.grey[800],
        textColor: Colors.white,
        fontSize: 16.0);
  }

  Stream<bool> _checkIsFavorited(String currentPetId) {
    // Fetch the current user's email using Firebase Authentication
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String currentUserEmail = user.email!;
      String collectionName = "AnimalHearted";

      // Create a stream controller to handle the updates
      StreamController<bool> controller = StreamController<bool>();

      // Listen for changes in Firestore and add them to the stream
      FirebaseFirestore.instance
          .collection(collectionName)
          .where("email", isEqualTo: currentUserEmail)
          .where("currentPetId", isEqualTo: currentPetId)
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.docs.isNotEmpty) {
          String adoptionFormsCollection = "AdoptionForms";
          QuerySnapshot adoptionSnapshot = await FirebaseFirestore.instance
              .collection(adoptionFormsCollection)
              .where("email", isEqualTo: currentUserEmail)
              .where("petId", isEqualTo: currentPetId)
              .get();

          if (adoptionSnapshot.docs.isNotEmpty) {
            String status = adoptionSnapshot.docs[0]["status"];
            if (status == "Accepted" ||
                status == "Shipped" ||
                status == "Adopted") {
              // Pet cannot be unfavorited, send a message to the user
              controller.addError(
                  "Pet cannot be unfavorited because it is already adopted or in the process.");
            } else {
              controller.add(snapshot.docs[0]["is_favorited"]);
            }
          } else {
            controller.add(false);
          }
        } else {
          controller.add(false);
        }
      });

      return controller.stream;
    }
    // Return an empty stream if user is not signed in
    return Stream<bool>.empty();
  }
}
