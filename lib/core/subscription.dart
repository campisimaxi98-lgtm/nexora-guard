/// Sistema de suscripción Básico/Premium listo para producción — arquitectura
/// separada de la UI, con frontera clara hacia el proveedor de pagos.
///
/// Reglas de honestidad:
/// - La app NUNCA toca datos de tarjeta: la frontera es [PaymentsProvider].
/// - Mientras no haya proveedor conectado, [UnconfiguredPaymentsProvider]
///   devuelve "no configurado" y la UI muestra la compra como próxima — está
///   PROHIBIDO simular una compra que no ocurrió.
/// - El estado se persiste localmente (json) para que el gating sea estable
///   entre sesiones; la fuente de verdad real la valida el proveedor.
library;

import 'dart:convert';
import 'dart:io';

/// Planes comercializables. [NexoraPlan.premium] es lo que se vende con
/// gating; el básico es siempre gratuito.
enum NexoraPlan { basic, premium }

/// Estado observado de una suscripción.
enum SubscriptionStatus { none, active }

/// Precio de referencia del plan premium, configurable (se muestra en la
/// pantalla de suscripción y se usa para cotizar el proveedor de pagos).
const nexoraPremiumPriceArs = 10000; // $10.000 ARS / mes (mercado local)
const nexoraPremiumPriceUsd = 9.99; // Referencia internacional (Play/App Store)

class NexoraSubscription {
  const NexoraSubscription({
    required this.plan,
    required this.status,
    this.startedAtMillis,
    this.renewalAtMillis,
    this.provider,
  });

  factory NexoraSubscription.fromMap(Map<String, Object?> map) =>
      NexoraSubscription(
        plan: map['plan'] == 'premium'
            ? NexoraPlan.premium
            : NexoraPlan.basic,
        status: map['status'] == 'active'
            ? SubscriptionStatus.active
            : SubscriptionStatus.none,
        startedAtMillis: map['startedAtMillis'] is num
            ? (map['startedAtMillis'] as num).toInt()
            : null,
        renewalAtMillis: map['renewalAtMillis'] is num
            ? (map['renewalAtMillis'] as num).toInt()
            : null,
        provider: map['provider'] is String ? map['provider'] as String : null,
      );

  final NexoraPlan plan;
  final SubscriptionStatus status;
  final int? startedAtMillis;
  final int? renewalAtMillis;

  /// Nombre del proveedor que la otorgó (para mostrarla transparente).
  final String? provider;

  bool get isActive => status == SubscriptionStatus.active;
  bool get isPremium => plan == NexoraPlan.premium && isActive;

  static const none = NexoraSubscription(
    plan: NexoraPlan.basic,
    status: SubscriptionStatus.none,
  );

  Map<String, Object?> toMap() => {
    'plan': plan.name,
    'status': status.name,
    if (startedAtMillis != null) 'startedAtMillis': startedAtMillis,
    if (renewalAtMillis != null) 'renewalAtMillis': renewalAtMillis,
    if (provider != null) 'provider': provider,
  };
}

/// Frontera hacia el proveedor de pagos real (Google Play Billing,
/// RevenueCat, backend propio…). Un futuro provider implementa esta
/// interfaz sin tocar la UI ni el servicio.
abstract class PaymentsProvider {
  /// `true` si hay un proveedor real conectado y operativo.
  Future<bool> isConfigured();

  /// Inicia la compra del plan. Lanza [PaymentsUnavailable] si el
  /// proveedor no está configurado.
  Future<NexoraSubscription> purchase(NexoraPlan plan);

  /// Restaura una compra previa (Play/App Store lo exigen).
  Future<NexoraSubscription> restore();
}

class PaymentsUnavailable implements Exception {
  const PaymentsUnavailable();
  @override
  String toString() => 'Payments provider is not configured yet.';
}

/// Proveedor por defecto: honesto. Compra/restauración devuelven plan básico
/// y `isConfigured() == false` — la UI muestra "próximamente".
class UnconfiguredPaymentsProvider implements PaymentsProvider {
  const UnconfiguredPaymentsProvider();

  @override
  Future<bool> isConfigured() async => false;

  @override
  Future<NexoraSubscription> purchase(NexoraPlan plan) async {
    throw const PaymentsUnavailable();
  }

  @override
  Future<NexoraSubscription> restore() async => NexoraSubscription.none;
}

/// Estado de suscripción de la sesión. Mismo patrón de los demás stores del
/// proyecto (clase simple, la UI hace `setState` después de operaciones
/// await) — sin dependencias de Flutter para testearlo con dart puro.
class NexoraSubscriptionService {
  NexoraSubscriptionService({PaymentsProvider? provider, this.directoryPath})
      : _provider = provider ?? const UnconfiguredPaymentsProvider() {
    if (directoryPath != null) _load();
  }

  final PaymentsProvider _provider;

  /// Directorio de persistencia local (json); null = sesión en memoria.
  final String? directoryPath;

  NexoraSubscription _current = NexoraSubscription.none;

  PaymentsProvider get provider => _provider;
  NexoraSubscription get current => _current;
  bool get isPremium => _current.isPremium;

  File get _file => File('${directoryPath!}/nexora-subscription.json');

  void _load() {
    try {
      final file = _file;
      if (file.existsSync()) {
        final decoded = jsonDecode(file.readAsStringSync());
        if (decoded is Map<String, Object?>) {
          _current = NexoraSubscription.fromMap(decoded);
        }
      }
    } on Object {
      // Estado corrupto: se opera como básico; la UI no debe crashear.
      _current = NexoraSubscription.none;
    }
  }

  Future<void> _persist(NexoraSubscription value) async {
    _current = value;
    final dir = directoryPath;
    if (dir == null) return;
    try {
      final file = File('$dir/nexora-subscription.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(value.toMap()), flush: true);
    } on FileSystemException {
      // Sin persistencia el gating sigue valiendo en esta sesión.
    }
  }

  /// Intenta comprar premium. Si el proveedor no está configurado lanza
  /// [PaymentsUnavailable] — la UI lo traduce a "próximamente", jamás a
  /// "compra exitosa".
  Future<NexoraSubscription> startPremium() async {
    final result = await _provider.purchase(NexoraPlan.premium);
    await _persist(result);
    return result;
  }

  Future<NexoraSubscription> restore() async {
    final result = await _provider.restore();
    await _persist(result);
    return result;
  }

  /// Aplica el estado que el proveedor reporta (p. ej. al vencerse).
  Future<void> apply(NexoraSubscription next) => _persist(next);
}