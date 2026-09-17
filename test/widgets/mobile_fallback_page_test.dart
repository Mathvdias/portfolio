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

    testWidgets('tapping app card opens full-screen window and closes via red button', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));

      // Tap ABOUT pocket app
      await tester.tap(find.text('ABOUT'));
      await tester.pumpAndSettle();

      expect(find.text('ABOUT ME'), findsOneWidget);
      expect(find.text('ESC'), findsOneWidget);

      // Tap close button (the red traffic light with close icon)
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('ABOUT ME'), findsNothing);
    });

    testWidgets('tapping app card opens full-screen window and closes via ESC button', (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(home: MobileFallbackPage()));

      // Tap SNAKE pocket app
      await tester.tap(find.text('SNAKE'));
      await tester.pumpAndSettle();

      expect(find.text('SNAKE GAME'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_up), findsOneWidget); // D-pad is visible on mobile

      // Tap ESC button
      await tester.tap(find.text('ESC'));
      await tester.pumpAndSettle();

      expect(find.text('SNAKE GAME'), findsNothing);
    });
  });
}
