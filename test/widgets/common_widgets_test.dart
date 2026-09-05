import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawsncare/data/models/pet_role.dart';
import 'package:pawsncare/presentation/widgets/role_badge.dart';
import 'package:pawsncare/presentation/widgets/accent_left_card.dart';

void main() {
  group('Common Reusable Widgets Tests', () {
    testWidgets('RoleBadge displays correct role name and icon for Owner', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RoleBadge(role: PetRole.owner),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Owner'), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
    });

    testWidgets('RoleBadge displays correct role name and icon for Caregiver', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RoleBadge(role: PetRole.caregiver),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Caregiver'), findsOneWidget);
      expect(find.byIcon(Icons.pets), findsOneWidget);
    });

    testWidgets('AccentLeftCard renders children and accent bar border', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccentLeftCard(
              accentColor: Colors.blue,
              child: Text('Card Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Card Content'), findsOneWidget);
    });
  });
}
