import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/shared/widgets/mobile_fallback_page.dart';
import 'package:portifolio/shared/constants/app_strings.dart';

void main() {
  group('MobileFallbackPage', () {
    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));

      expect(find.text(AppStrings.mobileTitle), findsOneWidget);
      expect(find.text(AppStrings.mobileSubtitle), findsOneWidget);
    });

    testWidgets('renders GitHub link', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));

      expect(find.text(AppStrings.mobileGitHubLink), findsOneWidget);
    });

    testWidgets('has a TextButton for GitHub', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));

      expect(find.byType(TextButton), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Pocket Apps grid and sections', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));

      expect(find.text('POCKET APPS'), findsOneWidget);
      expect(find.text('ABOUT'), findsOneWidget);
      expect(find.text('EXPERIENCE'), findsOneWidget);
      expect(find.text('SKILLS'), findsOneWidget);
      expect(find.text('PROJECTS'), findsOneWidget);
      expect(find.text('GUESTBOOK'), findsOneWidget);
      expect(find.text('TERMINAL'), findsOneWidget);
      expect(find.text('SNAKE'), findsOneWidget);
      expect(find.text('CALC'), findsOneWidget);
      expect(find.text('METRICS'), findsOneWidget);
    });

    testWidgets('renders quick dock links', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));

      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('LinkedIn'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('pub.dev'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });
  });
}
