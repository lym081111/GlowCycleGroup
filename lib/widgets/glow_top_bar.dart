import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../theme/app_colors.dart';

/// Persistent header with brand mark, shortcuts, and the profile menu.
class GlowTopBar extends StatelessWidget {
  const GlowTopBar({
    super.key,
    required this.user,
    required this.onSearch,
    required this.onNotifications,
    required this.onRecycleMap,
    required this.onSignOut,
  });

  final AppUser user;
  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final VoidCallback onRecycleMap;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
      decoration: BoxDecoration(
        color: surface.withValues(alpha: 0.94),
        border: Border(
          bottom: BorderSide(color: outlineVariant.withValues(alpha: 0.55)),
        ),
        boxShadow: [
          BoxShadow(
            color: ink.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [primaryContainer, secondaryContainer],
              ),
            ),
            child: const Icon(Icons.spa_outlined, color: primary, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'GlowCycle',
              style: TextStyle(
                color: primary,
                fontWeight: FontWeight.w900,
                fontSize: 24,
                letterSpacing: 0,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Search inventory',
            onPressed: onSearch,
            icon: const Icon(Icons.search, color: Color(0xFF424941)),
          ),
          IconButton(
            tooltip: 'Eco impact',
            onPressed: onNotifications,
            // Matches the star on the eco points banner: a bell suggested
            // notifications, which this button has never opened.
            icon: const Icon(Icons.auto_awesome, color: Color(0xFF424941)),
          ),
          IconButton(
            tooltip: 'Nearby recycling',
            onPressed: onRecycleMap,
            icon: const Icon(Icons.map_outlined, color: Color(0xFF424941)),
          ),
          PopupMenuButton<String>(
            tooltip: 'Profile',
            onSelected: (value) {
              if (value == 'logout') {
                onSignOut();
              }
            },
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: primaryContainer,
              child: Text(
                user.displayName.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Signed in as',
                      style: TextStyle(fontSize: 12, color: secondary),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
