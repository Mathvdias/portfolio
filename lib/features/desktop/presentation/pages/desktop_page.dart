import 'package:app_window/app_window.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixel_art/pixel_art.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/app_dependencies.dart';
import '../../../../features/desktop/presentation/viewmodels/desktop_viewmodel.dart';
import '../../../../features/visitors/presentation/viewmodels/visitor_viewmodel.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/models/experience.dart';
import '../../../../shared/widgets/about_window_content.dart';
import '../../../../shared/widgets/licenses_window_content.dart';
import '../../../../shared/widgets/calculator_content.dart';
import '../../../../shared/widgets/contact_form_content.dart';
import '../../../../shared/widgets/desktop_icon.dart';
import '../../../../shared/widgets/dock.dart';
import '../../../../shared/widgets/experience_window_content.dart';
import '../../../../shared/widgets/finder_content.dart';
import '../../../../shared/widgets/mac_menu_bar.dart';
import '../../../../shared/widgets/notification_center.dart';
import '../../../../shared/widgets/pixel_wallpaper.dart';
import '../../../../shared/widgets/project_window_content.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../../shared/widgets/skills_window_content.dart';
import '../../../../shared/widgets/snake_game_content.dart';
import '../../../../shared/widgets/sticky_note.dart';
import '../../../../shared/widgets/terminal_content.dart';
import '../../../../theme/app_theme.dart';

class DesktopPage extends StatefulWidget {
  const DesktopPage({super.key});

  @override
  State<DesktopPage> createState() => _DesktopPageState();
}

class _DesktopPageState extends State<DesktopPage> {
  late final DesktopViewModel _desktopVM;
  late VisitorViewModel _visitorVM;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _desktopVM = DesktopViewModel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final deps = AppDependencies.of(context);
      _visitorVM = VisitorViewModel(deps.visitorRepository)..init();
    }
  }

  @override
  void dispose() {
    _desktopVM.dispose();
    _visitorVM.dispose();
    super.dispose();
  }

  List<Experience> _buildExperiences(AppLocalizations l10n) {
    return l10n.experiences.map((e) {
      return Experience(
        company: e['company'] as String? ?? '',
        role: e['role'] as String? ?? '',
        period: e['period'] as String? ?? '',
        description: e['description'] as String? ?? '',
        technologies:
            (e['technologies'] as List<dynamic>?)?.cast<String>() ?? [],
      );
    }).toList();
  }

  Color _colorForCompany(String company) {
    if (company.contains('Zallpy')) return AppTheme.teal;
    if (company.contains('Banco') ||
        company.contains('PAN') ||
        company.contains('Pan')) {
      return AppTheme.blue;
    }
    if (company.contains('Conecthus')) return AppTheme.green;
    return AppTheme.peach;
  }

  List<List<int>> _pixelsForCompany(String company) {
    if (company.contains('Zallpy')) return kZallpyPixels;
    if (company.contains('Banco') ||
        company.contains('PAN') ||
        company.contains('Pan')) {
      return kBankPixels;
    }
    if (company.contains('Conecthus')) return kConecthusPixels;
    if (company.contains('Oi')) return kOiPixels;
    return kTerminalPixels;
  }

  String _shortNameFor(String company) {
    if (company.contains('Zallpy')) return 'Zallpy';
    if (company.contains('PAN') ||
        company.contains('Pan') ||
        company.contains('Banco')) {
      return 'Banco Pan';
    }
    if (company.contains('Conecthus')) return 'Conecthus';
    return company.split(' ').first;
  }

  Widget _buildIconsArea(AppLocalizations l10n, List<Experience> experiences) {
    final icons = <Widget>[
      DesktopIcon(
        label: l10n.about,
        pixels: kPersonPixels,
        color: AppTheme.blue,
        onTap: () => _desktopVM.openWindow(
          'about',
          l10n.about,
          AboutWindowContent(bio: l10n.bio, role: l10n.role),
          AppTheme.blue,
        ),
      ),
      DesktopIcon(
        label: 'Finder',
        pixels: kFinderPixels,
        color: AppTheme.red,
        onTap: () => _desktopVM.openWindow(
          'finder',
          'Finder',
          const FinderContent(),
          AppTheme.red,
        ),
      ),
      ...experiences.asMap().entries.map((entry) {
        final i = entry.key;
        final exp = entry.value;
        final color = _colorForCompany(exp.company);
        final pixels = _pixelsForCompany(exp.company);
        final shortName = _shortNameFor(exp.company);
        return DesktopIcon(
          label: shortName,
          pixels: pixels,
          color: color,
          onTap: () => _desktopVM.openWindow(
            'exp_$i',
            shortName,
            ExperienceWindowContent(experience: exp, accentColor: color),
            color,
          ),
        );
      }),
      DesktopIcon(
        label: 'Skills',
        pixels: kSkillsPixels,
        color: AppTheme.blue,
        onTap: () => _desktopVM.openWindow(
          'skills',
          'Skills',
          const SkillsWindowContent(),
          AppTheme.blue,
        ),
      ),
      DesktopIcon(
        label: 'Android',
        pixels: kAndroidPixels,
        color: AppTheme.green,
        onTap: () => _desktopVM.openWindow(
          'android',
          'Android Dev',
          const SkillsWindowContent(),
          AppTheme.green,
        ),
      ),
      DesktopIcon(
        label: 'Terminal',
        pixels: kTerminalPixels,
        color: AppTheme.green,
        onTap: () => _desktopVM.openWindow(
          'terminal',
          'Terminal',
          const TerminalContent(),
          AppTheme.green,
        ),
      ),
      DesktopIcon(
        label: 'Calculator',
        pixels: kCalculatorPixels,
        color: AppTheme.peach,
        onTap: () => _desktopVM.openWindow(
          'calculator',
          'Calculator',
          const CalculatorContent(),
          AppTheme.peach,
        ),
      ),
      DesktopIcon(
        label: 'Snake',
        pixels: kSnakePixels,
        color: AppTheme.peach,
        onTap: () => _desktopVM.openWindow(
          'snake',
          'Snake',
          const SnakeGameContent(),
          AppTheme.peach,
        ),
      ),
      DesktopIcon(
        label: 'Contact',
        pixels: kMailPixels,
        color: AppTheme.teal,
        onTap: () => _desktopVM.openWindow(
          'contact',
          'Contact',
          const ContactFormContent(),
          AppTheme.teal,
        ),
      ),
      DesktopIcon(
        label: 'Whitepaper',
        pixels: kMarianaPixels,
        color: AppTheme.blue,
        onTap: () async {
          final uri = Uri.parse('https://matheusdias.gitbook.io/tesouro');
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
      ),
      DesktopIcon(
        label: 'Resume',
        pixels: kLinkPixels,
        color: AppTheme.red,
        onTap: () async {
          final uri = Uri.parse('/resume.pdf');
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
      ),
      DesktopIcon(
        label: 'intercepted\n_http',
        pixels: kShieldPixels,
        color: AppTheme.blue,
        onTap: () => _desktopVM.openWindow(
          'intercepted_http',
          'intercepted_http',
          const ProjectWindowContent(
            name: 'intercepted_http',
            description:
                'A Flutter/Dart package that intercepts HTTP requests and responses, '
                'allowing you to inspect, mock, and modify network traffic in your app. '
                'Useful for debugging and testing.',
            githubUrl: 'https://github.com/Mathvdias/intercepted_http',
            pubDevUrl: 'https://pub.dev/packages/intercepted_http',
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
      padding: const EdgeInsets.only(top: 8, right: 8, bottom: 8, left: 8),
      child: Wrap(
        direction: Axis.vertical,
        alignment: WrapAlignment.start,
        runAlignment: WrapAlignment.end,
        verticalDirection: VerticalDirection.down,
        textDirection: TextDirection.rtl,
        spacing: 6.0,
        runSpacing: 6.0,
        children: icons,
      ),
    );
  }

  Widget _buildMobileView() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MATHEUS DIAS',
              style: GoogleFonts.pressStart2p(
                fontSize: 14,
                color: AppTheme.blue,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Portfolio\ndesigned\nfor desktop',
              style: GoogleFonts.pressStart2p(
                fontSize: 8,
                color: AppTheme.subtext,
                height: 1.8,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () async {
                final uri = Uri.parse('https://github.com/Mathvdias');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
              child: Text(
                'github.com/Mathvdias',
                style: GoogleFonts.spaceMono(fontSize: 13, color: AppTheme.teal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveLayout.isMobile(context)) return _buildMobileView();

    final l10n = AppLocalizations.of(context);
    final localeVM = AppDependencies.of(context).localeViewModel;
    final experiences = _buildExperiences(l10n);

    return ListenableBuilder(
      listenable: _desktopVM,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Stack(
            children: [
              const Positioned.fill(child: PixelWallpaper()),

              StickyNote(
                initialPosition: const Offset(40, 100),
                text: l10n.stickyNoteTodo,
                color: const Color(0xFFFDE68A),
              ),

              ListenableBuilder(
                listenable: _visitorVM,
                builder: (context, _) => VisitorStickyNote(
                  initialPosition: const Offset(40, 260),
                  color: const Color(0xFFBAE6FD),
                  visitorCount: _visitorVM.count,
                ),
              ),

              Positioned.fill(
                top: 28,
                bottom: 80,
                child: _buildIconsArea(l10n, experiences),
              ),

              ..._desktopVM.windows.map(
                (w) => AppWindow(
                  key: ValueKey(w.id),
                  title: w.title,
                  initialPosition: w.position,
                  accentColor: w.accentColor,
                  titleBarColor: AppTheme.surface,
                  contentColor: AppTheme.background,
                  borderColor: AppTheme.surface0,
                  closeColor: AppTheme.red,
                  minimizeColor: AppTheme.yellow,
                  maximizeColor: AppTheme.green,
                  onClose: () => _desktopVM.closeWindow(w.id),
                  onFocus: () => _desktopVM.focusWindow(w.id),
                  child: w.content,
                ),
              ),

              if (_desktopVM.showNotifications)
                const Positioned(
                  top: 28,
                  right: 0,
                  bottom: 0,
                  child: NotificationCenter(),
                ),

              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: MacMenuBar(
                  currentLanguage: localeVM.currentCode,
                  onLanguageChanged: localeVM.setLocaleByCode,
                  onToggleNotifications: _desktopVM.toggleNotifications,
                  onAppMenuAction: (action) async {
                    switch (action) {
                      case AppMenuAction.about:
                        _desktopVM.openWindow(
                          'about',
                          l10n.about,
                          AboutWindowContent(bio: l10n.bio, role: l10n.role),
                          AppTheme.blue,
                        );
                      case AppMenuAction.licenses:
                        _desktopVM.openWindow(
                          'licenses',
                          'Open Source Licenses',
                          const LicensesWindowContent(),
                          AppTheme.teal,
                        );
                      case AppMenuAction.github:
                        final uri = Uri.parse('https://github.com/Mathvdias');
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      case AppMenuAction.linkedin:
                        final uri = Uri.parse(
                          'https://linkedin.com/in/matheusvdias',
                        );
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                    }
                  },
                ),
              ),

              const Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Center(child: Dock()),
              ),
            ],
          ),
        );
      },
    );
  }
}
