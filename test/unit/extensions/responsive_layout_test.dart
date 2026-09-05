import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawsncare/core/utils/responsive_layout.dart';

void main() {
  group('ResponsiveLayout Utility Tests', () {
    testWidgets('isTabletDevice identifies tablet vs phone based on shortestSide', (WidgetTester tester) async {
      late bool isTablet;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(800, 1200)),
          child: Builder(
            builder: (context) {
              isTablet = ResponsiveLayout.isTabletDevice(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isTablet, isTrue);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Builder(
            builder: (context) {
              isTablet = ResponsiveLayout.isTabletDevice(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isTablet, isFalse);
    });

    testWidgets('isTabletLayout evaluates to true only on tablet in landscape', (WidgetTester tester) async {
      late bool isTabletLayout;

      // Tablet in Landscape (800 shortestSide >= 600, orientation landscape)
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(1200, 800),
          ),
          child: Builder(
            builder: (context) {
              isTabletLayout = ResponsiveLayout.isTabletLayout(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(isTabletLayout, isTrue);
    });
  });
}
