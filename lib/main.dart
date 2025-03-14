// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trails_of_moments/pages/home_page.dart';
import 'package:trails_of_moments/pages/post_page.dart';
import 'package:trails_of_moments/pages/search_page.dart';
import 'package:trails_of_moments/pages/create_post_page.dart';
import 'package:trails_of_moments/pages/profile_page.dart';
import 'package:trails_of_moments/pages/login_page.dart';
import 'package:trails_of_moments/pages/register_page.dart';
import 'package:trails_of_moments/pages/edit_profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(), // Decides where to navigate
      routes: {
        '/homepage': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as int?;
          return HomePage(userId: args ?? 0);
        },
        '/searchpage': (context) => SearchPage(),
        '/createpostpage': (context) => CreatePostPage(),
        '/profilepage': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as int?;
          return ProfilePage(userId: args ?? 0);
        },
        '/postpage': (context) => const PostPage(),
        '/loginpage': (context) => const LoginPage(),
        '/registerpage': (context) => const RegisterPage(),
        '/editprofilepage': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as int?;
          return EditProfilePage(userId: args ?? 0);
        },
      },
    );
  }
}

// Checks if user is logged in using SharedPreferences
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    int? userId = prefs.getInt('userId');

    setState(() {
      _isLoggedIn = isLoggedIn;
      _userId = userId;
      _isLoading = false;
    });

    if (isLoggedIn && userId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(userId: userId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _isLoggedIn && _userId != null
        ? HomePage(userId: _userId!)
        : const LoginPage();
  }
}