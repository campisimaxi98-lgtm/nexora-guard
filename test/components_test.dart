import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_guard/core/app_risk_level.dart';
import 'package:nexora_guard/ui/components.dart';

void main() {
  group('LevelBadge', () {
    testWidgets('muestra etiqueta + ícono (no depende solo del color)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LevelBadge(level: AppRiskLevel.critical, label: 'Crítico'),
          ),
        ),
      );
      expect(find.text('Crítico'), findsOneWidget);
      expect(find.byIcon(riskLevelIcon(AppRiskLevel.critical)), findsOneWidget);
    });

    test('cada nivel tiene color e ícono propios', () {
      for (final level in AppRiskLevel.values) {
        expect(riskLevelColor(level), isNot(equals(Colors.transparent)));
        expect(riskLevelIcon(level), isNotNull);
      }
    });
  });

  group('NexoraCard', () {
    testWidgets('respeta el tap y el contenido', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NexoraCard(
              onTap: () => tapped = true,
              child: const Text('hola'),
            ),
          ),
        ),
      );
      expect(find.text('hola'), findsOneWidget);
      await tester.tap(find.text('hola'));
      expect(tapped, isTrue);
    });
  });

  group('PremiumLockedCard', () {
    testWidgets('CTA abre la acción pedida', (tester) async {
      var opened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PremiumLockedCard(
              title: 'Premium',
              description: 'Gated',
              ctaLabel: 'Ver Premium',
              onViewPremium: () => opened = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Ver Premium'));
      expect(opened, isTrue);
    });
  });

  group('Responsive', () {
    testWidgets('NexoraMaxWidth centra el contenido', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NexoraMaxWidth(
            child: const SizedBox(width: 300, height: 100),
          ),
        ),
      );
      expect(find.byType(NexoraMaxWidth), findsOneWidget);
    });
  });

  group('NexoraTopBar', () {
    testWidgets('muestra campana con badge y engranaje', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NexoraTopBar(
              alertCount: 3,
              onOpenAlerts: () {},
              onOpenSettings: () {},
            ),
          ),
        ),
      );
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(find.text('NEXORA'), findsOneWidget);
    });
  });

  group('FloatingAIButton', () {
    testWidgets('existe y es tocable', (tester) async {
      var opened = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FloatingAIButton(onTap: () => opened = true, tooltip: 'NEXORA AI'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.byType(FloatingAIButton));
      expect(opened, isTrue);
    });
  });

  test('tokens de superficie están definidos', () {
    expect(ntRadiusCard, greaterThan(0));
    expect(ntPad, greaterThan(0));
  });
}