/// Nexora AI — asistente local contextual.
///
/// Motor de reglas 100% local que responde con datos REALES del snapshot:
/// batería, temperatura, memoria, almacenamiento, nivel de cada app y
/// veredicto global. No hay red, no hay alucinación: cuando no hay dato
/// disponible lo dice (honestidad, reglas 8 y 43 del brief).
///
/// Vive en `ui/` porque necesita el texto localizado ([AppStrings]) para
/// componer respuestas; la lógica pura (clasificación, umbrales) está en
/// `core/`. Es la capa que luego puede delegar a un backend real
/// (OpenAI/Claude/Gemini/API propia) a través del mismo contrato
/// `String answer(String)` — sin tocar la pantalla del chat.
library;

import '../core/app_risk_level.dart';
import '../core/models.dart';
import 'strings.dart';

class NexoraAIEngine {
  NexoraAIEngine({required this.strings, this.snapshot, this.verdict});

  final AppStrings strings;
  final Snapshot? snapshot;
  final Verdict? verdict;

  /// Sugerencias rápidas que muestra la pantalla del chat.
  List<String> get quickPrompts => [
    strings.aiQuickDevice,
    strings.aiQuickAlert,
    strings.aiQuickApp,
    strings.aiQuickPermission,
    strings.aiQuickProtect,
  ];

  static final _normalization = <int, String>{
    0xE1: 'a', 0xE0: 'a', 0xE2: 'a', 0xE3: 'a', 0xE4: 'a', 0xE5: 'a',
    0xE9: 'e', 0xE8: 'e', 0xEA: 'e', 0xEB: 'e',
    0xED: 'i', 0xEC: 'i', 0xEE: 'i', 0xEF: 'i',
    0xF3: 'o', 0xF2: 'o', 0xF4: 'o', 0xF5: 'o', 0xF6: 'o',
    0xFA: 'u', 0xF9: 'u', 0xFB: 'u', 0xFC: 'u',
    0xF1: 'n',
    0xE7: 'c',
  };

  /// Normaliza el mensaje: minúsculas y sin acentos para matchear intenciones
  /// en cualquier idioma.
  String _normalize(String text) {
    final out = StringBuffer();
    for (final rune in text.toLowerCase().runes) {
      out.write(_normalization[rune] ?? String.fromCharCode(rune));
  }
    return out.toString();
  }

  bool _hasAny(String text, List<String> tokens) =>
      tokens.any((t) => text.contains(t));

  /// Devuelve la app instalada cuyo nombre encaja mejor con el mensaje
  /// (etiqueta o paquete); la de nombre más largo es la más específica.
  AppRisk? _findApp(String message) {
    final snapshot = this.snapshot;
    if (snapshot == null) return null;
    final norm = _normalize(message);
    AppRisk? best;
    var bestLen = 0;
    for (final app in snapshot.apps) {
      final label = _normalize(app.label);
      final pkg = _normalize(app.packageName);
      if (label.length >= 3 && norm.contains(label) && label.length > bestLen) {
        best = app;
        bestLen = label.length;
      } else if (pkg.length >= 5 && norm.contains(pkg) && pkg.length > bestLen) {
        best = app;
        bestLen = pkg.length;
      }
    }
    return best;
  }

  static const _stopWords = {
    'esta', 'este', 'estas', 'estos', 'estoy', 'hay', 'que', 'como',
    'cual', 'cuando', 'donde', 'mi', 'me', 'mis', 'tu', 'te', 'su', 'es',
    'son', 'del', 'al', 'el', 'la', 'los', 'las', 'un', 'una', 'unos',
    'unas', 'se', 'si', 'no', 'mas', 'muy', 'por', 'para', 'con', 'sin',
    'app', 'aplicacion', 'aplicativo', 'aplicativos', 'application',
    'my', 'your', 'the', 'is', 'are', 'do', 'does', 'can', 'this', 'that',
    'of', 'to', 'in', 'on', 'it',
    'seguro', 'segura', 'safe', 'secure', 'dangerous', 'peligrosa',
    'peligroso', 'perigosa', 'pericolosa', 'critica', 'critico',
  };

  static const _deviceWords = {
    'telefono', 'celular', 'movil', 'movel', 'smartphone', 'phone',
    'device', 'dispositivo', 'equipo', 'aparelho', 'pc',
  };

  /// Cuando el usuario nombra algo que suena a app pero no está instalada,
  /// devuelve ese nombre para responder "no la encuentro" en vez de inventar.
  String? _candidateAppName(String message) {
    final tokens = message
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length >= 3)
        .toList();
    for (final t in tokens) {
      if (!_stopWords.contains(t) && !_deviceWords.contains(t)) return t;
    }
    return null;
  }

  String _levelLabel(AppRiskLevel level) => switch (level) {
    AppRiskLevel.safe => strings.riskSafe,
    AppRiskLevel.attention => strings.riskAttention,
    AppRiskLevel.suspicious => strings.riskSuspicious,
    AppRiskLevel.critical => strings.riskCritical,
  };

  String _gb(double bytes) =>
      (bytes / (1024 * 1024 * 1024)).toStringAsFixed(1);

  String _batteryReply() {
    final b = snapshot?.battery;
    if (b == null) return strings.aiNoData;
    final state = b.charging ? strings.batteryCharging : strings.batteryDischarging;
    final pct = '${b.levelPercent}%';
    if (!b.temperatureAvailable) {
      return strings.aiReplyBatteryNoTemp(pct, state);
    }
    return strings.aiReplyBattery(
      pct,
      state,
      '${b.temperatureCelsius.toStringAsFixed(0)}°C',
    );
  }

  String _temperatureReply() {
    final b = snapshot?.battery;
    if (b == null || !b.temperatureAvailable) return strings.aiNoData;
    final t = b.temperatureCelsius;
    final status = t > 45.0
        ? strings.aiTempHot
        : t > 40.0
        ? strings.aiTempWarm
        : strings.aiTempOk;
    return strings.aiReplyTemp((t * 10).roundToDouble() / 10, status);
  }

  String _memoryReply() {
    final m = snapshot?.memory;
    if (m == null) return strings.aiNoData;
    final used = m.usedBytes;
    final total = m.totalBytes;
    final usedPct = total > 0 ? (used * 100 / total).round() : 0;
    final note = m.lowMemory ? strings.aiMemPressure : '';
    return strings.aiReplyMemory(
      _gb(used.toDouble()),
      _gb(m.availableBytes.toDouble()),
      usedPct,
      note,
    );
  }

  String _storageReply() {
    final s = snapshot?.storage;
    if (s == null) return strings.aiNoData;
    final freePct = (s.freeRatio * 100).round();
    return strings.aiReplyStorage(
      _gb(s.freeBytes.toDouble()),
      _gb(s.totalBytes.toDouble()),
      freePct,
    );
  }

  /// Compone la evidencia que sustenta el nivel de una app (solo hechos).
  String _evidenceFor(AppRisk app, AppRiskLevel level) {
    final active = app.activeCapabilities;
    if (active.isNotEmpty) {
      return '${strings.aiEvActive}${active.map(strings.flagLabel).join(', ')}.';
    }
    if (level == AppRiskLevel.suspicious || level == AppRiskLevel.critical) {
      final parts = <String>[
        for (final f in app.specialFlags)
          if (f != 'sideloaded') strings.flagLabel(f),
        if (app.sideloaded) strings.aiEvSideload,
      ];
      return parts.isEmpty ? strings.aiEvSafe : parts.join(', '); // + '.'
    }
    if (app.grantedPermissions.isNotEmpty) {
      final granted = app.grantedPermissions;
      final shown = granted.take(4).map(strings.permissionLabel).toList();
      final more = granted.length - shown.length;
      return '${strings.aiEvGranted}${shown.join(', ')}'
          '${more > 0 ? strings.aiEvAndMore(more) : '.'}';
    }
    if (app.sideloaded) return strings.aiEvSideload;
    if (app.dangerousPermissions.isNotEmpty) {
      final declared = app.dangerousPermissions;
      final shown = declared.take(4).map(strings.permissionLabel).toList();
      final more = declared.length - shown.length;
      return '${strings.aiEvDeclared}${shown.join(', ')}'
          '${more > 0 ? strings.aiEvAndMore(more) : '.'}';
    }
    return strings.aiEvSafe;
  }

  String _appReply(String message) {
    final app = _findApp(message);
    if (app == null) {
      final name = message.length > 40
          ? message.substring(0, 40)
          : message.trim();
      return strings.aiAppNotFound(name);
    }
    final level = classifyAppRisk(app);
    return strings.aiAppLevel(app.label, _levelLabel(level), _evidenceFor(app, level));
  }

  String _topRiskyReply() {
    final apps = snapshot?.apps;
    if (apps == null) return strings.aiNoData;
    final sorted = [...apps]..sort((a, b) => b.riskScore.compareTo(a.riskScore));
    final flagged = sorted.where((a) => classifyAppRisk(a) != AppRiskLevel.safe).take(3).toList();
    if (flagged.isEmpty) return strings.aiTopRiskyNone;
    return strings.aiTopRisky(
      flagged
          .map((a) => '${a.label} (${_levelLabel(classifyAppRisk(a))})')
          .join(', '),
    );
  }

  String _overallReply() {
    final v = verdict;
    if (v == null) return strings.aiNoData;
    final levelLabel = switch (v.severity) {
      Severity.normal => strings.verdictNormal,
      Severity.warning => strings.verdictWarning,
      Severity.critical => strings.verdictCritical,
    };
    var warnings = 0;
    var criticals = 0;
    for (final f in v.findings) {
      switch (f.severity) {
        case Severity.warning:
          warnings += 1;
        case Severity.critical:
          criticals += 1;
        case Severity.normal:
          break;
      }
    }
    return strings.aiReplyOverall(levelLabel, v.score, warnings, criticals);
  }

  String _alertReply() {
    final v = verdict;
    if (v == null) return strings.aiNoData;
    if (v.findings.isEmpty) return strings.aiAlertNone;
    final titles = v.findings.take(4).map(strings.findingTitle).join(' · ');
    final critical = v.findings.where((f) => f.severity == Severity.critical);
    final reco = critical.isNotEmpty
        ? strings.findingReco(critical.first)
        : strings.findingReco(v.findings.first);
    return strings.aiAlertSummary(strings.topAlerts, titles, reco);
  }

  String _protectReply() => strings.aiProtectTips;

  /// Responde a un mensaje libre. Sintetiza intentos en orden de prioridad;
  /// ante la duda, sugiere qué puede preguntar.
  String answer(String rawMessage) {
    final message = _normalize(rawMessage.trim());
    if (message.isEmpty) return strings.aiHelp;

    if (_hasAny(message, ['permiso', 'permission', 'permissao', 'permesso', 'autorisation'])) {
      // ¿Qué es este permiso? → explica por id si menciona uno conocido.
      if (_hasAny(message, ['camara', 'camera'])) {
        return strings.aiPermissionExplain('CAMERA');
      }
      if (_hasAny(message, ['microfono', 'microphone', 'audio'])) {
        return strings.aiPermissionExplain('RECORD_AUDIO');
      }
      if (_hasAny(message, ['ubicacion', 'location', 'gps', 'position', 'localizacao'])) {
        if (_hasAny(message, ['fondo', 'background', 'segundo plano', 'plano de fundo'])) {
          return strings.aiPermissionExplain('ACCESS_BACKGROUND_LOCATION');
        }
        return strings.aiPermissionExplain('ACCESS_FINE_LOCATION');
      }
      if (_hasAny(message, ['contacto', 'contact', 'agenda', 'contato'])) {
        return strings.aiPermissionExplain('READ_CONTACTS');
      }
      if (_hasAny(message, ['sms'])) {
        return strings.aiPermissionExplain('READ_SMS');
      }
      return strings.aiPermissionExplain('_generic');
    }

    final app = _findApp(rawMessage);
    if (app != null) return _appReply(rawMessage);

    if (_hasAny(message, ['bateria', 'battery', 'batteria', 'batterie'])) {
      return _batteryReply();
    }
    if (_hasAny(message, ['temperatura', 'temperature', 'temperatura', 'temperature', 'calor', 'sobrecalent', 'hot', 'overheat', 'chauff', 'riscald'])) {
      return _temperatureReply();
    }
    if (_hasAny(message, ['memoria', 'memory', 'ram', 'memoire', 'memoria'])) {
      return _memoryReply();
    }
    if (_hasAny(message, ['almacenamiento', 'storage', 'espacio', 'espaco', 'spazio', 'espace', 'stockage', 'armazenamento'])) {
      return _storageReply();
    }
    if (_hasAny(message, ['riesg', 'risk', 'danger', 'peligr', 'perigos', 'pericolos', 'dangerous', 'malware', 'virus', 'spyware', 'amenaza', 'threat'])) {
      final candidate = _candidateAppName(message);
      if (_findApp(rawMessage) == null && candidate != null) {
        return strings.aiAppNotFound(candidate);
      }
      return _topRiskyReply();
    }
    if (_hasAny(message, ['alerta', 'alert', 'significa', 'meaning', 'aviso', 'avvert'])) {
      return _alertReply();
    }
    if (_hasAny(message, ['proteger', 'proteg', 'protect', 'consejo', 'tip', 'dica', 'consiglio', 'astuce', 'como hago', 'como posso'])) {
      return _protectReply();
    }
    if (_hasAny(message, ['seguro', 'secure', 'safe', 'protegid', 'security', 'shell', 'estado', 'general'])) {
      final candidate = _candidateAppName(message);
      if (_findApp(rawMessage) == null && candidate != null) {
        return strings.aiAppNotFound(candidate);
      }
      return _overallReply();
    }
    if (_hasAny(message, ['hola', 'hello', 'ola', 'ciao', 'salut', 'bonjour', 'hey', 'hi '])) {
      return strings.aiGreetReply;
    }
    return strings.aiHelp;
  }
}