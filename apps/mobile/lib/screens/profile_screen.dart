import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    final displayName = email.isNotEmpty
        ? email.split('@').first.replaceAll('.', ' ')
        : 'User';
    final formattedName = displayName
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar section
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4361EE).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 52,
                    color: Color(0xFF4361EE),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4361EE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Name and role
          Text(
            'Dr. $formattedName',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Clinic Admin',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),

          // Hospital chip
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4361EE).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF4361EE).withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_hospital_rounded,
                    size: 14,
                    color: Color(0xFF4361EE),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'General Hospital',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF4361EE),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // GENERAL SETTINGS section
          _SectionHeader(title: 'GENERAL SETTINGS', theme: theme),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.settings_rounded,
                  iconColor: const Color(0xFF4361EE),
                  title: 'Settings',
                  subtitle: 'App preferences and configuration',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  icon: Icons.help_outline_rounded,
                  iconColor: const Color(0xFF22C55E),
                  title: 'Help & Support',
                  subtitle: 'FAQs, contact support',
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  icon: Icons.shield_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Privacy & Security',
                  subtitle: 'Data privacy and security settings',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ACCOUNT section
          _SectionHeader(title: 'ACCOUNT', theme: theme),
          const SizedBox(height: 8),
          Card(
            child: _SettingsTile(
              icon: Icons.logout_rounded,
              iconColor: const Color(0xFFEF4444),
              title: 'Logout',
              subtitle: 'Sign out of your account',
              titleColor: const Color(0xFFEF4444),
              showChevron: false,
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text(
                        'Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                        ),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ApiService().signOut();
                }
              },
            ),
          ),
          const SizedBox(height: 32),

          // Footer version text
          Text(
            'Clindex v2.0.0',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Clinical Register Digitizer',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final ThemeData theme;

  const _SectionHeader({required this.title, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color? titleColor;
  final bool showChevron;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.titleColor,
    this.showChevron = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
