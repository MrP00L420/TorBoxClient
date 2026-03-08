// =============================================================================
// FILE: lib/screens/home_screen.dart
// PURPOSE: Displays the user's torrent list split into Active and Completed
//          sections. Includes a search bar to filter torrents by name and an
//          animated expandable FAB (speed dial) for adding new torrents.
// =============================================================================

import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:TBox/api.dart';
import 'package:TBox/models/torrent.dart';
import 'package:TBox/screens/torrent_details_screen.dart';
import 'package:TBox/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// SingleTickerProviderStateMixin provides the vsync needed for
// the AnimationController that drives the FAB expand/collapse animation.
class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Torrent data state
  // Instead of using FutureBuilder (which can be unreliable with replaced
  // futures), we store the torrent list directly in state. This gives us
  // full control over when and how the UI updates after fetching data.
  // ---------------------------------------------------------------------------

  /// The full list of torrents fetched from the API (unfiltered)
  List<Torrent> _allTorrents = [];

  /// Whether a fetch is currently in progress (shows loading spinner)
  bool _isLoading = false;

  /// Error message from the last failed fetch, or null if no error
  String? _error;

  /// Whether the initial fetch has completed at least once.
  /// Used to differentiate between "first load" and "empty list".
  bool _initialLoadComplete = false;

  // ---------------------------------------------------------------------------
  // Search state
  // The search query filters _allTorrents locally — no API call needed.
  // ---------------------------------------------------------------------------

  /// The current search text entered by the user
  String _searchQuery = '';

  /// Controller for the search TextField so we can clear it programmatically
  final _searchController = TextEditingController();

  final _storageService = StorageService();

  // ---------------------------------------------------------------------------
  // FAB animation state
  // ---------------------------------------------------------------------------
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    developer.log('HomeScreen initState', name: 'dev.TBox.ui');

    // Initialize the FAB animation — 250ms for a snappy feel
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // Fetch torrents on first load
    _fetchTorrents();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // _fetchTorrents()
  // Fetches the torrent list from the TorBox API and stores the result
  // directly in state. This method is awaited fully, so pull-to-refresh
  // and post-add refreshes work correctly.
  //
  // Flow:
  //   1. Set loading state (shows spinner)
  //   2. Get API key from storage
  //   3. Call api.getTorrents() and AWAIT the full response
  //   4. Store the result in _allTorrents
  //   5. Clear loading state
  //
  // On error: stores error message in _error (shown in UI)
  // ---------------------------------------------------------------------------
  Future<void> _fetchTorrents() async {
    developer.log('Fetching torrents...', name: 'dev.TBox.ui');

    // Set loading state — shows the spinner in the UI
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiKey = await _storageService.getApiKey();

      if (apiKey == null) {
        throw Exception('API Key not configured.');
      }

      final api = TorboxApi(apiKey);

      // AWAIT the actual API response — this is key for reliable refreshing.
      // Previously, we just set a Future and let FutureBuilder handle it,
      // which could lead to stale data if the Future reference wasn't
      // properly detected as "new" by FutureBuilder.
      final torrents = await api.getTorrents();

      developer.log('Fetched ${torrents.length} torrents', name: 'dev.TBox.ui');

      if (mounted) {
        setState(() {
          _allTorrents = torrents;
          _isLoading = false;
          _initialLoadComplete = true;
        });
      }
    } catch (e, s) {
      developer.log(
        'Error fetching torrents',
        name: 'dev.TBox.ui',
        error: e,
        stackTrace: s,
      );

      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _initialLoadComplete = true;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // _filteredTorrents
  // Returns the torrent list filtered by the current search query.
  // Search is case-insensitive and matches against the torrent name.
  // If the search query is empty, returns all torrents unfiltered.
  // ---------------------------------------------------------------------------
  List<Torrent> get _filteredTorrents {
    if (_searchQuery.isEmpty) {
      return _allTorrents;
    }

    final query = _searchQuery.toLowerCase();
    return _allTorrents
        .where((torrent) => torrent.name.toLowerCase().contains(query))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // _formatBytes()
  // Converts raw byte count into a human-readable string (e.g., "1.23 GB").
  // ---------------------------------------------------------------------------
  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  // ---------------------------------------------------------------------------
  // FAB toggle methods
  // ---------------------------------------------------------------------------

  /// Toggles the FAB between expanded and collapsed
  void _toggleFab() {
    if (_fabAnimationController.isDismissed) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  /// Closes the FAB if it's currently open
  void _closeFab() {
    if (!_fabAnimationController.isDismissed) {
      _fabAnimationController.reverse();
    }
  }

  // ---------------------------------------------------------------------------
  // _showMagnetLinkDialog()
  // Opens a dialog where the user can paste a magnet link to add a new torrent.
  // On success: closes dialog, shows success SnackBar, refreshes torrent list.
  // On error: keeps dialog open for retry, shows error SnackBar.
  // ---------------------------------------------------------------------------
  Future<void> _showMagnetLinkDialog() async {
    final magnetController = TextEditingController();

    // Capture the scaffold messenger BEFORE showing the dialog, so we can
    // show SnackBars after the dialog is popped
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    await showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSubmitting = false;

        // StatefulBuilder lets us update only the dialog's state
        return StatefulBuilder(
          builder: (statefulContext, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.link,
                    color: Theme.of(statefulContext).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  const Text('Add Magnet Link'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: magnetController,
                    decoration: InputDecoration(
                      hintText: 'magnet:?xt=urn:btih:...',
                      labelText: 'Magnet Link',
                      prefixIcon: const Icon(Icons.link),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 3,
                    enabled: !isSubmitting,
                  ),
                  if (isSubmitting)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: LinearProgressIndicator(),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final magnet = magnetController.text.trim();

                          if (magnet.isEmpty) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a magnet link'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                          });

                          try {
                            final apiKey = await _storageService.getApiKey();
                            if (apiKey == null) {
                              throw Exception('API Key not found');
                            }

                            final api = TorboxApi(apiKey);
                            final message = await api.createTorrent(
                              magnet: magnet,
                            );

                            // Close dialog on success
                            Navigator.of(dialogContext).pop();

                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text(message)),
                            );

                            // Refresh the list — now properly awaited so
                            // the new torrent will appear
                            _fetchTorrents();
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                            });

                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Theme.of(
                                  statefulContext,
                                ).colorScheme.error,
                              ),
                            );
                          }
                        },
                  child: const Text('Add Torrent'),
                ),
              ],
            );
          },
        );
      },
    );

    magnetController.dispose();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Split the filtered torrents into active and completed groups
    final filtered = _filteredTorrents;
    final activeTorrents = filtered.where((t) => t.active).toList();
    final completedTorrents = filtered.where((t) => !t.active).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Torrents')),
      body: Stack(
        children: [
          // ----- Main content -----
          RefreshIndicator(
            // Pull-to-refresh now properly awaits the full API response
            onRefresh: _fetchTorrents,
            child: Column(
              children: [
                // ----- Search Bar -----
                _buildSearchBar(theme),

                // ----- Torrent List -----
                Expanded(
                  child: _buildTorrentList(
                    theme,
                    activeTorrents,
                    completedTorrents,
                  ),
                ),
              ],
            ),
          ),

          // ----- Backdrop overlay when FAB is expanded -----
          AnimatedBuilder(
            animation: _fabAnimationController,
            builder: (context, child) {
              if (_fabAnimationController.isDismissed) {
                return const SizedBox.shrink();
              }

              return GestureDetector(
                onTap: _closeFab,
                child: Container(
                  color: Colors.black.withOpacity(
                    0.5 * _fabAnimationController.value,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _buildExpandableFab(),
    );
  }

  // ---------------------------------------------------------------------------
  // _buildSearchBar()
  // Builds the search bar at the top of the home screen.
  // Features:
  //   - Search icon on the left
  //   - Clear button on the right (only visible when there's text)
  //   - Filters the torrent list in real-time as the user types
  //   - Does NOT make API calls — filters the already-loaded list locally
  // ---------------------------------------------------------------------------
  Widget _buildSearchBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search torrents...',
          prefixIcon: const Icon(Icons.search),

          // Clear button — only shown when there's text in the search field
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,

          // Rounded border styling
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 20,
          ),
        ),
        // Update the search query on every keystroke for real-time filtering
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // _buildTorrentList()
  // Builds the main content area based on the current state:
  //   - Loading (first load): shows a centered spinner
  //   - Error: shows error message with retry button
  //   - Empty (no torrents at all): shows "No torrents found"
  //   - Empty (search has no results): shows "No matching torrents"
  //   - Data: shows Active and Completed sections
  //
  // The entire thing is wrapped in a ListView to enable pull-to-refresh
  // even when the content doesn't fill the screen (using AlwaysScrollable).
  // ---------------------------------------------------------------------------
  Widget _buildTorrentList(
    ThemeData theme,
    List<Torrent> activeTorrents,
    List<Torrent> completedTorrents,
  ) {
    // Show loading spinner on initial load
    if (_isLoading && !_initialLoadComplete) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error state with retry button
    if (_error != null && _allTorrents.isEmpty) {
      return ListView(
        // AlwaysScrollable ensures pull-to-refresh works even when
        // content doesn't fill the viewport
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
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
                    Text('Error: $_error', textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _fetchTorrents,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Show empty state when there are no torrents at all
    if (_allTorrents.isEmpty && _initialLoadComplete) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: const Center(
              child: Text('No torrents found. Add one using the + button!'),
            ),
          ),
        ],
      );
    }

    // Show "no results" when search doesn't match anything
    if (activeTorrents.isEmpty &&
        completedTorrents.isEmpty &&
        _searchQuery.isNotEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 60,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No torrents matching "$_searchQuery"',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Main torrent list — Active and Completed sections
    return Stack(
      children: [
        ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(8.0),
          children: [
            _buildTorrentSection('Active', activeTorrents),
            _buildTorrentSection('Completed', completedTorrents),
            // Extra padding at the bottom so the FAB doesn't cover the last item
            const SizedBox(height: 80),
          ],
        ),

        // Show a subtle loading indicator at the top when refreshing
        // (but only after initial load — during initial load we show
        // the full-screen spinner instead)
        if (_isLoading && _initialLoadComplete)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // _buildExpandableFab()
  // Speed dial FAB with a rotating + icon and expandable option buttons.
  // ---------------------------------------------------------------------------
  Widget _buildExpandableFab() {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _fabAnimationController,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Magnet Link option
            IgnorePointer(
              ignoring: _fabAnimationController.isDismissed,
              child: _buildFabOption(
                icon: Icons.link,
                label: 'Magnet Link',
                heroTag: 'fab_magnet',
                theme: theme,
                onTap: () {
                  _closeFab();
                  _showMagnetLinkDialog();
                },
              ),
            ),

            const SizedBox(height: 12),

            // Main FAB — + icon rotates 45° to become × when expanded
            FloatingActionButton(
              heroTag: 'fab_main',
              onPressed: _toggleFab,
              child: Transform.rotate(
                angle: _fabAnimationController.value * (pi / 4),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // _buildFabOption()
  // Builds a single speed dial option with a label chip and small FAB icon.
  // Scales and fades in/out with the animation.
  // ---------------------------------------------------------------------------
  Widget _buildFabOption({
    required IconData icon,
    required String label,
    required String heroTag,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeOut,
      ),
      child: FadeTransition(
        opacity: _fabAnimationController,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label chip
              Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Small FAB icon
              FloatingActionButton.small(
                heroTag: heroTag,
                onPressed: onTap,
                child: Icon(icon),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // _buildTorrentSection()
  // Builds an expandable card for a group of torrents (Active or Completed).
  // ---------------------------------------------------------------------------
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
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Icon(
          title == 'Active' ? Icons.downloading : Icons.check_circle,
          color: theme.colorScheme.primary,
        ),
        initiallyExpanded: true,
        children: torrents
            .map((torrent) => _buildTorrentTile(torrent, theme))
            .toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // _buildTorrentTile()
  // Builds a single torrent list tile. Tapping navigates to details screen.
  // ---------------------------------------------------------------------------
  Widget _buildTorrentTile(Torrent torrent, ThemeData theme) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      title: Text(torrent.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          children: [
            Icon(
              Icons.folder_zip,
              size: 16,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(_formatBytes(torrent.size)),
            const SizedBox(width: 16),
            Icon(
              Icons.info_outline,
              size: 16,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(torrent.downloadState.toUpperCase()),
          ],
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _closeFab();

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
