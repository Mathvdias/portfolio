import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_strings.dart';
import '../constants/app_sizes.dart';
import '../mappers/experience_mapper.dart';
import '../models/experience.dart';
import 'desktop_icon.dart';
import 'experience_window_content.dart';
import 'about_window_content.dart';
import 'finder_content.dart';
import 'skills_window_content.dart';
import 'terminal_content.dart';
import 'calculator_content.dart';
import 'snake_game_content.dart';
import 'contact_form_content.dart';
import 'project_window_content.dart';
import 'android_dev_window_content.dart';

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
        iconWidget: const Icon(Icons.person),
        color: AppTheme.blue,
        onTap: () => onOpenWindow(
          AppStrings.winAbout,
          l10n.about,
          AboutWindowContent(bio: l10n.bio, role: l10n.role),
          AppTheme.blue,
        ),
      ),
      DesktopIcon(
        label: AppStrings.iconFinder,
        iconWidget: const Icon(Icons.folder),
        color: AppTheme.red,
        onTap: () => onOpenWindow(
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
          iconWidget: ExperienceMapper.iconWidgetFor(exp.company),
          color: color,
          onTap: () => onOpenWindow(
            'exp_$i',
            shortName,
            ExperienceWindowContent(experience: exp, accentColor: color),
            color,
          ),
        );
      }),
      DesktopIcon(
        label: AppStrings.iconSkills,
        iconWidget: const Icon(Icons.star),
        color: AppTheme.blue,
        onTap: () => onOpenWindow(
          AppStrings.winSkills,
          AppStrings.titleSkills,
          const SkillsWindowContent(),
          AppTheme.blue,
        ),
      ),
      DesktopIcon(
        label: AppStrings.iconAndroid,
        iconWidget: const FaIcon(FontAwesomeIcons.android),
        color: AppTheme.green,
        onTap: () => onOpenWindow(
          AppStrings.winAndroid,
          AppStrings.titleAndroid,
          const AndroidDevWindowContent(),
          AppTheme.green,
        ),
      ),
      DesktopIcon(
        label: AppStrings.iconTerminal,
        iconWidget: const Icon(Icons.terminal),
        color: AppTheme.green,
        onTap: () => onOpenWindow(
          AppStrings.winTerminal,
          AppStrings.titleTerminal,
          const TerminalContent(),
          AppTheme.green,
        ),
      ),
      DesktopIcon(
        label: AppStrings.iconCalculator,
        iconWidget: const Icon(Icons.calculate),
        color: AppTheme.peach,
        onTap: () => onOpenWindow(
          AppStrings.winCalculator,
          AppStrings.titleCalculator,
          const CalculatorContent(),
          AppTheme.peach,
        ),
      ),
      DesktopIcon(
        label: AppStrings.iconSnake,
        iconWidget: const FaIcon(FontAwesomeIcons.gamepad),
        color: AppTheme.peach,
        onTap: () => onOpenWindow(
          AppStrings.winSnake,
          AppStrings.titleSnake,
          const SnakeGameContent(),
          AppTheme.peach,
        ),
      ),
      DesktopIcon(
        label: AppStrings.iconContact,
        iconWidget: const Icon(Icons.mail),
        color: AppTheme.teal,
        onTap: () => onOpenWindow(
          AppStrings.winContact,
          AppStrings.titleContact,
          const ContactFormContent(),
          AppTheme.teal,
        ),
      ),
      DesktopIcon(
        label: AppStrings.iconWhitepaper,
        iconWidget: const Icon(Icons.description),
        color: AppTheme.blue,
        onTap: () async {
          final uri = Uri.parse(AppStrings.urlWhitepaper);
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
      ),
      DesktopIcon(
        label: AppStrings.iconResume,
        iconWidget: const Icon(Icons.picture_as_pdf),
        color: AppTheme.red,
        onTap: () async {
          final uri = Uri.parse(AppStrings.urlResume);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
      ),
      DesktopIcon(
        label: AppStrings.iconInterceptedHttp,
        iconWidget: const Icon(Icons.security),
        color: AppTheme.blue,
        onTap: () => onOpenWindow(
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
