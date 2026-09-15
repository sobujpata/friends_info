import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/friend.dart';
import '../services/db_service.dart';

/// Blood groups offered in the add/edit form dropdown.
const List<String> kBloodGroups = [
  'A+',
  'A-',
  'B+',
  'B-',
  'AB+',
  'AB-',
  'O+',
  'O-',
];

class FriendFormScreen extends StatefulWidget {
  final String ownerPersonnelNo;
  final Friend? friend;

  const FriendFormScreen({
    super.key,
    required this.ownerPersonnelNo,
    this.friend,
  });

  @override
  State<FriendFormScreen> createState() => _FriendFormScreenState();
}

class _FriendFormScreenState extends State<FriendFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name, _personnel, _trade, _phone;
  late TextEditingController _district, _upazila, _presentAddress;
  String? _bloodGroup;
  String? _photoPath;
  bool _saving = false;

  bool get isEdit => widget.friend != null;

  @override
  void initState() {
    super.initState();
    final f = widget.friend;
    _name = TextEditingController(text: f?.name ?? '');
    _personnel = TextEditingController(text: f?.personnelNo ?? '');
    _trade = TextEditingController(text: f?.trade ?? '');
    _bloodGroup = f?.bloodGroup;
    _phone = TextEditingController(text: f?.phone ?? '');
    _district = TextEditingController(text: f?.district ?? '');
    _upazila = TextEditingController(text: f?.upazila ?? '');
    _presentAddress = TextEditingController(text: f?.presentAddress ?? '');
    _photoPath = f?.photoPath;
  }

  @override
  void dispose() {
    _name.dispose();
    _personnel.dispose();
    _trade.dispose();
    _phone.dispose();
    _district.dispose();
    _upazila.dispose();
    _presentAddress.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final picked =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) return;
      if (kIsWeb) {
        _snack('Photo upload not supported on web in this demo', isError: true);
        return;
      }
      final dir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${dir.path}/photos');
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}${p.extension(picked.path)}';
      final saved = await File(picked.path).copy('${photosDir.path}/$fileName');
      if (!mounted) return;
      setState(() => _photoPath = saved.path);
    } catch (e) {
      if (!mounted) return;
      _snack('Photo error: $e', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  // ✅ FIXED: full try/catch, awaited DB write, guaranteed feedback
  Future<void> _save() async {
    // 1. Validate
    if (!_formKey.currentState!.validate()) {
      _snack('Please fill all required fields', isError: true);
      return;
    }

    // 2. Guard against double-tap
    if (_saving) return;
    setState(() => _saving = true);

    try {
      // 3. Build model
      final friend = Friend(
        id: widget.friend?.id, // null when adding -> DB will assign
        ownerPersonnelNo: widget.ownerPersonnelNo,
        name: _name.text.trim(),
        personnelNo: _personnel.text.trim(),
        trade: _trade.text.trim().isEmpty ? null : _trade.text.trim(),
        bloodGroup: _bloodGroup,
        phone: _phone.text.trim(),
        district: _district.text.trim().isEmpty ? null : _district.text.trim(),
        upazila: _upazila.text.trim().isEmpty ? null : _upazila.text.trim(),
        presentAddress: _presentAddress.text.trim().isEmpty
            ? null
            : _presentAddress.text.trim(),
        photoPath: _photoPath,
        isFavorite: widget.friend?.isFavorite ?? false,
      );

      // 4. Persist (await!)
      if (isEdit) {
        await DBService.update(friend);
      } else {
        final newId = await DBService.insert(friend);
        debugPrint('Inserted friend with id=$newId');
      }

      // 5. Only pop on success
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e, st) {
      debugPrint('Save failed: $e\n$st');
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('Save failed: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit friend' : 'Add friend'),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      backgroundImage: !kIsWeb &&
                              _photoPath != null &&
                              File(_photoPath!).existsSync()
                          ? FileImage(File(_photoPath!))
                          : null,
                      child: kIsWeb ||
                              _photoPath == null ||
                              !File(_photoPath!).existsSync()
                          ? const Icon(Icons.person, size: 48)
                          : null,
                    ),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.camera_alt,
                          size: 18, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                  labelText: 'Full name *',
                  prefixIcon: Icon(Icons.person_outline)),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _personnel,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                  labelText: 'Personnel number *',
                  prefixIcon: Icon(Icons.badge_outlined)),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _trade,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                  labelText: 'Trade (optional)',
                  prefixIcon: Icon(Icons.work_outlined)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: DropdownMenuFormField<String>(
                selectOnly: true,
                enableSearch: false,
                initialSelection: _bloodGroup,
                label: const Text('Blood group (optional)'),
                leadingIcon: const Icon(Icons.bloodtype),
                dropdownMenuEntries: [
                  for (final g in kBloodGroups)
                    DropdownMenuEntry<String>(value: g, label: g),
                ],
                onSelected: (v) => _bloodGroup = v,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                  labelText: 'Phone *', prefixIcon: Icon(Icons.phone_outlined)),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _district,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                  labelText: 'District (optional)',
                  prefixIcon: Icon(Icons.location_city)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _upazila,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                  labelText: 'Upazila (optional)',
                  prefixIcon: Icon(Icons.map_outlined)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _presentAddress,
              maxLines: 2,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                  labelText: 'Present address (optional)',
                  prefixIcon: Icon(Icons.home_outlined)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined),
              label: Text(isEdit ? 'Save changes' : 'Add friend'),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
