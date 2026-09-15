import 'package:flutter/material.dart';
import '../models/friend.dart';
import '../services/backup_service.dart';
import '../services/db_service.dart';
import '../widgets/friend_tile.dart';
import 'about_screen.dart';
import 'friend_detail_screen.dart';
import 'friend_form_screen.dart';
import 'instruction_screen.dart';
import 'chat_screen.dart';
import 'notes_tab.dart';

class HomeScreen extends StatefulWidget {
  final String personnelNo;
  final bool darkMode;
  final void Function(bool) onToggleDark;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.personnelNo,
    required this.darkMode,
    required this.onToggleDark,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  List<Friend> _friends = [];
  bool _loading = true;
  bool _onlyFav = false;
  int _tab = 0; // Home, Messages, Notes, Instruction, About Owner

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await DBService.list(
      widget.personnelNo,
      query: _searchCtrl.text,
      onlyFav: _onlyFav,
    );
    if (!mounted) return;
    setState(() {
      _friends = list;
      _loading = false;
    });
  }

  Future<void> _openForm({Friend? friend}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FriendFormScreen(
          ownerPersonnelNo: widget.personnelNo,
          friend: friend,
        ),
      ),
    );
    if (saved == true) {
      // Small delay guarantees the SQLite write is committed before reload.
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) _load();
    }
  }

  Future<void> _openDetail(Friend f) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FriendDetailScreen(
          friend: f,
          onChanged: _load,
        ),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _toggleFav(Friend f) async {
    await DBService.toggleFavorite(f);
    _load();
  }

  Future<void> _confirmDelete(Friend f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete friend?'),
        content: Text('Remove ${f.name} permanently?'),
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
      await DBService.delete(f.id!);
      _load();
    }
  }

  Future<void> _showMenu(String value) async {
    if (value == 'logout') {
      widget.onLogout();
    } else if (value == 'export') {
      await BackupService.export(widget.personnelNo);
    } else if (value == 'import') {
      final n = await BackupService.import(widget.personnelNo);
      if (n != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Imported $n records')));
        _load();
      }
    }
  }

  static const _tabTitles = [
    'Friends Info',
    'Messages',
    'Notes',
    'Instruction',
    'About Owner',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_tabTitles[_tab]),
            Text('Signed in as ${widget.personnelNo}',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          if (_tab == 0)
            IconButton(
              tooltip: 'Favorites only',
              icon: Icon(_onlyFav ? Icons.star : Icons.star_border),
              onPressed: () {
                setState(() => _onlyFav = !_onlyFav);
                _load();
              },
            ),
          IconButton(
            tooltip: 'Dark mode',
            icon: Icon(
                widget.darkMode ? Icons.dark_mode : Icons.dark_mode_outlined),
            onPressed: () => widget.onToggleDark(!widget.darkMode),
          ),
          PopupMenuButton<String>(
            onSelected: _showMenu,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'export', child: Text('Backup (export)')),
              PopupMenuItem(value: 'import', child: Text('Restore (import)')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _buildHomeTab(),
          ChatScreen(personnelNo: widget.personnelNo),
          NotesTab(ownerPersonnelNo: widget.personnelNo),
          const InstructionScreen(),
          const AboutScreen(),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Add friend'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.sticky_note_2_outlined),
            selectedIcon: Icon(Icons.sticky_note_2),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Instruction',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'About Owner',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => _load(),
            decoration: InputDecoration(
              hintText: 'Search by personnel no, name, phone…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchCtrl.clear();
                        _load();
                      },
                    ),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _friends.isEmpty
                  ? _EmptyState(hasQuery: _searchCtrl.text.isNotEmpty)
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                        itemCount: _friends.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final f = _friends[i];
                          return Dismissible(
                            key: ValueKey(f.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (_) async {
                              await _confirmDelete(f);
                              return false;
                            },
                            child: FriendTile(
                              friend: f,
                              onTap: () => _openDetail(f),
                              onFavorite: () => _toggleFav(f),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasQuery;
  const _EmptyState({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hasQuery ? Icons.search_off : Icons.people_outline,
              size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(hasQuery
              ? 'No friends match your search.'
              : 'No friends yet. Tap "Add friend" to start.'),
        ],
      ),
    );
  }
}
