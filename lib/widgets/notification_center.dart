import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class NotificationCenter extends StatelessWidget {
  const NotificationCenter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.95),
        border: const Border(left: BorderSide(color: AppTheme.surface0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Notification Center',
              style: GoogleFonts.spaceMono(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.text,
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.surface0),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: const [
                _NotificationItem(
                  title: 'Daily Verse',
                  message:
                      'I can do all things through Christ who strengthens me. - Phil 4:13',
                  time: 'Now',
                  icon: Icons.book,
                  color: AppTheme.mauve,
                ),
                SizedBox(height: 8),
                _NotificationItem(
                  title: 'System',
                  message: 'Portfolio updated successfully.',
                  time: '2h ago',
                  icon: Icons.system_update_alt,
                  color: AppTheme.green,
                ),
                SizedBox(height: 8),
                _NotificationItem(
                  title: 'GitHub',
                  message: 'New commit pushed to intercepted_http.',
                  time: '1d ago',
                  icon: Icons.code,
                  color: AppTheme.teal,
                ),
              ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface0.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 12),
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
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text,
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        color: AppTheme.subtext,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: GoogleFonts.spaceMono(
                    fontSize: 11,
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
