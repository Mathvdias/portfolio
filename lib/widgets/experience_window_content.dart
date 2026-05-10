import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/experience.dart';
import '../theme/app_theme.dart';

class ExperienceWindowContent extends StatelessWidget {
  const ExperienceWindowContent({
    super.key,
    required this.experience,
    this.accentColor = AppTheme.mauve,
  });

  final Experience experience;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              experience.company,
              style: GoogleFonts.pressStart2p(
                fontSize: 10,
                color: accentColor,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              experience.role,
              style: GoogleFonts.spaceMono(
                fontSize: 14,
                color: AppTheme.subtext,
                height: 1.6,
              ),
            ),
            Text(
              '▶ ${experience.period}',
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                color: AppTheme.overlay,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: AppTheme.surface0, thickness: 1),
            const SizedBox(height: 12),
            Text(
              experience.description,
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                color: AppTheme.text,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'TECH:',
              style: GoogleFonts.pressStart2p(
                fontSize: 7,
                color: AppTheme.subtext,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children:
                  experience.technologies.map((tech) {
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
        ),
      ),
    );
  }
}
