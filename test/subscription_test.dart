import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexora_guard/core/subscription.dart';

class FakeProvider implements PaymentsProvider {
  FakeProvider({this.configured = true});
  final bool configured;
  NexoraSubscription? nextResult;

  @override
  Future<bool> isConfigured() async => configured;

  @override
  Future<NexoraSubscription> purchase(NexoraPlan plan) async {
    if (!configured) throw const PaymentsUnavailable();
    return nextResult ??
        NexoraSubscription(
          plan: plan,
          status: SubscriptionStatus.active,
          startedAtMillis: 1000,
          renewalAtMillis: 1000 + 30 * 24 * 3600 * 1000,
          provider: 'fake',
        );
  }

  @override
  Future<NexoraSubscription> restore() async =>
      nextResult ?? NexoraSubscription.none;
}

void main() {
  group('precios configurables', () {
    test('plan premium \$10.000 ARS/mes (constante de producto)', () {
      expect(nexoraPremiumPriceArs, 10000);
      expect(nexoraPremiumPriceUsd, greaterThan(0));
    });
  });

  group('NexoraSubscriptionService', () {
    test('sin proveedor configurado: básico, sin gating premium', () {
      final service = NexoraSubscriptionService();
      expect(service.isPremium, isFalse);
      expect(service.current.status, SubscriptionStatus.none);
    });

    test('UnconfiguredPaymentsProvider es honesto', () async {
      const provider = UnconfiguredPaymentsProvider();
      expect(await provider.isConfigured(), isFalse);
      expect(() => provider.purchase(NexoraPlan.premium),
          throwsA(isA<PaymentsUnavailable>()));
      final restored = await provider.restore();
      expect(restored.isActive, isFalse);
    });

    test('compra con proveedor real activa premium y persiste', () async {
      final dir = Directory.systemTemp.createTempSync('nexora-sub');
      final service = NexoraSubscriptionService(
        provider: FakeProvider(),
        directoryPath: dir.path,
      );
      final result = await service.startPremium();
      expect(result.isPremium, isTrue);
      expect(service.isPremium, isTrue);

      // Un servicio NUEVO sobre el mismo directorio recupera el estado.
      final reloaded = NexoraSubscriptionService(
        provider: FakeProvider(),
        directoryPath: dir.path,
      );
      expect(reloaded.isPremium, isTrue);
      expect(reloaded.current.provider, 'fake');
    });

    test('degradación: archivo corrupto no rompe el servicio', () async {
      final dir = Directory.systemTemp.createTempSync('nexora-sub-corrupt');
      File('${dir.path}/nexora-subscription.json').writeAsStringSync('{nope');
      final service = NexoraSubscriptionService(directoryPath: dir.path);
      expect(service.isPremium, isFalse);
    });

    test('puedo canjear el estado que reporta el proveedor', () async {
      final service = NexoraSubscriptionService();
      await service.apply(
        const NexoraSubscription(
          plan: NexoraPlan.premium,
          status: SubscriptionStatus.active,
          provider: 'server',
        ),
      );
      expect(service.isPremium, isTrue);
    });
  });
}