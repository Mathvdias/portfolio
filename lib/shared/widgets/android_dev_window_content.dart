import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_sizes.dart';

class AndroidDevWindowContent extends StatelessWidget {
  const AndroidDevWindowContent({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Semantics(
                label: 'Android',
                child: const FaIcon(
                  FontAwesomeIcons.android,
                  color: AppTheme.green,
                  size: 48,
                ),
              ),
              const SizedBox(width: AppSizes.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.androidDev,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text,
                      ),
                    ),
                    Text(
                      l10n.androidDevSubtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.subtext,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingXl),
          Text(
            l10n.expertise,
            style: GoogleFonts.pressStart2p(
              fontSize: AppSizes.fontXs,
              color: AppTheme.green,
            ),
          ),
          const SizedBox(height: AppSizes.spacingMd),
          _ExpertiseSection(
            title: l10n.core,
            items: const [
              'Kotlin',
              'Jetpack Compose',
              'Coroutines',
              'Flow',
              'Dagger/Hilt',
            ],
          ),
          const SizedBox(height: AppSizes.spacingMd),
          _ExpertiseSection(
            title: l10n.tools,
            items: const [
              'Android Studio',
              'Firebase',
              'LeakCanary',
              'Bitrise',
              'ADB',
            ],
          ),
          const SizedBox(height: AppSizes.spacingMd),
          _ExpertiseSection(
            title: l10n.architecture,
            items: const [
              'MVVM',
              'MVI',
              'Clean Architecture',
              'Modularization',
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpertiseSection extends StatelessWidget {
  const _ExpertiseSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceMono(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.text,
          ),
        ),
        const SizedBox(height: AppSizes.spacingXs),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) => _TechChip(item)).toList(),
        ),
      ],
    );
  }
}

class _TechChip extends StatelessWidget {
  const _TechChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.green.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceMono(fontSize: 12, color: AppTheme.text),
      ),
    );
  }
}
