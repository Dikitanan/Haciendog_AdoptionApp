import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mad/screens/screens.dart/petdetails.dart';

class PetList extends StatefulWidget {
  @override
  _PetListState createState() => _PetListState();
}

class _PetListState extends State<PetList> {
  String currentCategory = 'All';
  String currentFilter = 'All';

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(child: Text('User not signed in.'));
    }

    String userEmail = user.email!;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Favorite Pets'),
          bottom: TabBar(
            tabs: ['All', 'Dog', 'Cat']
                .map((category) => Tab(text: category))
                .toList(),
            onTap: (index) {
              setState(() {
                currentCategory = ['All', 'Dog', 'Cat'][index];
              });
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: DropdownButton<String>(
                value: currentFilter,
                items: <String>['All', 'Form Submitted', 'Form Unsubmitted']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    currentFilter = newValue!;
                  });
                },
              ),
            ),
          ],
        ),
        body: buildBody(userEmail, currentCategory, currentFilter),
      ),
    );
  }

  Widget buildBody(
      String userEmail, String currentCategory, String currentFilter) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('AnimalHearted')
          .where('email', isEqualTo: userEmail)
          .where('is_favorited', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("There are no favorited pets."));
        }

        List<String> favoritePetIds = snapshot.data!.docs
            .map((doc) => doc['currentPetId'] as String)
            .toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Animal')
              .where(FieldPath.documentId, whereIn: favoritePetIds)
              .snapshots(),
          builder: (context, animalSnapshot) {
            if (animalSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (animalSnapshot.hasError) {
              return Text('Error: ${animalSnapshot.error}');
            }
            if (!animalSnapshot.hasData || animalSnapshot.data!.docs.isEmpty) {
              return Center(child: Text("No pets found."));
            }

            List<DocumentSnapshot> filteredAnimals = currentCategory == 'All'
                ? animalSnapshot.data!.docs
                : animalSnapshot.data!.docs
                    .where((doc) => doc['CatOrDog'] == currentCategory)
                    .toList();

            return FutureBuilder<List<DocumentSnapshot>>(
              future: _filterAnimalsByFormSubmission(
                  filteredAnimals, userEmail, currentFilter),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }
                List<DocumentSnapshot> filteredAnimals = snapshot.data ?? [];

                return Container(
                  height: 590,
                  child: ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: filteredAnimals.length,
                    itemBuilder: (context, index) {
                      DocumentSnapshot pet = filteredAnimals[index];
                      // Directly access the corresponding document from snapshot.data!
                      DocumentSnapshot? animalHeartedDoc =
                          snapshot.data!.firstWhere(
                        (doc) => doc.id == pet.id,
                        orElse: () => pet,
                      );
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: buildPetTile(pet, animalHeartedDoc, userEmail),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<DocumentSnapshot>> _filterAnimalsByFormSubmission(
      List<DocumentSnapshot> animals,
      String userEmail,
      String currentFilter) async {
    List<DocumentSnapshot> filteredAnimals = [];

    for (DocumentSnapshot animal in animals) {
      bool isFormSubmitted = await _isFormSubmitted(userEmail, animal.id);
      if (currentFilter == 'All' ||
          (currentFilter == 'Form Submitted' && isFormSubmitted) ||
          (currentFilter == 'Form Unsubmitted' && !isFormSubmitted)) {
        filteredAnimals.add(animal);
      }
    }

    return filteredAnimals;
  }

  Future<bool> _isFormSubmitted(String userEmail, String petId) async {
    QuerySnapshot formSnapshots = await FirebaseFirestore.instance
        .collection('AdoptionForms')
        .where('email', isEqualTo: userEmail)
        .where('petId', isEqualTo: petId)
        .get();

    return formSnapshots.docs.isNotEmpty;
  }

  Widget buildPetTile(DocumentSnapshot pet, DocumentSnapshot animalHeartedDoc,
      String userEmail) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('AdoptionForms')
          .where('email', isEqualTo: userEmail)
          .where('petId', isEqualTo: pet.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Show loading indicator while checking for form submission
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        // Check if there's a match in AdoptionForms
        bool isFormSubmitted =
            snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        // Get the status from the first document in the snapshot if available
        String status = 'Pending'; // Default status
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          status = snapshot.data!.docs.first['status'];
        }

        // Determine the text and color based on the status
        String formStatusText = '';
        Color formStatusColor = Colors.blue; // Default color for pending

        if (status == 'Accepted') {
          formStatusText = 'Form Accepted';
          formStatusColor = Colors.green;
        } else if (status == 'Rejected') {
          formStatusText = 'Form Rejected';
          formStatusColor = Colors.red;
        } else if (status == 'Cancelled') {
          formStatusText = 'Cancelled';
          formStatusColor = Colors.red;
        } else if (status == 'Archived') {
          // If the status is "Archived", we don't want to display any tag
          formStatusText = '';
        } else {
          formStatusText = isFormSubmitted ? 'Form Submitted' : '';
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => PetDetailsDialog(currentPetId: pet.id)),
            );
          },
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      Image.network(
                        pet['Image'] ?? '',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Container(
                        padding: EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              pet['Name'],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.pets, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Breed: ${pet['Breed']}',
                                  style: TextStyle(color: Colors.white),
                                ),
                                SizedBox(width: 15),
                                Icon(Icons.wc, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Gender: ${pet['Gender']}',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                          ],
                        ),
                      ),
                      if (formStatusText
                          .isNotEmpty) // Show label if form status is not empty
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: formStatusColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              formStatusText,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () =>
                      toggleFavoriteStatus(animalHeartedDoc, pet.id, userEmail),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void toggleFavoriteStatus(
      DocumentSnapshot animalHeartedDoc, String petId, String userEmail) async {
    // Function for checking the status of the AdoptionForms
    Future<bool> checkAdoptionFormStatus() async {
      bool isAccepted = false;
      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('AdoptionForms')
            .where('petId', isEqualTo: petId)
            .where('email', isEqualTo: userEmail)
            .get();

        querySnapshot.docs.forEach((doc) {
          if (doc['status'] == 'Accepted') {
            isAccepted = true;
          }
        });
      } catch (error) {
        print("Error checking adoption form status: $error");
      }
      return isAccepted;
    }

    // Check the status of the AdoptionForms
    bool adoptionFormAccepted = await checkAdoptionFormStatus();

    // If AdoptionForm is accepted, show dialog and return
    if (adoptionFormAccepted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Action not Permitted"),
            content: Text(
                "Reason: Your Adoption form is already accepted. Please message the Admin if you want to Cancel your Adoption Form."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    // Update the status of the document in the AdoptionForms collection to "Archived"
    await FirebaseFirestore.instance
        .collection('AdoptionForms')
        .where('petId', isEqualTo: petId)
        .where('email', isEqualTo: userEmail)
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        doc.reference.update({'status': 'Archived'});
      });
    }).catchError((error) {
      print("Error updating document status: $error");
    });

    // Update the is_favorited field in the AnimalHearted collection
    await FirebaseFirestore.instance
        .collection('AnimalHearted')
        .where('currentPetId', isEqualTo: petId)
        .where('email', isEqualTo: userEmail)
        .get()
        .then((querySnapshot) {
      querySnapshot.docs.forEach((doc) async {
        // Toggle the is_favorited field
        bool currentStatus = doc['is_favorited'];
        await doc.reference.update({'is_favorited': !currentStatus});
      });
    }).catchError((error) {
      print("Error updating favorite status: $error");
    });
  }
}
