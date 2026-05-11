import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';

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
        padding: const EdgeInsets.all(AppSizes.spacing3xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.pressStart2p(
                fontSize: AppSizes.fontBase,
                color: accentColor,
                height: 1.8,
              ),
            ),
            if (version != null) ...[
              Text(
                'v$version',
                style: GoogleFonts.spaceMono(
                  fontSize: AppSizes.fontXl,
                  color: AppTheme.subtext,
                  height: 1.6,
                ),
              ),
            ],
            const SizedBox(height: AppSizes.spacingLg),
            const Divider(color: AppTheme.surface0, thickness: 1),
            const SizedBox(height: AppSizes.spacingLg),
            Text(
              description,
              style: GoogleFonts.spaceMono(
                fontSize: AppSizes.fontXxl,
                color: AppTheme.text,
                height: 1.6,
              ),
            ),
            if (technologies.isNotEmpty) ...[
              const SizedBox(height: AppSizes.spacingXl),
              Wrap(
                spacing: AppSizes.spacingSm,
                runSpacing: AppSizes.spacingSm,
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
                            fontSize: AppSizes.fontXxs,
                            color: AppTheme.blue,
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
            const SizedBox(height: AppSizes.spacingXl),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => _launch(githubUrl),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accentColor,
                    side: BorderSide(color: accentColor, width: 1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacingLg,
                      vertical: AppSizes.spacingMd,
                    ),
                  ),
                  child: Text(
                    'GitHub',
                    style: GoogleFonts.pressStart2p(fontSize: AppSizes.fontXs),
                  ),
                ),
                if (pubDevUrl != null) ...[
                  const SizedBox(width: AppSizes.spacingMd),
                  OutlinedButton(
                    onPressed: () => _launch(pubDevUrl!),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accentColor,
                      side: BorderSide(color: accentColor, width: 1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.spacingLg,
                        vertical: AppSizes.spacingMd,
                      ),
                    ),
                    child: Text(
                      'pub.dev',
                      style: GoogleFonts.pressStart2p(fontSize: AppSizes.fontXs),
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
