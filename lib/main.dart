import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/pocket_sync_service.dart';
import 'theme.dart';

void main() {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const FriendsApp());
}

class FriendsApp extends StatefulWidget {
  const FriendsApp({super.key});
  @override
  State<FriendsApp> createState() => _FriendsAppState();
}

class _FriendsAppState extends State<FriendsApp> {
  bool _dark = false;
  String? _user;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      _dark = await AuthService.isDarkMode();
      _user = await AuthService.currentUser();
      if (_user != null) {
        await PocketSyncService.setUserId(_user!);
        await PocketSyncService.startSync();
      }
    } catch (error) {
      debugPrint('Startup bootstrap failed: $error');
    } finally {
      if (mounted) {
        setState(() => _loaded = true);
      }
    }
  }

  void _toggleDark(bool v) async {
    setState(() => _dark = v);
    await AuthService.setDarkMode(v);
  }

  Future<void> _onLogin(String user) async {
    try {
      await PocketSyncService.setUserId(user);
      await PocketSyncService.startSync();
    } catch (error) {
      debugPrint('PocketSync login sync failed: $error');
    }
    if (mounted) setState(() => _user = user);
  }

  Future<void> _onLogout() async {
    try {
      await PocketSyncService.stopSync();
    } catch (error) {
      debugPrint('PocketSync logout failed: $error');
    }
    await AuthService.logout();
    if (mounted) setState(() => _user = null);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MaterialApp(
      title: 'Friends Info',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      home: _user == null
          ? LoginScreen(onLogin: _onLogin)
          : HomeScreen(
              personnelNo: _user!,
              darkMode: _dark,
              onToggleDark: _toggleDark,
              onLogout: _onLogout,
            ),
    );
  }
}
