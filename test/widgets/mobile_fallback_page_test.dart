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

      expect(find.text(AppStrings.mobilePocketApps), findsOneWidget);
      expect(find.text(AppStrings.mobileAppAbout), findsOneWidget);
      expect(find.text(AppStrings.mobileAppExperience), findsOneWidget);
      expect(find.text(AppStrings.mobileAppSkills), findsOneWidget);
      expect(find.text(AppStrings.mobileAppProjects), findsOneWidget);
      expect(find.text(AppStrings.mobileAppGuestbook), findsOneWidget);
      expect(find.text(AppStrings.mobileAppTerminal), findsOneWidget);
      expect(find.text(AppStrings.mobileAppSnake), findsOneWidget);
      expect(find.text(AppStrings.mobileAppCalc), findsOneWidget);
      expect(find.text(AppStrings.mobileAppMetrics), findsOneWidget);
    });

    testWidgets('renders quick dock links', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));

      expect(find.text(AppStrings.dockGitHub), findsOneWidget);
      expect(find.text(AppStrings.dockLinkedIn), findsOneWidget);
      expect(find.text(AppStrings.dockMedium), findsOneWidget);
      expect(find.text(AppStrings.dockPubDev), findsOneWidget);
      expect(find.text(AppStrings.dockResume), findsOneWidget);
      expect(find.text(AppStrings.dockEmail), findsOneWidget);
    });

    testWidgets('tapping app card opens full-screen window and closes via red button', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));

      // Tap ABOUT pocket app
      await tester.tap(find.text(AppStrings.mobileAppAbout));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.mobileAppAboutTitle), findsOneWidget);
      expect(find.text(AppStrings.mobileEsc), findsOneWidget);

      // Tap close button (the red traffic light with close icon)
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.mobileAppAboutTitle), findsNothing);
    });

    testWidgets('tapping app card opens full-screen window and closes via ESC button', (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));

      // Tap SNAKE pocket app
      await tester.tap(find.text(AppStrings.mobileAppSnake));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.mobileAppSnakeTitle), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_up), findsOneWidget); // D-pad is visible on mobile

      // Tap ESC button
      await tester.tap(find.text(AppStrings.mobileEsc));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.mobileAppSnakeTitle), findsNothing);
    });
  });
}
