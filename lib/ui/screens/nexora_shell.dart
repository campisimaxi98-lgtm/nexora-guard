/// Shell de navegación con barra inferior (Inicio · Análisis · Protección
/// · Alertas · Perfil), igual al mockup de referencia. Reemplaza la
/// `TabBar` superior que tenía la app; toda la lógica de captura/config
/// sigue viviendo en `main.dart` — este widget solo la presenta distinto.
///
/// Las pantallas "avanzadas" que no entran en la barra de 5 ítems (apps,
/// red, historial técnico, almacenamiento, dispositivo, cercanía,
/// configuración, acerca de) siguen existiendo tal cual estaban: se
/// alcanzan empujándolas por encima con [legacyTab], que en `main.dart`
/// apunta al mismo `_tabView` de siempre. No se perdió ninguna pantalla.
library;

import 'package:flutter/material.dart';

import '../../core/history_store.dart';
import '../../core/models.dart';
import '../strings.dart';
import '../theme.dart';
import 'nexora_alerts.dart';
import 'nexora_apps_analysis.dart';
import 'nexora_dashboard.dart';
import 'nexora_profile.dart';
import 'nexora_protection.dart';
import 'nexora_quickscan.dart';
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
  });

  final Snapshot? snapshot;
  final Verdict? verdict;
  final List<dynamic> history; // List<HistoryRow>
  final AppStrings strings;
  final bool loading;
  final Future<void> Function() onRefresh;
  final void Function(String packageName) onOpenApp;

  /// Construye una pantalla "legada" por id: 'apps' | 'network' | 'history'
  /// | 'device' | 'storage' | 'nearby' | 'settings' | 'about'.
  final Widget Function(String id) legacyTab;

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

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return NexoraSplashScreen(
        onContinue: () => setState(() => _showSplash = false),
      );
    }

    final snapshot = widget.snapshot;
    final verdict = widget.verdict;

    if (snapshot == null || verdict == null) {
      return const Scaffold(
        backgroundColor: nexoraBackground,
        body: Center(child: CircularProgressIndicator(color: nexoraGold)),
      );
    }

    final pages = <Widget>[
      NexoraDashboardScreen(
        snapshot: snapshot,
        verdict: verdict,
        history: widget.history.map((h) => h as HistoryRow).toList(),
        strings: widget.strings,
        onRefresh: widget.onRefresh,
        onOpenTab: (_) => setState(() => _index = 0),
      ),
      NexoraQuickScanScreen(
        snapshot: snapshot,
        verdict: verdict,
        loading: widget.loading,
        onRefresh: widget.onRefresh,
      ),
      NexoraProtectionScreen(
        snapshot: snapshot,
        verdict: verdict,
        strings: widget.strings,
      ),
      NexoraAlertsScreen(verdict: verdict, strings: widget.strings),
      NexoraProfileScreen(
        onOpenLegacy: _openLegacy,
        onRestart: () => setState(() => _showSplash = true),
      ),
    ];

    // La pestaña de Análisis de Apps vive fuera de la lista fija de arriba
    // porque necesita `onOpenApp`; se muestra empujada desde el acceso
    // rápido del Dashboard/las Alertas en vez de ocupar un 6º ítem de la
    // barra (el diseño de referencia usa 5).
    return Scaffold(
      backgroundColor: nexoraBackground,
      body: IndexedStack(index: _index, children: pages),
      floatingActionButton: _index == 0
          ? null
          : FloatingActionButton.small(
              backgroundColor: nexoraGold,
              foregroundColor: nexoraBackground,
              tooltip: 'Análisis de Apps',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    backgroundColor: nexoraBackground,
                    appBar: AppBar(
                      backgroundColor: nexoraBackground,
                      title: const Text('Análisis de Apps'),
                    ),
                    body: NexoraAppsAnalysisScreen(
                      snapshot: snapshot,
                      onOpenApp: widget.onOpenApp,
                    ),
                  ),
                ),
              ),
              child: const Icon(Icons.apps),
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
                label: 'Inicio',
                selected: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
              _NavItem(
                icon: Icons.bolt,
                label: 'Análisis',
                selected: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
              _NavItem(
                icon: Icons.shield_outlined,
                label: 'Protección',
                selected: _index == 2,
                onTap: () => setState(() => _index = 2),
              ),
              _NavItem(
                icon: Icons.notifications_none,
                label: 'Alertas',
                selected: _index == 3,
                badge: verdict.findings.isEmpty
                    ? null
                    : verdict.findings.length,
                onTap: () => setState(() => _index = 3),
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'Perfil',
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
