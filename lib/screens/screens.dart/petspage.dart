import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String name;
  final String breed;
  final String gender;
  final String imageUrl;

  Pet({
    required this.name,
    required this.breed,
    required this.gender,
    required this.imageUrl,
  });
}

class PetsPage extends StatefulWidget {
  const PetsPage({Key? key}) : super(key: key);

  @override
  State<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends State<PetsPage> {
  // List of pets
  List<Pet> pets = [];

  // Controller for PageView
  late PageController _pageController;

  // Index to keep track of the current pet
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: currentIndex);
    // Fetch data when the page initializes
    fetchAnimalData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> fetchAnimalData() async {
    CollectionReference petsCollection =
        FirebaseFirestore.instance.collection('Animal');

    QuerySnapshot querySnapshot = await petsCollection.get();

    List<Pet> fetchedPets = [];

    querySnapshot.docs.forEach((doc) {
      Map<String, dynamic> petInfoMap = doc.data() as Map<String, dynamic>;
      fetchedPets.add(
        Pet(
          name: petInfoMap['Name'],
          breed: petInfoMap['Breed'],
          gender: petInfoMap['Gender'],
          imageUrl: petInfoMap['Image'],
        ),
      );
    });

    setState(() {
      pets = fetchedPets;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Swipe Pets'),
      ),
      body: Center(
        child: PageView.builder(
          controller: _pageController,
          itemCount: pets.length,
          onPageChanged: (index) {
            setState(() {
              currentIndex = index;
            });
          },
          itemBuilder: (context, index) {
            return _buildPetCard(index);
          },
        ),
      ),
    );
  }

  Widget _buildPetCard(int index) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1;
        if (_pageController.position.haveDimensions) {
          value = _pageController.page! - index;
          value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
        }
        return Center(
          child: SizedBox(
            height: Curves.easeOut.transform(value) * 400,
            width: Curves.easeOut.transform(value) * 300,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            _pageController.previousPage(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          } else if (details.primaryVelocity! < 0) {
            _pageController.nextPage(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
                20.0), // Rounded corners for the entire card
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20.0),
                child: Image.network(
                  pets[index].imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                left: 20,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        pets[index].name,
                        style: TextStyle(
                          fontSize: 28.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Handle onTap action here
                          // For example, you can navigate to a details screen
                          // or show more information about the pet
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                100), // Circular border radius
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: Ink(
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                    100), // Circular border radius to match icon size
                              ),
                              child: InkWell(
                                onTap: () {
                                  // Handle onTap action here
                                },
                                borderRadius: BorderRadius.circular(
                                    100), // Circular border radius to match icon size
                                child: Icon(
                                  Icons.visibility,
                                  color: Colors.white,
                                  size: 28.0,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailText(Icons.category,
                          'Breed: ${pets[index].breed}', Colors.white),
                      SizedBox(height: 5),
                      _buildDetailText(Icons.wc,
                          'Gender: ${pets[index].gender}', Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailText(IconData iconData, String text, Color color) {
    return Row(
      children: [
        Icon(iconData, color: color, size: 20),
        SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(fontSize: 18.0, color: color),
        ),
      ],
    );
  }
}
