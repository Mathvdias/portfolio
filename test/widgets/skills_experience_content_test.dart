// ignore_for_file: prefer_const_constructors
// Const constructors are intentionally omitted in this file so that widget
// constructors execute at runtime and are tracked by the coverage tool.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:portifolio/core/constants/app_svgs.dart';
import 'package:portifolio/l10n/app_localizations.dart';
import 'package:portifolio/shared/constants/app_strings.dart';
import 'package:portifolio/shared/models/experience.dart';
import 'package:portifolio/shared/widgets/experience_window_content.dart';
import 'package:portifolio/shared/widgets/skills_window_content.dart';
import 'package:portifolio/theme/app_theme.dart';

/// What the skills window is expected to show, row by row.
class _ExpectedSkill {
  const _ExpectedSkill(this.name, this.asset, this.color, this.level);

  final String name;
  final String asset;
  final Color color;
  final double level;

  String get percentage => '${(level * 100).round()}%';
}

const _mobileSkills = [
  _ExpectedSkill('Flutter', AppSvgs.flutter, AppTheme.blue, 0.95),
  _ExpectedSkill('Android', AppSvgs.android, AppTheme.green, 0.85),
  _ExpectedSkill('Dart', AppSvgs.dart, AppTheme.teal, 0.95),
  _ExpectedSkill('Kotlin', AppSvgs.kotlin, AppTheme.mauve, 0.80),
];

const _backendSkills = [
  _ExpectedSkill('REST APIs', AppSvgs.api, AppTheme.blue, 0.85),
  _ExpectedSkill('Firebase', AppSvgs.firebase, AppTheme.yellow, 0.75),
  _ExpectedSkill('Git / CI', AppSvgs.github, AppTheme.subtext, 0.90),
  _ExpectedSkill('Fastlane', AppSvgs.fastlane, AppTheme.peach, 0.70),
];

const _allSkills = [..._mobileSkills, ..._backendSkills];

const _experience = Experience(
  company: 'Zallpy Digital',
  role: 'Flutter Engineer',
  period: 'Sep 2024 – Present',
  description: 'Building cross-platform mobile experiences with Flutter.',
  technologies: ['Flutter', 'Dart', 'Firebase', 'REST APIs'],
);

Widget _host(Widget child) {
  return MaterialApp(
    localizationsDelegates: [AppLocalizationsDelegate()],
    home: Scaffold(body: child),
  );
}

/// Pumps [child] and waits for the asynchronous localization load to finish.
Future<void> _pumpContent(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(_host(child));
  await tester.pumpAndSettle();
}

void _useSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// The row that holds the icon, name, bar and percentage of [skillName].
Finder _rowOf(String skillName) {
  return find.ancestor(of: find.text(skillName), matching: find.byType(Row));
}

void main() {
  // PressStart2P is not bundled; never reach for the network from a test.
  GoogleFonts.config.allowRuntimeFetching = false;

  group('SkillsWindowContent', () {
    testWidgets('renders both skill groups with upper-cased titles', (
      tester,
    ) async {
      _useSurface(tester, Size(800, 1000));
      await _pumpContent(tester, SkillsWindowContent());

      expect(find.text(AppStrings.skillsMobile.toUpperCase()), findsOneWidget);
      expect(find.text(AppStrings.skillsBackend.toUpperCase()), findsOneWidget);
      // The raw, mixed-case titles are never shown.
      expect(find.text(AppStrings.skillsMobile), findsNothing);
      expect(find.text(AppStrings.skillsBackend), findsNothing);
    });

    testWidgets('lists the mobile skills above the backend skills, in order', (
      tester,
    ) async {
      _useSurface(tester, Size(800, 1000));
      await _pumpContent(tester, SkillsWindowContent());

      final mobileTitleY =
          tester
              .getTopLeft(find.text(AppStrings.skillsMobile.toUpperCase()))
              .dy;
      final backendTitleY =
          tester
              .getTopLeft(find.text(AppStrings.skillsBackend.toUpperCase()))
              .dy;

      double previousY = mobileTitleY;
      for (final skill in _mobileSkills) {
        final y = tester.getTopLeft(find.text(skill.name)).dy;
        expect(y, greaterThan(previousY), reason: skill.name);
        expect(y, lessThan(backendTitleY), reason: skill.name);
        previousY = y;
      }

      previousY = backendTitleY;
      for (final skill in _backendSkills) {
        final y = tester.getTopLeft(find.text(skill.name)).dy;
        expect(y, greaterThan(previousY), reason: skill.name);
        previousY = y;
      }
    });

    testWidgets('each row shows the rounded percentage in the skill colour', (
      tester,
    ) async {
      _useSurface(tester, Size(800, 1000));
      await _pumpContent(tester, SkillsWindowContent());

      expect(find.byType(SvgPicture), findsNWidgets(_allSkills.length));

      for (final skill in _allSkills) {
        final row = _rowOf(skill.name);
        expect(row, findsOneWidget, reason: skill.name);

        final percentage = find.descendant(
          of: row,
          matching: find.text(skill.percentage),
        );
        expect(percentage, findsOneWidget, reason: skill.name);
        expect(
          tester.widget<Text>(percentage).style?.color,
          skill.color,
          reason: skill.name,
        );

        final name = tester.widget<Text>(find.text(skill.name));
        expect(name.style?.color, AppTheme.text, reason: skill.name);
        expect(name.style?.fontWeight, FontWeight.bold, reason: skill.name);
      }
    });

    testWidgets('each row shows its own icon tinted with the skill colour', (
      tester,
    ) async {
      _useSurface(tester, Size(800, 1000));
      await _pumpContent(tester, SkillsWindowContent());

      for (final skill in _allSkills) {
        final icon = tester.widget<SvgPicture>(
          find.descendant(
            of: _rowOf(skill.name),
            matching: find.byType(SvgPicture),
          ),
        );

        expect(
          (icon.bytesLoader as SvgAssetLoader).assetName,
          skill.asset,
          reason: skill.name,
        );
        expect(
          icon.colorFilter,
          ColorFilter.mode(skill.color, BlendMode.srcIn),
          reason: skill.name,
        );
        expect(icon.width, 24, reason: skill.name);
        expect(icon.height, 24, reason: skill.name);
      }
    });

    testWidgets('the bar is filled proportionally to the skill level', (
      tester,
    ) async {
      _useSurface(tester, Size(800, 1000));
      await _pumpContent(tester, SkillsWindowContent());

      for (final skill in _allSkills) {
        final bars = find.descendant(
          of: _rowOf(skill.name),
          matching: find.byType(Container),
        );
        expect(bars, findsNWidgets(2), reason: skill.name);

        final track = tester.widget<Container>(bars.at(0));
        final fill = tester.widget<Container>(bars.at(1));
        expect(track.color, AppTheme.surface0, reason: skill.name);
        expect(
          fill.color,
          skill.color.withValues(alpha: 0.85),
          reason: skill.name,
        );

        final trackSize = tester.getSize(bars.at(0));
        final fillSize = tester.getSize(bars.at(1));
        expect(trackSize.height, 8, reason: skill.name);
        expect(fillSize.height, 8, reason: skill.name);
        expect(trackSize.width, greaterThan(0), reason: skill.name);
        expect(
          fillSize.width,
          moreOrLessEquals(trackSize.width * skill.level, epsilon: 0.01),
          reason: skill.name,
        );
      }
    });

    testWidgets('the bar track follows the available width', (tester) async {
      _useSurface(tester, Size(800, 1000));
      await _pumpContent(tester, SkillsWindowContent());
      final wideTrack =
          tester
              .getSize(
                find
                    .descendant(
                      of: _rowOf('Flutter'),
                      matching: find.byType(Container),
                    )
                    .first,
              )
              .width;

      tester.view.physicalSize = Size(500, 1000);
      await tester.pump();
      final narrowTrack =
          tester
              .getSize(
                find
                    .descendant(
                      of: _rowOf('Flutter'),
                      matching: find.byType(Container),
                    )
                    .first,
              )
              .width;

      // The fixed icon, name and percentage columns keep their width, so the
      // whole 300px difference is absorbed by the bar.
      expect(wideTrack - narrowTrack, moreOrLessEquals(300, epsilon: 0.01));
    });

    testWidgets('scrolls to the last skill when the window is short', (
      tester,
    ) async {
      _useSurface(tester, Size(500, 300));
      await _pumpContent(tester, SkillsWindowContent());

      expect(tester.takeException(), isNull);
      expect(tester.getTopLeft(find.text('Fastlane')).dy, greaterThan(300));

      await tester.drag(find.byType(SingleChildScrollView), Offset(0, -1000));
      await tester.pump();

      expect(tester.getBottomLeft(find.text('Fastlane')).dy, lessThan(300));
      expect(
        tester
            .getBottomLeft(find.text(AppStrings.skillsMobile.toUpperCase()))
            .dy,
        lessThan(0),
      );
    });
  });

  group('ExperienceWindowContent', () {
    testWidgets('renders company, role, period and description', (
      tester,
    ) async {
      await _pumpContent(
        tester,
        ExperienceWindowContent(experience: _experience),
      );

      expect(find.text('Zallpy Digital'), findsOneWidget);
      expect(find.text('Flutter Engineer'), findsOneWidget);
      expect(find.text('▶ Sep 2024 – Present'), findsOneWidget);
      // The period is only ever shown with its marker.
      expect(find.text('Sep 2024 – Present'), findsNothing);
      expect(
        find.text('Building cross-platform mobile experiences with Flutter.'),
        findsOneWidget,
      );
    });

    testWidgets('stacks header, divider, description and tech list in order', (
      tester,
    ) async {
      await _pumpContent(
        tester,
        ExperienceWindowContent(experience: _experience),
      );

      final ys = [
        tester.getTopLeft(find.text(_experience.company)).dy,
        tester.getTopLeft(find.text(_experience.role)).dy,
        tester.getTopLeft(find.text('▶ ${_experience.period}')).dy,
        tester.getTopLeft(find.byType(Divider)).dy,
        tester.getTopLeft(find.text(_experience.description)).dy,
        tester.getTopLeft(find.text(AppStrings.techLabel)).dy,
        tester.getTopLeft(find.text('Dart')).dy,
      ];

      for (var i = 1; i < ys.length; i++) {
        expect(ys[i], greaterThan(ys[i - 1]), reason: 'item $i');
      }
      expect(
        tester.widget<Divider>(find.byType(Divider)).color,
        AppTheme.surface0,
      );
    });

    testWidgets('renders one bordered chip per technology, in order', (
      tester,
    ) async {
      await _pumpContent(
        tester,
        ExperienceWindowContent(experience: _experience),
      );

      expect(find.text(AppStrings.techLabel), findsOneWidget);

      final chips = find.descendant(
        of: find.byType(Wrap),
        matching: find.byType(Container),
      );
      expect(chips, findsNWidgets(_experience.technologies.length));

      for (var i = 0; i < _experience.technologies.length; i++) {
        final tech = _experience.technologies[i];
        final label = find.descendant(
          of: chips.at(i),
          matching: find.byType(Text),
        );
        expect(tester.widget<Text>(label).data, tech);
        expect(tester.widget<Text>(label).style?.color, AppTheme.blue);

        final decoration =
            tester.widget<Container>(chips.at(i)).decoration as BoxDecoration;
        expect(
          decoration.border,
          Border.all(color: AppTheme.blue.withValues(alpha: 0.5), width: 1),
          reason: tech,
        );
      }
    });

    testWidgets(
      'keeps the tech label but shows no chips without technologies',
      (tester) async {
        await _pumpContent(
          tester,
          ExperienceWindowContent(
            experience: Experience(
              company: 'Solo Studio',
              role: 'Founder',
              period: '2019',
              description: 'Shipped side projects.',
              technologies: [],
            ),
          ),
        );

        expect(find.text('Solo Studio'), findsOneWidget);
        expect(find.text('▶ 2019'), findsOneWidget);
        expect(find.text(AppStrings.techLabel), findsOneWidget);
        expect(tester.widget<Wrap>(find.byType(Wrap)).children, isEmpty);
        expect(
          find.descendant(of: find.byType(Wrap), matching: find.byType(Text)),
          findsNothing,
        );
      },
    );

    testWidgets('paints the company in mauve unless an accent is given', (
      tester,
    ) async {
      await _pumpContent(
        tester,
        ExperienceWindowContent(experience: _experience),
      );
      expect(
        tester.widget<Text>(find.text(_experience.company)).style?.color,
        AppTheme.mauve,
      );

      await _pumpContent(
        tester,
        ExperienceWindowContent(
          experience: _experience,
          accentColor: AppTheme.peach,
        ),
      );
      expect(
        tester.widget<Text>(find.text(_experience.company)).style?.color,
        AppTheme.peach,
      );
      // The accent only affects the company name.
      expect(
        tester.widget<Text>(find.text(_experience.role)).style?.color,
        AppTheme.subtext,
      );
      expect(
        tester.widget<Text>(find.text('▶ ${_experience.period}')).style?.color,
        AppTheme.overlay,
      );
      expect(
        tester.widget<Text>(find.text(_experience.description)).style?.color,
        AppTheme.text,
      );
    });

    testWidgets('wraps the chips and scrolls when the window is small', (
      tester,
    ) async {
      _useSurface(tester, Size(320, 240));
      final technologies = List.generate(12, (i) => 'Technology $i');
      await _pumpContent(
        tester,
        ExperienceWindowContent(
          experience: Experience(
            company: 'A Company With A Rather Long Name',
            role: 'Senior Mobile Engineer',
            period: 'Jan 2020 – Dec 2023',
            description: List.filled(12, 'Delivered features.').join(' '),
            technologies: technologies,
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      final first = find.text(technologies.first);
      final last = find.text(technologies.last);
      // The chips do not fit on a single run, so they wrap onto new lines.
      expect(
        tester.getTopLeft(last).dy,
        greaterThan(tester.getTopLeft(first).dy),
      );
      expect(tester.getTopLeft(last).dy, greaterThan(240));

      await tester.drag(find.byType(SingleChildScrollView), Offset(0, -5000));
      await tester.pump();

      expect(tester.getBottomLeft(last).dy, lessThan(240));
      expect(tester.takeException(), isNull);
    });
  });
}
