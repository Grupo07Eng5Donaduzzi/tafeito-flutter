import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tafeito_flutter/src/core/network/api_client.dart';
import 'package:tafeito_flutter/src/features/chat/data/datasources/chat_remote_data_source.dart';

class _FakeApiClient implements ApiClient {
  _FakeApiClient(this.response);

  final Object? response;
  String? lastPath;
  Map<String, String?>? lastQuery;

  @override
  Future<Object?> get(String path, {Map<String, String?>? queryParameters}) async {
    lastPath = path;
    lastQuery = queryParameters;
    return response;
  }

  @override
  Future<Object?> post(String path, {JsonObject? body, Map<String, String?>? queryParameters}) =>
      throw UnimplementedError();
  @override
  Future<Object?> put(String path, {JsonObject? body, Map<String, String?>? queryParameters}) =>
      throw UnimplementedError();
  @override
  Future<Object?> patch(String path, {JsonObject? body, Map<String, String?>? queryParameters}) =>
      throw UnimplementedError();
  @override
  Future<Object?> delete(String path, {Map<String, String?>? queryParameters}) =>
      throw UnimplementedError();
  @override
  Future<Object?> patchMultipart(String path,
          {required Uint8List bytes, required String filename, required String mimeType}) =>
      throw UnimplementedError();
}

void main() {
  test('getServiceMessages requests the right path and parses data list', () async {
    final api = _FakeApiClient({
      'data': [
        {
          'id': 'm1',
          'serviceId': 's1',
          'senderId': 'u1',
          'recipientId': 'u2',
          'content': 'segundo',
          'status': 'sent',
          'createdAt': '2026-06-11T20:30:00.000Z',
        },
        {
          'id': 'm2',
          'serviceId': 's1',
          'senderId': 'u2',
          'recipientId': 'u1',
          'content': 'primeiro',
          'status': 'sent',
          'createdAt': '2026-06-11T20:00:00.000Z',
        },
      ],
      'total': 2,
      'page': 1,
      'pageSize': 50,
      'hasMore': false,
    });
    final dataSource = ApiChatRemoteDataSource(apiClient: api);

    final messages = await dataSource.getServiceMessages('s1');

    expect(api.lastPath, '/v1/chat/services/s1/messages');
    expect(api.lastQuery, {'page': '1', 'pageSize': '50'});
    expect(messages, hasLength(2));
    expect(messages.first.content, 'primeiro');
    expect(messages.last.content, 'segundo');
  });
}
