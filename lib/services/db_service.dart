import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/friend.dart';
import '../models/note.dart';

class DBService {
  static Database? _db;

  static const int _schemaVersion = 3;

  static const String _createNotesTable = '''
    CREATE TABLE notes(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      owner_personnel_no TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      color INTEGER NOT NULL DEFAULT 0,
      is_pinned INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String _createTableV2 = '''
    CREATE TABLE friends(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      owner_personnel_no TEXT NOT NULL,
      name TEXT NOT NULL,
      personnel_no TEXT NOT NULL,
      trade TEXT,
      blood_gp TEXT,
      phone TEXT NOT NULL,
      district TEXT,
      upazila TEXT,
      present_address TEXT,
      photo_path TEXT,
      is_favorite INTEGER NOT NULL DEFAULT 0
    )
  ''';

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    String path;
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final dir = await getApplicationSupportDirectory();
      path = join(dir.path, 'friends.db');
    } else {
      path = join(await getDatabasesPath(), 'friends.db');
    }
    return openDatabase(
      path,
      version: _schemaVersion,
      onCreate: (db, v) async {
        await db.execute(_createTableV2);
        await db
            .execute('CREATE INDEX idx_owner ON friends(owner_personnel_no)');
        await db.execute(_createNotesTable);
        await db.execute(
            'CREATE INDEX idx_notes_owner ON notes(owner_personnel_no)');
        await db.execute(
            'CREATE INDEX idx_notes_updated ON notes(owner_personnel_no, updated_at DESC)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // v1 -> v2: drop whatsapp/email, fold old `address` into
        // `present_address` and add trade/blood_gp/district/upazila.
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE friends_new(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              owner_personnel_no TEXT NOT NULL,
              name TEXT NOT NULL,
              personnel_no TEXT NOT NULL,
              trade TEXT,
              blood_gp TEXT,
              phone TEXT NOT NULL,
              district TEXT,
              upazila TEXT,
              present_address TEXT,
              photo_path TEXT,
              is_favorite INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            INSERT INTO friends_new(
              id, owner_personnel_no, name, personnel_no, phone,
              present_address, photo_path, is_favorite)
            SELECT id, owner_personnel_no, name, personnel_no, phone,
                   address, photo_path, is_favorite
            FROM friends
          ''');
          await db.execute('DROP TABLE friends');
          await db.execute('ALTER TABLE friends_new RENAME TO friends');
          await db
              .execute('CREATE INDEX idx_owner ON friends(owner_personnel_no)');
        }
        if (oldVersion < 3) {
          await db.execute(_createNotesTable);
          await db.execute(
              'CREATE INDEX idx_notes_owner ON notes(owner_personnel_no)');
          await db.execute(
              'CREATE INDEX idx_notes_updated ON notes(owner_personnel_no, updated_at DESC)');
        }
      },
    );
  }

  static Future<List<Friend>> list(String owner,
      {String query = '', bool onlyFav = false}) async {
    final db = await database;
    final where = StringBuffer('owner_personnel_no = ?');
    final args = <Object>[owner];
    if (onlyFav) where.write(' AND is_favorite = 1');
    if (query.trim().isNotEmpty) {
      where.write(
          ' AND (personnel_no LIKE ? OR name LIKE ? OR phone LIKE ? OR trade LIKE ?)');
      final q = '%${query.trim()}%';
      args
        ..add(q)
        ..add(q)
        ..add(q)
        ..add(q);
    }
    final rows = await db.query('friends',
        where: where.toString(),
        whereArgs: args,
        orderBy: 'is_favorite DESC, name ASC');
    return rows.map((r) => Friend.fromMap(r)).toList();
  }

  // ✅ FIXED: strip 'id' key entirely so AUTOINCREMENT assigns it
  static Future<int> insert(Friend f) async {
    final db = await database;
    final map = Map<String, dynamic>.from(f.toMap())..remove('id');
    return db.insert('friends', map,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ✅ FIXED: same treatment, but keep id for the WHERE clause
  static Future<void> update(Friend f) async {
    if (f.id == null) {
      throw ArgumentError('Cannot update Friend without id');
    }
    final db = await database;
    final map = Map<String, dynamic>.from(f.toMap())..remove('id');
    await db.update('friends', map, where: 'id = ?', whereArgs: [f.id]);
  }

  static Future<void> delete(int id) async {
    final db = await database;
    await db.delete('friends', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> toggleFavorite(Friend f) async {
    if (f.id == null) return;
    final db = await database;
    await db.update('friends', {'is_favorite': f.isFavorite ? 0 : 1},
        where: 'id = ?', whereArgs: [f.id]);
  }

  static Future<void> replaceAll(String owner, List<Friend> friends) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('friends',
          where: 'owner_personnel_no = ?', whereArgs: [owner]);
      for (final f in friends) {
        final map = Map<String, dynamic>.from(f.toMap())..remove('id');
        map['owner_personnel_no'] = owner;
        await txn.insert('friends', map);
      }
    });
  }

  static Future<List<Note>> listNotes(String owner,
      {String query = ''}) async {
    final db = await database;
    final trimmed = query.trim();
    final where = StringBuffer('owner_personnel_no = ?');
    final args = <Object>[owner];
    if (trimmed.isNotEmpty) {
      where.write(' AND (title LIKE ? OR description LIKE ?)');
      final value = '%$trimmed%';
      args
        ..add(value)
        ..add(value);
    }
    final rows = await db.query(
      'notes',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'is_pinned DESC, updated_at DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  static Future<int> insertNote(Note note) async {
    final db = await database;
    final map = Map<String, dynamic>.from(note.toMap())..remove('id');
    return db.insert('notes', map);
  }

  static Future<void> updateNote(Note note) async {
    if (note.id == null) {
      throw ArgumentError('Cannot update Note without id');
    }
    final db = await database;
    final map = Map<String, dynamic>.from(note.toMap())..remove('id');
    await db.update('notes', map, where: 'id = ?', whereArgs: [note.id]);
  }

  static Future<void> deleteNote(int id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> toggleNotePin(Note note) async {
    if (note.id == null) return;
    final db = await database;
    await db.update(
      'notes',
      {
        'is_pinned': note.isPinned ? 0 : 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  static Future<void> deleteAllNotesFor(String owner) async {
    final db = await database;
    await db.delete('notes',
        where: 'owner_personnel_no = ?', whereArgs: [owner]);
  }

  static Future<void> replaceAllNotes(String owner, List<Note> notes) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('notes',
          where: 'owner_personnel_no = ?', whereArgs: [owner]);
      for (final note in notes) {
        final map = Map<String, dynamic>.from(note.toMap())..remove('id');
        map['owner_personnel_no'] = owner;
        await txn.insert('notes', map);
      }
    });
  }
}
