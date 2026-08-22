/// "Mi Perfil" — cabecera de identidad de la app (no de una cuenta de
/// usuario: NEXORA GUARD no tiene sistema de cuentas, ver nota en
/// `nexora_splash.dart`) y accesos a las pantallas técnicas que ya existían
/// (`SettingsScreen`, `AboutScreen`, `DeviceScreen`, `StorageScreen`,
/// `NearbyScreen`), reutilizadas tal cual vía [legacyTab].
library;

import 'package:flutter/material.dart';

import '../../meta.dart';
import '../nexora_logo.dart';
import '../theme.dart';

class NexoraProfileScreen extends StatelessWidget {
  const NexoraProfileScreen({
    super.key,
    required this.onOpenLegacy,
    required this.onRestart,
  });

  /// Empuja una de las pantallas técnicas existentes por id
  /// ('settings' | 'about' | 'device' | 'storage' | 'nearby').
  final void Function(String id, String title) onOpenLegacy;

  /// Vuelve a la pantalla de bienvenida (no es un "cerrar sesión" real,
  /// ver nota de honestidad en nexora_splash.dart).
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text(
          'Mi Perfil',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: nexoraSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: nexoraBorder),
          ),
          child: Row(
            children: [
              const NexoraLogo(size: 52, showRing: false),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      Meta.productName,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'v${Meta.version} · creado por ${Meta.author}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _ProfileMenu(
          items: [
            _MenuItem(
              icon: Icons.phone_android,
              label: 'Resumen del dispositivo',
              onTap: () => onOpenLegacy('device', 'Dispositivo'),
            ),
            _MenuItem(
              icon: Icons.sd_storage_outlined,
              label: 'Almacenamiento',
              onTap: () => onOpenLegacy('storage', 'Almacenamiento'),
            ),
            _MenuItem(
              icon: Icons.bluetooth_searching,
              label: 'Cercanía Bluetooth',
              onTap: () => onOpenLegacy('nearby', 'Cercanía'),
            ),
            _MenuItem(
              icon: Icons.settings_outlined,
              label: 'Configuración',
              onTap: () => onOpenLegacy('settings', 'Configuración'),
            ),
            _MenuItem(
              icon: Icons.info_outline,
              label: 'Acerca de / Ayuda',
              onTap: () => onOpenLegacy('about', 'Acerca de'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE05263),
              side: const BorderSide(color: nexoraWine, width: 1.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onRestart,
            child: const Text('VOLVER AL INICIO'),
          ),
        ),
      ],
    ),
  );
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _ProfileMenu extends StatelessWidget {
  const _ProfileMenu({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: nexoraSurface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: nexoraBorder),
    ),
    child: Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          ListTile(
            leading: Icon(items[i].icon, color: nexoraGoldLight),
            title: Text(
              items[i].label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white38),
            onTap: items[i].onTap,
          ),
          if (i != items.length - 1)
            const Divider(height: 1, color: nexoraBorder),
        ],
      ],
    ),
  );
}
