// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trails_of_moments/db_helper.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  int? userId;
  final int _selectedIndex = 0;
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _comments = [];
  final TextEditingController _commentController = TextEditingController();
  int? _postId;

  Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  @override
  void initState() {
    super.initState();

    _getCurrentUserId(); // Fetch and store user ID

    Future.delayed(Duration.zero, () {
      final Map<String, dynamic>? postData =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (postData != null && postData.containsKey('id')) {
        _postId = postData['id'];
        _fetchPosts(_postId!);
        _fetchComments(_postId!);
      } else {
        print("ERROR: Post ID not found in arguments");
      }
    });
  }

  void _getCurrentUserId() async {
    userId = await getUserId(); // Fetch user ID
    setState(() {}); // Refresh UI to reflect the userId
  }

  Future<void> _fetchPosts(int postId) async {
    final posts = await DBHelper.getAllPostsWithUserData();
    if (posts.isEmpty) {
      print("ERROR: No posts found in the database.");
      return;
    }

    final List<Map<String, dynamic>> modifiablePosts = List.from(posts);
    final selectedPostIndex = modifiablePosts.indexWhere(
      (post) => post['id'] == postId,
    );

    if (selectedPostIndex != -1) {
      final selectedPost = modifiablePosts.removeAt(selectedPostIndex);
      modifiablePosts.insert(0, selectedPost);
    } else {
      print("ERROR: Post with ID $postId not found in database.");
    }

    setState(() {
      _posts = modifiablePosts;
    });

    print("DEBUG: Posts successfully fetched and reordered.");
  }

  Future<void> _fetchComments(int postId) async {
    final comments = await DBHelper.getCommentsByPostId(postId);
    setState(() {
      _comments = comments;
    });
  }

  Future<void> _addComment(int postId) async {
    if (_commentController.text.trim().isEmpty) return;

    final int? userId = await getUserId();
    if (userId == null) {
      print("ERROR: User ID not found");
      return;
    }

    await DBHelper.addComment(postId, userId, _commentController.text.trim());
    _commentController.clear();

    // Refresh comments only for the specific post
    await _fetchComments(postId);
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

  void _showCommentsBottomSheet(BuildContext context, int postId) {
    _fetchComments(postId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows proper resizing
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets, // Adjust for keyboard
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const Text(
                      "Comments",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    SizedBox(
                      height: 300, // Ensure enough space for comments
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  comment["profilePic"] != null
                                      ? FileImage(File(comment["profilePic"]))
                                      : const AssetImage(
                                            "assets/default_avatar.jpg",
                                          )
                                          as ImageProvider,
                            ),
                            title: Text(comment["username"] ?? "Unknown User"),
                            subtitle: Text(comment["content"] ?? ""),
                            trailing:
                                (userId != null && comment["user_id"] == userId)
                                    ? IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        await DBHelper.deleteComment(comment["id"]);
                                        await _fetchComments(postId); // Wait for the comments to refresh
                                        setState(() {}); // Update the UI after fetching the new comments
                                      },
                                    )
                                    : null,
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              decoration: InputDecoration(
                                hintText: "Add a comment...",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.grey[200],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () async {
                              await _addComment(postId);
                              setState(() {}); // Refresh the bottom sheet
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? postData =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

    if (postData == null || _posts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Post")),
        body: const Center(child: Text("Post not found")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Post Details",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post Image
              ClipRRect(
                borderRadius: BorderRadius.circular(0), // No padding
                child: Image.file(
                  File(post["image"]),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              // Padding for Post Info
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage:
                              post["profilePic"] != null
                                  ? FileImage(File(post["profilePic"]))
                                      as ImageProvider
                                  : const AssetImage(
                                    "assets/default_avatar.jpg",
                                  ),
                          radius: 25,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          post["username"] ?? "Unknown User",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Description
                    Text(
                      post["description"] ?? "No description",
                      style: const TextStyle(fontSize: 16),
                    ),

                    const SizedBox(height: 10),

                    // Comments Section
                    GestureDetector(
                      onTap:
                          () => _showCommentsBottomSheet(context, post["id"]),
                      child: Text(
                        "Comments",
                        style: const TextStyle(
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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
