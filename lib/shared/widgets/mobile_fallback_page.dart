import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_svgs.dart';
import '../../core/di/app_dependencies.dart';
import '../../core/services/sound_service.dart';
import '../../features/guestbook/presentation/viewmodels/guestbook_viewmodel.dart';
import '../../features/guestbook/presentation/widgets/guestbook_content.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';
import '../mappers/experience_mapper.dart';
import '../models/experience.dart';
import 'about_window_content.dart';
import 'calculator_content.dart';
import 'experience_window_content.dart';
import 'pixel_wallpaper.dart';
import 'project_stats_window_content.dart';
import 'skills_window_content.dart';
import 'snake_game_content.dart';
import 'terminal_content.dart';

const _kMobileLanguages = [
  ('en', '🇺🇸', 'EN'),
  ('pt', '🇧🇷', 'PT'),
  ('es', '🇪🇸', 'ES'),
  ('fr', '🇫🇷', 'FR'),
  ('it', '🇮🇹', 'IT'),
];

/// A rich, responsive "MathOS Pocket Edition" shown on mobile devices.
///
/// Features a retro cyberdeck status bar, interactive app launcher grid,
/// animated cosmic wallpaper with parallax scroll, macOS-styled modal sheets
/// with live contents (Guestbook, Terminal, Snake, Experiences, Skills),
/// and quick links to professional profiles.
class MobileFallbackPage extends StatefulWidget {
  const MobileFallbackPage({super.key});

  @override
  State<MobileFallbackPage> createState() => _MobileFallbackPageState();
}

class _MobileFallbackPageState extends State<MobileFallbackPage> {
  late Timer _clockTimer;
  late final ScrollController _scrollController;
  DateTime _now = DateTime.now();
  SoundService? _sound;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      _sound = AppDependencies.of(context).soundService;
    } catch (_) {
      _sound = SoundService();
    }
    _muted = _sound?.isMuted ?? false;
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _playSound(void Function(SoundService) action) {
    final s = _sound ?? SoundService();
    action(s);
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openApp(
    BuildContext context, {
    required String title,
    required Color accent,
    required Widget child,
  }) {
    _playSound((s) => s.playWindowOpen());
    Navigator.of(context)
        .push<void>(
          PageRouteBuilder<void>(
            opaque: true,
            pageBuilder: (ctx, animation, secondaryAnimation) {
              return _MobileAppWindow(
                title: title,
                accent: accent,
                onClose: () => Navigator.of(ctx).pop(),
                child: child,
              );
            },
            transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              );
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(curved),
                child: FadeTransition(opacity: curved, child: child),
              );
            },
            transitionDuration: const Duration(milliseconds: 220),
            reverseTransitionDuration: const Duration(milliseconds: 180),
          ),
        )
        .then((_) {
          _playSound((s) => s.playWindowClose());
        });
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (_) {}

    final experiences =
        l10n != null
            ? ExperienceMapper.fromL10n(l10n.experiences)
            : <Experience>[];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // ── Parallax Cosmic Wallpaper ─────────────────────────────
          Positioned(
            top: -120,
            bottom: -400,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _scrollController,
              builder: (context, child) {
                final offset =
                    _scrollController.hasClients
                        ? _scrollController.offset
                        : 0.0;
                return Transform.translate(
                  offset: Offset(0, -offset * 0.3),
                  child: child,
                );
              },
              child: const RepaintBoundary(child: PixelWallpaper()),
            ),
          ),

          // ── Foreground Cyberdeck UI ───────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _MobileStatusBar(
                  now: _now,
                  sound: _sound,
                  muted: _muted,
                  onToggleMute: () {
                    final s = _sound ?? SoundService();
                    s.toggleMute();
                    setState(() => _muted = s.isMuted);
                    if (!_muted) s.playClick();
                  },
                  onPlaySound: _playSound,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _MobileProfileCard(onLaunch: _launch),
                        const SizedBox(height: 20),
                        const _PocketAppsHeader(),
                        const SizedBox(height: 12),
                        _MobileAppGrid(
                          l10n: l10n,
                          experiences: experiences,
                          onOpenApp: _openApp,
                          onPlaySound: _playSound,
                          onLaunch: _launch,
                        ),
                        const SizedBox(height: 24),
                        _MobileQuickDock(
                          onPlaySound: _playSound,
                          onLaunch: _launch,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileStatusBar extends StatelessWidget {
  const _MobileStatusBar({
    required this.now,
    required this.sound,
    required this.muted,
    required this.onToggleMute,
    required this.onPlaySound,
  });

  final DateTime now;
  final SoundService? sound;
  final bool muted;
  final VoidCallback onToggleMute;
  final void Function(void Function(SoundService)) onPlaySound;

  @override
  Widget build(BuildContext context) {
    final hourStr = now.hour.toString().padLeft(2, '0');
    final minStr = now.minute.toString().padLeft(2, '0');

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(color: AppTheme.surface0, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            '$hourStr:$minStr',
            style: GoogleFonts.pressStart2p(fontSize: 9, color: AppTheme.text),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onToggleMute,
            child: Icon(
              muted ? Icons.volume_off : Icons.volume_up,
              size: 15,
              color: muted ? AppTheme.subtext : AppTheme.green,
            ),
          ),
          const Spacer(),
          _MobileLanguagePicker(onPlaySound: onPlaySound),
          const SizedBox(width: 10),
          const Icon(Icons.wifi, size: 14, color: AppTheme.teal),
          const SizedBox(width: 6),
          Text(
            AppStrings.mobileBattery,
            style: GoogleFonts.spaceMono(fontSize: 10, color: AppTheme.subtext),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.battery_5_bar, size: 16, color: AppTheme.green),
        ],
      ),
    );
  }
}

class _MobileLanguagePicker extends StatelessWidget {
  const _MobileLanguagePicker({required this.onPlaySound});

  final void Function(void Function(SoundService)) onPlaySound;

  @override
  Widget build(BuildContext context) {
    String currentCode = 'en';
    try {
      currentCode = AppDependencies.of(context).localeViewModel.currentCode;
    } catch (_) {}

    return PopupMenuButton<String>(
      color: AppTheme.surface,
      offset: const Offset(0, 24),
      padding: EdgeInsets.zero,
      onSelected: (code) {
        onPlaySound((s) => s.playClick());
        try {
          AppDependencies.of(context).localeViewModel.setLocaleByCode(code);
        } catch (_) {}
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language, size: 13, color: AppTheme.blue),
          const SizedBox(width: 4),
          Text(
            currentCode.toUpperCase(),
            style: GoogleFonts.pressStart2p(
              fontSize: 8,
              color: AppTheme.subtext,
            ),
          ),
        ],
      ),
      itemBuilder:
          (ctx) =>
              _kMobileLanguages.map((lang) {
                return PopupMenuItem<String>(
                  value: lang.$1,
                  height: 32,
                  child: Row(
                    children: [
                      Text(lang.$2, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(
                        lang.$3,
                        style: GoogleFonts.spaceMono(
                          fontSize: 11,
                          color:
                              lang.$1 == currentCode
                                  ? AppTheme.blue
                                  : AppTheme.text,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
    );
  }
}

class _MobileProfileCard extends StatelessWidget {
  const _MobileProfileCard({required this.onLaunch});

  final Future<void> Function(String) onLaunch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppTheme.surface0, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.blue, width: 1.5),
                ),
                child: const Center(
                  child: Icon(Icons.terminal, color: AppTheme.blue, size: 26),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.mobileTitle,
                      style: GoogleFonts.pressStart2p(
                        fontSize: AppSizes.font2xl,
                        color: AppTheme.blue,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.mobileRole,
                      style: GoogleFonts.spaceMono(
                        fontSize: 12,
                        color: AppTheme.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.mobileSubtitle,
            style: GoogleFonts.pressStart2p(
              fontSize: AppSizes.fontSm,
              color: AppTheme.subtext,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on, size: 12, color: AppTheme.red),
              const SizedBox(width: 4),
              Text(
                AppStrings.mobileLocation,
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  color: AppTheme.subtext,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => onLaunch(AppStrings.urlGitHub),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              alignment: Alignment.centerLeft,
            ),
            child: Text(
              AppStrings.mobileGitHubLink,
              style: GoogleFonts.spaceMono(
                fontSize: AppSizes.fontXxl,
                color: AppTheme.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PocketAppsHeader extends StatelessWidget {
  const _PocketAppsHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.grid_view_rounded, size: 14, color: AppTheme.mauve),
        const SizedBox(width: 8),
        Text(
          AppStrings.mobilePocketApps,
          style: GoogleFonts.pressStart2p(
            fontSize: 10,
            color: AppTheme.mauve,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _MobileAppGrid extends StatelessWidget {
  const _MobileAppGrid({
    required this.l10n,
    required this.experiences,
    required this.onOpenApp,
    required this.onPlaySound,
    required this.onLaunch,
  });

  final AppLocalizations? l10n;
  final List<Experience> experiences;
  final void Function(
    BuildContext context, {
    required String title,
    required Color accent,
    required Widget child,
  })
  onOpenApp;
  final void Function(void Function(SoundService)) onPlaySound;
  final Future<void> Function(String) onLaunch;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: [
        _MobileAppCard(
          title: AppStrings.mobileAppAbout,
          subtitle: AppStrings.mobileAppAboutSubtitle,
          accent: AppTheme.blue,
          iconSvg: AppSvgs.person,
          onPlaySound: onPlaySound,
          onTap: () {
            onOpenApp(
              context,
              title: AppStrings.mobileAppAboutTitle,
              accent: AppTheme.blue,
              child: AboutWindowContent(
                bio: l10n?.bio ?? '',
                role: l10n?.role ?? AppStrings.mobileDefaultRole,
              ),
            );
          },
        ),
        _MobileAppCard(
          title: AppStrings.mobileAppExperience,
          subtitle: AppStrings.mobileAppExperienceSubtitle,
          accent: AppTheme.peach,
          iconSvg: AppSvgs.kotlin,
          onPlaySound: onPlaySound,
          onTap: () {
            onOpenApp(
              context,
              title: AppStrings.mobileAppExperienceTitle,
              accent: AppTheme.peach,
              child: _MobileExperienceList(experiences: experiences),
            );
          },
        ),
        _MobileAppCard(
          title: AppStrings.mobileAppSkills,
          subtitle: AppStrings.mobileAppSkillsSubtitle,
          accent: AppTheme.mauve,
          iconSvg: AppSvgs.skills,
          onPlaySound: onPlaySound,
          onTap: () {
            onOpenApp(
              context,
              title: AppStrings.mobileAppSkillsTitle,
              accent: AppTheme.mauve,
              child: const SkillsWindowContent(),
            );
          },
        ),
        _MobileAppCard(
          title: AppStrings.mobileAppProjects,
          subtitle: AppStrings.mobileAppProjectsSubtitle,
          accent: AppTheme.teal,
          iconSvg: AppSvgs.file,
          onPlaySound: onPlaySound,
          onTap: () {
            onOpenApp(
              context,
              title: AppStrings.mobileAppProjectsTitle,
              accent: AppTheme.teal,
              child: _MobileProjectsList(onLaunch: onLaunch),
            );
          },
        ),
        _MobileAppCard(
          title: AppStrings.mobileAppGuestbook,
          subtitle: AppStrings.mobileAppGuestbookSubtitle,
          accent: AppTheme.mauve,
          iconSvg: AppSvgs.guestbook,
          onPlaySound: onPlaySound,
          onTap: () {
            GuestbookViewModel? vm;
            try {
              vm = AppDependencies.of(context).guestbookViewModel;
            } catch (_) {}
            if (vm != null) {
              onOpenApp(
                context,
                title: AppStrings.mobileAppGuestbookTitle,
                accent: AppTheme.mauve,
                child: GuestbookContent(viewModel: vm),
              );
            }
          },
        ),
        _MobileAppCard(
          title: AppStrings.mobileAppTerminal,
          subtitle: AppStrings.mobileAppTerminalSubtitle,
          accent: AppTheme.green,
          iconSvg: AppSvgs.terminal,
          onPlaySound: onPlaySound,
          onTap: () {
            onOpenApp(
              context,
              title: AppStrings.mobileAppTerminalTitle,
              accent: AppTheme.green,
              child: const TerminalContent(),
            );
          },
        ),
        _MobileAppCard(
          title: AppStrings.mobileAppSnake,
          subtitle: AppStrings.mobileAppSnakeSubtitle,
          accent: AppTheme.yellow,
          iconSvg: AppSvgs.game,
          onPlaySound: onPlaySound,
          onTap: () {
            onOpenApp(
              context,
              title: AppStrings.mobileAppSnakeTitle,
              accent: AppTheme.yellow,
              child: const SnakeGameContent(showDpad: true),
            );
          },
        ),
        _MobileAppCard(
          title: AppStrings.mobileAppCalc,
          subtitle: AppStrings.mobileAppCalcSubtitle,
          accent: AppTheme.peach,
          iconSvg: AppSvgs.calculator,
          onPlaySound: onPlaySound,
          onTap: () {
            onOpenApp(
              context,
              title: AppStrings.mobileAppCalcTitle,
              accent: AppTheme.peach,
              child: const CalculatorContent(),
            );
          },
        ),
        _MobileAppCard(
          title: AppStrings.mobileAppMetrics,
          subtitle: AppStrings.mobileAppMetricsSubtitle,
          accent: AppTheme.teal,
          iconSvg: AppSvgs.projectStats,
          onPlaySound: onPlaySound,
          onTap: () {
            onOpenApp(
              context,
              title: AppStrings.mobileAppMetricsTitle,
              accent: AppTheme.teal,
              child: const ProjectStatsWindowContent(),
            );
          },
        ),
      ],
    );
  }
}

class _MobileAppCard extends StatelessWidget {
  const _MobileAppCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.iconSvg,
    required this.onTap,
    required this.onPlaySound,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final String iconSvg;
  final VoidCallback onTap;
  final void Function(void Function(SoundService)) onPlaySound;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onPlaySound((s) => s.playClick());
        onTap();
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppTheme.surface0, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SvgPicture.asset(
                  iconSvg,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
                ),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.pressStart2p(fontSize: 8.5, color: accent),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.spaceMono(
                    fontSize: 10,
                    color: AppTheme.subtext,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileExperienceList extends StatelessWidget {
  const _MobileExperienceList({required this.experiences});

  final List<Experience> experiences;

  @override
  Widget build(BuildContext context) {
    if (experiences.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: experiences.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, i) {
        final exp = experiences[i];
        final color = ExperienceMapper.colorFor(exp.company);
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: AppTheme.surface0),
          ),
          child: ExperienceWindowContent(experience: exp, accentColor: color),
        );
      },
    );
  }
}

class _MobileProjectsList extends StatelessWidget {
  const _MobileProjectsList({required this.onLaunch});

  final Future<void> Function(String) onLaunch;

  @override
  Widget build(BuildContext context) {
    final projects = [
      (
        AppStrings.projectInterceptedName,
        AppStrings.projectInterceptedDesc,
        AppStrings.urlGitHubIntercepted,
        AppStrings.urlPubDevIntercepted,
        AppTheme.teal,
      ),
      (
        AppStrings.projectHomelabName,
        AppStrings.projectHomelabDesc,
        AppStrings.urlGitHubHomelab,
        null,
        AppTheme.blue,
      ),
      (
        AppStrings.projectLiturgicalName,
        AppStrings.projectLiturgicalDesc,
        AppStrings.urlGitHubLiturgical,
        null,
        AppTheme.peach,
      ),
      (
        AppStrings.projectLazyLoadName,
        AppStrings.projectLazyLoadDesc,
        AppStrings.urlGitHubLazyLoad,
        AppStrings.urlPubDevLazyLoad,
        AppTheme.mauve,
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final p = projects[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(color: AppTheme.surface0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                p.$1,
                style: GoogleFonts.pressStart2p(fontSize: 10, color: p.$5),
              ),
              const SizedBox(height: 8),
              Text(
                p.$2,
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  color: AppTheme.text,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => onLaunch(p.$3),
                    icon: const Icon(Icons.code, size: 14),
                    label: Text(
                      AppStrings.projectBtnGitHub,
                      style: GoogleFonts.spaceMono(fontSize: 10),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surface0,
                      foregroundColor: AppTheme.blue,
                    ),
                  ),
                  if (p.$4 != null) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => onLaunch(p.$4!),
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: Text(
                        AppStrings.projectBtnPubDev,
                        style: GoogleFonts.spaceMono(fontSize: 10),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.surface0,
                        foregroundColor: AppTheme.teal,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MobileQuickDock extends StatelessWidget {
  const _MobileQuickDock({required this.onPlaySound, required this.onLaunch});

  final void Function(void Function(SoundService)) onPlaySound;
  final Future<void> Function(String) onLaunch;

  @override
  Widget build(BuildContext context) {
    final links = [
      (
        AppStrings.dockGitHub,
        AppSvgs.github,
        AppStrings.urlGitHub,
        AppTheme.blue,
      ),
      (
        AppStrings.dockLinkedIn,
        AppSvgs.linkedin,
        AppStrings.urlLinkedIn,
        AppTheme.teal,
      ),
      (
        AppStrings.dockMedium,
        AppSvgs.medium,
        AppStrings.urlMedium,
        AppTheme.peach,
      ),
      (
        AppStrings.dockPubDev,
        AppSvgs.pubDev,
        AppStrings.urlPubDev,
        AppTheme.blue,
      ),
      (
        AppStrings.dockResume,
        AppSvgs.pdf,
        AppStrings.urlResume,
        AppTheme.yellow,
      ),
      (
        AppStrings.dockEmail,
        AppSvgs.email,
        AppStrings.emailAddress,
        AppTheme.mauve,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppTheme.surface0, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children:
            links.map((link) {
              return GestureDetector(
                onTap: () {
                  onPlaySound((s) => s.playClick());
                  onLaunch(link.$3);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      link.$2,
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(link.$4, BlendMode.srcIn),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      link.$1,
                      style: GoogleFonts.spaceMono(
                        fontSize: 8.5,
                        color: AppTheme.subtext,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _MobileAppWindow extends StatelessWidget {
  const _MobileAppWindow({
    required this.title,
    required this.accent,
    required this.onClose,
    required this.child,
  });

  final String title;
  final Color accent;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Retro macOS full-width window header
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                color: AppTheme.surface0,
                border: Border(
                  bottom: BorderSide(color: AppTheme.surface, width: 1.5),
                ),
              ),
              child: Row(
                children: [
                  // Red close traffic light (prominent & touch-friendly)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onClose,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppTheme.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close,
                          size: 13,
                          color: AppTheme.background,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 13,
                    height: 13,
                    decoration: const BoxDecoration(
                      color: AppTheme.yellow,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 13,
                    height: 13,
                    decoration: const BoxDecoration(
                      color: AppTheme.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      title,
                      style: GoogleFonts.pressStart2p(
                        fontSize: 9.5,
                        color: accent,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  // Retro ESC / Back button
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onClose,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.surface0, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back, size: 11, color: accent),
                          const SizedBox(width: 4),
                          Text(
                            AppStrings.mobileEsc,
                            style: GoogleFonts.pressStart2p(
                              fontSize: 7.5,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Full screen window content
            Expanded(
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(scaffoldBackgroundColor: AppTheme.background),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
