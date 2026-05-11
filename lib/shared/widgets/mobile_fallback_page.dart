import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../constants/app_strings.dart';
import '../constants/app_sizes.dart';

/// Full-screen fallback shown on mobile devices.
///
/// Extracted from `_buildMobileView()` in [DesktopPage] so the build
/// tree stays shallow and the widget gets its own [Element].
class MobileFallbackPage extends StatelessWidget {
  const MobileFallbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppStrings.mobileTitle,
              style: GoogleFonts.pressStart2p(
                fontSize: AppSizes.font2xl,
                color: AppTheme.blue,
                height: 1.8,
              ),
            ),
            const SizedBox(height: AppSizes.spacingXl),
            Text(
              AppStrings.mobileSubtitle,
              style: GoogleFonts.pressStart2p(
                fontSize: AppSizes.fontSm,
                color: AppTheme.subtext,
                height: 1.8,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.spacing4xl),
            TextButton(
              // coverage:ignore-start
              onPressed: () async {
                final uri = Uri.parse(AppStrings.urlGitHub);
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
              // coverage:ignore-end
              child: Text(
                AppStrings.mobileGitHubLink,
                style: GoogleFonts.spaceMono(
                  fontSize: AppSizes.fontXxl,
                  color: AppTheme.teal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
