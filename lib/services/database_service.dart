import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chapter.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('thiruvasagam_v1.db');
    return _database!;
  }

  static Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  static Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE chapters(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        song TEXT,
        isBookmarked INTEGER DEFAULT 0
      )
    ''');
  }

  static Future<void> seedDatabaseIfEmpty() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoaded = prefs.getBool('isDataLoaded') ?? false;

    if (!isLoaded) {
      final db = await database;

      // 1. Load the text file as a STRING, not as ByteData!
      String encryptedBase64 = await rootBundle.loadString(
        'assets/data_secure.txt', // Or whatever you named your .txt file
      );

      // 🚨 CRITICAL FIX: Strip all invisible line breaks/spaces that corrupt AES
      encryptedBase64 = encryptedBase64.replaceAll(RegExp(r'\s+'), '');

      // 2. Pull the keys from the --dart-define environment
      const String secretKeyString = String.fromEnvironment('DECRYPT_KEY');
      const String ivString = String.fromEnvironment('DECRYPT_IV');

      // 3. Safety check: Ensure the keys were actually passed
      if (secretKeyString.isEmpty || ivString.isEmpty) {
        throw Exception(
          "FATAL ERROR: Decryption keys are missing! Did you run with --dart-define?",
        );
      }

      // 4. Convert them directly to Encrypt Keys
      final key = enc.Key.fromUtf8(secretKeyString);
      final iv = enc.IV.fromUtf8(ivString);

      // 5. Decrypt safely from Base64
      final encrypter = enc.Encrypter(enc.AES(key));
      final encrypted = enc.Encrypted.fromBase64(encryptedBase64);

      // 🚨 THE TAMIL FIX: Decrypt to bytes first, then decode to UTF-8 String
      final List<int> decryptedBytes = encrypter.decryptBytes(
        encrypted,
        iv: iv,
      );
      final String decryptedJsonString = utf8.decode(decryptedBytes);

      // 6. Parse JSON and Insert into Sqflite via Batch (Super Fast)
      final List<dynamic> data = json.decode(decryptedJsonString);

      Batch batch = db.batch();
      for (var item in data) {
        batch.insert('chapters', {
          'title': item['title'],
          'song': item['song'],
          'isBookmarked': 0,
        });
      }
      await batch.commit(noResult: true);

      // Mark as loaded so this never runs again
      await prefs.setBool('isDataLoaded', true);
    }
  }

  // Fetch all chapters for the UI
  static Future<List<Chapter>> getAllChapters() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('chapters');
    return List.generate(maps.length, (i) => Chapter.fromMap(maps[i]));
  }

  // Inside your DatabaseService class

  static Future<void> updateBookmark(int id, bool isBookmarked) async {
    final db = await database;

    // Convert the boolean back into a 1 or 0 for SQLite
    final int sqliteValue = isBookmarked ? 1 : 0;

    await db.update(
      'chapters', // Your table name
      {'isBookmarked': sqliteValue}, // What we are updating
      where: 'id = ?', // Find the exact row
      whereArgs: [id], // Prevent SQL injection
    );

    debugPrint('Bookmark for chapter $id updated to $sqliteValue');
  }

  // lib/services/database_service.dart

  // Add this inside your DatabaseService class:
  static Future<List<Chapter>> getBookmarkedChapters() async {
    final db = await database;

    // Query only the rows where isBookmarked is 1 (true)
    final List<Map<String, dynamic>> maps = await db.query(
      'chapters',
      where: 'isBookmarked = ?',
      whereArgs: [1],
    );

    return List.generate(maps.length, (i) => Chapter.fromMap(maps[i]));
  }
}
