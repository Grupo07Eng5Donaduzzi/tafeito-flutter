abstract interface class ApiClient {
  Future<Map<String, Object?>> post(
    String path, {
    Map<String, Object?>? body,
  });
}

class UnimplementedApiClient implements ApiClient {
  @override
  Future<Map<String, Object?>> post(
    String path, {
    Map<String, Object?>? body,
  }) {
    throw UnimplementedError(
      'Configure uma implementacao HTTP para chamar $path.',
    );
  }
}
