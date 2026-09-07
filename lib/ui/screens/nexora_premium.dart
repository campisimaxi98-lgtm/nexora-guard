/// NEXORA PREMIUM (FASE 10) — pantalla de suscripción honesta.
///
/// Sine mock: si el proveedor de pagos no está configurado
/// ([UnconfiguredPaymentsProvider]), el botón de compra abre un diálogo que
/// dice "próximamente" — JAMÁS simula una compra. La restauración tampoco
/// inventa nada: si no hay compra previa lo informa de verdad.
library;

import 'package:flutter/material.dart';

import '../../core/subscription.dart';
import '../components.dart';
import '../nexora_logo.dart';
import '../strings.dart';
import '../theme.dart';

class NexoraPremiumScreen extends StatefulWidget {
  const NexoraPremiumScreen({
    super.key,
    required this.strings,
    required this.subscription,
  });

  final AppStrings strings;
  final NexoraSubscriptionService subscription;

  @override
  State<NexoraPremiumScreen> createState() => _NexoraPremiumScreenState();
}

class _NexoraPremiumScreenState extends State<NexoraPremiumScreen> {
  bool _busy = false;

  Future<void> _startPremium() async {
    if (_busy) return;
    final active = widget.subscription.isPremium;
    if (active) return;
    setState(() => _busy = true);
    try {
      final result = await widget.subscription.startPremium();
      if (!mounted) return;
      setState(() => _busy = false);
      if (result.isPremium) {
        _ok(widget.strings.premiumAlready);
      } else {
        _comingSoon();
      }
    } on PaymentsUnavailable {
      if (!mounted) return;
      setState(() => _busy = false);
      _comingSoon();
    } on Object {
      if (!mounted) return;
      setState(() => _busy = false);
      _comingSoon();
    }
  }

  Future<void> _restore() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await widget.subscription.restore();
      if (!mounted) return;
      setState(() => _busy = false);
      if (result.isPremium) {
        _ok(
          widget.strings.premiumRestoredOk(
            result.provider ?? widget.subscription.provider.runtimeType.toString(),
          ),
        );
      } else {
        _ok(widget.strings.premiumNotPurchased);
      }
    } on Object {
      if (!mounted) return;
      setState(() => _busy = false);
      _ok(widget.strings.premiumNotPurchased);
    }
  }

  void _comingSoon() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: nexoraSurface,
        title: Row(
          children: [
            const Icon(Icons.schedule, color: nexoraGoldLight, size: 22),
            const SizedBox(width: 8),
            Text(widget.strings.premiumComingSoon),
          ],
        ),
        content: Text(widget.strings.premiumUnavailable),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(widget.strings.confirm),
          ),
        ],
      ),
    );
  }

  void _ok(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final active = widget.subscription.isPremium;
    return Scaffold(
      backgroundColor: nexoraBackground,
      appBar: AppBar(
        backgroundColor: nexoraSurface,
        title: Text(strings.premiumTitle, style: const TextStyle(fontSize: 16)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(ntPad),
          children: [
            NexoraCard(
              glow: true,
              padding: const EdgeInsets.all(ntPad),
              child: Column(
                children: [
                  const NexoraLogo(size: 54, showRing: false),
                  const SizedBox(height: ntGapSmall),
                  Text(
                    active ? strings.planProfessional : strings.premiumTagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: active ? nexoraGoldLight : Colors.white,
                    ),
                  ),
                  const SizedBox(height: ntGapSmall),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        strings.premiumPriceArs,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: nexoraGoldLight,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        strings.premiumPerMonth,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: ntGapSmall),
                  _PlanBadge2(
                    label: active ? strings.planProfessional : strings.planBasic,
                    active: active,
                  ),
                ],
              ),
            ),
            const SizedBox(height: ntGapSmall),

            if (active)
              _InfoBanner(
                icon: Icons.verified_user,
                color: severityGreen,
                text: strings.premiumAlready,
              )
            else ...[
              _InfoBanner(
                icon: Icons.schedule,
                color: nexoraOrange,
                text: '${strings.premiumComingSoon}. ${strings.premiumUnavailable}',
              ),
              const SizedBox(height: ntGapSmall),
            ],

            NexoraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.premiumFeaturesTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: ntGapSmall),
                  _Feature(icon: Icons.show_chart, text: strings.premiumFeature1),
                  _Feature(icon: Icons.auto_awesome, text: strings.premiumFeature2),
                  _Feature(icon: Icons.compare_arrows, text: strings.premiumFeature3),
                  _Feature(icon: Icons.warning_amber, text: strings.premiumFeature4),
                ],
              ),
            ),
            const SizedBox(height: ntPad),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: active ? nexoraGold : nexoraGoldLight,
                  foregroundColor: nexoraBackground,
                ),
                onPressed: _busy ? null : _startPremium,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: nexoraBackground,
                        ),
                      )
                    : const Icon(Icons.workspace_premium, size: 20),
                label: Text(
                  active ? strings.premiumSee : strings.premiumCtaStart,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _busy ? null : _restore,
              icon: const Icon(Icons.restore, size: 18),
              label: Text(strings.premiumRestore),
            ),
            const SizedBox(height: ntPadSmall),
            Text(
              strings.premiumUnavailable,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanBadge2 extends StatelessWidget {
  const _PlanBadge2({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: active ? nexoraGold.withValues(alpha: 0.2) : nexoraSurfaceRaised,
      borderRadius: BorderRadius.circular(ntRadiusPill),
      border: Border.all(color: active ? nexoraGold : nexoraBorder),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: active
            ? nexoraGoldLight
            : Theme.of(context).disabledColor.withValues(alpha: 0.9),
      ),
    ),
  );
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(ntPadSmall),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(ntRadiusCard),
      border: Border.all(color: color.withValues(alpha: 0.45)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: ntGapSmall),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12.5)),
        ),
      ],
    ),
  );
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: nexoraGoldLight, size: 18),
        const SizedBox(width: ntGapSmall),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    ),
  );
}