import 'package:flutter/material.dart';
import '../models/note.dart';

const noteColors = <Color>[
  Color(0xFFFFF8E1),
  Color(0xFFFFE0B2),
  Color(0xFFFFCDD2),
  Color(0xFFE1BEE7),
  Color(0xFFBBDEFB),
  Color(0xFFB2DFDB),
  Color(0xFFC8E6C9),
  Color(0xFFF0F4C3),
];

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        noteColors[note.color.clamp(0, noteColors.length - 1).toInt()];
    final textColor = ThemeData.estimateBrightnessForColor(color) ==
            Brightness.dark
        ? Colors.white
        : Colors.black87;
    return Card(
      elevation: 1,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? 'Untitled' : note.title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (note.isPinned)
                    Icon(Icons.push_pin, size: 18, color: textColor),
                ],
              ),
              if (note.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note.description,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                _date(note.updatedAt),
                style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _date(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
}
