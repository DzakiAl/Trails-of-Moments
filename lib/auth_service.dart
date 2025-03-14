import 'db_helper.dart';

class AuthService {
  static Future<bool> registerUser(String username, String email, String password) async {
    try {
      await DBHelper.insertUser(username, email, password);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    return await DBHelper.login(email, password); // Returns user data or null
  }
}