import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

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
            width: AppSizes.stickyNoteSize,
            color: AppTheme.surface.withValues(alpha: 0.5),
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.spacingMd),
              children: [
                Text(
                  AppStrings.finderFavorites,
                  style: GoogleFonts.spaceMono(
                    fontSize: AppSizes.fontBase,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.subtext,
                  ),
                ),
                const SizedBox(height: AppSizes.spacingMd),
                const _SidebarItem(
                  icon: Icons.star,
                  label: AppStrings.finderRecents,
                  selected: true,
                ),
                const _SidebarItem(
                  icon: Icons.desktop_mac,
                  label: AppStrings.finderDesktop,
                ),
                const _SidebarItem(
                  icon: Icons.folder,
                  label: AppStrings.finderDocuments,
                ),
                const _SidebarItem(
                  icon: Icons.download,
                  label: AppStrings.finderDownloads,
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: AppTheme.surface0),
          // Main content
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSizes.spacingMd),
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
                      fontSize: AppSizes.fontXxl,
                    ),
                  ),
                  subtitle: Text(
                    item['desc'] as String,
                    style: GoogleFonts.spaceMono(
                      color: AppTheme.subtext,
                      fontSize: AppSizes.fontLg,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacingMd,
        vertical: AppSizes.spacingSm,
      ),
      decoration: BoxDecoration(
        color: selected ? AppTheme.surface0 : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppSizes.font2xl,
            color: selected ? AppTheme.blue : AppTheme.subtext,
          ),
          const SizedBox(width: AppSizes.spacingMd),
          Text(
            label,
            style: GoogleFonts.spaceMono(
              fontSize: AppSizes.fontLg,
              color: selected ? AppTheme.text : AppTheme.subtext,
            ),
          ),
        ],
      ),
    );
  }
}
