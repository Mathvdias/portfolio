import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../constants/app_strings.dart';
import '../constants/app_sizes.dart';

typedef _SpotlightState = ({List<SpotlightItem> filtered, int selectedIndex});

/// A Spotlight-style search overlay that lets the user search and open any
/// desktop window by name.
class SpotlightOverlay extends StatefulWidget {
  const SpotlightOverlay({
    super.key,
    required this.items,
    required this.onSelect,
    required this.onDismiss,
  });

  final List<SpotlightItem> items;
  final ValueChanged<SpotlightItem> onSelect;
  final VoidCallback onDismiss;

  @override
  State<SpotlightOverlay> createState() => _SpotlightOverlayState();
}

class _SpotlightOverlayState extends State<SpotlightOverlay> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late final ValueNotifier<_SpotlightState> _state;

  @override
  void initState() {
    super.initState();
    _state = ValueNotifier((filtered: widget.items, selectedIndex: 0));
    _controller.addListener(_onChanged);
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _state.dispose();
    super.dispose();
  }

  void _onChanged() {
    final query = _controller.text.toLowerCase();
    _state.value = (
      filtered:
          widget.items
              .where((item) => item.label.toLowerCase().contains(query))
              .toList(),
      selectedIndex: 0,
    );
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onDismiss();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final s = _state.value;
      _state.value = (
        filtered: s.filtered,
        selectedIndex: (s.selectedIndex + 1).clamp(0, s.filtered.length - 1),
      );
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final s = _state.value;
      _state.value = (
        filtered: s.filtered,
        selectedIndex: (s.selectedIndex - 1).clamp(0, s.filtered.length - 1),
      );
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      final s = _state.value;
      if (s.filtered.isNotEmpty) widget.onSelect(s.filtered[s.selectedIndex]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dismiss overlay on background tap
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.opaque,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
          ),
        ),
        // Spotlight card
        Positioned(
          top: 120,
          left: 0,
          right: 0,
          child: Center(
            child: Focus(
              onKeyEvent: _onKey,
              child: Container(
                width: AppSizes.spotlightWidth,
                constraints: const BoxConstraints(
                  maxHeight: AppSizes.spotlightMaxHeight,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                  border: Border.all(color: AppTheme.surface0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search field — never rebuilds on keystroke
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.spacingXl,
                        vertical: AppSizes.spacingLg,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: AppTheme.subtext,
                            size: 20,
                            semanticLabel:
                                AppLocalizations.of(context).semSearch,
                          ),
                          const SizedBox(width: AppSizes.spacingLg),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              autofocus: true,
                              style: GoogleFonts.spaceMono(
                                fontSize: AppSizes.font3xl,
                                color: AppTheme.text,
                              ),
                              decoration: InputDecoration(
                                hintText: AppStrings.spotlightHint,
                                hintStyle: GoogleFonts.spaceMono(
                                  fontSize: AppSizes.font3xl,
                                  color: AppTheme.overlay,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              cursorColor: AppTheme.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Results list — only this rebuilds on filter/selection change
                    ValueListenableBuilder<_SpotlightState>(
                      valueListenable: _state,
                      builder: (_, s, __) {
                        if (s.filtered.isEmpty) return const SizedBox.shrink();
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(height: 1, color: AppTheme.surface0),
                            Flexible(
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSizes.spacingXs,
                                ),
                                itemCount: s.filtered.length,
                                itemBuilder: (_, i) {
                                  final item = s.filtered[i];
                                  return _SpotlightRow(
                                    key: ValueKey(item.id),
                                    item: item,
                                    selected: i == s.selectedIndex,
                                    onTap: () => widget.onSelect(item),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpotlightRow extends StatelessWidget {
  const _SpotlightRow({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final SpotlightItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingXl,
          vertical: AppSizes.spacingMd,
        ),
        color:
            selected
                ? AppTheme.blue.withValues(alpha: 0.15)
                : Colors.transparent,
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: IconTheme(
                data: IconThemeData(color: item.color, size: 20),
                child: item.iconWidget,
              ),
            ),
            const SizedBox(width: AppSizes.spacingLg),
            Text(
              item.label,
              style: GoogleFonts.spaceMono(
                fontSize: AppSizes.fontXxl,
                color: selected ? AppTheme.blue : AppTheme.text,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One searchable item in the Spotlight overlay.
class SpotlightItem {
  const SpotlightItem({
    required this.id,
    required this.label,
    required this.iconWidget,
    required this.color,
  });

  final String id;
  final String label;
  final Widget iconWidget;
  final Color color;
}
