import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/friend.dart';
import '../services/db_service.dart';
import 'friend_form_screen.dart';

class FriendDetailScreen extends StatefulWidget {
  final Friend friend;
  final VoidCallback onChanged;

  const FriendDetailScreen({
    super.key,
    required this.friend,
    required this.onChanged,
  });

  @override
  State<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends State<FriendDetailScreen> {
  late Friend _f;

  @override
  void initState() {
    super.initState();
    _f = widget.friend;
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not open $url')));
    }
  }

  Future<void> _call() => _launch('tel:${_f.phone}');

  Future<void> _whatsapp() {
    final number = _f.phone.replaceAll(RegExp(r'[^\d]'), '');
    return _launch('https://wa.me/$number');
  }

  Future<void> _toggleFav() async {
    await DBService.toggleFavorite(_f);
    setState(() => _f = _f.copyWith(isFavorite: !_f.isFavorite));
    widget.onChanged();
  }

  Future<void> _edit() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FriendFormScreen(
          ownerPersonnelNo: _f.ownerPersonnelNo,
          friend: _f,
        ),
      ),
    );
    if (saved == true) {
      // Reload by refetching is overkill — just pop back with change flag.
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete friend?'),
        content: Text('Remove ${_f.name} permanently?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await DBService.delete(_f.id!);
      widget.onChanged();
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend details'),
        actions: [
          IconButton(
            icon: Icon(_f.isFavorite ? Icons.star : Icons.star_border,
                color: _f.isFavorite ? Colors.amber : null),
            onPressed: _toggleFav,
          ),
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _edit),
          IconButton(
              icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Hero(
              tag: 'avatar_${_f.id}',
              child: CircleAvatar(
                radius: 64,
                backgroundColor: scheme.primaryContainer,
                backgroundImage:
                    _f.photoPath != null && File(_f.photoPath!).existsSync()
                        ? FileImage(File(_f.photoPath!))
                        : null,
                child: _f.photoPath == null || !File(_f.photoPath!).existsSync()
                    ? Text(_f.name.isNotEmpty ? _f.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            fontSize: 44, fontWeight: FontWeight.w600))
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(_f.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('ID: ${_f.personnelNo}',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _call,
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _whatsapp,
                  icon: const Icon(Icons.chat),
                  label: const Text('WhatsApp'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _InfoTile(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: _f.phone,
              onTap: _call),
          if (_f.trade?.isNotEmpty ?? false)
            _InfoTile(
                icon: Icons.work_outlined, label: 'Trade', value: _f.trade!),
          if (_f.bloodGroup?.isNotEmpty ?? false)
            _InfoTile(
                icon: Icons.bloodtype,
                label: 'Blood group',
                value: _f.bloodGroup!),
          if (_f.district?.isNotEmpty ?? false)
            _InfoTile(
                icon: Icons.location_city,
                label: 'District',
                value: _f.district!),
          if (_f.upazila?.isNotEmpty ?? false)
            _InfoTile(
                icon: Icons.map_outlined, label: 'Upazila', value: _f.upazila!),
          if (_f.presentAddress?.isNotEmpty ?? false)
            _InfoTile(
                icon: Icons.home_outlined,
                label: 'Present address',
                value: _f.presentAddress!),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        subtitle: Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: onTap != null
            ? const Icon(Icons.arrow_forward_ios, size: 14)
            : null,
        onTap: onTap,
      ),
    );
  }
}
