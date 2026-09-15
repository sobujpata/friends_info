import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/note.dart';
import '../services/notes_service.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';

class NotesTab extends StatefulWidget {
  final String ownerPersonnelNo;

  const NotesTab({super.key, required this.ownerPersonnelNo});

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  final _searchController = TextEditingController();
  List<Note> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final notes = await NotesService.listNotes(
        widget.ownerPersonnelNo,
        query: _searchController.text,
      );
      if (mounted) setState(() => _notes = notes);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load notes: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openEditor([Note? note]) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NoteEditorScreen(
          ownerPersonnelNo: widget.ownerPersonnelNo,
          note: note,
        ),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _showActions(Note note) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(note.isPinned
                  ? Icons.push_pin_outlined
                  : Icons.push_pin),
              title: Text(note.isPinned ? 'Unpin' : 'Pin'),
              onTap: () => Navigator.pop(context, 'pin'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    try {
      if (action == 'pin') {
        await NotesService.togglePin(note);
        await _load();
      } else if (action == 'delete' && note.id != null) {
        await NotesService.deleteNote(note.id!);
        await _load();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update note: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final columns = MediaQuery.sizeOf(context).width >= 700 ? 3 : 2;
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Search notes',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? const Center(child: Text('No notes yet. Tap + to write one.'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: MasonryGridView.count(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                          crossAxisCount: columns,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          itemCount: _notes.length,
                          itemBuilder: (context, index) {
                            final note = _notes[index];
                            return NoteCard(
                              note: note,
                              onTap: () => _openEditor(note),
                              onLongPress: () => _showActions(note),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        tooltip: 'Create note',
        child: const Icon(Icons.add),
      ),
    );
  }
}
