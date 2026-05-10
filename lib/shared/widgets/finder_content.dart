import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

class FinderContent extends StatelessWidget {
  const FinderContent({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'name': 'About Me', 'icon': Icons.person, 'desc': 'Personal info'},
      {'name': 'Experiences', 'icon': Icons.work, 'desc': 'Work history'},
      {'name': 'Projects', 'icon': Icons.code, 'desc': 'My repositories'},
      {'name': 'Terminal', 'icon': Icons.terminal, 'desc': 'CLI view'},
      {
        'name': 'Snake Game',
        'icon': Icons.videogame_asset,
        'desc': 'Play a game',
      },
      {'name': 'Calculator', 'icon': Icons.calculate, 'desc': 'Math helper'},
      {'name': 'Contact', 'icon': Icons.email, 'desc': 'Reach out'},
    ];

    return Container(
      color: AppTheme.background,
      child: Row(
        children: [
          // Sidebar
          Container(
            width: 140,
            color: AppTheme.surface.withValues(alpha: 0.5),
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                Text(
                  'Favorites',
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.subtext,
                  ),
                ),
                const SizedBox(height: 8),
                const _SidebarItem(
                  icon: Icons.star,
                  label: 'Recents',
                  selected: true,
                ),
                const _SidebarItem(icon: Icons.desktop_mac, label: 'Desktop'),
                const _SidebarItem(icon: Icons.folder, label: 'Documents'),
                const _SidebarItem(icon: Icons.download, label: 'Downloads'),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: AppTheme.surface0),
          // Main content
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              separatorBuilder:
                  (_, __) => const Divider(color: AppTheme.surface0),
              itemBuilder: (context, i) {
                final item = items[i];
                return ListTile(
                  leading: Icon(item['icon'] as IconData, color: AppTheme.blue),
                  title: Text(
                    item['name'] as String,
                    style: GoogleFonts.spaceMono(
                      color: AppTheme.text,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    item['desc'] as String,
                    style: GoogleFonts.spaceMono(
                      color: AppTheme.subtext,
                      fontSize: 11,
                    ),
                  ),
                  onTap: () {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppTheme.surface0 : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: selected ? AppTheme.blue : AppTheme.subtext,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              color: selected ? AppTheme.text : AppTheme.subtext,
            ),
          ),
        ],
      ),
    );
  }
}
