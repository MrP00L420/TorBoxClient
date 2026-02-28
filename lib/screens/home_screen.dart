
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:myapp/api.dart';
import 'package:myapp/models/torrent.dart';
import 'package:myapp/screens/torrent_details_screen.dart';
import 'package:myapp/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<Torrent>>? _torrentsFuture;
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

  String _formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Torrents'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTorrents,
        child: FutureBuilder<List<Torrent>>(
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

            final activeTorrents = torrents.where((t) => t.active).toList();
            final completedTorrents = torrents.where((t) => !t.active).toList();

            return ListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                _buildTorrentSection('Active', activeTorrents),
                _buildTorrentSection('Completed', completedTorrents),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTorrentSection(String title, List<Torrent> torrents) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: const Border(),
        title: Text(
          '$title (${torrents.length})',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: Icon(
          title == 'Active' ? Icons.downloading : Icons.check_circle,
          color: theme.colorScheme.primary,
        ),
        initiallyExpanded: true,
        children: torrents.map((torrent) => _buildTorrentTile(torrent, theme)).toList(),
      ),
    );
  }

  Widget _buildTorrentTile(Torrent torrent, ThemeData theme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      title: Text(torrent.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          children: [
            Icon(Icons.folder_zip, size: 16, color: theme.colorScheme.secondary),
            const SizedBox(width: 8),
            Text(_formatBytes(torrent.size, 2)),
            const SizedBox(width: 16),
            Icon(Icons.info_outline, size: 16, color: theme.colorScheme.secondary),
            const SizedBox(width: 8),
            Text(torrent.downloadState.toUpperCase()),
          ],
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TorrentDetailsScreen(torrent: torrent),
          ),
        );
      },
    );
  }
}
