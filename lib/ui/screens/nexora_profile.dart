/// "Mi Perfil" (FASE 8) — identidad local de la sesión con diseño v2:
/// avatar (foto real elegida con el selector nativo; se conserva en
/// memoria esta sesión), nombre/seudónimo editables con validación,
/// plan actual, estadísticas de la sesión y accesos a las pantallas
/// técnicas que ya existían (reutilizadas vía [onOpenLegacy]).
///
/// Honestidad: NEXORA GUARD no tiene cuentas en la nube; lo que editas
/// acá es un perfil local de la app, no una cuenta online. La foto se
/// guarda en memoria: no se sube ni se persiste en disco en esta versión.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/subscription.dart';
import '../components.dart';
import '../strings.dart';
import '../theme.dart';

class NexoraProfileScreen extends StatefulWidget {
  const NexoraProfileScreen({
    super.key,
    required this.strings,
    required this.subscription,
    required this.onOpenLegacy,
    required this.onRestart,
    this.snapshot,
    this.verdict,
    this.pickImage,
    this.onOpenPremium,
  });

  final AppStrings strings;

  /// Estado de suscripción de la sesión (no persistido a nivel UI).
  final NexoraSubscriptionService subscription;

  /// Empuja una pantalla técnica por id ('settings' | 'about' | 'device' |
  /// 'storage' | 'nearby').
  final void Function(String id, String title) onOpenLegacy;

  /// Vuelve a la pantalla de bienvenida.
  final VoidCallback onRestart;

  /// Datos reales para las estadísticas de la sesión.
  final Snapshot? snapshot;
  final Verdict? verdict;

  /// Selector de imagen nativo (bytes decodificados); null en pruebas.
  final Future<Uint8List?> Function()? pickImage;

  /// Empuja la pantalla de suscripción premium.
  final VoidCallback? onOpenPremium;

  @override
  State<NexoraProfileScreen> createState() => _NexoraProfileScreenState();
}

class _NexoraProfileScreenState extends State<NexoraProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _username;
  Uint8List? _photoBytes;
  String? _nameError;
  String? _usernameError;
  String? _photoNote;
  bool _photoPicking = false;

  static final _usernameRe = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9._-]{2,19}$');

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: 'Maximiliano');
    _username = TextEditingController(text: 'maxi_g');
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = widget.pickImage;
    if (picker == null) return;
    setState(() => _photoPicking = true);
    final bytes = await picker();
    if (!mounted) return;
    setState(() {
      _photoPicking = false;
      if (bytes != null) {
        _photoBytes = bytes;
        _photoNote = widget.strings.profilePhotoKeep;
      }
    });
  }

  void _save() {
    final name = _name.text.trim();
    final username = _username.text.trim();
    setState(() {
      _nameError = name.isEmpty ? widget.strings.profileNameValidation : null;
      _usernameError =
          _usernameRe.hasMatch(username) ? null : widget.strings.profileUsernameValidation;
    });
    if (_nameError != null || _usernameError != null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.strings.profileSave)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final premium = widget.subscription;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(ntPad),
        children: [
          SectionHeaderRow(
            icon: Icons.person_outline,
            title: strings.profileTitle,
          ),
          const SizedBox(height: ntPadSmall),

          // ── Identidad + foto ──────────────────────────────────────────
          NexoraCard(
            glow: true,
            child: Column(
              children: [
                Row(
                  children: [
                    _Avatar(
                      bytes: _photoBytes,
                      picking: _photoPicking,
                      onTap: _photoBytes == null && widget.pickImage != null
                          ? _pickPhoto
                          : null,
                    ),
                    const SizedBox(width: ntPad),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _name.text.trim().isEmpty
                                ? MetaName.fallback
                                : _name.text.trim(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '@${_username.text.trim().isEmpty ? 'usuario' : _username.text.trim()}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _PlanBadge(
                            isPremium: premium.isPremium,
                            colors: context,
                            label: premium.isPremium
                                ? strings.planPremium
                                : strings.planBasic,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_photoBytes != null ||
                    (_photoNote != null && widget.pickImage != null)) ...[
                  const SizedBox(height: ntGapSmall),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _photoNote ?? strings.profilePhotoHint,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: ntGapSmall),
                if (widget.pickImage != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _photoBytes == null ? _pickPhoto : null,
                        icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                        label: Text(strings.profilePhotoPick),
                      ),
                      TextButton.icon(
                        onPressed: _photoBytes == null
                            ? null
                            : () => setState(() => _photoBytes = null),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: Text(strings.profilePhotoRemove),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: ntGapSmall),

          // ── Nombre y usuario editables ────────────────────────────────
          NexoraCard(
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: strings.profileName,
                    hintText: strings.profileNameHint,
                    errorText: _nameError,
                    prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _username,
                  decoration: InputDecoration(
                    labelText: strings.profileUsername,
                    hintText: strings.profileUsernameHint,
                    errorText: _usernameError,
                    prefixIcon: const Icon(Icons.alternate_email, size: 18),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(strings.profileSave),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ntGapSmall),

          // ── Premium ──────────────────────────────────────────────────
          if (widget.onOpenPremium != null)
            Padding(
              padding: const EdgeInsets.only(bottom: ntGapSmall),
              child: PremiumLockedCard(
                title: premium.isPremium
                    ? strings.premiumTitle
                    : strings.premiumCtaStart,
                description: premium.isPremium
                    ? strings.premiumAlready
                    : strings.premiumTagline,
                ctaLabel: strings.premiumSee,
                onViewPremium: widget.onOpenPremium!,
              ),
            ),

          // ── Estadísticas de la sesión ────────────────────────────────
          _StatsSection(
            snapshot: widget.snapshot,
            verdict: widget.verdict,
            strings: strings,
          ),
          const SizedBox(height: ntGapSmall),

          // ── Accesos técnicos (pantallas ya existentes) ───────────────
          NexoraCard(
            child: Column(
              children: [
                for (final item in _legacyItems(context, strings)) ...[
                  ListTile(
                    dense: true,
                    leading: Icon(item.icon, color: nexoraGoldLight, size: 20),
                    title: Text(item.label, style: const TextStyle(fontSize: 14)),
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: nexoraBorder,
                    ),
                    onTap: item.onTap,
                  ),
                  if (item != _legacyItems(context, strings).last)
                    const Divider(height: 1, color: nexoraBorder),
                ],
              ],
            ),
          ),
          const SizedBox(height: ntPad),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: nexoraRed,
                side: const BorderSide(color: nexoraWine, width: 1.4),
              ),
              onPressed: widget.onRestart,
              icon: const Icon(Icons.home_outlined, size: 18),
              label: Text(strings.profileBackHome),
            ),
          ),
        ],
      ),
    );
  }

  List<_LegacyItem> _legacyItems(BuildContext context, AppStrings strings) => [
    _LegacyItem(
      Icons.phone_android,
      strings.deviceTitle,
      () => widget.onOpenLegacy('device', strings.deviceTitle),
    ),
    _LegacyItem(
      Icons.sd_storage_outlined,
      strings.tabStorage,
      () => widget.onOpenLegacy('storage', strings.tabStorage),
    ),
    _LegacyItem(
      Icons.bluetooth_searching,
      strings.tabNearby,
      () => widget.onOpenLegacy('nearby', strings.tabNearby),
    ),
    _LegacyItem(
      Icons.settings_outlined,
      strings.tabSettings,
      () => widget.onOpenLegacy('settings', strings.tabSettings),
    ),
    _LegacyItem(
      Icons.info_outline,
      strings.tabAbout,
      () => widget.onOpenLegacy('about', strings.tabAbout),
    ),
  ];
}

class MetaName {
  static const String fallback = 'NEXORA';
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.bytes,
    required this.picking,
    required this.onTap,
  });

  final Uint8List? bytes;
  final bool picking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: picking ? null : onTap,
    borderRadius: BorderRadius.circular(ntRadiusCard),
    child: Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [nexoraGoldLight, nexoraGold, nexoraBlue],
        ),
        border: Border.all(color: nexoraGold.withValues(alpha: 0.5)),
      ),
      child: picking
          ? const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: nexoraBackground,
              ),
            )
          : bytes != null
          ? ClipOval(child: Image.memory(bytes!, width: 64, height: 64, fit: BoxFit.cover))
          : const Icon(Icons.person, color: nexoraBackground, size: 34),
    ),
  );
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({
    required this.isPremium,
    required this.label,
    required this.colors,
  });

  final bool isPremium;
  final String label;
  final BuildContext colors;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: isPremium
          ? nexoraGold.withValues(alpha: 0.2)
          : nexoraSurfaceRaised,
      borderRadius: BorderRadius.circular(ntRadiusPill),
      border: Border.all(
        color: isPremium ? nexoraGold : nexoraBorder,
      ),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: isPremium ? nexoraGoldLight : Theme.of(colors).disabledColor,
      ),
    ),
  );
}

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.snapshot,
    required this.verdict,
    required this.strings,
  });

  final Snapshot? snapshot;
  final Verdict? verdict;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final apps = snapshot?.apps.length;
    final signals = verdict?.findings.length;
    final last = snapshot?.timestampMillis;
    if (apps == null || signals == null) return const SizedBox.shrink();

    String? when() {
      if (last == null) return null;
      final diff = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(last),
      );
      if (diff.inMinutes < 1) return '${diff.inSeconds}s';
      if (diff.inHours < 1) return '${diff.inMinutes}min';
      return '${diff.inHours}h';
    }

    final w = when();
    return NexoraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeaderRow(
            icon: Icons.query_stats,
            title: strings.profileStatsTitle,
          ),
          const SizedBox(height: ntGapSmall),
          ValueRow(
            icon: Icons.apps,
            label: strings.profileStatsApps,
            value: '$apps',
            color: nexoraBlue,
          ),
          const SizedBox(height: 6),
          ValueRow(
            icon: Icons.flag_outlined,
            label: strings.profileStatsSignals,
            value: '$signals',
            color: signals > 0 ? nexoraRed : severityGreen,
          ),
          const SizedBox(height: 6),
          if (w != null)
            ValueRow(
              icon: Icons.schedule,
              label: strings.profileStatsLastSnapshot,
              value: w,
              color: nexoraGoldLight,
            ),
        ],
      ),
    );
  }
}

class _LegacyItem {
  const _LegacyItem(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}