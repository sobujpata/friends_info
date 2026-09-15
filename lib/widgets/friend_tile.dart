import 'dart:io';
import 'package:flutter/material.dart';
import '../models/friend.dart';

class FriendTile extends StatelessWidget {
  final Friend friend;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const FriendTile({
    super.key,
    required this.friend,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Hero(
                tag: 'avatar_${friend.id}',
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: scheme.primaryContainer,
                  backgroundImage: friend.photoPath != null &&
                          File(friend.photoPath!).existsSync()
                      ? FileImage(File(friend.photoPath!))
                      : null,
                  child: friend.photoPath == null ||
                          !File(friend.photoPath!).existsSync()
                      ? Text(
                          friend.name.isNotEmpty
                              ? friend.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                              fontSize: 22,
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(friend.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text('ID: ${friend.personnelNo}',
                        style: TextStyle(
                            color: scheme.onSurfaceVariant, fontSize: 13)),
                    Text(
                      [
                        friend.phone,
                        if (friend.trade?.isNotEmpty ?? false) friend.trade!,
                        if (friend.district?.isNotEmpty ?? false)
                          friend.district!,
                      ].join(' \u00b7 '),
                      style: TextStyle(
                          color: scheme.onSurfaceVariant, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  friend.isFavorite ? Icons.star : Icons.star_border,
                  color: friend.isFavorite ? Colors.amber : null,
                ),
                onPressed: onFavorite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
