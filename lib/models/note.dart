class Note {
  final int? id;
  final String ownerPersonnelNo;
  final String title;
  final String description;
  final int color;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Note({
    this.id,
    required this.ownerPersonnelNo,
    required this.title,
    required this.description,
    this.color = 0,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'owner_personnel_no': ownerPersonnelNo,
        'title': title,
        'description': description,
        'color': color,
        'is_pinned': isPinned ? 1 : 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Note.fromMap(Map<String, dynamic> map) => Note(
        id: map['id'] as int?,
        ownerPersonnelNo: map['owner_personnel_no'] as String,
        title: map['title'] as String? ?? '',
        description: map['description'] as String? ?? '',
        color: map['color'] as int? ?? 0,
        isPinned: (map['is_pinned'] as int? ?? 0) == 1,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Note copyWith({
    int? id,
    String? ownerPersonnelNo,
    String? title,
    String? description,
    int? color,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Note(
        id: id ?? this.id,
        ownerPersonnelNo: ownerPersonnelNo ?? this.ownerPersonnelNo,
        title: title ?? this.title,
        description: description ?? this.description,
        color: color ?? this.color,
        isPinned: isPinned ?? this.isPinned,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
