import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cityxplore/app/data/models/post_model.dart';
import 'package:cityxplore/app/data/models/user_model.dart';
import 'dart:math';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const int stressBatchCreateCount = 10000;
  const int stressConcurrentOperationsCount = 500;
  const int stressLargeBatchInsertCount = 15000;

  const int stressBatchCreateTimeLimitMs = 15000;
  const int stressConcurrentOpsTimeLimitMs = 8000;
  const int stressLargeBatchInsertTimeLimitMs = 3000;

  late Database _testDb;
  late int testUserId;

  setUp(() async {
    final dbPath = inMemoryDatabasePath;

    await deleteDatabase(dbPath);

    _testDb =
        await openDatabase(dbPath, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE user(
          uid INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT NOT NULL UNIQUE,
          email TEXT NOT NULL UNIQUE,
          password TEXT NOT NULL,
          photoPath TEXT,
          createdAt TEXT NOT NULL,
          updatedAt TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE post(
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
          FOREIGN KEY (uid) REFERENCES user (uid) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE 'like'(
          uid INTEGER NOT NULL,
          postId INTEGER NOT NULL,
          PRIMARY KEY (uid, postId),
          FOREIGN KEY (uid) REFERENCES user (uid) ON DELETE CASCADE,
          FOREIGN KEY (postId) REFERENCES post (postId) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        CREATE TABLE saved(
          uid INTEGER NOT NULL,
          postId INTEGER NOT NULL,
          PRIMARY KEY (uid, postId),
          FOREIGN KEY (uid) REFERENCES user (uid) ON DELETE CASCADE,
          FOREIGN KEY (postId) REFERENCES post (postId) ON DELETE CASCADE
        )
      ''');
    }, onConfigure: (db) async {
      await db.execute('PRAGMA foreign_keys = ON');
    });

    final dummyUserMap = User(
      username: 'stress_user_${DateTime.now().millisecondsSinceEpoch}',
      email: 'stress_${DateTime.now().millisecondsSinceEpoch}@example.com',
      password: 'password123',
      createdAt: DateTime.now(),
    ).toMap();
    testUserId = await _testDb.insert('user', dummyUserMap);
  });

  tearDown(() async {
    await _testDb.close();
    await deleteDatabase(_testDb.path);
  });

  group('Sqflite Database Stress Tests (Isolated)', () {
    test(
        'Stress: Should handle batch creation of $stressBatchCreateCount posts individually',
        () async {
      final stopwatch = Stopwatch()..start();
      final random = Random();

      for (int i = 0; i < stressBatchCreateCount; i++) {
        final postMap = Post(
          uid: testUserId,
          latitude: random.nextDouble() * 180 - 90,
          longitude: random.nextDouble() * 360 - 180,
          detailLoc: 'Location ${i + 1}',
          postTitle: 'Stress Post ${i + 1}',
          postDesc: 'Description for stress post ${i + 1}',
          postPrice: random.nextDouble() * 100000,
          createdAt: DateTime.now(),
        ).toMap();
        await _testDb.insert('post', postMap);
      }
      stopwatch.stop();

      print(
          '[Stress Test 1] Batch creation time: ${stopwatch.elapsedMilliseconds}ms');
      final count = Sqflite.firstIntValue(
          await _testDb.rawQuery('SELECT COUNT(*) FROM post'));
      expect(count, stressBatchCreateCount);
      expect(
          stopwatch.elapsedMilliseconds, lessThan(stressBatchCreateTimeLimitMs),
          reason:
              'Individual inserts took too long. Time: ${stopwatch.elapsedMilliseconds}ms');
    },
        timeout: Timeout(
            Duration(milliseconds: stressBatchCreateTimeLimitMs + 1000)));

    test(
        'Stress: Should handle $stressConcurrentOperationsCount concurrent read/write/update operations',
        () async {
      final stopwatch = Stopwatch()..start();
      final random = Random();

      for (int i = 0; i < 100; i++) {
        await _testDb.insert(
            'post',
            Post(
              uid: testUserId,
              latitude: 0.0,
              longitude: 0.0,
              detailLoc: 'Pre-filled Loc ${i + 1}',
              postTitle: 'Pre-filled Post ${i + 1}',
              postDesc: 'Desc',
              postPrice: 100.0,
              createdAt: DateTime.now(),
            ).toMap());
      }

      final operations =
          List.generate(stressConcurrentOperationsCount, (index) async {
        final operationType = random.nextInt(3);

        if (operationType == 0) {
          // Operasi Tulis
          await _testDb.insert(
              'post',
              Post(
                uid: testUserId,
                latitude: random.nextDouble(),
                longitude: random.nextDouble(),
                detailLoc: 'Concurrent Loc $index',
                postTitle: 'Concurrent Post $index',
                postDesc: 'Desc',
                postPrice: 50.0,
                createdAt: DateTime.now(),
              ).toMap());
        } else if (operationType == 1) {
          final posts = await _testDb.query('post');
          if (posts.isNotEmpty) {
            final postId = posts[random.nextInt(posts.length)]['postId'] as int;
            await _testDb
                .query('post', where: 'postId = ?', whereArgs: [postId]);
          }
        } else {
          final posts = await _testDb.query('post');
          if (posts.isNotEmpty) {
            final postId = posts[random.nextInt(posts.length)]['postId'] as int;
            await _testDb.insert('like', {'uid': testUserId, 'postId': postId},
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
      });

      await Future.wait(operations);
      stopwatch.stop();

      print(
          '[Stress Test 2] Concurrent operations time: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds,
          lessThan(stressConcurrentOpsTimeLimitMs),
          reason:
              'Concurrent operations took too long. Time: ${stopwatch.elapsedMilliseconds}ms');
    },
        timeout: Timeout(
            Duration(milliseconds: stressConcurrentOpsTimeLimitMs + 1000)));

    test(
        'Stress: Should handle large batch inserts via transaction for $stressLargeBatchInsertCount posts',
        () async {
      final stopwatch = Stopwatch()..start();
      final random = Random();

      await _testDb.transaction((txn) async {
        for (int i = 0; i < stressLargeBatchInsertCount; i++) {
          final postMap = Post(
            uid: testUserId,
            latitude: random.nextDouble() * 180 - 90,
            longitude: random.nextDouble() * 360 - 180,
            detailLoc: 'Batch Loc ${i + 1}',
            postTitle: 'Batch Post ${i + 1}',
            postDesc: 'Desc',
            postPrice: random.nextDouble() * 50000,
            createdAt: DateTime.now(),
          ).toMap();
          await txn.insert('post', postMap);
        }
      });
      stopwatch.stop();

      print(
          '[Stress Test 3] Batch insert via transaction time: ${stopwatch.elapsedMilliseconds}ms');
      final count = Sqflite.firstIntValue(
          await _testDb.rawQuery('SELECT COUNT(*) FROM post'));
      expect(count, stressLargeBatchInsertCount);
      expect(stopwatch.elapsedMilliseconds,
          lessThan(stressLargeBatchInsertTimeLimitMs),
          reason:
              'Large batch inserts took too long. Time: ${stopwatch.elapsedMilliseconds}ms');
    },
        timeout: Timeout(
            Duration(milliseconds: stressLargeBatchInsertTimeLimitMs + 1000)));
  });
}
