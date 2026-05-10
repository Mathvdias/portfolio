import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

class ProjectWindowContent extends StatelessWidget {
  const ProjectWindowContent({
    super.key,
    required this.name,
    required this.description,
    required this.githubUrl,
    this.pubDevUrl,
    this.version,
    this.technologies = const [],
    this.accentColor = AppTheme.teal,
  });

  final String name;
  final String description;
  final String githubUrl;
  final String? pubDevUrl;
  final String? version;
  final List<String> technologies;
  final Color accentColor;

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.pressStart2p(
                fontSize: 10,
                color: accentColor,
                height: 1.8,
              ),
            ),
            if (version != null) ...[
              Text(
                'v$version',
                style: GoogleFonts.spaceMono(
                  fontSize: 12,
                  color: AppTheme.subtext,
                  height: 1.6,
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(color: AppTheme.surface0, thickness: 1),
            const SizedBox(height: 12),
            Text(
              description,
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                color: AppTheme.text,
                height: 1.6,
              ),
            ),
            if (technologies.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    technologies.map((tech) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppTheme.blue.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          tech,
                          style: GoogleFonts.pressStart2p(
                            fontSize: 6,
                            color: AppTheme.blue,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => _launch(githubUrl),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accentColor,
                    side: BorderSide(color: accentColor, width: 1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: Text(
                    'GitHub',
                    style: GoogleFonts.pressStart2p(fontSize: 7),
                  ),
                ),
                if (pubDevUrl != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _launch(pubDevUrl!),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accentColor,
                      side: BorderSide(color: accentColor, width: 1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      'pub.dev',
                      style: GoogleFonts.pressStart2p(fontSize: 7),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
