
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';

class AndroidDevWindowContent extends StatelessWidget {
  const AndroidDevWindowContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.background,
      padding: const EdgeInsets.all(AppSizes.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.android, color: AppTheme.green, size: 32),
              const SizedBox(width: AppSizes.spacingMd),
              Text(
                'Android Development',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingLg),
          _buildExpertiseSection(
            'Core Technologies',
            ['Kotlin', 'Jetpack Compose', 'Android SDK', 'Java'],
          ),
          const SizedBox(height: AppSizes.spacingMd),
          _buildExpertiseSection(
            'Architecture & Patterns',
            ['MVVM', 'Clean Architecture', 'Dagger/Hilt', 'Coroutines'],
          ),
          const SizedBox(height: AppSizes.spacingMd),
          _buildExpertiseSection(
            'Tools',
            ['Android Studio', 'Firebase', 'Gradle', 'JUnit/Espresso'],
          ),
        ],
      ),
    );
  }

  Widget _buildExpertiseSection(String title, List<String> skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceMono(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.green,
          ),
        ),
        const SizedBox(height: AppSizes.spacingXs),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills.map((skill) => _SkillBadge(label: skill)).toList(),
        ),
      ],
    );
  }
}

class _SkillBadge extends StatelessWidget {
  final String label;
  const _SkillBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.surface0),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceMono(fontSize: 12, color: AppTheme.text),
      ),
    );
  }
}
