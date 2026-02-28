import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:myapp/api.dart';
import 'package:myapp/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<dynamic>>? _torrentsFuture;
  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    developer.log('HomeScreen initState', name: 'com.myapp.ui');
    _fetchTorrents();
  }

  Future<void> _fetchTorrents() async {
    developer.log('Attempting to fetch torrents...', name: 'com.myapp.ui');
    try {
      final apiKey = await _storageService.getApiKey();

      if (apiKey != null) {
        developer.log('API key found, creating TorboxApi instance.', name: 'com.myapp.ui');
        final api = TorboxApi(apiKey);
        setState(() {
          _torrentsFuture = api.getTorrents();
        });
         developer.log('Torrents future initiated.', name: 'com.myapp.ui');
      } else {
        developer.log('API key not found in local storage.', name: 'com.myapp.ui', level: 900);
        setState(() {
          _torrentsFuture = Future.error('API Key not configured.');
        });
      }
    } catch (e, s) {
      developer.log(
        'Error fetching API key from local storage',
        name: 'com.myapp.ui',
        error: e,
        stackTrace: s,
      );
       setState(() {
        _torrentsFuture = Future.error(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Torrents'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _torrentsFuture,
        builder: (context, snapshot) {
          developer.log('Building UI with snapshot state: ${snapshot.connectionState}', name: 'com.myapp.ui');

          if (snapshot.connectionState == ConnectionState.waiting) {
            developer.log('UI state: Waiting for torrents...', name: 'com.myapp.ui');
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
             developer.log(
              'UI state: Error fetching torrents.',
              name: 'com.myapp.ui',
              error: snapshot.error,
              stackTrace: snapshot.stackTrace,
              level: 1000,
            );
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
                      onPressed: _fetchTorrents,
                      child: const Text('Retry'),
                    )
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            developer.log('UI state: No torrents found.', name: 'com.myapp.ui');
            return const Center(child: Text('No torrents found.'));
          }

          final torrents = snapshot.data!;
          developer.log('UI state: Torrents loaded successfully (${torrents.length} items).', name: 'com.myapp.ui');

          final activeTorrents = torrents.where((t) => t['active'] == true).toList();
          final completedTorrents = torrents.where((t) => t['active'] == false).toList();

          return ListView(
            children: [
              ExpansionTile(
                title: Text('Active (${activeTorrents.length})'),
                initiallyExpanded: true,
                children: activeTorrents.map((torrent) => ListTile(
                  title: Text(torrent['name'] ?? 'No Name'),
                  subtitle: Text(torrent['status'] ?? 'Unknown Status'),
                  leading: const Icon(Icons.downloading),
                )).toList(),
              ),
              ExpansionTile(
                title: Text('Completed (${completedTorrents.length})'),
                children: completedTorrents.map((torrent) => ListTile(
                  title: Text(torrent['name'] ?? 'No Name'),
                  subtitle: Text(torrent['status'] ?? 'Unknown Status'),
                  leading: const Icon(Icons.done),
                )).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
