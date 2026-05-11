import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/shared/widgets/mobile_fallback_page.dart';
import 'package:portifolio/shared/constants/app_strings.dart';

void main() {
  group('MobileFallbackPage', () {
    testWidgets('renders title and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MobileFallbackPage()),
      );

      expect(find.text(AppStrings.mobileTitle), findsOneWidget);
      expect(find.text(AppStrings.mobileSubtitle), findsOneWidget);
    });

    testWidgets('renders GitHub link', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MobileFallbackPage()),
      );

      expect(find.text(AppStrings.mobileGitHubLink), findsOneWidget);
    });

    testWidgets('has a TextButton for GitHub', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MobileFallbackPage()),
      );

      expect(find.byType(TextButton), findsOneWidget);
    });
  });
}
