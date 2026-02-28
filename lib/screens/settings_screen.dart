import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:myapp/api.dart';
import 'package:myapp/main.dart';
import 'package:myapp/models/user.dart';
import 'package:myapp/storage_service.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) onLogout;

  const SettingsScreen({super.key, required this.onLogout});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<User>? _userFuture;
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      final apiKey = await _storageService.getApiKey();
      if (apiKey != null) {
        final api = TorboxApi(apiKey);
        setState(() {
          _userFuture = api.getUserDetails();
        });
      } else {
        setState(() {
          _userFuture = Future.error('API Key not configured.');
        });
      }
    } catch (e, s) {
      developer.log(
        'Error fetching user details',
        name: 'com.myapp.ui',
        error: e,
        stackTrace: s,
      );
      setState(() {
        _userFuture = Future.error(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
              },
            ),
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
                        const Icon(Icons.error_outline, color: Colors.red, size: 60),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _fetchUserDetails,
                          child: const Text('Retry'),
                        )
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
                    title: const Text('Customer ID'),
                    subtitle: Text(user.customer),
                    leading: const Icon(Icons.person),
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
