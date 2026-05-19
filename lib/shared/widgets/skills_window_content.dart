import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../models/sdf_shape.dart';
import 'sdf_icon.dart';

class SkillsWindowContent extends StatelessWidget {
  const SkillsWindowContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(AppSizes.spacingXxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SkillSection(
              title: AppStrings.skillsMobile,
              skills: [
                _Skill('Flutter', SdfIcon(SdfShape.rocket, color: AppTheme.blue), AppTheme.blue, 0.95),
                _Skill('Android', SdfIcon(SdfShape.android, color: AppTheme.green), AppTheme.green, 0.85),
                _Skill('Dart', SdfIcon(SdfShape.code, color: AppTheme.teal), AppTheme.teal, 0.95),
                _Skill('Kotlin', SdfIcon(SdfShape.terminal, color: AppTheme.mauve), AppTheme.mauve, 0.80),
              ],
            ),
            SizedBox(height: AppSizes.spacingXxl),
            _SkillSection(
              title: AppStrings.skillsBackend,
              skills: [
                _Skill('REST APIs', SdfIcon(SdfShape.globe, color: AppTheme.blue), AppTheme.blue, 0.85),
                _Skill('Firebase', SdfIcon(SdfShape.fire, color: AppTheme.yellow), AppTheme.yellow, 0.75),
                _Skill('Git / CI', SdfIcon(SdfShape.github, color: AppTheme.subtext), AppTheme.subtext, 0.90),
                _Skill('Fastlane', SdfIcon(SdfShape.rocket, color: AppTheme.peach), AppTheme.peach, 0.70),
              ],
            ),
          ],
        ),
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

class _SkillSection extends StatelessWidget {
  const _SkillSection({required this.title, required this.skills});

  final String title;
  final List<_Skill> skills;

  @override
  Widget build(BuildContext context) {
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
        ...skills.map((s) => _SkillRow(skill: s)),
      ],
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.skill});

  final _Skill skill;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.font2xl),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: IconTheme(
              data: IconThemeData(color: skill.color, size: 24),
              child: skill.iconWidget,
            ),
          ),
          const SizedBox(width: AppSizes.spacingLg),
          SizedBox(
            width: 90,
            child: Text(
              skill.name,
              style: GoogleFonts.spaceMono(
                fontSize: AppSizes.fontXl,
                color: AppTheme.text,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: _Bar(value: skill.level, color: skill.color)),
          const SizedBox(width: AppSizes.spacingMd),
          Text(
            '${(skill.level * 100).round()}%',
            style: GoogleFonts.spaceMono(
              fontSize: AppSizes.fontLg,
              color: skill.color,
            ),
          ),
        ],
      ),
    );
  }
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
