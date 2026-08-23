/// Genera los artefactos gráficos de las tiendas a partir de la marca real
/// de la app (el mismo escudo que se dibuja en pantalla). Se ejecuta con:
///
///   flutter test --update-goldens test/store_assets_test.dart
///
/// El texto del feature graphic NO va aquí (en tests no hay fuentes reales):
/// se compone después con scripts/make_store_assets.py sobre el arte base.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nexora_guard/ui/nexora_logo.dart';
import 'package:nexora_guard/ui/theme.dart';

Widget _stage(Widget child, Size size) => Directionality(
  textDirection: TextDirection.ltr,
  child: ColoredBox(
    color: nexoraBackground,
    child: SizedBox.fromSize(size: size, child: child),
  ),
);

void main() {
  testWidgets('ícono de Play Store 512×512', (tester) async {
    await tester.binding.setSurfaceSize(const Size(512, 512));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _stage(
        RepaintBoundary(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Halo dorado detrás del escudo.
              Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      nexoraGold.withValues(alpha: 0.28),
                      nexoraGold.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              const NexoraLogo(size: 340, showRing: true),
            ],
          ),
        ),
        const Size(512, 512),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('goldens/store-icon-512.png'),
    );
  });

  testWidgets('feature graphic 1024×500 (arte base, sin texto)', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _stage(
        RepaintBoundary(
          child: Stack(
            children: [
              // Glow azul profundo a la derecha, dorado a la izquierda.
              Positioned(
                right: -160,
                top: -120,
                child: Container(
                  width: 560,
                  height: 560,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        nexoraBlue.withValues(alpha: 0.35),
                        nexoraBlue.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -120,
                bottom: -180,
                child: Container(
                  width: 520,
                  height: 520,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        nexoraGold.withValues(alpha: 0.18),
                        nexoraGold.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Anillos decorativos alrededor del escudo.
              Center(
                child: SizedBox.square(
                  dimension: 420,
                  child: CustomPaint(painter: _StoreRingsPainter()),
                ),
              ),
              // Escudo protagonista a la izquierda.
              Positioned(left: 64, top: 0, bottom: 0, child: Center(child: const NexoraLogo(size: 300, showRing: true))),
            ],
          ),
        ),
        const Size(1024, 500),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('goldens/store-feature-base.png'),
    );
  });
}

/// Anillos finos giratorios congelados para el arte de la tienda.
class _StoreRingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var r = 0; r < 3; r++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 190.0 + r * 46),
        r * 1.1,
        3.4 - r * 0.6,
        false,
        paint..color = (r.isEven ? nexoraGold : nexoraBlue).withValues(alpha: 0.30),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
