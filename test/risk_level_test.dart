import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_guard/core/app_risk_level.dart';
import 'package:nexora_guard/core/models.dart';

AppRisk app({
  List<String> dangerous = const [],
  List<String> granted = const [],
  List<String> flags = const [],
  bool sideloaded = false,
}) => AppRisk.fromMap({
  'packageName': 'com.example.x',
  'label': 'X',
  'versionName': '1.0',
  'dangerousPermissions': dangerous,
  'grantedPermissions': granted,
  'specialFlags': flags,
  'sideloaded': sideloaded,
  'foregroundMillis24h': -1,
  'rxBytes24h': -1,
  'txBytes24h': -1,
});

void main() {
  group('classifyAppRisk', () {
    test('sin señales → segura', () {
      expect(classifyAppRisk(app()), AppRiskLevel.safe);
    });

    test('permiso declarado SOLO (sin conceder) no condena', () {
      expect(classifyAppRisk(app(dangerous: ['CAMERA'])), AppRiskLevel.safe);
    });

    test('reconoce el contexto: apps que declaran de más', () {
      // Muchos permisos declarados pero ninguno concedido → atención, no peor.
      expect(
        classifyAppRisk(
          app(dangerous: ['CAMERA', 'RECORD_AUDIO', 'ACCESS_FINE_LOCATION']),
        ),
        AppRiskLevel.attention,
      );
    });

    test('permiso concedido → atención (evidencia real de uso posible)', () {
      expect(
        classifyAppRisk(
          app(
            dangerous: ['CAMERA'],
            granted: ['CAMERA'],
          ),
        ),
        AppRiskLevel.attention,
      );
    });

    test('sideload sin otras señales → atención, nunca sospechoso', () {
      expect(
        classifyAppRisk(app(sideloaded: true)),
        AppRiskLevel.attention,
      );
    });

    test('warning + sideload → sospechoso', () {
      // 8 permisos peligrosos elevan el puntaje a 8 (warning del motor).
      final dangerous = List.generate(8, (i) => 'PERM_$i');
      expect(
        classifyAppRisk(app(dangerous: dangerous, sideloaded: true)),
        AppRiskLevel.suspicious,
      );
    });

    test('overlay activo + puntaje alto → sospechoso', () {
      final dangerous = List.generate(5, (i) => 'PERM_$i');
      expect(
        classifyAppRisk(app(dangerous: dangerous, flags: ['overlay'])),
        AppRiskLevel.suspicious,
      );
    });

    test('capacidad ACTIVA (accesibilidad) → crítico aunque no haya permisos', () {
      expect(
        classifyAppRisk(app(flags: ['accessibility-service'])),
        AppRiskLevel.critical,
      );
    });

    test('notification-listener activo → crítico', () {
      expect(
        classifyAppRisk(app(flags: ['notification-listener'])),
        AppRiskLevel.critical,
      );
    });

    test('device-admin activo → crítico', () {
      expect(
        classifyAppRisk(app(flags: ['device-admin-active'])),
        AppRiskLevel.critical,
      );
    });

    test('puntaje ≥ 12 del motor → crítico', () {
      final dangerous = List.generate(12, (i) => 'PERM_$i');
      expect(classifyAppRisk(app(dangerous: dangerous)), AppRiskLevel.critical);
    });
  });

  group('severity helpers (regresión)', () {
    test('activeCapabilities solo marca las concedidas y activas', () {
      final active = app(flags: ['overlay', 'accessibility-service']);
      expect(active.activeCapabilities, ['accessibility-service']);
    });
  });
}