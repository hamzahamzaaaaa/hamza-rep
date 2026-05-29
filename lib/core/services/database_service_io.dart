import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('medbouh_quran.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE durations (
        id TEXT PRIMARY KEY,
        duration_seconds INTEGER
      )
    ''');
  }

  Future<void> saveDuration(String id, int seconds) async {
    final db = await instance.database;
    await db.insert(
      'durations',
      {'id': id, 'duration_seconds': seconds},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int?> getDuration(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'durations',
      columns: ['duration_seconds'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first['duration_seconds'] as int;
    }
    return null;
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
