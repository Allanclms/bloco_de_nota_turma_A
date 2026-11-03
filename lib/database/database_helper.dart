import 'package:bloco_de_nota_turma_a/models/note.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        date TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'Pessoal',
        sync_id TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE notes ADD COLUMN category TEXT NOT NULL DEFAULT 'Pessoal'",
      );
      await db.execute(
        "ALTER TABLE notes ADD COLUMN sync_id TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE notes ADD COLUMN updated_at TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        'ALTER TABLE notes ADD COLUMN sync_status INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE notes ADD COLUMN is_deleted INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute(
        "UPDATE notes SET sync_id = 'legacy_' || id WHERE sync_id = ''",
      );
      await db.execute(
        "UPDATE notes SET updated_at = date WHERE updated_at = ''",
      );
    }
  }

  Future<int> insertNote(Note note) async {
    final db = await database;
    final values = note.toMap()..remove('id');
    return db.insert('notes', values);
  }

  Future<List<Note>> getNotes(
    String uid, {
    String search = '',
    String? category,
  }) async {
    final db = await database;
    final conditions = <String>['uid = ?', 'is_deleted = 0'];
    final arguments = <Object?>[uid];

    if (search.trim().isNotEmpty) {
      conditions.add('(title LIKE ? OR content LIKE ?)');
      final term = '%${search.trim()}%';
      arguments.addAll([term, term]);
    }

    if (category != null && category != 'Todas') {
      conditions.add('category = ?');
      arguments.add(category);
    }

    final result = await db.query(
      'notes',
      where: conditions.join(' AND '),
      whereArgs: arguments,
      orderBy: 'id DESC',
    );

    return result.map((map) => Note.fromMap(map)).toList();
  }

  Future<List<String>> getCategories(String uid) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT category FROM notes WHERE uid = ? AND is_deleted = 0 ORDER BY category',
      [uid],
    );
    final categories = result
        .map((item) => item['category'] as String)
        .toSet();
    categories.addAll(['Pessoal', 'Estudos', 'Trabalho', 'Outros']);
    return categories.toList()..sort();
  }

  Future<int> updateNote(Note note) async {
    final db = await database;
    return db.update(
      'notes',
      note.toMap()..remove('id'),
      where: 'id = ? AND uid = ?',
      whereArgs: [note.id, note.uid],
    );
  }

  Future<int> deleteNote(int id, String uid) async {
    final db = await database;
    return db.delete(
      'notes',
      where: 'id = ? AND uid = ?',
      whereArgs: [id, uid],
    );
  }
}
