import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../theme/app_theme.dart';
import '../models/experience.dart';

/// Maps raw l10n experience data into [Experience] objects and resolves
/// company-specific metadata (colour, pixel icon, short name).
///
/// This replaces the ad-hoc `_colorForCompany`, `_pixelsForCompany`,
/// `_shortNameFor` and `_buildExperiences` methods that were on the View.
abstract final class ExperienceMapper {
  // ── Parse l10n list into typed models ───────────────────────────
  static List<Experience> fromL10n(List<Map<String, dynamic>> raw) {
    return raw.map((e) {
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

  // ── Resolve accent colour ──────────────────────────────────────
  static Color colorFor(String company) {
    if (company.contains('Zallpy')) return AppTheme.teal;
    if (_isPan(company)) return AppTheme.blue;
    if (company.contains('Conecthus')) return AppTheme.green;
    return AppTheme.peach;
  }

  // ── Resolve IconData ───────────────────────────────────
  static Widget iconWidgetFor(String company) {
    if (company.contains('Zallpy'))
      return const FaIcon(FontAwesomeIcons.briefcase);
    if (_isPan(company)) return const FaIcon(FontAwesomeIcons.buildingColumns);
    if (company.contains('Conecthus'))
      return const FaIcon(FontAwesomeIcons.wifi);
    if (company.contains('Oi')) return const FaIcon(FontAwesomeIcons.phone);
    return const FaIcon(FontAwesomeIcons.buildingColumns);
  }

  // ── Resolve short display name ─────────────────────────────────
  static String shortNameFor(String company) {
    if (company.contains('Zallpy')) return 'Zallpy';
    if (_isPan(company)) return 'Banco Pan';
    if (company.contains('Conecthus')) return 'Conecthus';
    return company.split(' ').first;
  }

  // ── Helper ─────────────────────────────────────────────────────
  static bool _isPan(String c) =>
      c.contains('Banco') || c.contains('PAN') || c.contains('Pan');
}
