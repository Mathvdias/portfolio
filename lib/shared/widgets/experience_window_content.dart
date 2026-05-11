import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/experience.dart';
import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

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
        padding: const EdgeInsets.all(AppSizes.spacing3xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              experience.company,
              style: GoogleFonts.pressStart2p(
                fontSize: AppSizes.fontBase,
                color: accentColor,
                height: 1.8,
              ),
            ),
            const SizedBox(height: AppSizes.spacingMd),
            Text(
              experience.role,
              style: GoogleFonts.spaceMono(
                fontSize: AppSizes.font2xl,
                color: AppTheme.subtext,
                height: 1.6,
              ),
            ),
            Text(
              '▶ ${experience.period}',
              style: GoogleFonts.spaceMono(
                fontSize: AppSizes.fontXl,
                color: AppTheme.overlay,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppSizes.spacingLg),
            const Divider(color: AppTheme.surface0, thickness: 1),
            const SizedBox(height: AppSizes.spacingLg),
            Text(
              experience.description,
              style: GoogleFonts.spaceMono(
                fontSize: AppSizes.fontXxl,
                color: AppTheme.text,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppSizes.spacingXl),
            Text(
              AppStrings.techLabel,
              style: GoogleFonts.pressStart2p(
                fontSize: AppSizes.fontXs,
                color: AppTheme.subtext,
              ),
            ),
            const SizedBox(height: AppSizes.spacingMd),
            Wrap(
              spacing: AppSizes.spacingSm,
              runSpacing: AppSizes.spacingSm,
              children:
                  experience.technologies.map((tech) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.spacingMd,
                        vertical: AppSizes.spacingXs,
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
