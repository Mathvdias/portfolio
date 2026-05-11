import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class LicensesWindowContent extends StatelessWidget {
  const LicensesWindowContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('CUSTOM PACKAGES'),
          const SizedBox(height: 12),
          _licenseCard(
            name: 'app_window',
            version: '1.0.0',
            license: 'MIT',
            description:
                'Draggable, macOS-style app window widget with configurable '
                'traffic-light controls. Built in-house for this portfolio.',
            url: null,
          ),
          _licenseCard(
            name: 'pixel_art',
            version: '1.0.0',
            license: 'MIT',
            description:
                '16×16 pixel-art CustomPainter and 19 hand-crafted icon patterns. '
                'Built in-house for this portfolio.',
            url: null,
          ),
          const SizedBox(height: 24),
          _sectionHeader('OPEN SOURCE DEPENDENCIES'),
          const SizedBox(height: 12),
          _licenseCard(
            name: 'Flutter',
            version: '3.x',
            license: 'BSD-3-Clause',
            description:
                'Google\'s UI toolkit for building natively compiled applications '
                'for mobile, web, and desktop from a single codebase.',
            url: 'https://flutter.dev',
          ),
          _licenseCard(
            name: 'Dart',
            version: '3.x',
            license: 'BSD-3-Clause',
            description:
                'A client-optimized language for fast apps on any platform.',
            url: 'https://dart.dev',
          ),
          _licenseCard(
            name: 'google_fonts',
            version: '^8.1.0',
            license: 'MIT',
            description:
                'Flutter package to use fonts from fonts.google.com. '
                'Used for Space Mono, Press Start 2P, and Indie Flower.',
            url: 'https://pub.dev/packages/google_fonts',
          ),
          _licenseCard(
            name: 'firebase_core',
            version: '^4.7.0',
            license: 'BSD-3-Clause',
            description: 'Firebase Core Flutter plugin. Required for Firebase initialization.',
            url: 'https://pub.dev/packages/firebase_core',
          ),
          _licenseCard(
            name: 'cloud_firestore',
            version: '^6.3.0',
            license: 'BSD-3-Clause',
            description:
                'Flutter plugin for Cloud Firestore. Used to store and stream visitor counts.',
            url: 'https://pub.dev/packages/cloud_firestore',
          ),
          _licenseCard(
            name: 'shared_preferences',
            version: '^2.5.5',
            license: 'BSD-3-Clause',
            description:
                'Flutter plugin for reading and writing simple key-value pairs. '
                'Used to prevent duplicate visitor counts.',
            url: 'https://pub.dev/packages/shared_preferences',
          ),
          _licenseCard(
            name: 'url_launcher',
            version: '^6.1.14',
            license: 'BSD-3-Clause',
            description: 'Flutter plugin for launching URLs in the mobile platform. '
                'Used to open GitHub, LinkedIn, and the résumé PDF.',
            url: 'https://pub.dev/packages/url_launcher',
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '© 2026 Matheus Dias. MIT License.',
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: AppTheme.subtext,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.pressStart2p(
        fontSize: 7,
        color: AppTheme.blue,
        letterSpacing: 1,
      ),
    );
  }

  Widget _licenseCard({
    required String name,
    required String version,
    required String license,
    required String description,
    required String? url,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.surface0),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.spaceMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                    ),
                  ),
                ),
                Text(
                  version,
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    color: AppTheme.subtext,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            const SizedBox(height: 6),
            Text(
              description,
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: AppTheme.subtext,
                height: 1.6,
              ),
            ),
            if (url != null) ...[
              const SizedBox(height: 6),
              GestureDetector(
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
              ),
            ],
          ],
        ),
      ),
    );
  }
}
