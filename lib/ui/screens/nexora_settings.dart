/// Ajustes (FASE 8): pantalla organizada por grupos funcionales.
///
/// - CUENTA: correo local, cambiar contraseña y cerrar sesión.
/// - SEGURIDAD: centro de notificaciones, permisos de las apps y Protección.
/// - APLICACIÓN: plan del perfil, preferencias avanzadas (pantalla técnica
///   original [SettingsScreen]) y Acerca de.
library;

import 'package:flutter/material.dart';

import '../components.dart';
import '../strings.dart';
import '../theme.dart';

class NexoraSettingsScreen extends StatelessWidget {
  const NexoraSettingsScreen({
    super.key,
    required this.strings,
    required this.planLabel,
    this.accountEmail,
    this.onOpenChangePassword,
    this.onLogout,
    this.onOpenNotifications,
    this.onOpenApps,
    this.onOpenProtection,
    this.onOpenPremium,
    this.onOpenPrefs,
    this.onOpenAbout,
  });

  final AppStrings strings;

  /// Etiqueta del plan visible ('BASIC' o 'PROFESSIONAL' según la cuenta).
  final String planLabel;

  final String? accountEmail;
  final VoidCallback? onOpenChangePassword;
  final VoidCallback? onLogout;
  final VoidCallback? onOpenNotifications;
  final VoidCallback? onOpenApps;
  final VoidCallback? onOpenProtection;
  final VoidCallback? onOpenPremium;
  final VoidCallback? onOpenPrefs;
  final VoidCallback? onOpenAbout;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final hasAccount = accountEmail != null && onLogout != null;

    return Scaffold(
      backgroundColor: nexoraBackground,
      appBar: AppBar(
        backgroundColor: nexoraBackground,
        foregroundColor: nexoraGoldLight,
        title: Text(s.topSettings),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (hasAccount) ...[
            _GroupItem(
              icon: Icons.person_outline,
              group: s.settingsAccount,
              children: [
                NexoraCard(
                  padding: const EdgeInsets.all(ntPad),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.alternate_email,
                        size: 20,
                        color: nexoraGoldLight,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          accountEmail!,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                NexoraCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ntPad,
                    vertical: 6,
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.lock_reset,
                      size: 20,
                      color: nexoraGoldLight,
                    ),
                    title: Text(
                      s.settingsChangePassword,
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white38,
                      size: 20,
                    ),
                    onTap: onOpenChangePassword,
                  ),
                ),
                NexoraCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ntPad,
                    vertical: 6,
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.logout, size: 20, color: nexoraRed),
                    title: Text(
                      s.settingsLogout,
                      style: const TextStyle(
                        fontSize: 14,
                        color: nexoraRed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () {
                      // Vuelve a la raíz antes de cerrar, así el ciclo de
                      // reintento de `main.dart` muestra la portada.
                      Navigator.of(context).popUntil((r) => r.isFirst);
                      onLogout?.call();
                    },
                  ),
                ),
              ],
            ),
          ],
          _GroupItem(
            icon: Icons.security,
            group: s.settingsSecurity,
            children: [
              _row(
                context,
                icon: Icons.notifications_outlined,
                title: s.settingsNotifications,
                subtitle: s.settingsNotificationsDesc,
                onTap: onOpenNotifications,
              ),
              _row(
                context,
                icon: Icons.notification_important_outlined,
                title: s.settingsPermissionsApps,
                subtitle: s.settingsPermissionsAppsDesc,
                onTap: onOpenApps,
              ),
              _row(
                context,
                icon: Icons.shield_outlined,
                title: s.settingsProtectionRow,
                subtitle: s.settingsProtectionRowDesc,
                onTap: onOpenProtection,
              ),
            ],
          ),
          _GroupItem(
            icon: Icons.apps,
            group: s.settingsAppGroup,
            children: [
              _row(
                context,
                icon: Icons.workspace_premium_outlined,
                title: s.settingsPlanRow,
                subtitle: s.settingsPlanRowDesc,
                trailingLabel: planLabel,
                trailingHighlight: planLabel == s.planProfessional,
                onTap: onOpenPremium,
              ),
              _row(
                context,
                icon: Icons.tune,
                title: s.settingsPrefsRow,
                subtitle: s.settingsPrefsRowDesc,
                onTap: onOpenPrefs,
              ),
              _row(
                context,
                icon: Icons.info_outline,
                title: s.settingsAboutRow,
                subtitle: s.settingsAboutRowDesc,
                onTap: onOpenAbout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    String? trailingLabel,
    bool trailingHighlight = false,
    VoidCallback? onTap,
  }) => NexoraCard(
    padding: const EdgeInsets.symmetric(horizontal: ntPad, vertical: 6),
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: nexoraGoldLight),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11.5,
                color: Colors.white38,
                height: 1.3,
              ),
            ),
      trailing: trailingLabel == null
          ? const Icon(Icons.chevron_right, color: Colors.white38, size: 20)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trailingLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: trailingHighlight
                        ? nexoraGoldLight
                        : Colors.white54,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white38,
                  size: 20,
                ),
              ],
            ),
      onTap: onTap,
    ),
  );
}

class _GroupItem extends StatelessWidget {
  const _GroupItem({
    required this.icon,
    required this.group,
    required this.children,
  });

  final IconData icon;
  final String group;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: nexoraGoldLight),
            const SizedBox(width: 8),
            Text(
              group.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: nexoraGoldLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );
}