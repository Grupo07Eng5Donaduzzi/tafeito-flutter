import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

typedef JsonObject = Map<String, Object?>;

abstract interface class ApiClient {
  Future<Object?> get(
    String path, {
    Map<String, String?>? queryParameters,
  });

  Future<Object?> post(
    String path, {
    JsonObject? body,
    Map<String, String?>? queryParameters,
  });

  Future<Object?> put(
    String path, {
    JsonObject? body,
    Map<String, String?>? queryParameters,
  });

  Future<Object?> patch(
    String path, {
    JsonObject? body,
    Map<String, String?>? queryParameters,
  });

  Future<Object?> delete(
    String path, {
    Map<String, String?>? queryParameters,
  });

  Future<Object?> multipartPost(
    String path, {
    required List<MultipartFilePayload> files,
    JsonObject? fields,
    Map<String, String?>? queryParameters,
  });
}

class MultipartFilePayload {
  const MultipartFilePayload({
    required this.fieldName,
    required this.fileName,
    required this.bytes,
  });

  final String fieldName;
  final String fileName;
  final Uint8List bytes;
}

class HttpApiClient implements ApiClient {
  HttpApiClient({
    http.Client? httpClient,
    Uri? baseUri,
    FutureOr<String?> Function()? accessTokenProvider,
  })  : _httpClient = httpClient ?? http.Client(),
        _baseUri = baseUri ?? Uri.parse(defaultBaseUrl),
        _accessTokenProvider = accessTokenProvider;

  static const defaultBaseUrl = String.fromEnvironment(
    'TAFEITO_MAIN_API_BASE_URL',
    defaultValue: 'https://tafeito.rietto.com/main',
  );

  final http.Client _httpClient;
  final Uri _baseUri;
  final FutureOr<String?> Function()? _accessTokenProvider;

  @override
  Future<Object?> get(
    String path, {
    Map<String, String?>? queryParameters,
  }) {
    return _send(
      'GET',
      path,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<Object?> post(
    String path, {
    JsonObject? body,
    Map<String, String?>? queryParameters,
  }) {
    return _send(
      'POST',
      path,
      body: body,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<Object?> put(
    String path, {
    JsonObject? body,
    Map<String, String?>? queryParameters,
  }) {
    return _send(
      'PUT',
      path,
      body: body,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<Object?> patch(
    String path, {
    JsonObject? body,
    Map<String, String?>? queryParameters,
  }) {
    return _send(
      'PATCH',
      path,
      body: body,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<Object?> delete(
    String path, {
    Map<String, String?>? queryParameters,
  }) {
    return _send(
      'DELETE',
      path,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<Object?> multipartPost(
    String path, {
    required List<MultipartFilePayload> files,
    JsonObject? fields,
    Map<String, String?>? queryParameters,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _resolve(path, queryParameters),
    );
    request.headers.addAll(await _headers(jsonContent: false));
    for (final entry in (fields ?? const <String, Object?>{}).entries) {
      final value = entry.value;
      if (value != null) {
        request.fields[entry.key] = value.toString();
      }
    }
    for (final file in files) {
      request.files.add(
        http.MultipartFile.fromBytes(
          file.fieldName,
          file.bytes,
          filename: file.fileName,
        ),
      );
    }

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiClientException(
        statusCode: response.statusCode,
        message: _readErrorMessage(response),
      );
    }

    if (response.statusCode == 204 || response.bodyBytes.isEmpty) {
      return <String, Object?>{};
    }

    return jsonDecode(utf8.decode(response.bodyBytes)) as Object?;
  }

  Future<Object?> _send(
    String method,
    String path, {
    JsonObject? body,
    Map<String, String?>? queryParameters,
  }) async {
    final request = http.Request(method, _resolve(path, queryParameters));
    request.headers.addAll(await _headers());

    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiClientException(
        statusCode: response.statusCode,
        message: _readErrorMessage(response),
      );
    }

    if (response.statusCode == 204 || response.bodyBytes.isEmpty) {
      return <String, Object?>{};
    }

    return jsonDecode(utf8.decode(response.bodyBytes)) as Object?;
  }

  Future<Map<String, String>> _headers({bool jsonContent = true}) async {
    final accessToken = await Future<String?>.value(
      _accessTokenProvider?.call(),
    );

    return {
      'Accept': 'application/json',
      if (jsonContent) 'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
  }

  Uri _resolve(
    String path,
    Map<String, String?>? queryParameters,
  ) {
    final normalizedBase = _baseUri.toString().endsWith('/')
        ? _baseUri
        : Uri.parse('${_baseUri.toString()}/');
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = normalizedBase.resolve(normalizedPath);
    final cleanQueryParameters = <String, String>{};

    for (final entry
        in (queryParameters ?? const <String, String?>{}).entries) {
      final value = entry.value;
      if (value != null && value.isNotEmpty) {
        cleanQueryParameters[entry.key] = value;
      }
    }

    return cleanQueryParameters.isEmpty
        ? uri
        : uri.replace(queryParameters: cleanQueryParameters);
  }

  String _readErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map) {
        final message = decoded['message'];
        if (message is List) {
          return message.whereType<Object>().join('\n');
        }

        final text = message ?? decoded['error'];
        if (text != null && text.toString().isNotEmpty) {
          return text.toString();
        }
      }
    } on Object {
      // Keep the generic message below when the server does not return JSON.
    }

    return 'Erro ${response.statusCode} ao chamar a API.';
  }
}

class UnimplementedApiClient implements ApiClient {
  @override
  Future<Object?> get(
    String path, {
    Map<String, String?>? queryParameters,
  }) {
    return _throw(path);
  }

  @override
  Future<Object?> post(
    String path, {
    JsonObject? body,
    Map<String, String?>? queryParameters,
  }) {
    return _throw(path);
  }

  @override
  Future<Object?> put(
    String path, {
    JsonObject? body,
    Map<String, String?>? queryParameters,
  }) {
    return _throw(path);
  }

  @override
  Future<Object?> patch(
    String path, {
    JsonObject? body,
    Map<String, String?>? queryParameters,
  }) {
    return _throw(path);
  }

  @override
  Future<Object?> delete(
    String path, {
    Map<String, String?>? queryParameters,
  }) {
    return _throw(path);
  }

  @override
  Future<Object?> multipartPost(
    String path, {
    required List<MultipartFilePayload> files,
    JsonObject? fields,
    Map<String, String?>? queryParameters,
  }) {
    return _throw(path);
  }

  Never _throw(String path) {
    throw UnimplementedError(
      'Configure uma implementacao HTTP para chamar $path.',
    );
  }
}

class ApiClientException implements Exception {
  const ApiClientException({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiClientException($statusCode): $message';
}

JsonObject asJsonObject(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }

  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  throw const FormatException('Resposta da API nao e um objeto JSON.');
}

List<Object?> asJsonList(Object? value) {
  if (value is List) {
    return value.cast<Object?>();
  }

  throw const FormatException('Resposta da API nao e uma lista JSON.');
}

Object? unwrapJsonData(Object? value) {
  if (value is Map) {
    return value['data'] ?? value['result'] ?? value['user'] ?? value;
  }

  return value;
}
