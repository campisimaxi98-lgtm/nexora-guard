/// Shell de navegación v2 (FASE 11) — barra inferior con 5 pestañas
/// (Inicio · Análisis · Protección · Alertas · Perfil) y chrome superior
/// [NexoraTopBar] (campana con badge + engranaje + refresh).
///
/// Sustituye la `TabBar` superior que tenía la app. Toda la lógica de
/// captura/config sigue viviendo en `main.dart`; este widget solo la
/// presenta distinto. Las pantallas técnicas que no entran en la barra
/// (apps, red, almacenamiento, dispositivo, cercanía, configuración, acerca)
/// se alcanzan por encima vía [legacyTab] — nada se pierde.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/history_store.dart';
import '../../core/auth_store.dart';
import '../../core/models.dart';
import '../../core/notification_feed_store.dart';
import '../../core/subscription.dart';
import '../components.dart';
import '../strings.dart';
import '../theme.dart';
import 'auth.dart';
import 'nexora_alerts.dart';
import 'nexora_bot.dart';
import 'nexora_charts.dart';
import 'nexora_dashboard.dart';
import 'nexora_notifications.dart';
import 'nexora_premium.dart';
import 'nexora_profile.dart';
import 'nexora_protection.dart';
import 'nexora_settings.dart';
import 'nexora_splash.dart';

class NexoraShell extends StatefulWidget {
  const NexoraShell({
    super.key,
    required this.snapshot,
    required this.verdict,
    required this.history,
    required this.strings,
    required this.loading,
    required this.onRefresh,
    required this.onOpenApp,
    required this.legacyTab,
    required this.subscription,
    this.authStore,
    this.pickImage,
    this.onExport,
    this.feed,
    this.onLogout,
  });

  final Snapshot? snapshot;
  final Verdict? verdict;
  final List<HistoryRow> history;
  final AppStrings strings;
  final bool loading;
  final Future<void> Function() onRefresh;
  final void Function(String packageName) onOpenApp;

  /// Construye una pantalla "legada" por id: 'apps' | 'network' | 'history'
  /// | 'device' | 'storage' | 'nearby' | 'settings' | 'about'.
  final Widget Function(String id) legacyTab;

  final NexoraSubscriptionService subscription;

  /// Cuenta local activa (perfil persistente y cambio de contraseña).
  final AuthStore? authStore;

  /// Selector de imagen nativo para el perfil (bytes en memoria).
  final Future<Uint8List?> Function()? pickImage;

  /// Comparte/exporta el snapshot en JSON (botón en el análisis).
  final VoidCallback? onExport;

  /// Centro de notificaciones persistente (FASE 8). Si no hay, la campana
  /// vuelve al comportamiento anterior (abre la pestaña de alertas).
  final NotificationFeedStore? feed;

  /// Cierre de sesión pedido desde Ajustes (lo aplica `main.dart`).
  final VoidCallback? onLogout;

  @override
  State<NexoraShell> createState() => _NexoraShellState();
}

class _NexoraShellState extends State<NexoraShell> {
  int _index = 0;
  bool _showSplash = true;

  void _openLegacy(String id, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: nexoraBackground,
          appBar: AppBar(backgroundColor: nexoraBackground, title: Text(title)),
          body: widget.legacyTab(id),
        ),
      ),
    );
  }

  void _openBot(Snapshot snapshot, Verdict verdict) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NexoraBotScreen(
          strings: widget.strings,
          snapshot: snapshot,
          verdict: verdict,
        ),
      ),
    );
  }

  void _openPremium() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NexoraPremiumScreen(
          strings: widget.strings,
          subscription: widget.subscription,
        ),
      ),
    );
  }

  void _openNotifications() {
    final feed = widget.feed;
    if (feed == null) {
      setState(() => _index = 3);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NexoraNotificationCenterScreen(
          store: feed,
          strings: widget.strings,
        ),
      ),
    );
  }

  void _openChangePassword() {
    final auth = widget.authStore;
    if (auth == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangePasswordScreen(
          strings: widget.strings,
          store: auth,
        ),
      ),
    );
  }

  void _openSettings() {
    final strings = widget.strings;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NexoraSettingsScreen(
          strings: strings,
          accountEmail: widget.authStore?.account?.email,
          planLabel: widget.subscription.isPremium
            ? strings.planProfessional
            : strings.planBasic,
          onOpenChangePassword: widget.authStore == null
              ? null
              : _openChangePassword,
          onLogout: widget.onLogout,
          onOpenNotifications: _openNotifications,
          onOpenApps: () => _openLegacy('apps', strings.tabApps),
          onOpenProtection: () => setState(() => _index = 2),
          onOpenPremium: _openPremium,
          onOpenPrefs: () => _openLegacy('settings', strings.topSettings),
          onOpenAbout: () => _openLegacy('about', strings.tabAbout),
        ),
      ),
    );
  }

  /// Que el Dashboard salte a donde toca dentro de la shell.
  void _openTab(String destination) {
    switch (destination) {
      case 'apps':
        _openLegacy('apps', widget.strings.tabApps);
        break;
      case 'network':
        _openLegacy('network', widget.strings.tabNetwork);
        break;
      case 'device':
        _openLegacy('device', widget.strings.tabDevice);
        break;
      case 'storage':
        _openLegacy('storage', widget.strings.tabStorage);
        break;
      case 'flagged':
        setState(() => _index = 3);
        break;
      default:
        setState(() => _index = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return NexoraSplashScreen(
        onContinue: () {
          final auth = widget.authStore;
          if (auth != null && !auth.loggedIn) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AuthScreen(
                  strings: widget.strings,
                  store: auth,
                  onAuthenticated: () {
                    Navigator.of(context).pop();
                    setState(() => _showSplash = false);
                  },
                ),
              ),
            );
            return;
          }
          setState(() => _showSplash = false);
        },
      );
    }

    final snapshot = widget.snapshot;
    final verdict = widget.verdict;
    final strings = widget.strings;

    if (snapshot == null || verdict == null) {
      return Scaffold(
        backgroundColor: nexoraBackground,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: nexoraGold),
              const SizedBox(height: 14),
              Text(
                strings.loading,
                style: TextStyle(color: Theme.of(context).disabledColor),
              ),
            ],
          ),
        ),
      );
    }

    final pages = <Widget>[
      NexoraDashboardScreen(
        snapshot: snapshot,
        verdict: verdict,
        history: widget.history,
        strings: strings,
        onRefresh: widget.onRefresh,
        onOpenTab: _openTab,
      ),
      NexoraChartsScreen(
        snapshot: snapshot,
        history: widget.history,
        strings: strings,
        onRefresh: widget.onRefresh,
        extraTrailing: widget.onExport == null
            ? null
            : IconButton(
                onPressed: widget.onExport,
                icon: const Icon(Icons.ios_share, size: 20),
                tooltip: strings.actionExport,
              ),
      ),
      NexoraProtectionScreen(
        snapshot: snapshot,
        verdict: verdict,
        strings: strings,
        apps: snapshot.apps,
        onOpenApp: widget.onOpenApp,
      ),
      NexoraAlertsScreen(verdict: verdict, strings: strings),
      NexoraProfileScreen(
        strings: strings,
        subscription: widget.subscription,
        authStore: widget.authStore,
        onOpenLegacy: _openLegacy,
        onRestart: () => setState(() => _showSplash = true),
        snapshot: snapshot,
        verdict: verdict,
        pickImage: widget.pickImage,
        onOpenPremium: _openPremium,
      ),
    ];

    return Scaffold(
      backgroundColor: nexoraBackground,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: NexoraTopBar(
              alertCount: widget.feed?.unreadCount ??
                  verdict.findings.length,
              onOpenAlerts: _openNotifications,
              onOpenSettings: () => _openSettings(),
              onRefresh: widget.onRefresh,
              refreshEnabled: !widget.loading,
              refreshing: widget.loading,
            ),
          ),
          Expanded(child: IndexedStack(index: _index, children: pages)),
        ],
      ),
      floatingActionButton: FloatingAIButton(
        onTap: () => _openBot(snapshot, verdict),
        tooltip: strings.aiTitle,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: nexoraSurface,
          border: Border(top: BorderSide(color: nexoraBorder)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_filled,
                label: strings.tabHome,
                selected: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
              _NavItem(
                icon: Icons.bolt,
                label: strings.tabAnalyze,
                selected: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
              _NavItem(
                icon: Icons.shield_outlined,
                label: strings.tabProtection,
                selected: _index == 2,
                onTap: () => setState(() => _index = 2),
              ),
              _NavItem(
                icon: Icons.notifications_none,
                label: strings.topAlerts,
                selected: _index == 3,
                badge: verdict.findings.isEmpty ? null : verdict.findings.length,
                onTap: () => setState(() => _index = 3),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: strings.tabProfile,
                selected: _index == 4,
                onTap: () => setState(() => _index = 4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: selected ? nexoraGoldLight : Colors.white38,
                  size: 22,
                ),
                if (badge != null)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: nexoraRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                color: selected ? nexoraGoldLight : Colors.white38,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}