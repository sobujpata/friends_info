import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/friend.dart';
import '../models/note.dart';
import 'db_service.dart';

class BackupService {
  static Future<void> export(String owner) async {
    if (kIsWeb) return;
    final friends = await DBService.list(owner);
    final notes = await DBService.listNotes(owner);
    final json = jsonEncode({
      'version': 2,
      'owner': owner,
      'exported_at': DateTime.now().toIso8601String(),
      'friends': friends.map((f) => f.toMap()..remove('id')).toList(),
      'notes': notes.map((n) => n.toMap()..remove('id')).toList(),
    });

    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/friends_backup_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(json);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'Friends backup'),
    );
  }

  /// Returns number of imported records, or null if cancelled.
  static Future<int?> import(String owner) async {
    if (kIsWeb) return null;
    // file_picker 12+: pickFiles() returns List<PlatformFile>, empty list if cancelled.
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (files.isEmpty || files.single.path == null) return null;
    final raw = await File(files.single.path!).readAsString();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final friends = (data['friends'] as List? ?? [])
        .map((e) => Friend.fromMap({
              ...Map<String, dynamic>.from(e),
              'owner_personnel_no': owner,
            }))
        .toList();
    final notes = (data['notes'] as List? ?? [])
        .map((e) => Note.fromMap({
              ...Map<String, dynamic>.from(e),
              'owner_personnel_no': owner,
            }))
        .toList();
    await DBService.replaceAll(owner, friends);
    await DBService.replaceAllNotes(owner, notes);
    return friends.length + notes.length;
  }
}
