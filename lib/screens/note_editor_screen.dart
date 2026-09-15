import 'package:flutter/material.dart';
import '../models/note.dart';
import '../services/notes_service.dart';
import '../widgets/note_card.dart';

class NoteEditorScreen extends StatefulWidget {
  final String ownerPersonnelNo;
  final Note? note;

  const NoteEditorScreen({
    super.key,
    required this.ownerPersonnelNo,
    this.note,
  });

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late int _color;
  late bool _isPinned;
  late final DateTime _createdAt;
  bool _saving = false;

  bool get _isNew => widget.note == null;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _titleController = TextEditingController(text: note?.title ?? '');
    _descriptionController =
        TextEditingController(text: note?.description ?? '');
    _color = note?.color ?? 0;
    _isPinned = note?.isPinned ?? false;
    _createdAt = note?.createdAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _hasContent =>
      _titleController.text.trim().isNotEmpty ||
      _descriptionController.text.trim().isNotEmpty;

  Future<void> _saveAndClose() async {
    if (_saving) return;
    if (!_hasContent && _isNew) {
      if (mounted) Navigator.pop(context, false);
      return;
    }
    setState(() => _saving = true);
    final now = DateTime.now();
    final note = Note(
      id: widget.note?.id,
      ownerPersonnelNo: widget.ownerPersonnelNo,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      color: _color,
      isPinned: _isPinned,
      createdAt: _createdAt,
      updatedAt: now,
    );
    try {
      if (_isNew) {
        await NotesService.insertNote(note);
      } else {
        await NotesService.updateNote(note);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save note: $error')),
        );
      }
    }
  }

  Future<void> _delete() async {
    final id = widget.note?.id;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This note will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await NotesService.deleteNote(id);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete note: $error')),
        );
      }
    }
  }

  Future<void> _pickColor() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => GridView.builder(
        padding: const EdgeInsets.all(24),
        shrinkWrap: true,
        itemCount: noteColors.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemBuilder: (context, index) => InkWell(
          onTap: () => Navigator.pop(context, index),
          borderRadius: BorderRadius.circular(40),
          child: CircleAvatar(backgroundColor: noteColors[index]),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _color = selected);
  }

  Future<void> _togglePin() async {
    setState(() => _isPinned = !_isPinned);
    if (widget.note?.id == null) return;
    try {
      await NotesService.togglePin(widget.note!.copyWith(
        isPinned: !_isPinned,
      ));
    } catch (error) {
      if (mounted) {
        setState(() => _isPinned = !_isPinned);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update pin: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _saveAndClose();
      },
      child: Scaffold(
        backgroundColor:
            noteColors[_color.clamp(0, noteColors.length - 1).toInt()],
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _saveAndClose,
          ),
          actions: [
            IconButton(
              tooltip: 'Choose color',
              onPressed: _pickColor,
              icon: const Icon(Icons.palette_outlined),
            ),
            IconButton(
              tooltip: 'Pin note',
              onPressed: _togglePin,
              icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
            ),
            if (!_isNew)
              IconButton(
                tooltip: 'Delete note',
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                autofocus: _isNew,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  hintText: 'Title',
                  border: InputBorder.none,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _descriptionController,
                  expands: true,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: 'Write a note...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
