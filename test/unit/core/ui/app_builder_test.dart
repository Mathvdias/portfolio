import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portifolio/core/ui/app_builder.dart';

void main() {
  group('AppBuilder.withFixedTextScale', () {
    testWidgets('forces TextScaler.noScaling regardless of ambient scale', (
      tester,
    ) async {
      // Simulate a user with 2× OS text scale
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: Builder(
            builder: (outer) {
              // Apply the builder as MaterialApp would
              return AppBuilder.withFixedTextScale(
                outer,
                Builder(
                  builder:
                      (inner) => Text(
                        MediaQuery.textScalerOf(inner).toString(),
                        textDirection: TextDirection.ltr,
                      ),
                ),
              );
            },
          ),
        ),
      );

      // The text inside must see NoScaling, not the 2× scale from outside
      expect(
        find.text(TextScaler.noScaling.toString()),
        findsOneWidget,
        reason: 'AppBuilder must override ambient textScaler to noScaling',
      );
    });

    testWidgets('passes child through without adding extra widgets', (
      tester,
    ) async {
      const sentinel = SizedBox(key: Key('child'), width: 42);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Builder(
            builder: (ctx) => AppBuilder.withFixedTextScale(ctx, sentinel),
          ),
        ),
      );

      expect(find.byKey(const Key('child')), findsOneWidget);
    });
  });
}
