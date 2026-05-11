import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

class AboutWindowContent extends StatelessWidget {
  const AboutWindowContent({super.key, required this.bio, required this.role});

  final String bio;
  final String role;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing3xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.aboutName,
              style: GoogleFonts.pressStart2p(
                fontSize: AppSizes.fontXl,
                color: AppTheme.blue,
                height: 1.8,
              ),
            ),
            const SizedBox(height: AppSizes.spacingMd),
            Text(
              role,
              style: GoogleFonts.pressStart2p(
                fontSize: AppSizes.fontSm,
                color: AppTheme.mauve,
                height: 1.8,
              ),
            ),
            const SizedBox(height: AppSizes.spacingXs),
            Text(
              AppStrings.aboutLocation,
              style: GoogleFonts.spaceMono(
                fontSize: AppSizes.fontXl,
                color: AppTheme.subtext,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppSizes.spacingXl),
            const Divider(color: AppTheme.surface0, thickness: 1),
            const SizedBox(height: AppSizes.spacingXl),
            Text(
              bio,
              style: GoogleFonts.spaceMono(
                fontSize: AppSizes.fontXxl,
                color: AppTheme.text,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppSizes.spacingXxl),
            Text(
              AppStrings.aboutEducation,
              style: GoogleFonts.pressStart2p(
                fontSize: AppSizes.fontXs,
                color: AppTheme.subtext,
              ),
            ),
            const SizedBox(height: AppSizes.spacingMd),
            Text(
              'Eng. Elétrica — UniNorte (2019–2023)',
              style: GoogleFonts.spaceMono(
                fontSize: AppSizes.fontXxl,
                color: AppTheme.text,
                height: 1.6,
              ),
            ),
            Text(
              'Téc. Eletrônica — IFAM (2014–2016)',
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                color: AppTheme.text,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppSizes.spacingXxl),
            Text(
              AppStrings.aboutInterests,
              style: GoogleFonts.pressStart2p(
                fontSize: AppSizes.fontXs,
                color: AppTheme.subtext,
              ),
            ),
            const SizedBox(height: AppSizes.spacingMd),
            Text(
              'Game engine (Jetpack Compose)',
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                color: AppTheme.text,
                height: 1.6,
              ),
            ),
            Text(
              'Home lab (Docker + Raspberry Pi)',
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                color: AppTheme.text,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
