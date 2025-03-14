import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:trails_of_moments/db_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required int userId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final int _selectedIndex = 0; // Track the selected tab
  List<Map<String, dynamic>> _posts = []; // Store fetched posts

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    final posts = await DBHelper.getAllPosts();
    setState(() {
      _posts = posts;
    });
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushNamed(context, '/homepage');
    } else if (index == 1) {
      Navigator.pushNamed(context, '/searchpage');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/createpostpage');
    } else if (index == 3) {
      Navigator.pushNamed(context, '/profilepage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Trails of Moments",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child:
            _posts.isEmpty
                ? const Center(
                  child: Text(
                    "No posts yet",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                )
                : MasonryGridView.count(
                  crossAxisCount: 2, // Two columns
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/postpage',
                          arguments: {
                            'id':_posts[index]['id'],
                            'image': _posts[index]['image'],
                            'username': _posts[index]['username'],
                            'description': _posts[index]['description'],
                            'profilePic': _posts[index]['profilePic'],
                            'comments': _posts[index]['comments'],
                          },
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          12,
                        ), // Rounded corners
                        child: Image.file(
                          File(_posts[index]['image']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        backgroundColor: Colors.white,
        elevation: 8,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
