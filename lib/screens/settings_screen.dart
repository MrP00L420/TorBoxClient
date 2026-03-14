import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:TBox/api.dart';
import 'package:TBox/models/user.dart';
import 'package:TBox/storage_service.dart';
import 'package:TBox/widgets/theme_switcher.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) onLogout;

  const SettingsScreen({super.key, required this.onLogout});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<User>? _userFuture;
  final _storageService = StorageService();
  bool _isAppLockEnabled = false;

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUserDetails();
    _loadAppLockState();
  }

  Future<void> _loadAppLockState() async {
    final isEnabled = await _storageService.isAppLockEnabled();
    setState(() {
      _isAppLockEnabled = isEnabled;
    });
  }

  Future<User> _fetchUserDetails() async {
    try {
      final apiKey = await _storageService.getApiKey();
      if (apiKey != null) {
        final api = TorboxApi(apiKey);
        return api.getUserDetails();
      } else {
        throw Exception('API Key not configured.');
      }
    } catch (e, s) {
      developer.log(
        'Error fetching user details',
        name: 'dev.TBox.ui',
        error: e,
        stackTrace: s,
      );
      rethrow;
    }
  }

  void _reloadUserDetails() {
    setState(() {
      _userFuture = _fetchUserDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ThemeSwitcher(),
          const Divider(),
          SwitchListTile(
            title: const Text('App Lock'),
            subtitle: const Text('Require authentication to open the app'),
            value: _isAppLockEnabled,
            onChanged: (bool value) async {
              await _storageService.setAppLock(value);
              setState(() {
                _isAppLockEnabled = value;
              });
            },
            secondary: const Icon(Icons.fingerprint),
          ),
          const Divider(),
          FutureBuilder<User>(
            future: _userFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _reloadUserDetails,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: Text('No user data found.'));
              }

              final user = snapshot.data!;

              return Column(
                children: [
                  ListTile(
                    title: const Text('Email'),
                    subtitle: Text(user.email),
                    leading: const Icon(Icons.email),
                  ),
                  ListTile(
                    title: const Text('Premium Expires At'),
                    subtitle: Text(user.premiumExpiresAt),
                    leading: const Icon(Icons.star),
                  ),
                ],
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Logout'),
            leading: const Icon(Icons.logout),
            onTap: () async {
              await _storageService.deleteApiKey();
              widget.onLogout(true);
            },
          ),
        ],
      ),
    );
  }
}
