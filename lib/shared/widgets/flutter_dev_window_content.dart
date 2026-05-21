import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:portifolio/core/constants/app_svgs.dart';

import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

class FlutterDevWindowContent extends StatelessWidget {
  const FlutterDevWindowContent({super.key}); // coverage:ignore-line

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Semantics(
                label: 'Flutter',
                child: SvgPicture.asset(
                  AppSvgs.flutter,
                  colorFilter: const ColorFilter.mode(
                    AppTheme.blue,
                    BlendMode.dstIn,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.titleFlutter,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.text,
                      ),
                    ),
                    Text(
                      AppStrings.flutterDevSubtitle,
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
            AppStrings.flutterExpertise,
            style: GoogleFonts.pressStart2p(
              fontSize: AppSizes.fontXs,
              color: AppTheme.blue,
            ),
          ),
          const SizedBox(height: AppSizes.spacingMd),
          const _ExpertiseSection(
            title: AppStrings.flutterSectionCore,
            items: [
              'Dart 3',
              'Flutter SDK',
              'BLoC',
              'MobX',
              'InheritedWidget',
              'Riverpod',
            ],
          ),
          const SizedBox(height: AppSizes.spacingMd),
          const _ExpertiseSection(
            title: AppStrings.flutterSectionTesting,
            items: [
              'Unit Tests',
              'Widget Tests',
              'Golden Tests',
              'Integration / E2E',
            ],
          ),
          const SizedBox(height: AppSizes.spacingMd),
          const _ExpertiseSection(
            title: AppStrings.flutterSectionArchitecture,
            items: [
              'MVVM',
              'Clean Architecture',
              'Modularization at Scale',
              'Data Structures',
              'Impeller / CanvasKit',
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
        border: Border.all(color: AppTheme.blue.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceMono(fontSize: 12, color: AppTheme.text),
      ),
    );
  }
}
