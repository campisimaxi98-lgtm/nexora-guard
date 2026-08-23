/// Cliente del backend NEXORA GUARD para cuentas, análisis bajo demanda y
/// estadísticas. Mismo criterio que `nexora_chat_client.dart`: `dart:io`
/// puro, sin paquetes externos, y solo se usa en el flavor `connected`.
library;

import 'dart:convert';
import 'dart:io';

class NexoraApiException implements Exception {
  const NexoraApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class NexoraAuthResult {
  const NexoraAuthResult({
    required this.token,
    required this.email,
    this.displayName,
  });
  final String token;
  final String email;
  final String? displayName;
}

class NexoraAnalysisResult {
  const NexoraAnalysisResult({
    required this.riskScore,
    required this.riskLevel,
    required this.isScam,
    required this.confidence,
    required this.signals,
    required this.recommendation,
    required this.uncertain,
    required this.alertSent,
    required this.sourcesUsed,
  });

  final int riskScore;
  final String riskLevel;
  final bool isScam;
  final double confidence;
  final List<String> signals;
  final String recommendation;
  final bool uncertain;
  final bool alertSent;
  final List<String> sourcesUsed;

  factory NexoraAnalysisResult.fromJson(Map<String, dynamic> j) =>
      NexoraAnalysisResult(
        riskScore: (j['risk_score'] as num?)?.toInt() ?? 0,
        riskLevel: j['risk_level'] as String? ?? 'MEDIUM',
        isScam: j['is_scam'] as bool? ?? false,
        confidence: (j['confidence'] as num?)?.toDouble() ?? 0,
        signals:
            (j['signals'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        recommendation: j['recommendation'] as String? ?? '',
        uncertain: j['uncertain'] as bool? ?? true,
        alertSent: j['alert_sent'] as bool? ?? false,
        sourcesUsed:
            (j['sources_used'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
      );
}

class NexoraStats {
  const NexoraStats({
    required this.total,
    required this.low,
    required this.medium,
    required this.high,
    required this.alertsSent,
    required this.safePercent,
    required this.byChannel,
    required this.timeline,
  });

  final int total;
  final int low;
  final int medium;
  final int high;
  final int alertsSent;
  final int safePercent;
  final Map<String, int> byChannel;
  final List<(DateTime day, int total, int high)> timeline;

  factory NexoraStats.fromJson(Map<String, dynamic> j) {
    final totals = j['totals'] as Map<String, dynamic>? ?? const {};
    final channels = (j['by_channel'] as List?) ?? const [];
    final timelineRaw = (j['timeline'] as List?) ?? const [];
    return NexoraStats(
      total: (totals['total'] as num?)?.toInt() ?? 0,
      low: (totals['low'] as num?)?.toInt() ?? 0,
      medium: (totals['medium'] as num?)?.toInt() ?? 0,
      high: (totals['high'] as num?)?.toInt() ?? 0,
      alertsSent: (totals['alerts_sent'] as num?)?.toInt() ?? 0,
      safePercent: (totals['safe_percent'] as num?)?.toInt() ?? 0,
      byChannel: {
        for (final row in channels)
          (row['channel'] as String? ?? 'other'):
              (row['total'] as num?)?.toInt() ?? 0,
      },
      timeline: [
        for (final row in timelineRaw)
          (
            DateTime.tryParse(row['day'] as String? ?? '') ?? DateTime.now(),
            (row['total'] as num?)?.toInt() ?? 0,
            (row['high'] as num?)?.toInt() ?? 0,
          ),
      ],
    );
  }

  static const empty = NexoraStats(
    total: 0,
    low: 0,
    medium: 0,
    high: 0,
    alertsSent: 0,
    safePercent: 0,
    byChannel: {},
    timeline: [],
  );
}

class NexoraApiClient {
  NexoraApiClient({
    required this.baseUrl,
    this.token,
    this.timeout = const Duration(seconds: 20),
  });

  final String baseUrl;
  final String? token;
  final Duration timeout;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, dynamic>> _postJson(
    String path,
    Map<String, Object?> body, {
    bool auth = false,
  }) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.postUrl(_uri(path)).timeout(timeout);
      request.headers.contentType = ContentType.json;
      if (auth && token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      request.write(jsonEncode(body));
      final response = await request.close().timeout(timeout);
      final text = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      final decoded = text.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(text) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw NexoraApiException(
          decoded['error'] as String? ??
              'Error del servidor (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
      return decoded;
    } on NexoraApiException {
      rethrow;
    } on SocketException {
      throw const NexoraApiException(
        'No se pudo conectar al servidor. Revisá la URL y tu conexión.',
      );
    } on FormatException {
      throw const NexoraApiException(
        'El servidor devolvió una respuesta inválida.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(_uri(path)).timeout(timeout);
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      final response = await request.close().timeout(timeout);
      final text = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      final decoded = text.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(text) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw NexoraApiException(
          decoded['error'] as String? ??
              'Error del servidor (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
      return decoded;
    } on NexoraApiException {
      rethrow;
    } on SocketException {
      throw const NexoraApiException(
        'No se pudo conectar al servidor. Revisá la URL y tu conexión.',
      );
    } on FormatException {
      throw const NexoraApiException(
        'El servidor devolvió una respuesta inválida.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<NexoraAuthResult> register(String email, String password) async {
    final j = await _postJson('/api/auth/register', {
      'email': email,
      'password': password,
    });
    final user = j['user'] as Map<String, dynamic>? ?? const {};
    return NexoraAuthResult(
      token: j['token'] as String? ?? '',
      email: user['email'] as String? ?? email,
      displayName: user['displayName'] as String?,
    );
  }

  Future<NexoraAuthResult> login(String email, String password) async {
    final j = await _postJson('/api/auth/login', {
      'email': email,
      'password': password,
    });
    final user = j['user'] as Map<String, dynamic>? ?? const {};
    return NexoraAuthResult(
      token: j['token'] as String? ?? '',
      email: user['email'] as String? ?? email,
      displayName: user['displayName'] as String?,
    );
  }

  Future<NexoraAnalysisResult> analyzeText(
    String text, {
    required String channel,
    String? alertPhone,
  }) async {
    final j = await _postJson('/api/analyze', {
      'text': text,
      'channel': channel,
      if (alertPhone != null && alertPhone.isNotEmpty) 'alertPhone': alertPhone,
    }, auth: true);
    return NexoraAnalysisResult.fromJson(j);
  }

  Future<NexoraStats> fetchStats() async {
    final j = await _getJson('/api/me/stats');
    return NexoraStats.fromJson(j);
  }

  /// Devuelve el CSV crudo (texto). Guardarlo a disco es responsabilidad
  /// de quien llama (ver `nexora_stats.dart`, que reusa el mismo mecanismo
  /// de guardado que ya usaba la app para exportar snapshots).
  Future<String> exportCsv() async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client
          .getUrl(_uri('/api/me/export'))
          .timeout(timeout);
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      final response = await request.close().timeout(timeout);
      final text = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw const NexoraApiException('No se pudo exportar la información.');
      }
      return text;
    } on NexoraApiException {
      rethrow;
    } on SocketException {
      throw const NexoraApiException('No se pudo conectar al servidor.');
    } finally {
      client.close(force: true);
    }
  }
}
