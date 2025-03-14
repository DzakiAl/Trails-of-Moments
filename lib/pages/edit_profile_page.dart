// ignore_for_file: library_prefixes

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as Path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trails_of_moments/db_helper.dart';

class EditProfilePage extends StatefulWidget {
  int userId;
  EditProfilePage({super.key, required this.userId});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  int _selectedIndex = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _verifyPasswordController = TextEditingController();
  File? _selectedImage;
  String? _profilePicPath;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
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
        _nameController.text = user['username'];
        _emailController.text = user['email'];
        _profilePicPath = user['profilePic'];
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final path = Path.join(directory.path, Path.basename(pickedFile.path));
      final File newImage = await File(pickedFile.path).copy(path);

      setState(() {
        _selectedImage = newImage;
        _profilePicPath = newImage.path; // Ensure the path is updated
      });
    }
  }

  Future<void> _saveProfileChanges() async {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();

    String? imagePath = _profilePicPath;
    if (_selectedImage != null) {
      imagePath = _selectedImage!.path;
    }

    await DBHelper.updateProfile(widget.userId, name, email, imagePath);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );

      // Navigate back to refresh the profile page
      Navigator.pop(context, true);
    }
  }

  Future<void> _savePasswordChanges() async {
    final String password = _passwordController.text.trim();
    final String verifyPassword = _verifyPasswordController.text.trim();

    if (password.isEmpty ||
        verifyPassword.isEmpty ||
        password != verifyPassword) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match!")),
        );
      }
      return;
    }

    await DBHelper.updatePassword(widget.userId, password);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password changed successfully!")),
      );
    }

    _passwordController.clear();
    _verifyPasswordController.clear();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate based on index
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
          "Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundImage:
                        _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (_profilePicPath != null
                                    ? FileImage(File(_profilePicPath!))
                                    : const AssetImage(
                                      "assets/default_avatar.jpg",
                                    ))
                                as ImageProvider,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 20,
                      ),
                    ),
                    child: const Text(
                      "Change Picture",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Change Name"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "Change Email"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfileChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
              ),
              child: const Text(
                "Save Profile Changes",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "New Password"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _verifyPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Verify New Password",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _savePasswordChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
              ),
              child: const Text(
                "Save Password Changes",
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 40),
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
