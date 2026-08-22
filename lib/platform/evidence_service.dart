/// Evidencia portable — backup completo, restauración y borrado.
///
/// "La evidencia es tuya" en serio: sobrevive a desinstalar y a cambiar
/// de teléfono (backup JSON exportable/importable) y desaparece cuando
/// tú lo decides (borrado desde la app, sin desinstalar).
library;

import 'dart:convert';
import 'dart:io';

class EvidenceService {
  const EvidenceService(this.directoryPath);

  final String directoryPath;

  static const int backupFormatVersion = 1;
  static const _files = <String, String>{
    'config': 'nexora-config.json',
    'history': 'nexora-history.jsonl',
    'baseline': 'nexora-apps-baseline.json',
    'nearby': 'nexora-nearby.json',
    'crashlog': 'nexora-crashlog.txt',
  };

  /// Crea el archivo de backup en el sandbox y devuelve su ruta.
  Future<String> writeBackup({required int nowMillis}) async {
    final bundle = <String, Object?>{
      'nexoraBackup': backupFormatVersion,
      'exportedAtMillis': nowMillis,
    };
    for (final entry in _files.entries) {
      final file = File('$directoryPath/${entry.value}');
      bundle[entry.key] = await file.exists()
          ? await file.readAsString()
          : null;
    }
    final out = File('$directoryPath/nexora-backup-$nowMillis.json');
    await out.writeAsString(jsonEncode(bundle), flush: true);
    return out.path;
  }

  /// Restaura un backup. Devuelve `false` si el contenido no es un
  /// backup válido (nunca escribe a medias: valida antes de tocar disco).
  Future<bool> restoreBackup(String content) async {
    Object? decoded;
    try {
      decoded = jsonDecode(content);
    } on FormatException {
      return false;
    }
    if (decoded is! Map<String, dynamic> ||
        decoded['nexoraBackup'] is! num) {
      return false;
    }
    for (final entry in _files.entries) {
      final data = decoded[entry.key];
      final file = File('$directoryPath/${entry.value}');
      if (data is String) {
        await file.writeAsString(data, flush: true);
      }
    }
    return true;
  }

  /// Borra historial, baseline, cercanía, registro de errores y exports.
  /// La configuración se conserva (idioma, umbrales): borrar evidencia no
  /// es resetear la app.
  Future<void> wipeEvidence() async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return;
    const evidence = [
      'nexora-history.jsonl',
      'nexora-apps-baseline.json',
      'nexora-nearby.json',
      'nexora-crashlog.txt',
    ];
    for (final name in evidence) {
      final file = File('$directoryPath/$name');
      if (await file.exists()) await file.delete();
    }
    await for (final entity in dir.list()) {
      if (entity is File) {
        final name = entity.uri.pathSegments.last;
        if (name.startsWith('nexora-snapshot-') ||
            name.startsWith('nexora-backup-') ||
            name.startsWith('nexora-informe-')) {
          await entity.delete();
        }
      }
    }
  }
}
