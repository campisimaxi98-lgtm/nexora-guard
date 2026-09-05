import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_guard/core/models.dart';
import 'package:nexora_guard/ui/nexora_ai.dart';
import 'package:nexora_guard/ui/strings.dart';

import 'helpers.dart';

const _es = AppStrings(AppLang.es);
const _en = AppStrings(AppLang.en);

Snapshot snapshotWith() => buildSnapshot(
  apps: [
    AppRisk.fromMap({
      'packageName': 'com.android.legacy.spy',
      'label': 'LegacyTracker',
      'versionName': '1.0',
      'dangerousPermissions': ['RECORD_AUDIO', 'ACCESS_FINE_LOCATION'],
      'grantedPermissions': ['RECORD_AUDIO', 'ACCESS_FINE_LOCATION'],
      'specialFlags': ['accessibility-service'],
      'sideloaded': false,
      'foregroundMillis24h': -1,
      'rxBytes24h': -1,
      'txBytes24h': -1,
    }),
    AppRisk.fromMap({
      'packageName': 'com.example.notes',
      'label': 'Notas',
      'versionName': '1.0',
      'dangerousPermissions': [],
      'grantedPermissions': [],
      'specialFlags': [],
      'sideloaded': false,
      'foregroundMillis24h': -1,
      'rxBytes24h': -1,
      'txBytes24h': -1,
    }),
  ],
);

const _verdict = Verdict(
  severity: Severity.warning,
  score: 62,
  findings: [],
);

void main() {
  NexoraAIEngine engine({List<AppRisk> apps = const []}) => NexoraAIEngine(
    strings: _es,
    snapshot: snapshotWith(),
    verdict: _verdict,
  );

  group('batería y temperatura', () {
    test('responde con datos reales del snapshot (es)', () {
      final reply = engine().answer('¿cómo está la batería?');
      expect(reply, contains('80%'));
      expect(reply, contains('30'));
    });

    test('responde en inglés', () {
      final reply = NexoraAIEngine(
        strings: _en,
        snapshot: snapshotWith(),
      ).answer('how is my battery?');
      expect(reply, contains('80%'));
    });

    test('temperatura por encima del umbral advierte', () {
      final hot = buildSnapshot(
        battery: buildSnapshot().battery,
        apps: const [],
      );
      // Se reemplaza la batería con una caliente.
      final s = Snapshot(
        timestampMillis: hot.timestampMillis,
        memory: hot.memory,
        storage: hot.storage,
        battery: const BatteryInfo(
          levelPercent: 50,
          charging: false,
          temperatureCelsius: 47.0,
          temperatureAvailable: true,
          voltageMillivolts: 4000,
          healthy: true,
          healthLabel: 'good',
        ),
        network: hot.network,
        apps: hot.apps,
        device: hot.device,
      );
      final reply = NexoraAIEngine(strings: _es, snapshot: s).answer('temperatura');
      expect(reply, contains('47'));
      expect(reply, contains('crítica'));
    });
  });

  group('memoria y almacenamiento', () {
    test('memoria usa datos reales', () {
      final reply = engine().answer('¿cómo está la ram?');
      expect(reply, contains('4.0'));
    });

    test('almacenamiento usa datos reales', () {
      final reply = engine().answer('¿cuánto espacio libre tengo?');
      expect(reply, contains('64'));
      expect(reply, contains('128'));
    });
  });

  group('apps', () {
    test('una app con capacidad ACTIVA se reporta crítica con evidencia', () {
      final reply = engine().answer('¿LegacyTracker es peligrosa?');
      expect(reply, contains('LegacyTracker'));
      expect(reply, contains('Crítico'));
      expect(reply, contains('ACTIVA'));
    });

    test('una app sin señales se reporta segura', () {
      final reply = engine().answer('¿Notas es segura?');
      expect(reply, contains('Seguro'));
    });

    test('no encuentra la app y lo dice honesto', () {
      final reply = engine().answer('¿Excel es peligrosa?');
      expect(reply.toLowerCase(), contains('excel'));
      expect(reply, contains('No encuentro'));
    });
  });

  group('veredicto global', () {
    test('responde el nivel global desde Verdict', () {
      final reply = engine().answer('¿mi teléfono está seguro?');
      expect(reply, contains('Advertencia'));
      expect(reply, contains('62'));
    });
  });

  group('honestidad y fallback', () {
    test('sin snapshot: no inventa datos', () {
      final reply = NexoraAIEngine(strings: _es).answer('¿cómo está la batería?');
      expect(reply, _es.aiNoData);
    });

    test('pregunta inexplicable deriva a ayuda', () {
      final reply = engine().answer('zzzz qwerty');
      expect(reply, _es.aiHelp);
    });

    test('sugerencias rápidas disponibles', () {
      expect(engine().quickPrompts.length, 5);
    });
  });
}