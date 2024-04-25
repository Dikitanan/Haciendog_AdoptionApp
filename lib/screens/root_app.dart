import 'package:flutter/material.dart';
import 'package:mad/screens/screens.dart/petspage.dart';

class RootApp extends StatefulWidget {
  const RootApp({Key? key}) : super(key: key);

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          height: 30,
          child: AppBar(
            backgroundColor: Colors.blue,
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        children: [
          // Replace these with your actual body content widgets
          Center(child: Text('Home Page')),
          Center(child: Text('Search Page')),
          Center(child: PetsPage()),
          Center(child: Text('Favorites Page')),
          Center(child: Text('Profile Page')),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                _pageController.animateToPage(0,
                    duration: Duration(milliseconds: 300), curve: Curves.ease);
              },
            ),
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                _pageController.animateToPage(1,
                    duration: Duration(milliseconds: 300), curve: Curves.ease);
              },
            ),
            InkWell(
              onTap: () {
                _pageController.animateToPage(2,
                    duration: Duration(milliseconds: 300), curve: Curves.ease);
              },
              child: Container(
                width: 56.0,
                height: 56.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                child: Icon(Icons.pets, color: Colors.white),
              ),
            ),
            IconButton(
              icon: Icon(Icons.favorite),
              onPressed: () {
                _pageController.animateToPage(3,
                    duration: Duration(milliseconds: 300), curve: Curves.ease);
              },
            ),
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                _pageController.animateToPage(4,
                    duration: Duration(milliseconds: 300), curve: Curves.ease);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
