import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

class LicensesWindowContent extends StatelessWidget {
  const LicensesWindowContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSizes.spacingXxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(AppStrings.licensesCustomPackages),
          SizedBox(height: AppSizes.spacingLg),
          _LicenseCard(
            name: 'app_window',
            version: '1.0.0',
            license: 'MIT',
            description:
                'Draggable, macOS-style app window widget with configurable '
                'traffic-light controls. Built in-house for this portfolio.',
          ),
          SizedBox(height: AppSizes.spacing3xl),
          _SectionHeader(AppStrings.licensesOpenSource),
          SizedBox(height: AppSizes.spacingLg),
          _LicenseCard(
            name: 'font_awesome_flutter',
            version: '^11.0.0',
            license: 'MIT',
            description:
                'The Font Awesome Icon pack available as set of Flutter Icons. '
                'Provides high quality vector graphics for the UI.',
            url: 'https://pub.dev/packages/font_awesome_flutter',
          ),
          _LicenseCard(
            name: 'Flutter',
            version: '3.x',
            license: 'BSD-3-Clause',
            description:
                'Google\'s UI toolkit for building natively compiled applications '
                'for mobile, web, and desktop from a single codebase.',
            url: 'https://flutter.dev',
          ),
          _LicenseCard(
            name: 'Dart',
            version: '3.x',
            license: 'BSD-3-Clause',
            description:
                'A client-optimized language for fast apps on any platform.',
            url: 'https://dart.dev',
          ),
          _LicenseCard(
            name: 'google_fonts',
            version: '^8.1.0',
            license: 'MIT',
            description:
                'Flutter package to use fonts from fonts.google.com. '
                'Used for Space Mono, Press Start 2P, and Indie Flower.',
            url: 'https://pub.dev/packages/google_fonts',
          ),
          _LicenseCard(
            name: 'firebase_core',
            version: '^4.7.0',
            license: 'BSD-3-Clause',
            description:
                'Firebase Core Flutter plugin. Required for Firebase initialization.',
            url: 'https://pub.dev/packages/firebase_core',
          ),
          _LicenseCard(
            name: 'cloud_firestore',
            version: '^6.3.0',
            license: 'BSD-3-Clause',
            description:
                'Flutter plugin for Cloud Firestore. Used to store and stream visitor counts.',
            url: 'https://pub.dev/packages/cloud_firestore',
          ),
          _LicenseCard(
            name: 'shared_preferences',
            version: '^2.5.5',
            license: 'BSD-3-Clause',
            description:
                'Flutter plugin for reading and writing simple key-value pairs. '
                'Used to prevent duplicate visitor counts.',
            url: 'https://pub.dev/packages/shared_preferences',
          ),
          _LicenseCard(
            name: 'url_launcher',
            version: '^6.1.14',
            license: 'BSD-3-Clause',
            description:
                'Flutter plugin for launching URLs in the mobile platform. '
                'Used to open GitHub, LinkedIn, and the résumé PDF.',
            url: 'https://pub.dev/packages/url_launcher',
          ),
          SizedBox(height: AppSizes.spacing3xl),
          Center(child: _CopyrightText()),
          SizedBox(height: AppSizes.spacingMd),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.pressStart2p(
        fontSize: AppSizes.fontXs,
        color: AppTheme.blue,
        letterSpacing: 1,
      ),
    );
  }
}

class _LicenseCard extends StatelessWidget {
  const _LicenseCard({
    required this.name,
    required this.version,
    required this.license,
    required this.description,
    this.url,
  });

  final String name;
  final String version;
  final String license;
  final String description;
  final String? url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingBase),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.surface0),
        ),
        padding: const EdgeInsets.all(AppSizes.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.spaceMono(
                      fontSize: AppSizes.fontXl,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                    ),
                  ),
                ),
                Text(
                  version,
                  style: GoogleFonts.spaceMono(
                    fontSize: AppSizes.fontBase,
                    color: AppTheme.subtext,
                  ),
                ),
                const SizedBox(width: AppSizes.spacingMd),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingSm,
                    vertical: AppSizes.spacingXxs,
                  ),
                  color: AppTheme.surface0,
                  child: Text(
                    license,
                    style: GoogleFonts.spaceMono(
                      fontSize: 9,
                      color: AppTheme.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacingSm),
            Text(
              description,
              style: GoogleFonts.spaceMono(
                fontSize: AppSizes.fontBase,
                color: AppTheme.subtext,
                height: 1.6,
              ),
            ),
            if (url != null) ...[
              const SizedBox(height: AppSizes.spacingSm),
              _UrlLink(url: url!),
            ],
          ],
        ),
      ),
    );
  }
}

class _UrlLink extends StatelessWidget {
  const _UrlLink({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text(
          url,
          style: GoogleFonts.spaceMono(
            fontSize: 9,
            color: AppTheme.blue,
            decoration: TextDecoration.underline,
            decorationColor: AppTheme.blue,
          ),
        ),
      ),
    );
  }
}

class _CopyrightText extends StatelessWidget {
  const _CopyrightText();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppStrings.licensesCopyright,
      style: GoogleFonts.spaceMono(
        fontSize: AppSizes.fontBase,
        color: AppTheme.subtext,
      ),
    );
  }
}
