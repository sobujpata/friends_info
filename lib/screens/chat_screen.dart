import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pocketsync_flutter/pocketsync_flutter.dart';
import '../models/chat_message.dart';
import '../services/pocket_sync_service.dart';

/// Chat page: listens to the PocketSync local database and displays synced messages in real time.
class ChatScreen extends StatefulWidget {
  final String personnelNo;

  const ChatScreen({super.key, required this.personnelNo});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    try {
      await PocketSyncService.sendMessage(widget.personnelNo, text);
      _inputController.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!PocketSyncService.isConfigured) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Chat sync is not configured yet. Add the PocketSync project settings in the service file.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final database = PocketSync.instance.database;
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: database.watch(
              'SELECT * FROM messages ORDER BY created_at ASC',
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Failed to load messages: ${snapshot.error}'));
              }
              final rows = snapshot.data ?? const <Map<String, dynamic>>[];
              if (rows.isEmpty) {
                return const Center(child: Text('No messages yet'));
              }

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(
                    _scrollController.position.maxScrollExtent,
                  );
                }
              });
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final message = ChatMessage.fromMap(rows[index]);
                  return _MessageBubble(
                    message: message,
                    isMine: message.senderId == widget.personnelNo,
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _send,
                  icon: const Icon(Icons.send),
                  tooltip: 'Send',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A single message bubble. Messages sent by the current user are aligned right.
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final time = DateTime.tryParse(message.createdAt);
    final formattedTime =
        time == null
            ? message.createdAt
            : DateFormat('MM-dd HH:mm').format(time.toLocal());
    final background =
        isMine ? colorScheme.primary : colorScheme.surfaceContainerHighest;
    final foreground = isMine ? colorScheme.onPrimary : colorScheme.onSurface;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.senderId,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(message.message, style: TextStyle(color: foreground)),
            const SizedBox(height: 3),
            Text(
              formattedTime,
              style: TextStyle(
                color: foreground.withValues(alpha: 0.75),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
