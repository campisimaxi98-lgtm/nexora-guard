/// Centro de notificaciones persistente (FASE 8).
///
/// Registra cada análisis completado como una entrada local (nuevo/leído,
/// con fecha), con los MISMO valores que produjo la captura: severidad,
/// cantidad de hallazgos y puntaje. Nada se inventa: el texto visible lo
/// arma la UI con [AppStrings] a partir de estos campos, así el centro se
/// muestra en el idioma activo.
library;

import 'dart:convert';
import 'dart:io';

/// Entrada del centro de notificaciones.
class FeedEntry {
  const FeedEntry({
    required this.id,
    required this.timestampMillis,
    required this.severityKey,
    required this.findings,
    required this.score,
    this.read = false,
  });

  factory FeedEntry.fromMap(Map<String, dynamic> map) => FeedEntry(
    id: map['id'] as String? ?? '',
    timestampMillis: (map['timestampMillis'] as num?)?.toInt() ?? 0,
    severityKey: map['severityKey'] as String? ?? 'normal',
    findings: (map['findings'] as num?)?.toInt() ?? 0,
    score: (map['score'] as num?)?.toInt() ?? 0,
    read: map['read'] == true,
  );

  /// Id único (timestamp + contador corto) para leído/no leído.
  final String id;
  final int timestampMillis;

  /// 'normal' | 'warning' | 'critical' — el nombre visible lo traduce la UI.
  final String severityKey;
  final int findings;
  final int score;
  final bool read;

  Map<String, dynamic> toMap() => {
    'id': id,
    'timestampMillis': timestampMillis,
    'severityKey': severityKey,
    'findings': findings,
    'score': score,
    'read': read,
  };

  FeedEntry copyWith({bool? read}) => FeedEntry(
    id: id,
    timestampMillis: timestampMillis,
    severityKey: severityKey,
    findings: findings,
    score: score,
    read: read ?? this.read,
  );
}

/// Persiste el feed en `nexora-feed.json` dentro de la carpeta de datos.
class NotificationFeedStore {
  NotificationFeedStore(this.directory);

  final Directory directory;
  static const _fileName = 'nexora-feed.json';

  List<FeedEntry> _entries = const [];

  List<FeedEntry> get entries => List.unmodifiable(_entries);

  int get unreadCount => _entries.where((e) => !e.read).length;

  void load() {
    _entries = const [];
    try {
      final file = File('${directory.path}/$_fileName');
      if (!file.existsSync()) return;
      final decoded = jsonDecode(file.readAsStringSync());
      if (decoded is! List) return;
      _entries = [
        for (final item in decoded)
          if (item is Map<String, dynamic>) FeedEntry.fromMap(item),
      ];
    } on FileSystemException {
      // Sin acceso al archivo el centro arranca vacío (igual que la config).
    } on FormatException {
      // JSON corrupto: se descarta y arranca limpio.
    }
  }

  void add(FeedEntry entry) {
    _entries = [entry, ..._entries];
    _persist();
  }

  void markRead(String id) {
    _entries = [
      for (final e in _entries) e.id == id ? e.copyWith(read: true) : e,
    ];
    _persist();
  }

  void markAllRead() {
    _entries = [for (final e in _entries) e.read ? e : e.copyWith(read: true)];
    _persist();
  }

  void _persist() {
    try {
      File('${directory.path}/$_fileName').writeAsStringSync(
        jsonEncode([for (final e in _entries) e.toMap()]),
        flush: true,
      );
    } on FileSystemException {
      // El centro sigue vivo en memoria esta sesión.
    }
  }
}