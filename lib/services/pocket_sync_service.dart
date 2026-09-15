import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pocketsync_flutter/pocketsync_flutter.dart';
import '../models/chat_message.dart';

// ─────────────────────────────────────────────────────────────
// ⚠️  PocketSync placeholder configuration
//     After creating the project in the PocketSync Dashboard,
//     replace projectId / authToken / serverUrl with real values.
// ─────────────────────────────────────────────────────────────
const String kPocketSyncProjectId = 'YOUR_PROJECT_ID';
const String kPocketSyncAuthToken = 'YOUR_AUTH_TOKEN';
const String kPocketSyncServerUrl = 'https://api.pocketsync.dev';

/// Message table definition, consistent with the PocketSync server schema.
final TableSchema kMessagesTableSchema = TableSchema(
  name: 'messages',
  columns: [
    TableColumn.primaryKey(
      name: 'id',
      type: ColumnType.integer,
      isAutoIncrement: true,
    ),
    TableColumn.text(name: 'sender_id', isNullable: false),
    TableColumn.text(name: 'message', isNullable: false),
    TableColumn.text(name: 'created_at', isNullable: false),
  ],
);

/// PocketSync sync service: initializes the chat database, sets the user ID,
/// controls sync start/stop, and writes incoming chat messages.
class PocketSyncService {
  static bool _initialized = false;

  /// Whether PocketSync is supported on the current platform.
  static bool get isSupported => !kIsWeb;

  /// Whether initialization has completed.
  static bool get isInitialized => _initialized;

  /// Whether the real PocketSync project settings have been configured.
  /// If the placeholders are still present, chat sync is turned off safely so the
  /// app can still open and work without crashing.
  static bool get isConfigured =>
      kPocketSyncProjectId.trim().isNotEmpty &&
      kPocketSyncProjectId != 'YOUR_PROJECT_ID' &&
      kPocketSyncAuthToken.trim().isNotEmpty &&
      kPocketSyncAuthToken != 'YOUR_AUTH_TOKEN' &&
      kPocketSyncServerUrl.trim().isNotEmpty &&
      kPocketSyncServerUrl != 'https://api.pocketsync.dev';

  /// Initializes PocketSync. Safe to call multiple times.
  /// The configuration values come from the PocketSync Dashboard.
  static Future<void> initialize() async {
    if (!isSupported) {
      throw UnsupportedError('PocketSync chat sync is not supported on the web platform');
    }
    if (_initialized) return;

    if (!isConfigured) {
      debugPrint('PocketSync is not configured. Chat sync is disabled until the real project values are set.');
      _initialized = true;
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'pocket_sync.db');

    await PocketSync.initialize(
      options: PocketSyncOptions(
        projectId: kPocketSyncProjectId,
        authToken: kPocketSyncAuthToken,
        serverUrl: kPocketSyncServerUrl,
        verbose: true,
      ),
      databaseOptions: DatabaseOptions(
        version: 1,
        dbPath: dbPath,
        schema: DatabaseSchema(tables: [kMessagesTableSchema]),
        // Create the messages table when the database is first created.
        // PocketSync appends the ps_global_id column automatically and creates
        // change-sync triggers for the table.
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS messages(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sender_id TEXT NOT NULL,
              message TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''' );
        },
      ),
    );
    _initialized = true;
  }

  /// Sets the current user ID after a successful login.
  /// PocketSync isolates data on the server by userId, so only users with the
  /// same personnelNo can see each other's messages.
  static Future<void> setUserId(String personnelNo) async {
    if (!isConfigured) {
      debugPrint('PocketSync user ID not set because the project is not configured yet.');
      return;
    }
    await initialize();
    PocketSync.instance.setUserId(personnelNo);
  }

  /// Starts synchronization. Call this after [setUserId].
  static Future<void> startSync() async {
    if (!isConfigured) {
      debugPrint('PocketSync sync not started because the project is not configured yet.');
      return;
    }
    await initialize();
    await PocketSync.instance.start();
  }

  /// Stops synchronization. Call this during logout.
  static Future<void> stopSync() async {
    if (!_initialized || !isConfigured) return;
    try {
      await PocketSync.instance.stop();
    } catch (e) {
      debugPrint('Failed to stop PocketSync sync: $e');
    }
  }

  /// Inserts a message into the messages table; PocketSync uploads it automatically.
  static Future<int> sendMessage(String senderId, String message) async {
    if (!isConfigured) {
      throw StateError('PocketSync is not configured. Add the real project settings first.');
    }
    await initialize();
    final msg = ChatMessage(
      senderId: senderId,
      message: message,
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );
    return PocketSync.instance.database.insert(
      'messages',
      msg.toMap()..remove('id'),
    );
  }
}