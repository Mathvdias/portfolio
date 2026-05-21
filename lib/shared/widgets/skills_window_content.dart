import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_svgs.dart';
import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

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
                _Skill('Flutter', AppSvgs.flutter, AppTheme.blue, 0.95),
                _Skill('Android', AppSvgs.android, AppTheme.green, 0.85),
                _Skill('Dart', AppSvgs.dart, AppTheme.teal, 0.95),
                _Skill('Kotlin', AppSvgs.kotlin, AppTheme.mauve, 0.80),
              ],
            ),
            SizedBox(height: AppSizes.spacingXxl),
            _SkillSection(
              title: AppStrings.skillsBackend,
              skills: [
                _Skill('REST APIs', AppSvgs.api, AppTheme.blue, 0.85),
                _Skill('Firebase', AppSvgs.firebase, AppTheme.yellow, 0.75),
                _Skill('Git / CI', AppSvgs.github, AppTheme.subtext, 0.90),
                _Skill('Fastlane', AppSvgs.fastlane, AppTheme.peach, 0.70),
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
  final String iconAsset;
  final Color color;
  final double level;
  const _Skill(this.name, this.iconAsset, this.color, this.level);
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
            child: SvgPicture.asset(
              skill.iconAsset,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(skill.color, BlendMode.srcIn),
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
