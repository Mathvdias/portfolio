import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SkillsWindowContent extends StatelessWidget {
  const SkillsWindowContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacingXxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section(AppStrings.skillsMobile, [
              _Skill('Flutter', const Icon(Icons.flutter_dash), AppTheme.blue, 0.95),
              _Skill('Android', const FaIcon(FontAwesomeIcons.android), AppTheme.green, 0.85),
              _Skill('Dart', const Icon(Icons.code), AppTheme.teal, 0.95),
              _Skill('Kotlin', const Icon(Icons.integration_instructions), AppTheme.mauve, 0.80),
            ]),
            const SizedBox(height: AppSizes.spacingXxl),
            _section(AppStrings.skillsBackend, [
              _Skill('REST APIs', const Icon(Icons.api), AppTheme.blue, 0.85),
              _Skill('Firebase', const Icon(Icons.local_fire_department), AppTheme.yellow, 0.75),
              _Skill('Git / CI', const FaIcon(FontAwesomeIcons.github), AppTheme.subtext, 0.90),
              _Skill('Fastlane', const Icon(Icons.rocket_launch), AppTheme.peach, 0.70),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<_Skill> skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.pressStart2p(
            fontSize: 8,
            color: AppTheme.subtext,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: AppSizes.spacingLg),
        ...skills.map(_buildRow),
      ],
    );
  }

  Widget _buildRow(_Skill s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.font2xl),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: IconTheme(
              data: IconThemeData(color: s.color, size: 24),
              child: s.iconWidget,
            ),
          ),
          const SizedBox(width: AppSizes.spacingLg),
          SizedBox(
            width: 90,
            child: Text(
              s.name,
              style: GoogleFonts.spaceMono(
                fontSize: AppSizes.fontXl,
                color: AppTheme.text,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: _Bar(value: s.level, color: s.color)),
          const SizedBox(width: AppSizes.spacingMd),
          Text(
            '${(s.level * 100).round()}%',
            style: GoogleFonts.spaceMono(fontSize: AppSizes.fontLg, color: s.color),
          ),
        ],
      ),
    );
  }
}

class _Skill {
  final String name;
  final Widget iconWidget;
  final Color color;
  final double level;
  const _Skill(this.name, this.iconWidget, this.color, this.level);
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final total = constraints.maxWidth;
        return Stack(
          children: [
            Container(height: 8, color: AppTheme.surface0),
            Container(
              height: 8,
              width: total * value,
              color: color.withValues(alpha: 0.85),
            ),
          ],
        );
      },
    );
  }
}
