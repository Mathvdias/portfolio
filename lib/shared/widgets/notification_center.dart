import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';
import '../../features/desktop/presentation/viewmodels/desktop_viewmodel.dart';

class NotificationCenter extends StatelessWidget {
  const NotificationCenter({super.key, required this.desktopVM});

  final DesktopViewModel desktopVM;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      width: AppSizes.notificationCenterWidth,
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.95),
        border: const Border(left: BorderSide(color: AppTheme.surface0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSizes.spacingXl),
            child: Text(
              l10n.notificationCenter,
              style: GoogleFonts.spaceMono(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.surface0),
          Expanded(
            child: desktopVM.notifications.isEmpty
                ? Center(
                    child: Text(
                      'No new notifications',
                      style: GoogleFonts.spaceMono(
                        color: AppTheme.subtext,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSizes.spacingLg),
                    itemCount: desktopVM.notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSizes.spacingMd),
                    itemBuilder: (context, index) {
                      final notif = desktopVM.notifications[index];
                      // Format time dynamically
                      final diff = DateTime.now().difference(notif.time);
                      final timeStr = diff.inMinutes < 60
                          ? '${diff.inMinutes}m ago'
                          : diff.inHours < 24
                              ? '${diff.inHours}h ago'
                              : '${diff.inDays}d ago';

                      return _NotificationItem(
                        title: notif.title,
                        message: notif.message,
                        time: timeStr,
                        icon: notif.icon,
                        color: notif.color,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.surface0.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizes.font3xl, color: color),
          const SizedBox(width: AppSizes.spacingLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceMono(
                        fontSize: AppSizes.fontXl,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text,
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.spaceMono(
                        fontSize: AppSizes.fontBase,
                        color: AppTheme.subtext,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.spacingXs),
                Text(
                  message,
                  style: GoogleFonts.spaceMono(
                    fontSize: AppSizes.fontLg,
                    color: AppTheme.subtext,
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
