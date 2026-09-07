import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_guard/core/auth_store.dart';
import 'package:nexora_guard/main.dart';
import 'package:nexora_guard/ui/screens/nexora_settings.dart';
import 'package:nexora_guard/ui/screens/settings.dart';

/// Crea un AuthStore con sesión ya abierta sobre un directorio temporal.
/// Toda la API del store es síncrona: no hace falta runAsync en testWidgets.
AuthStore loggedInStore() {
  final dir = Directory.systemTemp.createTempSync('nexora-widget-auth');
  final store = AuthStore(dir)
    ..load()
    ..register('tester@nexora.dev', 'Secret1@2026');
  addTearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });
  return store;
}

/// Snapshot "típico" que devolvería el colector nativo: la misma forma de
/// mapa que documenta docs/ARCHITECTURE.md y que parsea `Snapshot`.
Map<Object?, Object?> nativeSnapshotMap() => {
  'memory': {
    'totalBytes': 8 * 1024 * 1024 * 1024,
    'availableBytes': 4 * 1024 * 1024 * 1024,
    'lowMemory': false,
  },
  'storage': {
    'totalBytes': 128 * 1024 * 1024 * 1024,
    'freeBytes': 64 * 1024 * 1024 * 1024,
    'appCacheBytes': 2048,
  },
  'battery': {
    'levelPercent': 80,
    'charging': false,
    'temperatureCelsius': 30.0,
    'temperatureAvailable': true,
    'voltageMillivolts': 4000,
    'healthy': true,
    'healthLabel': 'good',
  },
  'network': {
    'connected': true,
    'transport': 'wifi',
    'vpnActive': false,
    'metered': false,
    'downstreamKbps': 10000,
    'upstreamKbps': 5000,
    'totalRxBytes': 1000,
    'totalTxBytes': 500,
  },
  'apps': <Object?>[
    {
      'packageName': 'com.example.gallery',
      'label': 'Gallery',
      'versionName': '2.1',
      'dangerousPermissions': ['READ_MEDIA_IMAGES'],
      'grantedPermissions': ['READ_MEDIA_IMAGES'],
      'specialFlags': <String>[],
      'sideloaded': false,
      'rxBytes24h': 250 * 1024,
      'txBytes24h': 60 * 1024,
      'foregroundMillis24h': 15 * 60 * 1000,
    },
  ],
  'device': {
    'manufacturer': 'Test',
    'model': 'Unit',
    'osVersion': '14',
    'sdkInt': 34,
    'securityPatch': '2026-06-01',
    'cpuCores': 8,
    'uptimeMillis': 3600000,
    'rootIndicators': <String>[],
    'appsAuditSupported': true,
  },
};

/// Registra un mock del canal `nexora/collectors` que devuelve un snapshot
/// realista. `documentsPath` responde `null` (como en un entorno sin
/// nativo): la captura no hace I/O de archivos, que en FakeAsync no
/// completaría, y el flujo llega directo a la shell v2.
void installSnappyNative(WidgetTester tester) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('nexora/collectors'),
    (call) async {
      switch (call.method) {
        case 'collect':
          return nativeSnapshotMap();
        case 'refreshWidget':
        case 'requestNotificationPermissions':
        case 'requestBlePermissions':
          return null;
        case 'documentsPath':
        case 'clearOwnCache':
          return null;
        case 'notifyCritical':
        case 'shareFile':
        case 'openSystemScreen':
        case 'configureBackgroundCapture':
          return true;
        default:
          return null;
      }
    },
  );
}

/// Entra a la shell v2 desde el splash de la marca (el botón "COMENZAR" y
/// la navegación por íconos no dependen del idioma elegido).
Future<void> enterApp(WidgetTester tester, AuthStore store) async {
  await tester.pumpWidget(NexoraApp(authStore: store));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(find.text('COMENZAR'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  testWidgets(
    'sin canal nativo arranca, muestra la marca y degrada sin crashear',
    (tester) async {
      // Sin mock: en el entorno de test no hay handler del canal. La app no
      // debe crashear: el splash de la marca aparece y la captura queda en
      // estado de carga (espacio para el nativo) en vez de tumbar la UI.
      await tester.pumpWidget(NexoraApp(authStore: loggedInStore()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('NEXORA'), findsOneWidget);
      expect(find.text('COMENZAR'), findsOneWidget);

      await tester.tap(find.text('COMENZAR'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // Sin respuesta del canal: estado de carga controlado, sin crash.
      expect(
        tester.takeException(),
        isNull,
        reason: 'La captura sin nativo no debe producir errores visibles.',
      );
    },
  );

  testWidgets('la shell v2 arranca completa con el canal nativo simulado', (
    tester,
  ) async {
    installSnappyNative(tester);
    await enterApp(tester, loggedInStore());

    // Chrome de la shell v2: barra superior + barra inferior con las 5
    // pestañas + el botón flotante de Nexora AI (algunos íconos también
    // aparecen en el contenido del Dashboard, por eso ≥1).
    expect(find.text('NEXORA'), findsOneWidget);
    expect(find.byIcon(Icons.home_filled), findsWidgets);
    expect(find.byIcon(Icons.bolt), findsWidgets);
    expect(find.byIcon(Icons.shield_outlined), findsWidgets);
    expect(find.byIcon(Icons.notifications_none), findsWidgets);
    expect(find.byIcon(Icons.person_outline), findsWidgets);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    // Idioma automático: el entorno de test corre en en_US.
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('la barra inferior navega entre las 5 pestañas de la shell', (
    tester,
  ) async {
    installSnappyNative(tester);
    await enterApp(tester, loggedInStore());

    IndexedStack stack() =>
        tester.widget<IndexedStack>(find.byType(IndexedStack));
    expect(stack().index, 0);

    // Los íconos de la barra inferior son los ÚLTIMOS del árbol (el contenido
    // puede reusar el mismo ícono): se tocan con `.last`.
    Future<void> goTo(IconData icon) async {
      await tester.tap(find.byIcon(icon).last, warnIfMissed: false);
      await tester.pump();
    }

    // Charts.
    await goTo(Icons.bolt);
    expect(stack().index, 1);

    // Protección.
    await goTo(Icons.shield_outlined);
    expect(stack().index, 2);

    // Alertas.
    await goTo(Icons.notifications_none);
    expect(stack().index, 3);

    // Perfil.
    await goTo(Icons.person_outline);
    expect(stack().index, 4);

    // De vuelta al Inicio.
    await goTo(Icons.home_filled);
    expect(stack().index, 0);
  });

  testWidgets('autodetecta el idioma y Configuración permite cambiarlo', (
    tester,
  ) async {
    installSnappyNative(tester);
    await enterApp(tester, loggedInStore());

    // Idioma automático: en_US. La pestaña Inicio se llama "Home".
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Inicio'), findsNothing);

    // El cambio de idioma vive en Configuración: el engranaje abre el
    // Ajustes organizado por grupos (Cuenta/Seguridad/Aplicación) y
    // 'Preferences' conduce a la pantalla técnica con el selector.
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(NexoraSettingsScreen), findsOneWidget);

    // La fila 'Preferences' está bajo el pliegue del Ajustes por grupos:
    // se baja hasta ella antes de tocar.
    final settingsScrollable = find.descendant(
      of: find.byType(NexoraSettingsScreen),
      matching: find.byType(Scrollable),
    );
    expect(settingsScrollable, findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Preferences'),
      200,
      scrollable: settingsScrollable.first,
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Preferences'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // La sección de idioma puede estar bajo el pliegue: se baja hasta ella.
    final scrollable = find.descendant(
      of: find.byType(SettingsScreen),
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Español'),
      200,
      scrollable: scrollable.first,
    );
    await tester.pump(const Duration(milliseconds: 100));

    final spanish = find.widgetWithText(ChoiceChip, 'Español');
    expect(spanish, findsOneWidget);
    await tester.tap(spanish, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Volver al Inicio: se retrocede cada pantalla intermedia (Configuración
    // técnica y Ajustes) hasta que no queden rutas por deshacer.
    for (var i = 0; i < 6; i++) {
      final back = find.byTooltip('Back');
      if (back.evaluate().isEmpty) break;
      await tester.tap(back.first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('Inicio'), findsWidgets);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('sin sesión abierta muestra la puerta de cuenta local', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('nexora-auth-gate');
    final store = AuthStore(dir)..load();
    addTearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    await tester.pumpWidget(NexoraApp(authStore: store));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    // pumps acotados (los anillos del planeta animan en bucle continuo).

    // La PORTADA con el planeta es la puerta de entrada sin sesión.
    expect(find.text('NEXORA'), findsOneWidget);
    expect(find.text('S E C U R I T Y'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
    // La app todavía NO está visible detrás de la puerta.
    expect(find.byIcon(Icons.home_filled), findsNothing);

    // Ir a crear cuenta desde la portada.
    await tester.tap(find.text('Create account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('G U A R D'), findsOneWidget);

    // Crear la cuenta desde la UI (con perfil, recordándola y aceptando
    // los términos) abre la app (operación síncrona local).
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Username').first,
      'nuevo_user',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email address').first,
      'nuevo@nexora.dev',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password').first,
      'Secret1@2026',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Repeat password').first,
      'Secret1@2026',
    );
    final termsCheckbox = find.byType(Checkbox).first;
    await tester.ensureVisible(termsCheckbox);
    await tester.pump();
    await tester.tap(termsCheckbox, warnIfMissed: false);
    await tester.pump();
    // FASE 8: la verificación humana es obligatoria de verdad para crear la
    // cuenta (el segundo checkbox del formulario de registro).
    final humanCheckbox = find.byType(Checkbox).last;
    await tester.ensureVisible(humanCheckbox);
    await tester.pump();
    await tester.tap(humanCheckbox, warnIfMissed: false);
    await tester.pump();
    final createButton = find.widgetWithText(FilledButton, 'Create my account');
    await tester.ensureVisible(createButton);
    await tester.pump();
    await tester.tap(createButton, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // La cuenta recién creada entra al splash de la marca de la shell v2.
    expect(find.text('COMENZAR'), findsOneWidget);
  });

  testWidgets(
    'con cuenta existente el modo inicial es iniciar sesión, y volver a entrar funciona',
    (tester) async {
      final store = loggedInStore();
      // Cerrar la sesión manualmente: queda cuenta pero sin sesión abierta.
      store.logout();

      await tester.pumpWidget(NexoraApp(authStore: store));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // La portada muestra "Sign in" sin estar todavía en la pantalla de
      // cuenta (que tendría el botón "Enter").
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Enter'), findsNothing);

      // Entrar a iniciar sesión desde la portada.
      await tester.tap(find.text('Sign in'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.text('Enter'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email address').first,
        'tester@nexora.dev',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password').first,
        'Secret1@2026',
      );
      final enterButton = find.widgetWithText(FilledButton, 'Enter');
      await tester.ensureVisible(enterButton);
      await tester.pump();
      await tester.tap(enterButton, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Sesión restablecida → splash de la marca de la shell v2.
      expect(find.text('COMENZAR'), findsOneWidget);
    },
  );
}