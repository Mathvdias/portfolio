import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'pixel_icon_painter.dart';

class SkillsWindowContent extends StatelessWidget {
  const SkillsWindowContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section('Mobile', [
              _Skill('Flutter', kFlutterPixels, AppTheme.blue, 0.95),
              _Skill('Android', kAndroidPixels, AppTheme.green, 0.85),
              _Skill('Dart', kDartPixels, AppTheme.teal, 0.95),
              _Skill('Kotlin', kKotlinPixels, AppTheme.mauve, 0.80),
            ]),
            const SizedBox(height: 20),
            _section('Backend & Tools', [
              _Skill('REST APIs', kLinkPixels, AppTheme.blue, 0.85),
              _Skill('Firebase', kPackagePixels, AppTheme.yellow, 0.75),
              _Skill('Git / CI', kGithubPixels, AppTheme.subtext, 0.90),
              _Skill('Fastlane', kTerminalPixels, AppTheme.peach, 0.70),
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
        const SizedBox(height: 12),
        ...skills.map(_buildRow),
      ],
    );
  }

  Widget _buildRow(_Skill s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CustomPaint(
              painter: PixelIconPainter(pixels: s.pixels, color: s.color),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              s.name,
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                color: AppTheme.text,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: _Bar(value: s.level, color: s.color)),
          const SizedBox(width: 8),
          Text(
            '${(s.level * 100).round()}%',
            style: GoogleFonts.spaceMono(fontSize: 11, color: s.color),
          ),
        ],
      ),
    );
  }
}

class _Skill {
  final String name;
  final List<List<int>> pixels;
  final Color color;
  final double level;
  const _Skill(this.name, this.pixels, this.color, this.level);
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
