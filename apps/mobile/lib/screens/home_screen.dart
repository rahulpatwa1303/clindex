import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'review_screen.dart';
import 'scanner_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? successMessage;

  const HomeScreen({super.key, this.successMessage});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  late Future<List<dynamic>> _scansFuture;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All Records';

  static const _filters = ['All Records', 'Pending', 'Verified', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _scansFuture = _apiService.fetchScans();

    if (widget.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(widget.successMessage!),
              ],
            ),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _scansFuture = _apiService.fetchScans();
    });
  }

  List<dynamic> _applyFilters(List<dynamic> scans) {
    var result = scans;

    // Apply status filter
    if (_selectedFilter != 'All Records') {
      result = result.where((s) {
        final status = (s['status'] as String? ?? '').toLowerCase();
        switch (_selectedFilter) {
          case 'Pending':
            return status == 'processing' || status == 'pending';
          case 'Verified':
            return status == 'completed' || status == 'verified';
          case 'Rejected':
            return status == 'rejected';
          default:
            return true;
        }
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((s) {
        final id = (s['id'] as String? ?? '').toLowerCase();
        final createdAt = (s['created_at'] as String? ?? '').toLowerCase();
        return id.contains(q) || createdAt.contains(q);
      }).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF4361EE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.feed_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            Text(
              'Clindex',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4361EE),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              // Focus the search bar in body
            },
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
            tooltip: 'Profile',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        color: const Color(0xFF4361EE),
        child: FutureBuilder<List<dynamic>>(
          future: _scansFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _buildError(theme, snapshot.error.toString());
            }

            final allScans = snapshot.data ?? [];
            final filtered = _applyFilters(allScans);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats cards row
                        Row(
                          children: [
                            Expanded(
                              child: _StatsCard(
                                title: 'Verified Records',
                                count: allScans
                                    .where((s) {
                                      final st = (s['status'] as String? ?? '').toLowerCase();
                                      return st == 'completed' || st == 'verified';
                                    })
                                    .length,
                                badge: '+12%',
                                badgeColor: const Color(0xFF22C55E),
                                icon: Icons.verified_rounded,
                                iconColor: const Color(0xFF22C55E),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatsCard(
                                title: 'Pending Review',
                                count: allScans
                                    .where((s) {
                                      final st = (s['status'] as String? ?? '').toLowerCase();
                                      return st == 'processing' || st == 'pending' || st == 'needs_review';
                                    })
                                    .length,
                                icon: Icons.pending_rounded,
                                iconColor: const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Search bar
                        TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Search patient name or ID...',
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Filter chips
                        SizedBox(
                          height: 36,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _filters.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final filter = _filters[i];
                              final selected = filter == _selectedFilter;
                              return FilterChip(
                                label: Text(
                                  filter,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : theme.colorScheme.onSurface,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                                selected: selected,
                                onSelected: (_) =>
                                    setState(() => _selectedFilter = filter),
                                showCheckmark: false,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmpty(theme),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _ScanTile(
                        scan: filtered[index],
                        apiService: _apiService,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScannerScreen()),
          );
        },
        child: const Icon(Icons.camera_alt_rounded),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'All Records'
                  ? 'No matching records'
                  : 'No documents yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'All Records'
                  ? 'Try adjusting your search or filter'
                  : 'Tap the camera button to capture\nyour first document',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded,
                size: 64, color: theme.colorScheme.error.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              'Could not load records',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final int count;
  final String? badge;
  final Color? badgeColor;
  final IconData icon;
  final Color iconColor;

  const _StatsCard({
    required this.title,
    required this.count,
    this.badge,
    this.badgeColor,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                if (badge != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? iconColor).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeColor ?? iconColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '$count',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanTile extends StatefulWidget {
  final Map<String, dynamic> scan;
  final ApiService apiService;

  const _ScanTile({required this.scan, required this.apiService});

  @override
  State<_ScanTile> createState() => _ScanTileState();
}

class _ScanTileState extends State<_ScanTile> {
  bool _loading = false;

  Future<void> _openReview() async {
    final scanId = widget.scan['id'] as String? ?? '';
    if (scanId.isEmpty) return;

    setState(() => _loading = true);
    try {
      final full = await widget.apiService.fetchScan(scanId);
      if (!mounted) return;
      final data = full['raw_ai_response'] as Map<String, dynamic>? ?? {};
      final imageUrl = full['image_url'] as String? ?? '';
      final refreshNeeded = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewScreen(
            scanData: data,
            imageUrl: imageUrl,
            scanId: scanId,
            scanMeta: widget.scan,
            apiService: widget.apiService,
          ),
        ),
      );
      if (refreshNeeded == true && context.mounted) {
        // Bubble refresh signal up to HomeScreen
        final homeState =
            context.findAncestorStateOfType<_HomeScreenState>();
        homeState?._refresh();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load scan: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'verified':
        return const Color(0xFF22C55E);
      case 'processing':
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'needs_review':
        return const Color(0xFF3B82F6);
      case 'rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'verified':
        return 'Verified';
      case 'processing':
        return 'Processing';
      case 'pending':
        return 'Pending';
      case 'needs_review':
        return 'Needs Review';
      case 'rejected':
        return 'Rejected';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = widget.scan['image_url'] as String? ?? '';
    final createdAt = widget.scan['created_at'] as String?;
    final status = widget.scan['status'] as String? ?? 'unknown';
    final scanId = widget.scan['id'] as String? ?? '';
    final records = widget.scan['record_count'] as int?;

    final dateLabel = _formatDate(createdAt) ?? scanId.substring(0, 8);
    final timeLabel = _formatTime(createdAt);
    final statusColor = _statusColor(status);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _loading ? null : _openReview,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail with JPG badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _thumbPlaceholder(theme),
                            )
                          : _thumbPlaceholder(theme),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'JPG',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Info section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan ${scanId.substring(0, scanId.length > 8 ? 8 : scanId.length).toUpperCase()}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      timeLabel != null
                          ? '$dateLabel · $timeLabel'
                          : dateLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Right side: record count + more icon
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF4361EE),
                      ),
                    )
                  else
                    Icon(
                      Icons.more_vert_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  if (records != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$records/$records Verified',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceVariant,
      child: Icon(
        Icons.description_rounded,
        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
      ),
    );
  }

  String? _formatDate(String? iso) {
    if (iso == null) return null;
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return null;
    }
  }

  String? _formatTime(String? iso) {
    if (iso == null) return null;
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return null;
    }
  }
}
