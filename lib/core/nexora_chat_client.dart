/// Cliente del chat "Nexora" en línea — habla con `POST /api/chat/nexora`
/// del backend NEXORA GUARD (ver el proyecto Node.js, no incluido acá).
///
/// Deliberadamente NO usa el paquete `http` ni ningún otro paquete externo,
/// para no arrastrar dependencias transitivas nuevas a este proyecto (regla
/// de cero dependencias externas, ver pubspec.yaml). Usa `dart:io.HttpClient`
/// directo, que ya viene con el SDK.
///
/// Solo se instancia/usa cuando [AppFlavor.isConnected] es true y la
/// persona dio consentimiento explícito en Configuración — ver
/// `nexora_bot.dart`. En el flavor `offline` este archivo compila pero
/// nunca se llama, y aunque se llamara, el sistema operativo bloquearía el
/// socket por no tener el permiso INTERNET.
library;

import 'dart:convert';
import 'dart:io';

class NexoraChatException implements Exception {
  const NexoraChatException(this.message);
  final String message;
  @override
  String toString() => message;
}

class NexoraChatClient {
  NexoraChatClient({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 20),
  });

  /// Ej: `https://tu-dominio.com` (sin `/` final). Configurable en
  /// Ajustes → Chat en línea; no hay una URL fija porque cada quien aloja
  /// su propio backend.
  final String baseUrl;
  final Duration timeout;

  Future<String> send(
    String message, {
    List<(String role, String content)> history = const [],
  }) async {
    final url = Uri.tryParse('$baseUrl/api/chat/nexora');
    if (url == null || (!url.isScheme('http') && !url.isScheme('https'))) {
      throw const NexoraChatException(
        'URL de servidor inválida. Revisá Ajustes.',
      );
    }

    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.postUrl(url).timeout(timeout);
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'message': message,
          'history': [
            for (final (role, content) in history)
              {'role': role, 'content': content},
          ],
        }),
      );

      final response = await request.close().timeout(timeout);
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);

      if (response.statusCode != 200) {
        final reason =
            _tryExtractError(body) ??
            'Error del servidor (${response.statusCode}).';
        throw NexoraChatException(reason);
      }

      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['reply'] is String) {
        return decoded['reply'] as String;
      }
      throw const NexoraChatException('Respuesta inesperada del servidor.');
    } on NexoraChatException {
      rethrow;
    } on SocketException {
      throw const NexoraChatException(
        'No se pudo conectar al servidor. Revisá la URL y tu conexión.',
      );
    } on HttpException {
      throw const NexoraChatException(
        'El servidor no respondió correctamente.',
      );
    } on FormatException {
      throw const NexoraChatException(
        'El servidor devolvió una respuesta inválida.',
      );
    } finally {
      client.close(force: true);
    }
  }

  String? _tryExtractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is String)
        return decoded['error'] as String;
    } on FormatException {
      // body no era JSON — se ignora, se usa el mensaje genérico.
    }
    return null;
  }
}
