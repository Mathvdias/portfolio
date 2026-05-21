import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/project_stats.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';

class ProjectStatsWindowContent extends StatelessWidget {
  const ProjectStatsWindowContent({
    super.key,
    @visibleForTesting this.coverageOverride,
  });

  @visibleForTesting
  final double? coverageOverride;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final coverage = coverageOverride ?? ProjectStats.coverage;
    final color =
        coverage >= 80
            ? AppTheme.green
            : (coverage >= 60 ? AppTheme.yellow : AppTheme.red);

    return ColoredBox(
      color: AppTheme.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.spacingLg),
        child: Column(
          children: [
          Text(
            l10n.projectMetrics,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.text,
            ),
          ),
          const SizedBox(height: AppSizes.spacingLg),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: coverage / 100,
                  strokeWidth: 12,
                  backgroundColor: AppTheme.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                children: [
                  Text(
                    '${coverage.toStringAsFixed(1)}%',
                    style: GoogleFonts.spaceMono(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    l10n.coverageLabel,
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: AppTheme.subtext,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingLg),
          _StatRow(
            label: l10n.unitTests,
            value: ProjectStats.totalTests.toString(),
          ),
          _StatRow(label: l10n.codeQuality, value: 'A+'),
          _StatRow(label: l10n.buildStatus, value: l10n.passing),
          const SizedBox(height: AppSizes.spacingLg),
          const _TechStackSection(),
          const SizedBox(height: AppSizes.spacingXxl),
          const _TechQASection(),
          const SizedBox(height: AppSizes.spacingXxl),
          Text(
            l10n.keepBuilding,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceMono(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppTheme.subtext,
            ),
          ),
          const SizedBox(height: AppSizes.spacingMd),
        ],
      ),
    ),
  );
  }
}

class _TechStackSection extends StatelessWidget {
  const _TechStackSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TECH STACK',
          style: GoogleFonts.pressStart2p(
            fontSize: AppSizes.fontXs,
            color: AppTheme.yellow,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSizes.spacingMd),
        const _TechGroup(
          label: 'Runtime & Architecture',
          chips: [
            ('Architecture', 'MVVM 2.0'),
            ('State', 'InheritedWidget'),
            ('DI', 'InheritedWidget · Pure Dart'),
            ('Wallpaper', 'GLSL GPU Shader'),
            ('Web Render', 'CanvasKit / WebGL'),
            ('CI', 'GitHub Actions'),
          ],
        ),
        const SizedBox(height: AppSizes.spacingMd),
        const _TechGroup(
          label: 'Testing — 100% coverage',
          chips: [
            ('Unit Tests', '✓'),
            ('Widget Tests', '✓'),
            ('Golden Tests', '✓'),
            ('Integration / E2E', '✓'),
          ],
        ),
      ],
    );
  }
}

class _TechGroup extends StatelessWidget {
  const _TechGroup({required this.label, required this.chips});

  final String label;
  final List<(String, String)> chips;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceMono(
            fontSize: 10,
            color: AppTheme.subtext,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSizes.spacingSm),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children:
              chips
                  .map((c) => _StackChip(label: c.$1, value: c.$2))
                  .toList(),
        ),
      ],
    );
  }
}

class _StackChip extends StatelessWidget {
  const _StackChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.yellow.withValues(alpha: 0.3)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                color: AppTheme.subtext,
              ),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.yellow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TechQASection extends StatelessWidget {
  const _TechQASection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.techQAHeader,
          style: GoogleFonts.pressStart2p(
            fontSize: AppSizes.fontXs,
            color: AppTheme.teal,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSizes.spacingMd),
        _QACard(
          question: l10n.techQAQ1,
          points: [
            (l10n.techQAA1p1Title, l10n.techQAA1p1Body),
            (l10n.techQAA1p2Title, l10n.techQAA1p2Body),
            (l10n.techQAA1p3Title, l10n.techQAA1p3Body),
          ],
        ),
      ],
    );
  }
}

class _QACard extends StatelessWidget {
  const _QACard({required this.question, required this.points});

  final String question;
  final List<(String, String)> points;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.teal.withValues(alpha: 0.25)),
        ),
        child: Material(
          color: AppTheme.surface,
          child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingLg,
            vertical: AppSizes.spacingXs,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSizes.spacingLg,
            0,
            AppSizes.spacingLg,
            AppSizes.spacingLg,
          ),
          iconColor: AppTheme.teal,
          collapsedIconColor: AppTheme.subtext,
          title: Text(
            question,
            style: GoogleFonts.spaceMono(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.text,
              height: 1.5,
            ),
          ),
          children: [
            const Divider(color: AppTheme.surface0, height: 1),
            const SizedBox(height: AppSizes.spacingMd),
            ...points.map((p) => _QAPoint(title: p.$1, body: p.$2)),
          ],
        ),
      ),
    ),
    );
  }
}

class _QAPoint extends StatelessWidget {
  const _QAPoint({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spacingMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '▸ ',
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              color: AppTheme.teal,
              height: 1.6,
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title\n',
                    style: GoogleFonts.spaceMono(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.text,
                      height: 1.6,
                    ),
                  ),
                  TextSpan(
                    text: body,
                    style: GoogleFonts.spaceMono(
                      fontSize: 10,
                      color: AppTheme.subtext,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceMono(fontSize: 14, color: AppTheme.subtext),
          ),
          Text(
            value,
            style: GoogleFonts.spaceMono(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.text,
            ),
          ),
        ],
      ),
    );
  }
}
