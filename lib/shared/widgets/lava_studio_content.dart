import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lava_flutter/lava_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../constants/app_sizes.dart';
import '../constants/app_strings.dart';

/// Interactive showcase window for the `lava_flutter` package.
///
/// Demonstrates real-time 3D perspective matrix tilt, spring tactile compression,
/// frame scrubbing, variable speed playback, and hardware-accelerated tile blitting.
class LavaStudioContent extends StatefulWidget {
  const LavaStudioContent({super.key});

  @override
  State<LavaStudioContent> createState() => _LavaStudioContentState();
}

class _LavaStudioContentState extends State<LavaStudioContent>
    with SingleTickerProviderStateMixin {
  late final LavaController _controller;
  LavaDemoType _selectedType = LavaDemoType.macintosh;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = LavaController(
      totalFrames: 24,
      fps: 30,
      autoPlay: false,
      loop: true,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _selectModel(LavaDemoType type) {
    if (_selectedType == type) return;
    setState(() {
      _selectedType = type;
      // Frame count / fps come from the bundle manifest: LavaIcon reconfigures
      // the shared controller as soon as the new bundle is decoded.
      _controller.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spacing3xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            AppStrings.lavaStudioTitle,
            style: GoogleFonts.pressStart2p(
              fontSize: AppSizes.fontSm,
              color: AppTheme.peach,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSizes.spacingXs),
          Text(
            AppStrings.lavaStudioSubtitle,
            style: GoogleFonts.spaceMono(
              fontSize: AppSizes.fontSm,
              color: AppTheme.subtext,
            ),
          ),
          const SizedBox(height: AppSizes.spacingMd),

          // Tech Badges
          const Wrap(
            spacing: AppSizes.spacingSm,
            runSpacing: AppSizes.spacingSm,
            children: [
              _Badge(
                label: AppStrings.lavaStudioBadgeTile,
                color: AppTheme.blue,
              ),
              _Badge(
                label: AppStrings.lavaStudioBadgeAlpha,
                color: AppTheme.green,
              ),
              _Badge(
                label: AppStrings.lavaStudioBadgePerspective,
                color: AppTheme.peach,
              ),
              _Badge(
                label: AppStrings.lavaStudioBadgeZeroAlloc,
                color: AppTheme.teal,
              ),
              _Badge(
                label: AppStrings.lavaStudioBadgeWasm,
                color: AppTheme.mauve,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacingLg),
          const Divider(color: AppTheme.surface0, thickness: 1),
          const SizedBox(height: AppSizes.spacingLg),

          // Airbnb-Style Category Navigation Bar
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacingLg,
                  vertical: AppSizes.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  border: Border.all(color: AppTheme.surface0, width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _AirbnbCategoryTab(
                      label: AppStrings.lavaModelMacintosh,
                      demoType: LavaDemoType.macintosh,
                      isSelected: _selectedType == LavaDemoType.macintosh,
                      onTap: () => _selectModel(LavaDemoType.macintosh),
                    ),
                    const SizedBox(width: AppSizes.spacingLg),
                    _AirbnbCategoryTab(
                      label: AppStrings.lavaModelTree,
                      demoType: LavaDemoType.sunflower,
                      isSelected: _selectedType == LavaDemoType.sunflower,
                      onTap: () => _selectModel(LavaDemoType.sunflower),
                    ),
                    const SizedBox(width: AppSizes.spacingLg),
                    _AirbnbCategoryTab(
                      label: AppStrings.lavaModelLavaLamp,
                      demoType: LavaDemoType.lavaLamp,
                      isSelected:
                          _selectedType == LavaDemoType.lavaLamp,
                      onTap: () => _selectModel(LavaDemoType.lavaLamp),
                    ),
                    const SizedBox(width: AppSizes.spacingLg),
                    _AirbnbCategoryTab(
                      label: AppStrings.lavaModelCampfire,
                      demoType: LavaDemoType.campfire,
                      isSelected: _selectedType == LavaDemoType.campfire,
                      onTap: () => _selectModel(LavaDemoType.campfire),
                    ),
                    const SizedBox(width: AppSizes.spacingLg),
                    _AirbnbCategoryTab(
                      label: AppStrings.lavaModelRocket,
                      demoType: LavaDemoType.rocket,
                      isSelected: _selectedType == LavaDemoType.rocket,
                      onTap: () => _selectModel(LavaDemoType.rocket),
                    ),
                    const SizedBox(width: AppSizes.spacingLg),
                    _AirbnbCategoryTab(
                      label: AppStrings.lavaModelSenna,
                      demoType: LavaDemoType.senna,
                      isSelected: _selectedType == LavaDemoType.senna,
                      onTap: () => _selectModel(LavaDemoType.senna),
                    ),
                    const SizedBox(width: AppSizes.spacingLg),
                    _AirbnbCategoryTab(
                      label: AppStrings.lavaModelChristmasTree,
                      demoType: LavaDemoType.christmasTree,
                      isSelected: _selectedType == LavaDemoType.christmasTree,
                      onTap: () => _selectModel(LavaDemoType.christmasTree),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingXl),

          // Interactive Stage Box
          Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 440),
              padding: const EdgeInsets.symmetric(
                vertical: AppSizes.spacing3xl,
                horizontal: AppSizes.spacingLg,
              ),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: Border.all(color: AppTheme.surface0, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LavaIcon.demo(
                    demoType: _selectedType,
                    controller: _controller,
                    size: 140,
                    interactive: true,
                  ),
                  const SizedBox(height: AppSizes.spacingMd),
                  Text(
                    switch (_selectedType) {
                      LavaDemoType.macintosh => AppStrings.lavaModelMacintosh,
                      LavaDemoType.sunflower => AppStrings.lavaModelTree,
                      LavaDemoType.lavaLamp => AppStrings.lavaModelLavaLamp,
                      LavaDemoType.campfire => AppStrings.lavaModelCampfire,
                      LavaDemoType.rocket => AppStrings.lavaModelRocket,
                      LavaDemoType.senna => AppStrings.lavaModelSenna,
                      LavaDemoType.christmasTree =>
                        AppStrings.lavaModelChristmasTree,
                    },
                    style: GoogleFonts.spaceMono(
                      fontSize: AppSizes.fontSm,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.peach,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingXxs),
                  Text(
                    switch (_selectedType) {
                      LavaDemoType.macintosh =>
                        AppStrings.lavaModelMacintoshDesc,
                      LavaDemoType.sunflower => AppStrings.lavaModelTreeDesc,
                      LavaDemoType.lavaLamp => AppStrings.lavaModelLavaLampDesc,
                      LavaDemoType.campfire => AppStrings.lavaModelCampfireDesc,
                      LavaDemoType.rocket => AppStrings.lavaModelRocketDesc,
                      LavaDemoType.senna => AppStrings.lavaModelSennaDesc,
                      LavaDemoType.christmasTree =>
                        AppStrings.lavaModelChristmasTreeDesc,
                    },
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceMono(
                      fontSize: AppSizes.fontXs,
                      color: AppTheme.subtext,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingSm),
                  Text(
                    AppStrings.lavaStudioHint,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceMono(
                      fontSize: AppSizes.fontXs,
                      color: AppTheme.subtext,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingLg),

          // Timeline & Scrubbing Panel
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(AppSizes.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: AppTheme.surface0),
              ),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${AppStrings.lavaStudioFrame} ${_controller.currentFrame + 1} / ${_controller.totalFrames}',
                            style: GoogleFonts.spaceMono(
                              fontSize: AppSizes.fontSm,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.peach,
                            ),
                          ),
                          Text(
                            '${_controller.status.name.toUpperCase()} • ${AppStrings.lavaStudioFps}',
                            style: GoogleFonts.spaceMono(
                              fontSize: AppSizes.fontXs,
                              color: AppTheme.subtext,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.spacingXs),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      return SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppTheme.peach,
                          inactiveTrackColor: AppTheme.surface0,
                          thumbColor: AppTheme.peach,
                          overlayColor: AppTheme.peach.withValues(alpha: 0.2),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: _controller.currentFrame.toDouble(),
                          min: 0,
                          max: (_controller.totalFrames - 1).toDouble(),
                          onChanged: (val) {
                            _controller.seekToFrame(val.round());
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSizes.spacingXs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filled(
                        tooltip: AppStrings.lavaStudioAutoRotate,
                        onPressed: () {
                          if (_controller.isPlaying) {
                            _controller.pause();
                          } else {
                            _controller.play();
                          }
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.peach,
                          foregroundColor: AppTheme.background,
                        ),
                        icon: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            return Icon(
                              _controller.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacingSm),
                      IconButton.outlined(
                        onPressed: () => _controller.reset(),
                        style: IconButton.styleFrom(
                          foregroundColor: AppTheme.subtext,
                          side: const BorderSide(color: AppTheme.surface0),
                        ),
                        icon: const Icon(Icons.replay),
                      ),
                      const SizedBox(width: AppSizes.spacingMd),
                      SegmentedButton<double>(
                        segments: const [
                          ButtonSegment(value: 0.5, label: Text('0.5x')),
                          ButtonSegment(value: 1.0, label: Text('1.0x')),
                          ButtonSegment(value: 2.0, label: Text('2.0x')),
                        ],
                        selected: {_speed},
                        style: ButtonStyle(
                          textStyle: WidgetStatePropertyAll(
                            GoogleFonts.spaceMono(fontSize: AppSizes.fontXs),
                          ),
                        ),
                        onSelectionChanged: (selected) {
                          setState(() {
                            _speed = selected.first;
                            _controller.setSpeed(_speed);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacing3xl),

          // Architecture Info
          Text(
            AppStrings.lavaStudioArchitecture,
            style: GoogleFonts.pressStart2p(
              fontSize: AppSizes.fontXs,
              color: AppTheme.teal,
            ),
          ),
          const SizedBox(height: AppSizes.spacingSm),
          Text(
            AppStrings.lavaStudioArchitectureDesc,
            style: GoogleFonts.spaceMono(
              fontSize: AppSizes.fontSm,
              color: AppTheme.text,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSizes.spacingXl),

          // External Link Buttons
          Row(
            children: [
              OutlinedButton(
                onPressed: () => _launch(AppStrings.urlGitHubLava),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.peach,
                  side: const BorderSide(color: AppTheme.peach, width: 1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingLg,
                    vertical: AppSizes.spacingMd,
                  ),
                ),
                child: Text(
                  AppStrings.lavaStudioBtnGithub,
                  style: GoogleFonts.pressStart2p(fontSize: AppSizes.fontXs),
                ),
              ),
              const SizedBox(width: AppSizes.spacingMd),
              OutlinedButton(
                onPressed: () => _launch(AppStrings.urlPubDev),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.blue,
                  side: const BorderSide(color: AppTheme.blue, width: 1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacingLg,
                    vertical: AppSizes.spacingMd,
                  ),
                ),
                child: Text(
                  AppStrings.lavaStudioBtnPubDev,
                  style: GoogleFonts.pressStart2p(fontSize: AppSizes.fontXs),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceMono(
          fontSize: AppSizes.fontXs,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _AirbnbCategoryTab extends StatefulWidget {
  const _AirbnbCategoryTab({
    required this.label,
    required this.demoType,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final LavaDemoType demoType;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_AirbnbCategoryTab> createState() => _AirbnbCategoryTabState();
}

class _AirbnbCategoryTabState extends State<_AirbnbCategoryTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spacingMd,
            vertical: AppSizes.spacingXs,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: widget.isSelected ? AppTheme.peach : Colors.transparent,
                width: 2.0,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LavaIcon.demo(
                demoType: widget.demoType,
                size: 44,
                autoPlay: _isHovered,
                interactive: false,
              ),
              const SizedBox(height: AppSizes.spacingXs),
              Text(
                widget.label,
                style: GoogleFonts.spaceMono(
                  fontSize: AppSizes.fontXs,
                  fontWeight:
                      widget.isSelected ? FontWeight.bold : FontWeight.normal,
                  color:
                      widget.isSelected
                          ? AppTheme.peach
                          : (_isHovered ? AppTheme.text : AppTheme.subtext),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
