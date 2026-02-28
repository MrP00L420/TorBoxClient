
import 'package:flutter/material.dart';
import 'package:myapp/api.dart';
import 'package:myapp/models/file.dart' as t_file;
import 'package:myapp/models/torrent.dart';
import 'package:myapp/storage_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class TorrentDetailsScreen extends StatefulWidget {
  final Torrent torrent;

  const TorrentDetailsScreen({super.key, required this.torrent});

  @override
  State<TorrentDetailsScreen> createState() => _TorrentDetailsScreenState();
}

class _TorrentDetailsScreenState extends State<TorrentDetailsScreen> {
  bool _showAdvancedOptions = false;
  bool? _zipLink = false;
  String? _userIp;
  bool? _redirect = true;

  String _formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  Future<void> _download(t_file.File file) async {
    final apiKey = await StorageService().getApiKey();
    if (!mounted) return;

    final theme = Theme.of(context);
    if (apiKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key not found.')),
      );
      return;
    }

    final api = TorboxApi(apiKey);

    try {
      final downloadLink = await api.getDownloadLink(
        torrentId: widget.torrent.id,
        fileId: file.id,
        zipLink: _zipLink,
        userIp: _userIp,
        redirect: _redirect,
      );

      if (!mounted) return;
      final uri = Uri.parse(downloadLink);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Could not launch $downloadLink';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.torrent.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.torrent.name,
                      style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.folder_zip, color: theme.colorScheme.primary),
                      title: const Text('Size'),
                      subtitle: Text(_formatBytes(widget.torrent.size, 2)),
                    ),
                    ListTile(
                      leading: Icon(Icons.download_for_offline, color: theme.colorScheme.secondary),
                      title: const Text('Status'),
                      subtitle: Text(widget.torrent.downloadState.toUpperCase()),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Files', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            _buildFilesList(theme),
            const SizedBox(height: 24),
            _buildAdvancedOptions(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildFilesList(ThemeData theme) {
    if (widget.torrent.files.isEmpty) {
      return const Center(child: Text('No files available in this torrent.'));
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.torrent.files.length,
        itemBuilder: (context, index) {
          final file = widget.torrent.files[index];
          return ListTile(
            leading: Icon(Icons.insert_drive_file_outlined, color: theme.colorScheme.tertiary),
            title: Text(file.name, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(_formatBytes(file.size, 2)),
            trailing: IconButton(
              icon: Icon(Icons.download, color: theme.colorScheme.primary),
              onPressed: () => _download(file),
              tooltip: 'Download File',
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdvancedOptions(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: const Border(), // Remove the default border
        title: Text('Advanced Download Options', style: theme.textTheme.titleMedium),
        leading: Icon(Icons.settings, color: theme.colorScheme.primary),
        onExpansionChanged: (expanded) {
          setState(() {
            _showAdvancedOptions = expanded;
          });
        },
        initiallyExpanded: _showAdvancedOptions,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                CheckboxListTile(
                  title: const Text('Generate Zip Link'),
                  subtitle: const Text('Create a single zip file for download.'),
                  value: _zipLink,
                  onChanged: (value) {
                    setState(() {
                      _zipLink = value;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Use Redirect'),
                  subtitle: const Text('Follow HTTP redirects automatically.'),
                  value: _redirect,
                  onChanged: (value) {
                    setState(() {
                      _redirect = value;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'User IP (Optional)',
                      hintText: 'e.g., 192.168.1.100',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _userIp = value.isNotEmpty ? value : null;
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
