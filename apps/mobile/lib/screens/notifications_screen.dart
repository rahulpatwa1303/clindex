import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<_NotificationItem> _newItems = [
    _NotificationItem(
      icon: Icons.verified_rounded,
      iconColor: Color(0xFF22C55E),
      title: 'Scan Verified',
      body: 'Scan #A1B2C3D4 has been verified and saved successfully.',
      timestamp: '2 min ago',
      isUnread: true,
    ),
    _NotificationItem(
      icon: Icons.warning_amber_rounded,
      iconColor: Color(0xFFF59E0B),
      title: 'Low Confidence Detected',
      body: 'Scan #E5F6G7H8 has 3 records with low confidence scores. Please review.',
      timestamp: '15 min ago',
      isUnread: true,
    ),
    _NotificationItem(
      icon: Icons.auto_awesome_rounded,
      iconColor: Color(0xFF4361EE),
      title: 'AI Processing Complete',
      body: 'Scan #I9J0K1L2 has been processed. 12 records extracted.',
      timestamp: '1 hr ago',
      isUnread: true,
    ),
  ];

  final List<_NotificationItem> _earlierItems = [
    _NotificationItem(
      icon: Icons.cancel_rounded,
      iconColor: Color(0xFFEF4444),
      title: 'Scan Rejected',
      body: 'Scan #M3N4O5P6 was rejected. Reason: Illegible handwriting.',
      timestamp: 'Yesterday, 14:30',
      isUnread: false,
    ),
    _NotificationItem(
      icon: Icons.cloud_upload_rounded,
      iconColor: Color(0xFF3B82F6),
      title: 'Scan Uploaded',
      body: 'Scan #Q7R8S9T0 has been uploaded and is awaiting processing.',
      timestamp: 'Yesterday, 09:15',
      isUnread: false,
    ),
    _NotificationItem(
      icon: Icons.verified_rounded,
      iconColor: Color(0xFF22C55E),
      title: 'Scan Verified',
      body: 'Scan #U1V2W3X4 has been verified and saved successfully.',
      timestamp: '2 days ago',
      isUnread: false,
    ),
  ];

  void _markAllRead() {
    setState(() {
      for (final item in _newItems) {
        item.isUnread = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = _newItems.any((i) => i.isUnread);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _markAllRead,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4361EE),
              ),
              child: const Text(
                'Mark all as read',
                style: TextStyle(fontSize: 13),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // NEW section
          if (_newItems.isNotEmpty) ...[
            _SectionLabel(label: 'NEW', theme: theme),
            ..._newItems.map((item) => _NotificationTile(item: item)),
          ],

          // Divider
          const SizedBox(height: 4),
          const Divider(height: 1),
          const SizedBox(height: 4),

          // EARLIER section
          if (_earlierItems.isNotEmpty) ...[
            _SectionLabel(label: 'EARLIER', theme: theme),
            ..._earlierItems.map((item) => _NotificationTile(item: item)),
          ],
        ],
      ),
    );
  }
}

class _NotificationItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String timestamp;
  bool isUnread;

  _NotificationItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.isUnread,
  });
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _SectionLabel({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.8,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final _NotificationItem item;

  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {},
      child: Container(
        color: item.isUnread
            ? (isDark
                ? const Color(0xFF4361EE).withOpacity(0.06)
                : const Color(0xFF4361EE).withOpacity(0.04))
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored circle icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: item.iconColor.withOpacity(item.isUnread ? 0.15 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.icon,
                color: item.isUnread
                    ? item.iconColor
                    : item.iconColor.withOpacity(0.5),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: item.isUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: item.isUnread
                                ? null
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (item.isUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4361EE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'UNREAD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: item.isUnread
                          ? theme.colorScheme.onSurface.withOpacity(0.75)
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.timestamp,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
