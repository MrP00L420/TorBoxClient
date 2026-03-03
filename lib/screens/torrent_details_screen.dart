// =============================================================================
// FILE: lib/screens/torrent_details_screen.dart
// PURPOSE: Displays detailed information about a single torrent, lists all its
//          files with individual download buttons, and provides a "Download All
//          as ZIP" option at the bottom.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:myapp/api.dart';
import 'package:myapp/models/file.dart' as t_file;
import 'package:myapp/models/torrent.dart';
import 'package:myapp/storage_service.dart';
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
  //   - decimals: number of decimal places to show
  // Returns: formatted string like "4.20 MB"
  // ---------------------------------------------------------------------------
  String _formatBytes(int bytes, int decimals) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  // ---------------------------------------------------------------------------
  // _downloadSingleFile()
  // Handles downloading a single file from the torrent.
  // Steps:
  //   1. Retrieve the API key from local storage
  //   2. Call api.getDownloadLink() with torrentId and fileId
  //   3. Launch the returned URL in an external browser
  // Shows a loading spinner on the specific file's download button while working.
  // ---------------------------------------------------------------------------
  Future<void> _downloadSingleFile(t_file.File file) async {
    // Set loading state for this specific file
    setState(() {
      _downloadingFileId = file.id;
    });

    final apiKey = await StorageService().getApiKey();
    if (!mounted) return;

    // If no API key is found, show an error and stop
    if (apiKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key not found. Please log in again.')),
      );
      setState(() {
        _downloadingFileId = null;
      });
      return;
    }

    final api = TorboxApi(apiKey);

    try {
      // Request the download link from TorBox API
      // Only torrentId and fileId are needed — no extra options
      final downloadLink = await api.getDownloadLink(
        torrentId: widget.torrent.id,
        fileId: file.id,
      );

      developer.log('Got download link: $downloadLink',
          name: 'com.myapp.download');

      if (!mounted) return;

      // Parse the URL and launch it in an external browser
      final uri = Uri.parse(downloadLink);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Forces external browser
      );

      // If the URL couldn't be launched, show an error
      if (!launched) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open download link for ${file.shortName}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      developer.log('Error downloading file: $e', name: 'com.myapp.download');
      if (!mounted) return;

      // Show error message in a SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      // Clear the loading state regardless of success or failure
      if (mounted) {
        setState(() {
          _downloadingFileId = null;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // _downloadAllAsZip()
  // Handles downloading ALL files in the torrent as a single ZIP archive.
  // Steps:
  //   1. Retrieve the API key from local storage
  //   2. Call api.getZipDownloadLink() with just the torrentId
  //   3. Launch the returned URL in an external browser
  // Shows a loading spinner on the ZIP button while working.
  // ---------------------------------------------------------------------------
  Future<void> _downloadAllAsZip() async {
    // Set loading state for the ZIP button
    setState(() {
      _downloadingZip = true;
    });

    final apiKey = await StorageService().getApiKey();
    if (!mounted) return;

    // If no API key is found, show an error and stop
    if (apiKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API Key not found. Please log in again.')),
      );
      setState(() {
        _downloadingZip = false;
      });
      return;
    }

    final api = TorboxApi(apiKey);

    try {
      // Request the ZIP download link from TorBox API
      // Only torrentId is needed — zip_link is set to true internally
      final downloadLink = await api.getZipDownloadLink(
        torrentId: widget.torrent.id,
      );

      developer.log('Got ZIP download link: $downloadLink',
          name: 'com.myapp.download');

      if (!mounted) return;

      // Parse the URL and launch it in an external browser
      final uri = Uri.parse(downloadLink);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // Forces external browser
      );

      // If the URL couldn't be launched, show an error
      if (!launched) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open ZIP download link'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      developer.log('Error downloading ZIP: $e', name: 'com.myapp.download');
      if (!mounted) return;

      // Show error message in a SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ZIP download error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      // Clear the loading state regardless of success or failure
      if (mounted) {
        setState(() {
          _downloadingZip = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // build()
  // Main build method for the torrent details screen.
  // Layout:
  //   1. Torrent info card (name, size, status)
  //   2. Files section header
  //   3. List of files with individual download buttons
  //   4. "Download All as ZIP" button at the bottom
  // ---------------------------------------------------------------------------
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
            // -----------------------------------------------------------------
            // Torrent Info Card
            // Displays the torrent name, total size, and current status
            // -----------------------------------------------------------------
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Torrent name as the card header
                    Text(
                      widget.torrent.name,
                      style: textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Total size of the torrent
                    ListTile(
                      leading: Icon(Icons.folder_zip,
                          color: theme.colorScheme.primary),
                      title: const Text('Size'),
                      subtitle:
                          Text(_formatBytes(widget.torrent.size, 2)),
                    ),

                    // Current download state (e.g., "COMPLETED", "DOWNLOADING")
                    ListTile(
                      leading: Icon(Icons.download_for_offline,
                          color: theme.colorScheme.secondary),
                      title: const Text('Status'),
                      subtitle: Text(
                          widget.torrent.downloadState.toUpperCase()),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // -----------------------------------------------------------------
            // Files Section Header
            // -----------------------------------------------------------------
            Text('Files', style: textTheme.titleLarge),
            const SizedBox(height: 8),

            // -----------------------------------------------------------------
            // Files List
            // Each file gets its own ListTile with a download button
            // -----------------------------------------------------------------
            _buildFilesList(theme),

            const SizedBox(height: 24),

            // -----------------------------------------------------------------
            // Download All as ZIP Button
            // Only shown if the torrent actually has files
            // -----------------------------------------------------------------
            if (widget.torrent.files.isNotEmpty) _buildZipDownloadButton(theme),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // _buildFilesList()
  // Builds the card containing all files in the torrent.
  // Each file shows:
  //   - File icon
  //   - File name (up to 2 lines, then ellipsis)
  //   - File size in human-readable format
  //   - Download button (or loading spinner if that file is being fetched)
  // ---------------------------------------------------------------------------
  Widget _buildFilesList(ThemeData theme) {
    // If the torrent has no files, show a placeholder message
    if (widget.torrent.files.isEmpty) {
      return const Center(
          child: Text('No files available in this torrent.'));
    }

    return Card(
      elevation: 2,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.torrent.files.length,
        // Add a thin divider between each file entry for visual clarity
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final file = widget.torrent.files[index];

          // Check if THIS specific file is currently being downloaded
          final isDownloading = _downloadingFileId == file.id;

          return ListTile(
            // File icon on the left
            leading: Icon(Icons.insert_drive_file_outlined,
                color: theme.colorScheme.tertiary),

            // File name — limited to 2 lines with ellipsis overflow
            title: Text(file.name,
                maxLines: 2, overflow: TextOverflow.ellipsis),

            // File size underneath the name
            subtitle: Text(_formatBytes(file.size, 2)),

            // Download button on the right
            // Shows a loading spinner if this file's download link is being fetched
            trailing: isDownloading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: Icon(Icons.download,
                        color: theme.colorScheme.primary),
                    onPressed: () => _downloadSingleFile(file),
                    tooltip: 'Download ${file.shortName}',
                  ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // _buildZipDownloadButton()
  // Builds the "Download All as ZIP" button shown below the files list.
  // This button:
  //   - Spans the full width of the screen
  //   - Has a ZIP icon and descriptive text
  //   - Shows a loading spinner while the ZIP link is being fetched
  //   - Is disabled while loading to prevent double-taps
  // ---------------------------------------------------------------------------
  Widget _buildZipDownloadButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        // Disable the button while the ZIP download link is being fetched
        onPressed: _downloadingZip ? null : _downloadAllAsZip,

        // Show a loading spinner or the ZIP icon depending on state
        icon: _downloadingZip
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.archive),

        // Button label changes based on loading state
        label: Text(
          _downloadingZip
              ? 'Fetching ZIP link...'
              : 'Download All as ZIP',
        ),

        // Styled with primary color, rounded corners, and some padding
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