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
/// macOS-styled modal sheets with live contents (Guestbook, Terminal, Snake,
/// Experiences, Skills), and quick links to professional profiles.
class MobileFallbackPage extends StatefulWidget {
  const MobileFallbackPage({super.key});

  @override
  State<MobileFallbackPage> createState() => _MobileFallbackPageState();
}

class _MobileFallbackPageState extends State<MobileFallbackPage> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  SoundService? _sound;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
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
    Navigator.of(context).push<void>(
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
            child: FadeTransition(
              opacity: curved,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
      ),
    ).then((_) {
      _playSound((s) => s.playWindowClose());
    });
  }

  void _openSheet(
    BuildContext context, {
    required String title,
    required Color accent,
    required Widget child,
  }) => _openApp(context, title: title, accent: accent, child: child);

  @override
  Widget build(BuildContext context) {
    AppLocalizations? l10n;
    try {
      l10n = AppLocalizations.of(context);
    } catch (_) {}

    final experiences = l10n != null
        ? ExperienceMapper.fromL10n(l10n.experiences)
        : <Experience>[];

    final hourStr = _now.hour.toString().padLeft(2, '0');
    final minStr = _now.minute.toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Status Bar ─────────────────────────────────────────
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(bottom: BorderSide(color: AppTheme.surface0, width: 1)),
              ),
              child: Row(
                children: [
                  Text(
                    '$hourStr:$minStr',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 9,
                      color: AppTheme.text,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Sound Toggle
                  GestureDetector(
                    onTap: () {
                      final s = _sound ?? SoundService();
                      s.toggleMute();
                      setState(() => _muted = s.isMuted);
                      if (!_muted) s.playClick();
                    },
                    child: Icon(
                      _muted ? Icons.volume_off : Icons.volume_up,
                      size: 15,
                      color: _muted ? AppTheme.subtext : AppTheme.green,
                    ),
                  ),
                  const Spacer(),
                  // Language Picker
                  _buildLanguagePicker(),
                  const SizedBox(width: 10),
                  const Icon(Icons.wifi, size: 14, color: AppTheme.teal),
                  const SizedBox(width: 6),
                  Text(
                    '82%',
                    style: GoogleFonts.spaceMono(fontSize: 10, color: AppTheme.subtext),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.battery_5_bar, size: 16, color: AppTheme.green),
                ],
              ),
            ),

            // ── Main Scrollable Body ──────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Header Card
                    _buildProfileCard(l10n),
                    const SizedBox(height: 20),

                    // Section Title
                    Row(
                      children: [
                        const Icon(Icons.grid_view_rounded, size: 14, color: AppTheme.mauve),
                        const SizedBox(width: 8),
                        Text(
                          'POCKET APPS',
                          style: GoogleFonts.pressStart2p(
                            fontSize: 10,
                            color: AppTheme.mauve,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Pocket Apps Grid
                    _buildAppGrid(context, l10n, experiences),
                    const SizedBox(height: 24),

                    // Quick Links Dock Bar
                    _buildQuickDock(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagePicker() {
    String currentCode = 'en';
    try {
      currentCode = AppDependencies.of(context).localeViewModel.currentCode;
    } catch (_) {}

    return PopupMenuButton<String>(
      color: AppTheme.surface,
      offset: const Offset(0, 24),
      padding: EdgeInsets.zero,
      onSelected: (code) {
        _playSound((s) => s.playClick());
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
      itemBuilder: (ctx) => _kMobileLanguages.map((lang) {
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
                  color: lang.$1 == currentCode ? AppTheme.blue : AppTheme.text,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProfileCard(AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
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
                      'Mobile Software Engineer',
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
                'São Paulo, SP — Brazil',
                style: GoogleFonts.spaceMono(fontSize: 11, color: AppTheme.subtext),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _launch(AppStrings.urlGitHub),
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

  Widget _buildAppGrid(
    BuildContext context,
    AppLocalizations? l10n,
    List<Experience> experiences,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.45,
      children: [
        _buildAppCard(
          title: 'ABOUT',
          subtitle: 'Bio & Education',
          accent: AppTheme.blue,
          iconSvg: AppSvgs.person,
          onTap: () {
            _openSheet(
              context,
              title: 'ABOUT ME',
              accent: AppTheme.blue,
              child: AboutWindowContent(
                bio: l10n?.bio ?? '',
                role: l10n?.role ?? 'Software Engineer',
              ),
            );
          },
        ),
        _buildAppCard(
          title: 'EXPERIENCE',
          subtitle: 'Career Timeline',
          accent: AppTheme.peach,
          iconSvg: AppSvgs.kotlin,
          onTap: () {
            _openSheet(
              context,
              title: 'EXPERIENCE',
              accent: AppTheme.peach,
              child: _buildExperienceList(experiences),
            );
          },
        ),
        _buildAppCard(
          title: 'SKILLS',
          subtitle: 'Stack & Tools',
          accent: AppTheme.mauve,
          iconSvg: AppSvgs.skills,
          onTap: () {
            _openSheet(
              context,
              title: 'TECHNICAL SKILLS',
              accent: AppTheme.mauve,
              child: const SkillsWindowContent(),
            );
          },
        ),
        _buildAppCard(
          title: 'PROJECTS',
          subtitle: 'Open Source',
          accent: AppTheme.teal,
          iconSvg: AppSvgs.file,
          onTap: () {
            _openSheet(
              context,
              title: 'PROJECTS',
              accent: AppTheme.teal,
              child: _buildProjectsList(),
            );
          },
        ),
        _buildAppCard(
          title: 'GUESTBOOK',
          subtitle: 'Leave a Note',
          accent: AppTheme.mauve,
          iconSvg: AppSvgs.guestbook,
          onTap: () {
            GuestbookViewModel? vm;
            try {
              vm = AppDependencies.of(context).guestbookViewModel;
            } catch (_) {}
            if (vm != null) {
              _openSheet(
                context,
                title: 'GUESTBOOK',
                accent: AppTheme.mauve,
                child: GuestbookContent(viewModel: vm),
              );
            }
          },
        ),
        _buildAppCard(
          title: 'TERMINAL',
          subtitle: 'Interactive Shell',
          accent: AppTheme.green,
          iconSvg: AppSvgs.terminal,
          onTap: () {
            _openSheet(
              context,
              title: 'TERMINAL',
              accent: AppTheme.green,
              child: const TerminalContent(),
            );
          },
        ),
        _buildAppCard(
          title: 'SNAKE',
          subtitle: 'Retro Arcade',
          accent: AppTheme.yellow,
          iconSvg: AppSvgs.game,
          onTap: () {
            _openSheet(
              context,
              title: 'SNAKE GAME',
              accent: AppTheme.yellow,
              child: const SnakeGameContent(showDpad: true),
            );
          },
        ),
        _buildAppCard(
          title: 'CALC',
          subtitle: 'Calculator',
          accent: AppTheme.peach,
          iconSvg: AppSvgs.calculator,
          onTap: () {
            _openSheet(
              context,
              title: 'CALCULATOR',
              accent: AppTheme.peach,
              child: const CalculatorContent(),
            );
          },
        ),
        _buildAppCard(
          title: 'METRICS',
          subtitle: 'CI & 100% Tests',
          accent: AppTheme.teal,
          iconSvg: AppSvgs.projectStats,
          onTap: () {
            _openSheet(
              context,
              title: 'METRICS & CI',
              accent: AppTheme.teal,
              child: const ProjectStatsWindowContent(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppCard({
    required String title,
    required String subtitle,
    required Color accent,
    required String iconSvg,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        _playSound((s) => s.playClick());
        onTap();
      },
      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
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
                  style: GoogleFonts.pressStart2p(
                    fontSize: 8.5,
                    color: accent,
                  ),
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

  Widget _buildExperienceList(List<Experience> experiences) {
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
          child: ExperienceWindowContent(
            experience: exp,
            accentColor: color,
          ),
        );
      },
    );
  }

  Widget _buildProjectsList() {
    final projects = [
      (
        'intercepted_http',
        'Composable HTTP interceptor layer for Dart / Flutter — token refresh, auth, and retry without replacing client.',
        'https://github.com/Mathvdias/intercepted_http',
        'https://pub.dev/packages/intercepted_http',
        AppTheme.teal,
      ),
      (
        'homelab-infrastructure',
        'IaC & SRE automation for bare-metal homelab: Docker microservices, Linux BBR TCP kernel tuning, Cloudflare R2.',
        'https://github.com/Mathvdias/homelab-infrastructure',
        null,
        AppTheme.blue,
      ),
      (
        'liturgical-calendar-engine',
        'High-performance traditional Roman Rite liturgical calendar computation engine in Go.',
        'https://github.com/cm-manaus/liturgical-calendar-engine',
        null,
        AppTheme.peach,
      ),
      (
        'flutter_lazy_load_web',
        'A Flutter package for intelligent on-demand deferred chunk loading on Flutter Web.',
        'https://github.com/Mathvdias/flutter_lazy_load_web',
        'https://pub.dev/packages/flutter_lazy_load_web',
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
                style: GoogleFonts.pressStart2p(
                  fontSize: 10,
                  color: p.$5,
                ),
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
                    onPressed: () => _launch(p.$3),
                    icon: const Icon(Icons.code, size: 14),
                    label: Text(
                      'GitHub',
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
                      onPressed: () => _launch(p.$4!),
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: Text(
                        'pub.dev',
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

  Widget _buildQuickDock() {
    final links = [
      ('GitHub', AppSvgs.github, AppStrings.urlGitHub, AppTheme.blue),
      ('LinkedIn', AppSvgs.linkedin, AppStrings.urlLinkedIn, AppTheme.teal),
      ('Medium', AppSvgs.medium, AppStrings.urlMedium, AppTheme.peach),
      ('pub.dev', AppSvgs.pubDev, AppStrings.urlPubDev, AppTheme.blue),
      ('Resume', AppSvgs.pdf, AppStrings.urlResume, AppTheme.yellow),
      ('Email', AppSvgs.email, AppStrings.emailAddress, AppTheme.mauve),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppTheme.surface0, width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: links.map((link) {
          return GestureDetector(
            onTap: () {
              _playSound((s) => s.playClick());
              _launch(link.$3);
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
                        child: Icon(Icons.close, size: 13, color: AppTheme.background),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                            'ESC',
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
                data: Theme.of(context).copyWith(
                  scaffoldBackgroundColor: AppTheme.background,
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
