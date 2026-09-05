/// Logros de NEXORA PLAY — desbloqueados SOLO con hechos reales.
///
/// El catálogo declara qué hecho desbloquea cada logro (`achievements.dart`).
/// Un logro jamás se regala: llega cuando el dato real lo justifica
/// (capturas, juegos ganados, puntajes). Persistencia JSON local.
library;

import 'dart:convert';
import 'dart:io';

class Achievement {
  const Achievement({required this.id, required this.earnedAtMillis});

  final String id;
  final int earnedAtMillis;

  Map<String, Object?> toMap() => {'id': id, 'earnedAtMillis': earnedAtMillis};
}

class AchievementStore {
  AchievementStore._(this._byId, this._file);

  final File? _file;
  final Map<String, Achievement> _byId;

  static Future<AchievementStore> load(String? directoryPath) async {
    if (directoryPath == null) return AchievementStore._({}, null);
    final file = File('$directoryPath/nexora-achievements.json');
    try {
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is List) {
          final map = <String, Achievement>{
            for (final item in decoded)
              if (item is Map)
                if (item['id'] is String)
                  item['id'] as String: Achievement(
                    id: item['id'] as String,
                    earnedAtMillis:
                        item['earnedAtMillis'] is num
                            ? (item['earnedAtMillis'] as num).toInt()
                            : 0,
                  ),
          };
          return AchievementStore._(map, file);
        }
      }
    } on FileSystemException {
      // Sin acceso al disco: logros de la sesión.
    } on FormatException {
      // Archivo corrupto: logros de la sesión.
    }
    return AchievementStore._({}, file);
  }

  bool isUnlocked(String id) => _byId.containsKey(id);

  List<Achievement> unlocked() =>
      _byId.values.toList()..sort((a, b) => a.earnedAtMillis.compareTo(b.earnedAtMillis));

  int get unlockedCount => _byId.length;

  /// Desbloquea un logro si no estaba ya. Nunca revierte el tiempo máquina.
  Future<void> unlock(String id, {required int nowMillis}) async {
    if (_byId.containsKey(id)) return;
    _byId[id] = Achievement(id: id, earnedAtMillis: nowMillis);
    await _persist();
  }

  Future<void> _persist() async {
    final file = _file;
    if (file == null) return;
    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode([for (final a in unlocked()) a.toMap()]),
        flush: true,
      );
    } on FileSystemException {
      // El logro vive en la sesión.
    }
  }
}