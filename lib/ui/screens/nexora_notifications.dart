/// Centro de notificaciones (FASE 8): feed persistente de análisis con
/// estado nuevo/leído y fecha. Los textos se localizan al renderizar a
/// partir de los campos semánticos que dejó la captura (severidad,
/// hallazgos y puntaje) — nada se inventa.
library;

import 'package:flutter/material.dart';

import '../../core/notification_feed_store.dart';
import '../components.dart';
import '../strings.dart';
import '../theme.dart';

String _severityLabel(AppStrings s, String key) => switch (key) {
  'critical' => s.ncSeverityCritical,
  'warning' => s.ncSeverityWarning,
  _ => s.ncSeveritySafe,
};

Color _severityDot(String key) => switch (key) {
  'critical' => nexoraRed,
  'warning' => severityYellow,
  _ => severityGreen,
};

IconData _severityIcon(String key) => switch (key) {
  'critical' => Icons.gpp_bad,
  'warning' => Icons.warning_amber_rounded,
  _ => Icons.check_circle,
};

class NexoraNotificationCenterScreen extends StatefulWidget {
  const NexoraNotificationCenterScreen({
    super.key,
    required this.store,
    required this.strings,
  });

  final NotificationFeedStore store;
  final AppStrings strings;

  @override
  State<NexoraNotificationCenterScreen> createState() => _CenterState();
}

class _CenterState extends State<NexoraNotificationCenterScreen> {
  String _dateLabel(int ms) {
    final s = widget.strings;
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    String two(int v) => v.toString().padLeft(2, '0');
    if (day == today) return '${s.ncToday} · ${two(dt.hour)}:${two(dt.minute)}';
    if (today.difference(day).inDays == 1) {
      return s.ncYesterday;
    }
    return '${two(dt.day)}/${two(dt.month)}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final entries = widget.store.entries;
    final hasUnread = entries.any((e) => !e.read);

    return Scaffold(
      backgroundColor: nexoraBackground,
      appBar: AppBar(
        backgroundColor: nexoraBackground,
        foregroundColor: nexoraGoldLight,
        title: Text(s.ncTitle),
        actions: [
          if (hasUnread)
            Center(
              child: TextButton(
                onPressed: () => setState(() => widget.store.markAllRead()),
                child: Text(
                  s.ncMarkAllRead,
                  style: const TextStyle(
                    color: nexoraGoldLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: entries.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.notifications_off_outlined,
                      color: Colors.white24,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      s.ncEmptyTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.ncEmptyBody,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white38),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final e = entries[i];
                final color = _severityDot(e.severityKey);
                return NexoraCard(
                  padding: const EdgeInsets.all(ntPad),
                  onTap: () {
                    if (!e.read) setState(() => widget.store.markRead(e.id));
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          _severityIcon(e.severityKey),
                          color: color,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: ntGapSmall),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    s.ncAnalysisTitle,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: e.read
                                          ? FontWeight.w600
                                          : FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (!e.read)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: nexoraRed.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        s.ncNewLabel,
                                        style: const TextStyle(
                                          color: nexoraRed,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _severityLabel(s, e.severityKey),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.ncAnalysisBody(e.findings, e.score),
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _dateLabel(e.timestampMillis),
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).disabledColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}