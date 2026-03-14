// =============================================================================
// FILE: lib/screens/torrent_details_screen.dart
// PURPOSE: Displays detailed information about a single torrent, lists all its
//          files with individual download buttons, and provides a "Download All
//          as ZIP" option at the bottom.
// =================================e=============================================

import 'package:flutter/material.dart';
import 'package:TBox/api.dart';
import 'package:TBox/models/file.dart';
import 'package:TBox/models/torrent.dart';
import 'package:TBox/storage_service.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'dart:developer' as developer;

class TorrentDetailsScreen extends StatefulWidget {
  final Torrent torrent;

  const TorrentDetailsScreen({super.key, required this.torrent});

  @override
  State<TorrentDetailsScreen> createState() => _TorrentDetailsScreenState();
}

class _TorrentDetailsScreenState extends State<TorrentDetailsScreen> {
  final _storageService = StorageService();

  // ---------------------------------------------------------------------------
  // State variables
  // ---------------------------------------------------------------------------

  // Tracks which individual file is currently being fetched for download.
  // We store the file ID so we can show a loading spinner on that specific
  // file's download button, rather than blocking the entire UI.
  int? _downloadingFileId;

  // Tracks whether the "Download All as ZIP" button is currently loading.
  bool _downloadingZip = false;

  // ---------------------------------------------------------------------------
  // _formatBytes()
  // Converts raw byte count into a human-readable string (e.g., "1.23 GB").
  // Parameters:
  //   - bytes: the raw size in bytes
  // Returns: formatted string like "4.20 MB"
  // ---------------------------------------------------------------------------
  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  // ---------------------------------------------------------------------------
  // _showDownloadOptions()
  // Displays a bottom sheet with options for the download link:
  //   1. Open in Browser
  //   2. Copy to Clipboard
  //   3. Share
  // ---------------------------------------------------------------------------
  void _showDownloadOptions(
      BuildContext context, String downloadLink, String fileName) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.open_in_browser),
                title: const Text('Open in Browser'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final uri = Uri.parse(downloadLink);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy Link'),
                onTap: () {
                  Navigator.of(context).pop();
                  Clipboard.setData(ClipboardData(text: downloadLink));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download link copied!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.of(context).pop();
                  Share.share('Download link for $fileName: $downloadLink');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // _getDownloadLinkAndShowOptions()
  // Fetches the download link and then presents the options modal.
  // Handles loading states and errors.
  // ---------------------------------------------------------------------------
  Future<void> _getDownloadLinkAndShowOptions(
      {TorrentFile? file, bool isZip = false}) async {
    // Set loading state
    setState(() {
      if (isZip) {
        _downloadingZip = true;
      } else if (file != null) {
        _downloadingFileId = file.id;
      }
    });

    final apiKey = await _storageService.getApiKey();
    if (!mounted) return;

    if (apiKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('API Key not found. Please log in again.')),
      );
      // Reset loading state
      setState(() {
        _downloadingZip = false;
        _downloadingFileId = null;
      });
      return;
    }

    final api = TorboxApi(apiKey);

    try {
      final String downloadLink;
      final String fileName;

      if (isZip) {
        downloadLink = await api.getZipDownloadLink(torrentId: widget.torrent.id);
        fileName = '${widget.torrent.name}.zip';
        developer.log('Got ZIP download link: REDACTED', name: 'dev.TBox.download');
      } else {
        downloadLink = await api.getDownloadLink(
            torrentId: widget.torrent.id, fileId: file!.id);
        fileName = file.name;
        developer.log('Got download link: REDACTED', name: 'dev.TBox.download');
      }

      if (mounted) {
        _showDownloadOptions(context, downloadLink, fileName);
      }
    } catch (e) {
      developer.log('Error getting download link: $e', name: 'dev.TBox.download');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An error occurred while getting the download link.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _downloadingZip = false;
          _downloadingFileId = null;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // build()
  // Main build method for the torrent details screen.
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.torrent.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Torrent Info Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.torrent.name,
                      style: textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.folder_zip,
                          color: theme.colorScheme.primary),
                      title: const Text('Size'),
                      subtitle: Text(_formatBytes(widget.torrent.size)),
                    ),
                    ListTile(
                      leading: Icon(Icons.download_for_offline,
                          color: theme.colorScheme.secondary),
                      title: const Text('Status'),
                      subtitle:
                          Text(widget.torrent.downloadState.toUpperCase()),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Files Section Header
            Text('Files', style: textTheme.titleLarge),
            const SizedBox(height: 8),

            // Files List
            _buildFilesList(theme),

            const SizedBox(height: 24),

            // Download All as ZIP Button
            if (widget.torrent.files.isNotEmpty) _buildZipDownloadButton(theme),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // _buildFilesList()
  // Builds the card containing all files in the torrent.
  // ---------------------------------------------------------------------------
  Widget _buildFilesList(ThemeData theme) {
    if (widget.torrent.files.isEmpty) {
      return const Center(child: Text('No files available in this torrent.'));
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.torrent.files.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final file = widget.torrent.files[index];
          final isDownloading = _downloadingFileId == file.id;

          return ListTile(
            leading: Icon(Icons.insert_drive_file_outlined,
                color: theme.colorScheme.tertiary),
            title: Text(file.name,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(_formatBytes(file.size)),
            trailing: isDownloading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: Icon(Icons.download, color: theme.colorScheme.primary),
                    onPressed: () =>
                        _getDownloadLinkAndShowOptions(file: file), // Updated call
                    tooltip: 'Download ${file.shortName}',
                  ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // _buildZipDownloadButton()
  // Builds the "Download All as ZIP" button.
  // ---------------------------------------------------------------------------
  Widget _buildZipDownloadButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _downloadingZip
            ? null
            : () => _getDownloadLinkAndShowOptions(
                isZip: true), // Updated call
        icon: _downloadingZip
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.archive),
        label: Text(
          _downloadingZip ? 'Fetching ZIP link...' : 'Download All as ZIP',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
