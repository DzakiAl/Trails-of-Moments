import 'db_helper.dart';

class AuthService {
  static Future<bool> isUsernameTaken(String name) async {
    final existingUser = await DBHelper.getUserByName(name);
    return existingUser != null; // Return true if user exists
  }

  static Future<bool> registerUser(
    String name,
    String email,
    String password,
  ) async {
    final isNameTaken = await isUsernameTaken(name);
    if (isNameTaken) return false; // Prevent duplicate usernames

    int result = await DBHelper.insertUser(name, email, password);
    return result > 0; // Returns true if the insert was successful
  }

  static Future<Map<String, dynamic>?> loginUser(
    String email,
    String password,
  ) async {
    return await DBHelper.login(email, password); // Returns user data or null
  }
}
