import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'main.dart';

class DatabaseHelper {
  static Database? _database;

  // =====================================================
  // เปิด Database
  // =====================================================

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  // =====================================================
  // สร้าง Database
  // =====================================================

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, 'mydiary.db');

    return await openDatabase(
      path,
      version: 2,

      // สร้างตารางครั้งแรก
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE diaries(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            quote TEXT NOT NULL DEFAULT '',
            date TEXT NOT NULL,
            point TEXT NOT NULL,
            mood TEXT NOT NULL,
            isImportant INTEGER NOT NULL,
            isPinned INTEGER NOT NULL,
            type TEXT NOT NULL
          )
          ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE diaries ADD COLUMN quote TEXT NOT NULL DEFAULT ''",
          );
        }
      },
    );
  }

  // =====================================================
  // GET ALL
  // =====================================================

  static Future<List<Diary>> getAll() async {
    final db = await database;

    final result = await db.query('diaries', orderBy: 'id DESC');

    return result.map((map) {
      return Diary.fromMap(map);
    }).toList();
  }

  // =====================================================
  // INSERT
  // =====================================================

  static Future<int> insert(Diary diary) async {
    final db = await database;

    final map = diary.toMap();

    // ไม่ต้องส่ง id ตอนเพิ่มข้อมูลใหม่
    map.remove('id');

    return await db.insert('diaries', map);
  }

  // =====================================================
  // UPDATE
  // =====================================================

  static Future<int> update(Diary diary) async {
    final db = await database;

    final map = diary.toMap();

    // ไม่ต้องส่ง id ไปแก้
    map.remove('id');

    return await db.update(
      'diaries',
      map,
      where: 'id = ?',
      whereArgs: [diary.id],
    );
  }

  // =====================================================
  // DELETE
  // =====================================================

  static Future<int> delete(int id) async {
    final db = await database;

    return await db.delete('diaries', where: 'id = ?', whereArgs: [id]);
  }
}
