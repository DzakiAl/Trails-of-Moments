import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:bcrypt/bcrypt.dart';

class DBHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL,
            profilePic TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE posts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            image TEXT NOT NULL,
            description TEXT,
            keywords TEXT,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE comments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            post_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            content TEXT NOT NULL,
            parent_id INTEGER,
            FOREIGN KEY(post_id) REFERENCES posts(id) ON DELETE CASCADE,
            FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY(parent_id) REFERENCES comments(id) ON DELETE CASCADE
          );
        ''');
      },
    );
  }

  static Future<int> insertUser(
    String username,
    String email,
    String password,
  ) async {
    final db = await database;

    // Hash password using BCrypt
    String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

    return await db.insert('users', {
      'username': username,
      'email': email,
      'password': hashedPassword,
      'profilePic': null,
    });
  }

  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    final db = await database;

    // Fetch user by email
    List<Map<String, dynamic>> users = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (users.isNotEmpty) {
      String storedHashedPassword = users.first['password'];

      // Verify password using BCrypt
      if (BCrypt.checkpw(password, storedHashedPassword)) {
        return users.first; // Password is correct
      }
    }

    return null; // Invalid email or password
  }

  static Future<int> updateProfile(
    int userId,
    String username,
    String email,
    String? profilePic,
  ) async {
    final db = await database;
    return await db.update(
      'users',
      {'username': username, 'email': email, 'profilePic': profilePic},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  static Future<Map<String, dynamic>?> getUserById(int userId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  static Future<int> updatePassword(int userId, String newPassword) async {
    final db = await database;

    // Hash the new password
    String hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt());

    return await db.update(
      'users',
      {'password': hashedPassword},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  static Future<List<Map<String, dynamic>>> getUserPosts(int userId) async {
    final db = await database;

    List<Map<String, dynamic>> result = await db.rawQuery(
      '''
    SELECT * FROM posts WHERE user_id = ?
  ''',
      [userId],
    );
  
    return result;
  }

  static Future<int> insertPost(
    int userId,
    String imagePath,
    String description,
    String keywords,
  ) async {
    final db = await database;
    return await db.insert('posts', {
      'user_id': userId,
      'image': imagePath,
      'description': description,
      'keywords': keywords,
    });
  }

  static Future<List<Map<String, dynamic>>> getAllPosts() async {
    final db = await database;
    return await db.query('posts', orderBy: 'id DESC');
  }

  static Future<List<Map<String, dynamic>>> getAllPostsWithUserData() async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.rawQuery('''
    SELECT posts.*, users.username, users.profilePic 
    FROM posts
    JOIN users ON posts.user_id = users.id
    ORDER BY posts.id DESC
  ''');

    return result;
  }

  static Future<int> deletePost(int postId) async {
    final db = await database;
    return await db.delete('posts', where: 'id = ?', whereArgs: [postId]);
  }

  static Future<Map<String, dynamic>?> getPostById(int postId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'posts',
      where: 'id = ?',
      whereArgs: [postId],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  static Future<void> printDatabaseContents() async {
    final db = await database;

    // Fetch all users
    List<Map<String, dynamic>> users = await db.query('users');
    print("=== Users Table ===");
    for (var user in users) {
      print(user);
    }

    // Fetch all posts
    List<Map<String, dynamic>> posts = await db.query('posts');
    print("\n=== Posts Table ===");
    for (var post in posts) {
      print(post);
    }

    // Fetch all comments
    List<Map<String, dynamic>> comments = await db.query('comments');
    print("\n=== Comments Table ===");
    for (var comment in comments) {
      print(comment);
    }
  }

  static Future<List<Map<String, dynamic>>> getCommentsByPostId(
    int postId,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT comments.*, users.username, users.profilePic 
    FROM comments
    JOIN users ON comments.user_id = users.id
    WHERE comments.post_id = ?
    ORDER BY comments.id ASC
  ''',
      [postId],
    );
  }

  static Future<void> addComment(int postId, int userId, String content) async {
    final db = await database;
    await db.insert('comments', {
      'post_id': postId,
      'user_id': userId,
      'content': content,
    });
  }

  static Future<int> deleteComment(int commentId) async {
    final db = await database;
    return await db.delete('comments', where: 'id = ?', whereArgs: [commentId]);
  }

    static Future<Map<String, dynamic>?> getUserByName(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [name],
    );
    return result.isNotEmpty ? result.first : null;
  }
}
