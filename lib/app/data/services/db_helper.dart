import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cityxplore/app/data/models/user_model.dart';
import 'package:cityxplore/app/data/models/post_model.dart';
import 'package:cityxplore/app/data/models/like_model.dart';
import 'package:cityxplore/app/data/models/saved_model.dart';

class DbHelper {
  static Database? _database;
  static const String _databaseName = "cityxplore.db";
  static const int _databaseVersion = 1;

  // Nama tabel
  static const String _userTable = 'user';
  static const String _postTable = 'post';
  static const String _likeTable = 'like';
  static const String _savedTable = 'saved';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = await getDatabasesPath();
    String databasePath = join(path, _databaseName);
    return await openDatabase(
      databasePath,
      version: _databaseVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
      onUpgrade: _onUpgrade,
    );
  }

  // Penting: Mengaktifkan Foreign Key Support
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  _onCreate(Database db, int version) async {
    // Buat tabel User
    await db.execute(
      '''
      CREATE TABLE $_userTable(
        uid INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        photoPath TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''',
    );

    await db.execute(
      '''
      CREATE TABLE $_postTable(
        postId INTEGER PRIMARY KEY AUTOINCREMENT,
        uid INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        detailLoc TEXT NOT NULL,
        postTitle TEXT NOT NULL,
        postDesc TEXT,
        postPrice REAL NOT NULL,
        postImage TEXT,
        createdAt TEXT NOT NULL,
        timeZone TEXT,
        FOREIGN KEY (uid) REFERENCES $_userTable (uid) ON DELETE CASCADE
      )
    ''',
    );

    // Buat tabel Like
    await db.execute(
      '''
      CREATE TABLE $_likeTable(
        uid INTEGER NOT NULL,
        postId INTEGER NOT NULL,
        PRIMARY KEY (uid, postId),
        FOREIGN KEY (uid) REFERENCES $_userTable (uid) ON DELETE CASCADE,
        FOREIGN KEY (postId) REFERENCES $_postTable (postId) ON DELETE CASCADE
      )
    ''',
    );

    // Buat tabel Saved
    await db.execute(
      '''
      CREATE TABLE $_savedTable(
        uid INTEGER NOT NULL,
        postId INTEGER NOT NULL,
        PRIMARY KEY (uid, postId),
        FOREIGN KEY (uid) REFERENCES $_userTable (uid) ON DELETE CASCADE,
        FOREIGN KEY (postId) REFERENCES $_postTable (postId) ON DELETE CASCADE
      )
    ''',
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE $_postTable ADD COLUMN postImage TEXT;');
    }
  }

  // --- USER OPERATIONS ---

  Future<int> insertUser(User user) async {
    Database db = await database;
    return await db.insert(_userTable, user.toMap());
  }

  Future<User?> getUserByUsername(String username) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      _userTable,
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      _userTable,
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(int uid) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      _userTable,
      where: 'uid = ?',
      whereArgs: [uid],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    Database db = await database;
    if (user.uid == null) {
      throw Exception("User ID is required for update.");
    }
    return await db.update(
      _userTable,
      user.toMap(),
      where: 'uid = ?',
      whereArgs: [user.uid],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- POST OPERATIONS ---

  Future<int> insertPost(Post post) async {
    Database db = await database;
    return await db.insert(_postTable, post.toMap());
  }

  Future<List<Post>> getAllPosts() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      _postTable,
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) {
      return Post.fromMap(maps[i]);
    });
  }

  Future<List<Post>> getPostsByUserId(int uid) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      _postTable,
      where: 'uid = ?',
      whereArgs: [uid],
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) {
      return Post.fromMap(maps[i]);
    });
  }

  Future<Post?> getPostById(int postId) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      _postTable,
      where: 'postId = ?',
      whereArgs: [postId],
    );
    
    if (maps.isNotEmpty) {
      return Post.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<int> deletePost(int postId) async {
    Database db = await database;
    return await db.delete(
      _postTable,
      where: 'postId = ?',
      whereArgs: [postId],
    );
  }

  // --- LIKE OPERATIONS ---

  Future<int> addLike(Like like) async {
    Database db = await database;
    return await db.insert(_likeTable, like.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> removeLike(int uid, int postId) async {
    Database db = await database;
    return await db.delete(
      _likeTable,
      where: 'uid = ? AND postId = ?',
      whereArgs: [uid, postId],
    );
  }

  Future<bool> isPostLikedByUser(int uid, int postId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      _likeTable,
      where: 'uid = ? AND postId = ?',
      whereArgs: [uid, postId],
    );
    return maps.isNotEmpty;
  }

  Future<int> countLikesForPost(int postId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT COUNT(*) FROM $_likeTable WHERE postId = ?',
      [postId],
    );
    return Sqflite.firstIntValue(maps) ?? 0;
  }

  // --- SAVED OPERATIONS ---

  Future<int> addSaved(Saved saved) async {
    Database db = await database;
    return await db.insert(_savedTable, saved.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> removeSaved(int uid, int postId) async {
    Database db = await database;
    return await db.delete(
      _savedTable,
      where: 'uid = ? AND postId = ?',
      whereArgs: [uid, postId],
    );
  }

  Future<bool> isPostSavedByUser(int uid, int postId) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      _savedTable,
      where: 'uid = ? AND postId = ?',
      whereArgs: [uid, postId],
    );
    return maps.isNotEmpty;
  }

  Future<List<Post>> getSavedPostsByUserId(int uid) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.* FROM $_postTable p
      INNER JOIN $_savedTable s ON p.postId = s.postId
      WHERE s.uid = ?
      ORDER BY p.createdAt DESC
    ''', [uid]);
    return List.generate(maps.length, (i) {
      return Post.fromMap(maps[i]);
    });
  }

  // --- Utility untuk testing ---
  Future<void> clearAllTables() async {
    Database db = await database;
    await db.delete(_likeTable);
    await db.delete(_savedTable);
    await db.delete(_postTable);
    await db.delete(_userTable);
  }
}
