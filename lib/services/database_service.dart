import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/qr_item.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'qr_history.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE history(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            content TEXT NOT NULL,
            source TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<int> insert(QrItem item) async {
    final db = await _database;
    return db.insert('history', item.toMap());
  }

  Future<List<QrItem>> getAll() async {
    final db = await _database;
    final rows = await db.query('history', orderBy: 'created_at DESC');
    return rows.map(QrItem.fromMap).toList();
  }

  Future<void> delete(int id) async {
    final db = await _database;
    await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clear() async {
    final db = await _database;
    await db.delete('history');
  }
}