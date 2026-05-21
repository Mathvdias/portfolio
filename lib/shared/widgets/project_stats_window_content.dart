import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/project_stats.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
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
