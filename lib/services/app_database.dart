import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/app_user.dart';
import '../models/screening_record.dart';

class AppDatabase {
  Database? _db;

  Future<void> init() async {
    final path = p.join(await getDatabasesPath(), 'speechcare_ai.db');
    _db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            passwordHash TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE screening_records(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER NOT NULL,
            audioPath TEXT NOT NULL,
            durationSeconds INTEGER NOT NULL,
            createdAt TEXT NOT NULL,
            finalLabel TEXT NOT NULL,
            confidencePercent REAL NOT NULL,
            stage1 TEXT NOT NULL,
            stage2 TEXT NOT NULL,
            probabilitiesJson TEXT NOT NULL,
            warning TEXT NOT NULL,
            recommendation TEXT NOT NULL,
            reportSummary TEXT NOT NULL,
            FOREIGN KEY(userId) REFERENCES users(id)
          )
        ''');
        await _createSessionTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createSessionTable(db);
        }
      },
    );
  }

  Database get db {
    final database = _db;
    if (database == null) throw StateError('Database not initialized');
    return database;
  }

  Future<AppUser?> findUserByEmail(String email) async {
    final rows = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
      limit: 1,
    );
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  Future<AppUser?> findUserById(int id) async {
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : AppUser.fromMap(rows.first);
  }

  Future<AppUser> insertUser(AppUser user) async {
    final id = await db.insert('users', user.toMap()..remove('id'));
    return user.copyWith(id: id);
  }

  Future<void> updateUserPasswordHash(int userId, String passwordHash) async {
    await db.update(
      'users',
      {'passwordHash': passwordHash},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> saveCurrentUserId(int userId) async {
    await db.insert('app_session', {
      'key': 'currentUserId',
      'value': userId.toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveLanguageCode(String languageCode) async {
    await db.insert('app_session', {
      'key': 'languageCode',
      'value': languageCode,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> savedLanguageCode() async {
    final rows = await db.query(
      'app_session',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['languageCode'],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<AppUser?> currentSessionUser() async {
    final rows = await db.query(
      'app_session',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: ['currentUserId'],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final userId = int.tryParse(rows.first['value'] as String);
    if (userId == null) {
      await clearCurrentUserId();
      return null;
    }

    final user = await findUserById(userId);
    if (user == null) await clearCurrentUserId();
    return user;
  }

  Future<void> clearCurrentUserId() async {
    await db.delete(
      'app_session',
      where: 'key = ?',
      whereArgs: ['currentUserId'],
    );
  }

  Future<int> insertRecord(ScreeningRecord record) {
    return db.insert('screening_records', record.toMap()..remove('id'));
  }

  Future<List<ScreeningRecord>> recordsForUser(int userId) async {
    final rows = await db.query(
      'screening_records',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(ScreeningRecord.fromMap).toList();
  }

  Future<void> clearRecords(int userId) async {
    await db.delete(
      'screening_records',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  Future<void> _createSessionTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS app_session(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }
}
