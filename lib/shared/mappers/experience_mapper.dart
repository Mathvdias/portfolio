import 'package:flutter/material.dart';


import '../../theme/app_theme.dart';
import '../constants/app_svgs.dart';
import '../models/experience.dart';

/// Maps raw l10n experience data into [Experience] objects and resolves
/// company-specific metadata (colour, icon widget, icon asset path, short name).
///
/// ### Icon strategy
/// Each company has:
/// - an [iconAssetFor] → SVG path in `assets/icons/` (drop the file to activate)
/// - an [iconWidgetFor] → FontAwesome fallback widget used while file is absent
///
/// [DesktopIconsGrid] passes **both** to [DesktopIcon]:
/// ```dart
/// DesktopIcon(
///   iconAsset:  ExperienceMapper.iconAssetFor(exp.company),   // preferred
///   iconWidget: ExperienceMapper.iconWidgetFor(exp.company),  // fallback
/// )
/// ```
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
    if (company.contains('Oi')) return AppTheme.peach;
    return AppTheme.peach;
  }

  // ── Resolve SVG asset path ─────────────────────────────────────
  //
  //  Company       Role                          Asset path
  //  ─────────────────────────────────────────────────────────────
  //  Zallpy        Mobile Software Engineer      AppSvgs.zallpy
  //  Banco Pan     Mobile Software Engineer      AppSvgs.bancoPan
  //  Conecthus     Mobile Developer PL (AI/POS)  AppSvgs.conecthus
  //  Oi            Maintenance Technician         AppSvgs.oi
  static String iconAssetFor(String company) {
    if (company.contains('Zallpy')) return AppSvgs.zallpy;
    if (_isPan(company)) return AppSvgs.bancoPan;
    if (company.contains('Conecthus')) return AppSvgs.conecthus;
    if (company.contains('Oi')) return AppSvgs.oi;
    return AppSvgs.bancoPan;
  }

  // ── Resolve FontAwesome fallback widget ────────────────────────
  //
  // Used by [DesktopIcon] while the SVG file from [iconAssetFor] is
  // not yet present in assets/icons/.
  static Widget iconWidgetFor(String company) {
    // Mobile Software Engineer — B2B, cross-platform, Clean Architecture
    if (company.contains('Zallpy')) {
      return const Icon(Icons.smartphone);
    }
    // Mobile Software Engineer — banking / design-system / Crashlytics
    if (_isPan(company)) {
      return const Icon(Icons.account_balance);
    }
    // Mobile Developer PL — AI/ML, POS kiosks, cross-platform
    if (company.contains('Conecthus')) {
      return const Icon(Icons.memory);
    }
    // Maintenance Technician — fiber-optic networks, Huawei routers, SQL
    if (company.contains('Oi')) {
      return const Icon(Icons.router);
    }
    return const Icon(Icons.account_balance);
  }

  // ── Resolve short display name ─────────────────────────────────
  static String shortNameFor(String company) {
    if (company.contains('Zallpy')) return 'Zallpy';
    if (_isPan(company)) return 'Banco Pan';
    if (company.contains('Conecthus')) return 'Conecthus';
    if (company.contains('Oi')) return 'Oi';
    return company.split(' ').first;
  }

  // ── Helper ─────────────────────────────────────────────────────
  static bool _isPan(String c) =>
      c.contains('Banco') || c.contains('PAN') || c.contains('Pan');
}
