import '../models/note.dart';
import 'db_service.dart';

class NotesService {
  static Future<List<Note>> listNotes(String owner,
          {String query = ''}) =>
      DBService.listNotes(owner, query: query);

  static Future<int> insertNote(Note note) => DBService.insertNote(note);

  static Future<void> updateNote(Note note) => DBService.updateNote(note);

  static Future<void> deleteNote(int id) => DBService.deleteNote(id);

  static Future<void> togglePin(Note note) => DBService.toggleNotePin(note);

  static Future<void> updateColor(Note note, int color) {
    return DBService.updateNote(note.copyWith(
      color: color,
      updatedAt: DateTime.now(),
    ));
  }

  static Future<void> deleteAllNotesFor(String owner) =>
      DBService.deleteAllNotesFor(owner);
}
