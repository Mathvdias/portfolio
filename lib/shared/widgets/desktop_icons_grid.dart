import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/di/app_dependencies.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../constants/app_svgs.dart';
import '../mappers/experience_mapper.dart';
import '../models/experience.dart';
import 'about_window_content.dart';
import 'android_dev_window_content.dart';
import 'flutter_dev_window_content.dart';
import 'calculator_content.dart';
import 'contact_form_content.dart';
import 'desktop_icon.dart';
import 'experience_window_content.dart';
import 'finder_content.dart';
import 'project_window_content.dart';
import 'skills_window_content.dart';
import 'snake_game_content.dart';
import 'terminal_content.dart';

/// The right-aligned, vertically-wrapping grid of desktop icons.
class DesktopIconsGrid extends StatelessWidget {
  const DesktopIconsGrid({
    super.key,
    required this.experiences,
    required this.onOpenWindow,
  });

  final List<Experience> experiences;

  /// Called with `(id, title, content, accentColor)`.
  final void Function(String id, String title, Widget content, Color accent)
  onOpenWindow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final icons = <Widget>[
      DesktopIcon(
        label: l10n.about,
        iconAsset: AppSvgs.about,
        color: AppTheme.blue,
        onTap:
            () => onOpenWindow(
              AppStrings.winAbout,
              l10n.about,
              AboutWindowContent(bio: l10n.bio, role: l10n.role),
              AppTheme.blue,
            ),
      ),
      DesktopIcon(
        label: AppStrings.iconFinder,
        iconAsset: AppSvgs.finder,
        color: AppTheme.red,
        onTap:
            () => onOpenWindow(
              AppStrings.winFinder,
              AppStrings.titleFinder,
              const FinderContent(),
              AppTheme.red,
            ),
      ),
      ...experiences.asMap().entries.map((entry) {
        final i = entry.key;
        final exp = entry.value;
        final color = ExperienceMapper.colorFor(exp.company);
        final shortName = ExperienceMapper.shortNameFor(exp.company);
        return DesktopIcon(
          label: shortName,
          // SVG asset (active when the file is added to assets/icons/)
          iconAsset: ExperienceMapper.iconAssetFor(exp.company),
          // FontAwesome fallback while the SVG file is absent
          color: color,
          onTap:
              () => onOpenWindow(
                'exp_$i',
                shortName,
                ExperienceWindowContent(experience: exp, accentColor: color),
                color,
              ),
        );
      }),
      DesktopIcon(
        label: AppStrings.iconSkills,
        iconAsset: AppSvgs.skills,
        color: AppTheme.blue,
        onTap:
            () => onOpenWindow(
              AppStrings.winSkills,
              AppStrings.titleSkills,
              const SkillsWindowContent(),
              AppTheme.blue,
            ),
      ),
      DesktopIcon(
        label: AppStrings.iconAndroid,
        iconAsset: AppSvgs.android,
        color: AppTheme.green,
        onTap:
            () => onOpenWindow(
              AppStrings.winAndroid,
              AppStrings.titleAndroid,
              const AndroidDevWindowContent(),
              AppTheme.green,
            ),
      ),
      DesktopIcon(
        label: AppStrings.iconFlutter,
        iconAsset: AppSvgs.flutter,
        color: AppTheme.blue,
        onTap:
            () => onOpenWindow(
              AppStrings.winFlutter,
              AppStrings.titleFlutter,
              const FlutterDevWindowContent(),
              AppTheme.blue,
            ),
      ),
      DesktopIcon(
        label: AppStrings.iconTerminal,
        iconAsset: AppSvgs.terminal,
        color: AppTheme.green,
        onTap:
            () => onOpenWindow(
              AppStrings.winTerminal,
              AppStrings.titleTerminal,
              const TerminalContent(),
              AppTheme.green,
            ),
      ),
      DesktopIcon(
        label: AppStrings.iconCalculator,
        iconAsset: AppSvgs.calculator,
        color: AppTheme.peach,
        onTap:
            () => onOpenWindow(
              AppStrings.winCalculator,
              AppStrings.titleCalculator,
              const CalculatorContent(),
              AppTheme.peach,
            ),
      ),
      DesktopIcon(
        label: AppStrings.iconSnake,
        iconAsset: AppSvgs.snake,
        color: AppTheme.peach,
        onTap:
            () => onOpenWindow(
              AppStrings.winSnake,
              AppStrings.titleSnake,
              const SnakeGameContent(),
              AppTheme.peach,
            ),
      ),
      DesktopIcon(
        label: AppStrings.iconContact,
        iconAsset: AppSvgs.at,
        color: AppTheme.teal,
        onTap:
            () => onOpenWindow(
              AppStrings.winContact,
              AppStrings.titleContact,
              const ContactFormContent(),
              AppTheme.teal,
            ),
      ),
      DesktopIcon(
        label: AppStrings.iconWhitepaper,
        iconAsset: AppSvgs.whitepaper,
        color: AppTheme.blue,
        onTap: () async {
          unawaited(
            AppDependencies.of(context).analyticsService.logLinkClick(
              'whitepaper',
              AppStrings.urlWhitepaper,
            ),
          );
          final uri = Uri.parse(AppStrings.urlWhitepaper);
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
      ),
      DesktopIcon(
        label: AppStrings.iconResume,
        iconAsset: AppSvgs.resume,
        color: AppTheme.red,
        onTap: () async {
          unawaited(
            AppDependencies.of(context).analyticsService.logResumeDownload(),
          );
          final uri = Uri.parse(AppStrings.urlResume);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
      ),
      DesktopIcon(
        label: AppStrings.iconInterceptedHttp,
        iconAsset: AppSvgs.dart,
        color: AppTheme.blue,
        onTap:
            () => onOpenWindow(
              AppStrings.winInterceptedHttp,
              AppStrings.titleInterceptedHttp,
              const ProjectWindowContent(
                name: AppStrings.titleInterceptedHttp,
                description:
                    'A Flutter/Dart package that intercepts HTTP requests and responses, '
                    'allowing you to inspect, mock, and modify network traffic in your app. '
                    'Useful for debugging and testing.',
                githubUrl: AppStrings.urlGitHubIntercepted,
                pubDevUrl: AppStrings.urlPubDev,
                version: '0.2.1',
                technologies: ['Flutter', 'Dart', 'HTTP', 'Testing'],
                accentColor: AppTheme.teal,
              ),
              AppTheme.teal,
            ),
      ),
    ];

    return Container(
      alignment: Alignment.topRight,
      padding: const EdgeInsets.all(AppSizes.spacingMd),
      child: Wrap(
        direction: Axis.vertical,
        alignment: WrapAlignment.start,
        runAlignment: WrapAlignment.end,
        verticalDirection: VerticalDirection.down,
        textDirection: TextDirection.rtl,
        spacing: AppSizes.spacingSm,
        runSpacing: AppSizes.spacingSm,
        children: icons,
      ),
    );
  }
}
