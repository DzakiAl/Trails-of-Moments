// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trails_of_moments/db_helper.dart';
import 'package:trails_of_moments/pages/edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  int userId;
  ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _selectedIndex = 3;
  String? profilePic;
  String? username;
  List<Map<String, dynamic>> userPosts = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile().then((_) {
      _loadUserPosts();
    });
  }

  void _onItemTapped(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      if (index == 0) {
        Navigator.pushReplacementNamed(context, '/homepage');
      } else if (index == 1) {
        Navigator.pushReplacementNamed(context, '/searchpage');
      } else if (index == 2) {
        Navigator.pushReplacementNamed(context, '/createpostpage');
      } else if (index == 3) {
        Navigator.pushReplacementNamed(context, '/profilepage');
      }
    }
  }

  Future<void> _loadUserProfile() async {
    if (widget.userId == 0) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? storedUserId = prefs.getInt('userId');

      if (storedUserId != null) {
        setState(() {
          widget.userId = storedUserId;
        });
      }
    }

    final user = await DBHelper.getUserById(widget.userId);
    if (user != null) {
      setState(() {
        username = user['username'] ?? "User";
        profilePic = user['profilePic'];
      });
    }
  }

  Future<void> _loadUserPosts() async {
    final posts = await DBHelper.getUserPosts(widget.userId);

    setState(() {
      userPosts = List<Map<String, dynamic>>.from(
        posts,
      ); // Ensure it's a modifiable list
    });
  }

  Future<void> _deletePost(int postId) async {
    bool confirmDelete =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text("Delete Post"),
                content: const Text(
                  "Are you sure you want to delete this post?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      "Delete",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmDelete) {
      // Remove the post from the list first to update the UI immediately
      setState(() {
        userPosts.removeWhere((post) => post['id'] == postId);
      });

      // Get the image path before deleting the post
      final post = await DBHelper.getPostById(postId);
      if (post != null) {
        String imagePath = post["image"];

        // Delete the image file
        File imageFile = File(imagePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
      }

      // Delete the post from the database
      await DBHelper.deletePost(postId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              bool confirmLogout =
                  await showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text("Log Out"),
                          content: const Text(
                            "Are you sure you want to log out?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                "Log Out",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                  ) ??
                  false;

              if (confirmLogout) {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);
                await prefs.remove('userId');
                Navigator.pushReplacementNamed(context, '/loginpage');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    backgroundImage:
                        profilePic != null
                            ? FileImage(File(profilePic!))
                            : const AssetImage("assets/default_avatar.jpg")
                                as ImageProvider,
                    radius: 70,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    username ?? "Loading...",
                    style: const TextStyle(fontSize: 30),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  EditProfilePage(userId: widget.userId),
                        ),
                      );
                      _loadUserProfile();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Edit Profile"),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Posts",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Divider(
                    thickness: 3,
                    color: Colors.black54,
                    indent: 20,
                    endIndent: 20,
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: MasonryGridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                itemCount: userPosts.length,
                shrinkWrap:
                    true, // Allows the grid to expand inside the scroll view
                physics:
                    const BouncingScrollPhysics(), // Allows internal scrolling
                itemBuilder: (context, index) {
                  final post = userPosts[index];

                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/postpage',
                            arguments: post,
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(post["image"]),
                            fit: BoxFit.cover, // Ensure it fills properly
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset("assets/default_image.png");
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 18,
                          child: IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: () => _deletePost(post['id']),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
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
