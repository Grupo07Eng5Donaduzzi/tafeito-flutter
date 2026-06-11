# Chat em Tempo Real Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tela de chat em tempo real (cliente↔prestador) no app Flutter, conectando ao gateway socket.io existente do tafeito-api.

**Architecture:** Feature vertical `lib/src/features/chat/` (data/domain/presentation, viewmodel `ChangeNotifier`). Histórico via REST (`ApiClient`), tempo real via `socket_io_client` no namespace `/chat`. Renderização única a partir do echo `new-message` do servidor (sem mensagem otimista). Entrada pelo botão "Conversar" nos cards da lista Explorar.

**Tech Stack:** Flutter 3.44, Dart, `socket_io_client: ^2.0.3`, `http` (via `ApiClient` existente), `flutter_test` com fakes escritos à mão (sem lib de mock).

---

## Convenções do projeto (ler antes de começar)

- Repositórios retornam `Result<T>` (`Success`/`Failure`, em `lib/src/core/result/result.dart`) e capturam exceções. Data sources lançam exceção.
- Data sources REST usam `ApiClient` (`lib/src/core/network/api_client.dart`) e os helpers `asJsonObject`, `asJsonList`, `unwrapJsonData`.
- ViewModels estendem `ChangeNotifier`, expõem getters e chamam `notifyListeners()`.
- Rotas REST levam prefixo `/v1` (ex.: `/v1/chat/...`).
- Cores: `AppTheme.primary` (#2563EB), `AppTheme.textPrimary`, `AppTheme.textMuted`, `AppTheme.inputBorder` em `lib/src/core/theme/app_theme.dart`.
- Sem lib de mock no projeto — testes usam fakes manuais.

---

## Estrutura de arquivos

```
lib/src/features/chat/
  domain/
    entities/chat_message.dart            # entidade imutável
    repositories/chat_repository.dart      # interface
  data/
    models/chat_message_dto.dart           # mapper JSON -> ChatMessage
    datasources/chat_remote_data_source.dart  # histórico REST
    datasources/chat_socket_data_source.dart  # wrapper socket.io
    repositories/chat_repository_impl.dart # orquestra REST + socket
  presentation/
    viewmodels/chat_thread_view_model.dart
    views/chat_thread_page.dart
test/features/chat/
  chat_message_dto_test.dart
  chat_remote_data_source_test.dart
  chat_repository_impl_test.dart
  chat_thread_view_model_test.dart
  chat_thread_page_test.dart
```
Modificados: `pubspec.yaml`, `lib/src/features/services/data/models/service_dto.dart`, `lib/src/features/auth/presentation/views/services_page.dart`, `lib/src/core/theme/main_page.dart`, `lib/src/app.dart`.

---

### Task 1: Entidade ChatMessage + mapper ChatMessageDto

**Files:**
- Create: `lib/src/features/chat/domain/entities/chat_message.dart`
- Create: `lib/src/features/chat/data/models/chat_message_dto.dart`
- Test: `test/features/chat/chat_message_dto_test.dart`

- [ ] **Step 1: Criar a entidade**

`lib/src/features/chat/domain/entities/chat_message.dart`:

```dart
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.serviceId,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String serviceId;
  final String senderId;
  final String recipientId;
  final String content;
  final String status;
  final DateTime createdAt;
}
```

- [ ] **Step 2: Escrever o teste que falha**

`test/features/chat/chat_message_dto_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tafeito_flutter/src/features/chat/data/models/chat_message_dto.dart';

void main() {
  group('ChatMessageDto.fromJson', () {
    test('parses camelCase payload from REST/socket', () {
      final message = ChatMessageDto.fromJson({
        'id': 'm1',
        'serviceId': 's1',
        'senderId': 'u1',
        'recipientId': 'u2',
        'content': 'oi',
        'status': 'sent',
        'createdAt': '2026-06-11T20:22:00.000Z',
      });

      expect(message.id, 'm1');
      expect(message.serviceId, 's1');
      expect(message.senderId, 'u1');
      expect(message.recipientId, 'u2');
      expect(message.content, 'oi');
      expect(message.status, 'sent');
      expect(message.createdAt.toUtc(), DateTime.utc(2026, 6, 11, 20, 22));
    });

    test('falls back to snake_case keys and defaults', () {
      final message = ChatMessageDto.fromJson({
        'id': 'm2',
        'service_id': 's2',
        'sender_id': 'u3',
        'recipient_id': 'u4',
        'content': 'ola',
      });

      expect(message.serviceId, 's2');
      expect(message.senderId, 'u3');
      expect(message.recipientId, 'u4');
      expect(message.status, 'sent');
    });
  });
}
```

- [ ] **Step 3: Rodar o teste e confirmar que falha**

Run: `flutter test test/features/chat/chat_message_dto_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'tafeito_flutter' ... chat_message_dto.dart` / arquivo não existe.

- [ ] **Step 4: Criar o mapper**

`lib/src/features/chat/data/models/chat_message_dto.dart`:

```dart
import '../../domain/entities/chat_message.dart';

class ChatMessageDto {
  static ChatMessage fromJson(Map<String, Object?> json) {
    final createdRaw =
        (json['createdAt'] ?? json['created_at'])?.toString() ?? '';
    final created =
        DateTime.tryParse(createdRaw)?.toLocal() ??
            DateTime.fromMillisecondsSinceEpoch(0);

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      serviceId: (json['serviceId'] ?? json['service_id'])?.toString() ?? '',
      senderId: (json['senderId'] ?? json['sender_id'])?.toString() ?? '',
      recipientId:
          (json['recipientId'] ?? json['recipient_id'])?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      status: json['status']?.toString() ?? 'sent',
      createdAt: created,
    );
  }
}
```

- [ ] **Step 5: Rodar o teste e confirmar que passa**

Run: `flutter test test/features/chat/chat_message_dto_test.dart`
Expected: PASS (2 testes).

- [ ] **Step 6: Commit**

```bash
git add lib/src/features/chat/domain/entities/chat_message.dart lib/src/features/chat/data/models/chat_message_dto.dart test/features/chat/chat_message_dto_test.dart
git commit -m "feat(chat): add ChatMessage entity and JSON mapper"
```

---

### Task 2: Histórico REST (ChatRemoteDataSource)

**Files:**
- Create: `lib/src/features/chat/data/datasources/chat_remote_data_source.dart`
- Test: `test/features/chat/chat_remote_data_source_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

`test/features/chat/chat_remote_data_source_test.dart`:

```dart
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
    expect(messages, hasLength(2));
    // ordenado por createdAt asc
    expect(messages.first.content, 'primeiro');
    expect(messages.last.content, 'segundo');
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/features/chat/chat_remote_data_source_test.dart`
Expected: FAIL — arquivo `chat_remote_data_source.dart` não existe.

- [ ] **Step 3: Implementar o data source**

`lib/src/features/chat/data/datasources/chat_remote_data_source.dart`:

```dart
import '../../../../core/network/api_client.dart';
import '../../domain/entities/chat_message.dart';
import '../models/chat_message_dto.dart';

abstract interface class ChatRemoteDataSource {
  Future<List<ChatMessage>> getServiceMessages(
    String serviceId, {
    int page,
    int pageSize,
  });
}

class ApiChatRemoteDataSource implements ChatRemoteDataSource {
  const ApiChatRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<List<ChatMessage>> getServiceMessages(
    String serviceId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _apiClient.get(
      '/v1/chat/services/$serviceId/messages',
      queryParameters: {
        'page': '$page',
        'pageSize': '$pageSize',
      },
    );

    final list = _extractList(response);
    final messages = list
        .whereType<Map>()
        .map((json) => ChatMessageDto.fromJson(asJsonObject(json)))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return messages;
  }

  List<Object?> _extractList(Object? response) {
    final unwrapped = unwrapJsonData(response);
    if (unwrapped is List) {
      return asJsonList(unwrapped);
    }
    if (unwrapped is Map) {
      final data = unwrapped['data'];
      if (data is List) {
        return asJsonList(data);
      }
    }
    return const <Object?>[];
  }
}
```

Nota: `unwrapJsonData` retorna `value['data']` quando presente; o `_extractList` cobre tanto lista direta quanto envelope `{data: [...]}`.

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `flutter test test/features/chat/chat_remote_data_source_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/features/chat/data/datasources/chat_remote_data_source.dart test/features/chat/chat_remote_data_source_test.dart
git commit -m "feat(chat): add REST data source for message history"
```

---

### Task 3: Wrapper socket.io (ChatSocketDataSource)

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/src/features/chat/data/datasources/chat_socket_data_source.dart`

Sem teste automatizado: integração com socket.io real é validada manualmente. A interface existe para que o repositório/viewmodel sejam testáveis com fakes.

- [ ] **Step 1: Adicionar a dependência**

Em `pubspec.yaml`, dentro de `dependencies:`, após `http_parser: ^4.0.0`:

```yaml
  socket_io_client: ^2.0.3
```

- [ ] **Step 2: Instalar**

Run: `flutter pub get`
Expected: resolve sem erros; `socket_io_client` aparece no lockfile.

- [ ] **Step 3: Criar a interface e a implementação**

`lib/src/features/chat/data/datasources/chat_socket_data_source.dart`:

```dart
import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/network/api_client.dart';
import '../../domain/entities/chat_message.dart';
import '../models/chat_message_dto.dart';

abstract interface class ChatSocketDataSource {
  void connect(String token);
  void joinService(String serviceId);
  void sendMessage({
    required String serviceId,
    required String recipientId,
    required String content,
  });
  Stream<ChatMessage> get onNewMessage;
  Stream<String> get onError;
  void dispose();
}

class SocketIoChatDataSource implements ChatSocketDataSource {
  SocketIoChatDataSource({required String wsBaseUrl}) : _wsBaseUrl = wsBaseUrl;

  final String _wsBaseUrl;
  io.Socket? _socket;
  String? _serviceId;

  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  @override
  void connect(String token) {
    final socket = io.io(
      '$_wsBaseUrl/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'token': token})
          .enableForceNew()
          .build(),
    );

    socket.onConnect((_) {
      final serviceId = _serviceId;
      if (serviceId != null) {
        socket.emit('join-service', {'serviceId': serviceId});
      }
    });

    socket.on('new-message', (data) {
      final message = data is Map ? data['message'] : null;
      if (message is Map) {
        _messageController.add(ChatMessageDto.fromJson(asJsonObject(message)));
      }
    });

    socket.on('error', (data) {
      final text = data is Map ? data['message']?.toString() : data?.toString();
      _errorController.add(text ?? 'Erro no chat.');
    });

    _socket = socket;
  }

  @override
  void joinService(String serviceId) {
    _serviceId = serviceId;
    _socket?.emit('join-service', {'serviceId': serviceId});
  }

  @override
  void sendMessage({
    required String serviceId,
    required String recipientId,
    required String content,
  }) {
    _socket?.emit('send-message', {
      'serviceId': serviceId,
      'recipientId': recipientId,
      'content': content,
    });
  }

  @override
  Stream<ChatMessage> get onNewMessage => _messageController.stream;

  @override
  Stream<String> get onError => _errorController.stream;

  @override
  void dispose() {
    _socket?.dispose();
    _socket = null;
    _messageController.close();
    _errorController.close();
  }
}
```

- [ ] **Step 4: Confirmar que compila**

Run: `flutter analyze lib/src/features/chat/data/datasources/chat_socket_data_source.dart`
Expected: "No issues found!" (warnings de info aceitáveis, zero errors).

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/src/features/chat/data/datasources/chat_socket_data_source.dart
git commit -m "feat(chat): add socket.io data source wrapper"
```

---

### Task 4: Repositório (interface + impl)

**Files:**
- Create: `lib/src/features/chat/domain/repositories/chat_repository.dart`
- Create: `lib/src/features/chat/data/repositories/chat_repository_impl.dart`
- Test: `test/features/chat/chat_repository_impl_test.dart`

- [ ] **Step 1: Criar a interface**

`lib/src/features/chat/domain/repositories/chat_repository.dart`:

```dart
import '../../../../core/result/result.dart';
import '../entities/chat_message.dart';

abstract interface class ChatRepository {
  Future<Result<List<ChatMessage>>> loadHistory(String serviceId);
  void connect(String token);
  void joinService(String serviceId);
  void sendMessage({
    required String serviceId,
    required String recipientId,
    required String content,
  });
  Stream<ChatMessage> get messages;
  Stream<String> get errors;
  void dispose();
}
```

- [ ] **Step 2: Escrever o teste que falha**

`test/features/chat/chat_repository_impl_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tafeito_flutter/src/core/result/result.dart';
import 'package:tafeito_flutter/src/features/chat/data/datasources/chat_remote_data_source.dart';
import 'package:tafeito_flutter/src/features/chat/data/datasources/chat_socket_data_source.dart';
import 'package:tafeito_flutter/src/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:tafeito_flutter/src/features/chat/domain/entities/chat_message.dart';

class _FakeRemote implements ChatRemoteDataSource {
  _FakeRemote(this.result);
  final Object result; // List<ChatMessage> ou Exception

  @override
  Future<List<ChatMessage>> getServiceMessages(String serviceId,
      {int page = 1, int pageSize = 50}) async {
    final value = result;
    if (value is Exception) throw value;
    return value as List<ChatMessage>;
  }
}

class _FakeSocket implements ChatSocketDataSource {
  final StreamController<ChatMessage> messageController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<String> errorController =
      StreamController<String>.broadcast();
  bool disposed = false;

  @override
  void connect(String token) {}
  @override
  void joinService(String serviceId) {}
  @override
  void sendMessage(
      {required String serviceId,
      required String recipientId,
      required String content}) {}
  @override
  Stream<ChatMessage> get onNewMessage => messageController.stream;
  @override
  Stream<String> get onError => errorController.stream;
  @override
  void dispose() {
    disposed = true;
    messageController.close();
    errorController.close();
  }
}

ChatMessage _msg(String id) => ChatMessage(
      id: id,
      serviceId: 's1',
      senderId: 'u1',
      recipientId: 'u2',
      content: 'oi',
      status: 'sent',
      createdAt: DateTime.utc(2026, 6, 11),
    );

void main() {
  test('loadHistory returns Success with messages', () async {
    final repo = ChatRepositoryImpl(
      remoteDataSource: _FakeRemote([_msg('m1')]),
      socketDataSource: _FakeSocket(),
    );

    final result = await repo.loadHistory('s1');

    expect(result, isA<Success<List<ChatMessage>>>());
    expect((result as Success<List<ChatMessage>>).data.single.id, 'm1');
  });

  test('loadHistory returns Failure on exception', () async {
    final repo = ChatRepositoryImpl(
      remoteDataSource: _FakeRemote(Exception('boom')),
      socketDataSource: _FakeSocket(),
    );

    final result = await repo.loadHistory('s1');

    expect(result, isA<Failure<List<ChatMessage>>>());
  });

  test('messages stream proxies the socket stream', () async {
    final socket = _FakeSocket();
    final repo = ChatRepositoryImpl(
      remoteDataSource: _FakeRemote(<ChatMessage>[]),
      socketDataSource: socket,
    );

    expectLater(repo.messages, emits(predicate<ChatMessage>((m) => m.id == 'm9')));
    socket.messageController.add(_msg('m9'));
  });

  test('dispose disposes the socket', () {
    final socket = _FakeSocket();
    final repo = ChatRepositoryImpl(
      remoteDataSource: _FakeRemote(<ChatMessage>[]),
      socketDataSource: socket,
    );

    repo.dispose();

    expect(socket.disposed, isTrue);
  });
}
```

- [ ] **Step 3: Rodar o teste e confirmar que falha**

Run: `flutter test test/features/chat/chat_repository_impl_test.dart`
Expected: FAIL — `chat_repository_impl.dart` não existe.

- [ ] **Step 4: Implementar o repositório**

`lib/src/features/chat/data/repositories/chat_repository_impl.dart`:

```dart
import '../../../../core/result/result.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';
import '../datasources/chat_socket_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({
    required ChatRemoteDataSource remoteDataSource,
    required ChatSocketDataSource socketDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _socketDataSource = socketDataSource;

  final ChatRemoteDataSource _remoteDataSource;
  final ChatSocketDataSource _socketDataSource;

  @override
  Future<Result<List<ChatMessage>>> loadHistory(String serviceId) async {
    try {
      final messages = await _remoteDataSource.getServiceMessages(serviceId);
      return Success(messages);
    } on Exception {
      return const Failure('Nao foi possivel carregar as mensagens agora.');
    }
  }

  @override
  void connect(String token) => _socketDataSource.connect(token);

  @override
  void joinService(String serviceId) =>
      _socketDataSource.joinService(serviceId);

  @override
  void sendMessage({
    required String serviceId,
    required String recipientId,
    required String content,
  }) =>
      _socketDataSource.sendMessage(
        serviceId: serviceId,
        recipientId: recipientId,
        content: content,
      );

  @override
  Stream<ChatMessage> get messages => _socketDataSource.onNewMessage;

  @override
  Stream<String> get errors => _socketDataSource.onError;

  @override
  void dispose() => _socketDataSource.dispose();
}
```

- [ ] **Step 5: Rodar o teste e confirmar que passa**

Run: `flutter test test/features/chat/chat_repository_impl_test.dart`
Expected: PASS (4 testes).

- [ ] **Step 6: Commit**

```bash
git add lib/src/features/chat/domain/repositories/chat_repository.dart lib/src/features/chat/data/repositories/chat_repository_impl.dart test/features/chat/chat_repository_impl_test.dart
git commit -m "feat(chat): add chat repository orchestrating REST and socket"
```

---

### Task 5: ViewModel da thread

**Files:**
- Create: `lib/src/features/chat/presentation/viewmodels/chat_thread_view_model.dart`
- Test: `test/features/chat/chat_thread_view_model_test.dart`

- [ ] **Step 1: Escrever o teste que falha**

`test/features/chat/chat_thread_view_model_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tafeito_flutter/src/core/result/result.dart';
import 'package:tafeito_flutter/src/features/chat/domain/entities/chat_message.dart';
import 'package:tafeito_flutter/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:tafeito_flutter/src/features/chat/presentation/viewmodels/chat_thread_view_model.dart';

class _FakeRepo implements ChatRepository {
  _FakeRepo({this.history = const <ChatMessage>[], this.fail = false});

  final List<ChatMessage> history;
  final bool fail;
  final StreamController<ChatMessage> messageController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<String> errorController =
      StreamController<String>.broadcast();

  bool connected = false;
  bool joined = false;
  final List<String> sent = [];
  bool disposed = false;

  @override
  Future<Result<List<ChatMessage>>> loadHistory(String serviceId) async {
    if (fail) return const Failure('erro');
    return Success(history);
  }

  @override
  void connect(String token) => connected = true;
  @override
  void joinService(String serviceId) => joined = true;
  @override
  void sendMessage(
      {required String serviceId,
      required String recipientId,
      required String content}) {
    sent.add(content);
  }

  @override
  Stream<ChatMessage> get messages => messageController.stream;
  @override
  Stream<String> get errors => errorController.stream;
  @override
  void dispose() {
    disposed = true;
    messageController.close();
    errorController.close();
  }
}

ChatMessage _msg(String id, {String sender = 'u2', String content = 'oi'}) =>
    ChatMessage(
      id: id,
      serviceId: 's1',
      senderId: sender,
      recipientId: 'u2',
      content: content,
      status: 'sent',
      createdAt: DateTime.utc(2026, 6, 11),
    );

void main() {
  test('init loads history, connects and joins', () async {
    final repo = _FakeRepo(history: [_msg('m1')]);
    final vm = ChatThreadViewModel(repository: repo, currentUserId: 'u1');

    await vm.init('s1', 'u2', 'token');

    expect(vm.messages.single.id, 'm1');
    expect(vm.isLoading, isFalse);
    expect(repo.connected, isTrue);
    expect(repo.joined, isTrue);
  });

  test('init sets error message on history failure', () async {
    final repo = _FakeRepo(fail: true);
    final vm = ChatThreadViewModel(repository: repo, currentUserId: 'u1');

    await vm.init('s1', 'u2', 'token');

    expect(vm.errorMessage, 'erro');
    expect(vm.messages, isEmpty);
  });

  test('incoming message is appended', () async {
    final repo = _FakeRepo();
    final vm = ChatThreadViewModel(repository: repo, currentUserId: 'u1');
    await vm.init('s1', 'u2', 'token');

    repo.messageController.add(_msg('m2'));
    await Future<void>.delayed(Duration.zero);

    expect(vm.messages.single.id, 'm2');
  });

  test('duplicate message id is not appended twice', () async {
    final repo = _FakeRepo();
    final vm = ChatThreadViewModel(repository: repo, currentUserId: 'u1');
    await vm.init('s1', 'u2', 'token');

    repo.messageController.add(_msg('m3'));
    repo.messageController.add(_msg('m3'));
    await Future<void>.delayed(Duration.zero);

    expect(vm.messages, hasLength(1));
  });

  test('send ignores empty content and forwards valid content', () async {
    final repo = _FakeRepo();
    final vm = ChatThreadViewModel(repository: repo, currentUserId: 'u1');
    await vm.init('s1', 'u2', 'token');

    vm.send('   ');
    vm.send('ola');

    expect(repo.sent, ['ola']);
  });

  test('isMine compares sender to current user', () async {
    final repo = _FakeRepo();
    final vm = ChatThreadViewModel(repository: repo, currentUserId: 'u1');
    await vm.init('s1', 'u2', 'token');

    expect(vm.isMine(_msg('m', sender: 'u1')), isTrue);
    expect(vm.isMine(_msg('m', sender: 'u2')), isFalse);
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/features/chat/chat_thread_view_model_test.dart`
Expected: FAIL — `chat_thread_view_model.dart` não existe.

- [ ] **Step 3: Implementar o viewmodel**

`lib/src/features/chat/presentation/viewmodels/chat_thread_view_model.dart`:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

class ChatThreadViewModel extends ChangeNotifier {
  ChatThreadViewModel({
    required ChatRepository repository,
    required String currentUserId,
  })  : _repository = repository,
        _currentUserId = currentUserId;

  final ChatRepository _repository;
  final String _currentUserId;

  List<ChatMessage> _messages = const [];
  bool _isLoading = false;
  String? _errorMessage;

  late String _serviceId;
  late String _recipientId;

  StreamSubscription<ChatMessage>? _messageSub;
  StreamSubscription<String>? _errorSub;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isMine(ChatMessage message) => message.senderId == _currentUserId;

  Future<void> init(String serviceId, String recipientId, String token) async {
    _serviceId = serviceId;
    _recipientId = recipientId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.loadHistory(serviceId);
    switch (result) {
      case Success(:final data):
        _messages = [...data];
      case Failure(:final message):
        _errorMessage = message;
    }

    _repository.connect(token);
    _repository.joinService(serviceId);
    _messageSub = _repository.messages.listen(_onMessage);
    _errorSub = _repository.errors.listen(_onError);

    _isLoading = false;
    notifyListeners();
  }

  void send(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _repository.sendMessage(
      serviceId: _serviceId,
      recipientId: _recipientId,
      content: trimmed,
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _onMessage(ChatMessage message) {
    if (_messages.any((existing) => existing.id == message.id)) {
      return;
    }
    _messages = [..._messages, message];
    notifyListeners();
  }

  void _onError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _errorSub?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `flutter test test/features/chat/chat_thread_view_model_test.dart`
Expected: PASS (6 testes).

- [ ] **Step 5: Commit**

```bash
git add lib/src/features/chat/presentation/viewmodels/chat_thread_view_model.dart test/features/chat/chat_thread_view_model_test.dart
git commit -m "feat(chat): add chat thread view model"
```

---

### Task 6: Tela da thread (ChatThreadPage)

**Files:**
- Create: `lib/src/features/chat/presentation/views/chat_thread_page.dart`
- Test: `test/features/chat/chat_thread_page_test.dart`

- [ ] **Step 1: Escrever o teste de widget que falha**

`test/features/chat/chat_thread_page_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tafeito_flutter/src/core/result/result.dart';
import 'package:tafeito_flutter/src/features/chat/domain/entities/chat_message.dart';
import 'package:tafeito_flutter/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:tafeito_flutter/src/features/chat/presentation/views/chat_thread_page.dart';

class _FakeRepo implements ChatRepository {
  final StreamController<ChatMessage> messageController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<String> errorController =
      StreamController<String>.broadcast();
  final List<String> sent = [];

  @override
  Future<Result<List<ChatMessage>>> loadHistory(String serviceId) async {
    return Success([
      ChatMessage(
        id: 'm1',
        serviceId: 's1',
        senderId: 'other',
        recipientId: 'me',
        content: 'ola cliente',
        status: 'sent',
        createdAt: DateTime.utc(2026, 6, 11, 20, 0),
      ),
    ]);
  }

  @override
  void connect(String token) {}
  @override
  void joinService(String serviceId) {}
  @override
  void sendMessage(
      {required String serviceId,
      required String recipientId,
      required String content}) {
    sent.add(content);
  }

  @override
  Stream<ChatMessage> get messages => messageController.stream;
  @override
  Stream<String> get errors => errorController.stream;
  @override
  void dispose() {
    messageController.close();
    errorController.close();
  }
}

void main() {
  testWidgets('renders history and sends a message', (tester) async {
    final repo = _FakeRepo();
    await tester.pumpWidget(MaterialApp(
      home: ChatThreadPage(
        repository: repo,
        serviceId: 's1',
        recipientId: 'other',
        title: 'Plantio de flores',
        currentUserId: 'me',
        token: 'token',
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Plantio de flores'), findsOneWidget);
    expect(find.text('ola cliente'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'oi prestador');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(repo.sent, ['oi prestador']);
    expect(find.text('oi prestador'), findsNothing); // só aparece via echo
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/features/chat/chat_thread_page_test.dart`
Expected: FAIL — `chat_thread_page.dart` não existe.

- [ ] **Step 3: Implementar a tela**

`lib/src/features/chat/presentation/views/chat_thread_page.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../viewmodels/chat_thread_view_model.dart';

class ChatThreadPage extends StatefulWidget {
  const ChatThreadPage({
    required this.repository,
    required this.serviceId,
    required this.recipientId,
    required this.title,
    required this.currentUserId,
    required this.token,
    super.key,
  });

  final ChatRepository repository;
  final String serviceId;
  final String recipientId;
  final String title;
  final String currentUserId;
  final String token;

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  late final ChatThreadViewModel _viewModel;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = ChatThreadViewModel(
      repository: widget.repository,
      currentUserId: widget.currentUserId,
    );
    _viewModel.addListener(_onChanged);
    _viewModel.init(widget.serviceId, widget.recipientId, widget.token);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    _viewModel.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
    setState(() {});
  }

  void _send() {
    _viewModel.send(_inputController.text);
    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_viewModel.isLoading && _viewModel.messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primary),
      );
    }

    if (_viewModel.errorMessage != null && _viewModel.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _viewModel.init(
                  widget.serviceId,
                  widget.recipientId,
                  widget.token,
                ),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_viewModel.messages.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma mensagem ainda.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _viewModel.messages.length,
      itemBuilder: (context, index) {
        final message = _viewModel.messages[index];
        return _MessageBubble(
          message: message,
          isMine: _viewModel.isMine(message),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Mensagem...',
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppTheme.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide:
                        const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final time =
        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: isMine ? AppTheme.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMine ? Colors.white : AppTheme.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isMine ? Colors.white70 : AppTheme.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `flutter test test/features/chat/chat_thread_page_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/features/chat/presentation/views/chat_thread_page.dart test/features/chat/chat_thread_page_test.dart
git commit -m "feat(chat): add chat thread screen UI"
```

---

### Task 7: Integração — DTO, entrada e wiring

**Files:**
- Modify: `lib/src/features/services/data/models/service_dto.dart`
- Modify: `lib/src/features/auth/presentation/views/services_page.dart`
- Modify: `lib/src/core/theme/main_page.dart`
- Modify: `lib/src/app.dart`
- Test: `test/features/chat/service_dto_provider_test.dart`

- [ ] **Step 1: Escrever o teste que falha (providerId no ServiceDto)**

`test/features/chat/service_dto_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:tafeito_flutter/src/features/services/data/models/service_dto.dart';

void main() {
  test('ServiceDto parses providerId from userId/user_id', () {
    final a = ServiceDto.fromJson({'id': 's1', 'userId': 'u1'});
    final b = ServiceDto.fromJson({'id': 's2', 'user_id': 'u2'});
    final c = ServiceDto.fromJson({'id': 's3'});

    expect(a.providerId, 'u1');
    expect(b.providerId, 'u2');
    expect(c.providerId, '');
  });
}
```

- [ ] **Step 2: Rodar e confirmar que falha**

Run: `flutter test test/features/chat/service_dto_provider_test.dart`
Expected: FAIL — `providerId` não existe em `ServiceDto`.

- [ ] **Step 3: Adicionar providerId ao ServiceDto**

Em `lib/src/features/services/data/models/service_dto.dart`, adicionar o campo e o parse. Resultado completo do arquivo:

```dart
class ServiceDto {
  const ServiceDto({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.providerId,
    this.duration,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final String price;
  final String providerId;
  final String? duration;

  factory ServiceDto.fromJson(Map<String, Object?> json) {
    return ServiceDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      providerId: (json['userId'] ?? json['user_id'])?.toString() ?? '',
      duration: _emptyToNull(json['duration']),
    );
  }
}

String? _emptyToNull(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) {
    return null;
  }

  return text;
}
```

- [ ] **Step 4: Rodar e confirmar que passa**

Run: `flutter test test/features/chat/service_dto_provider_test.dart`
Expected: PASS.

- [ ] **Step 5: Adicionar o factory do repositório e wiring no app.dart**

Em `lib/src/app.dart`:

5a. Adicionar imports (junto aos demais imports de features no topo):

```dart
import 'features/chat/data/datasources/chat_remote_data_source.dart';
import 'features/chat/data/datasources/chat_socket_data_source.dart';
import 'features/chat/data/repositories/chat_repository_impl.dart';
import 'features/chat/domain/repositories/chat_repository.dart';
```

5b. Adicionar a constante da base do WebSocket dentro de `_TaFeitoAppState` (logo após a declaração da classe State, antes de `initState`):

```dart
  static const _wsBaseUrl = String.fromEnvironment(
    'TAFEITO_WS_BASE_URL',
    defaultValue: 'https://tafeito.rietto.com',
  );

  ChatRepository _createChatRepository() {
    return ChatRepositoryImpl(
      remoteDataSource: ApiChatRemoteDataSource(apiClient: _apiClient),
      socketDataSource: SocketIoChatDataSource(wsBaseUrl: _wsBaseUrl),
    );
  }
```

5c. Nas DUAS construções de `MainPage` (rota `'/'` por volta da linha 102 e rota `MainPage.routeName` por volta da linha 149), adicionar o parâmetro `chatRepositoryFactory: _createChatRepository`:

```dart
                    child: MainPage(
                      sessionManager: _sessionManager,
                      profileRepository: _profileRepository,
                      servicesRepository: _servicesRepository,
                      chatRepositoryFactory: _createChatRepository,
                    ),
```

(repetir igual no segundo `MainPage`).

- [ ] **Step 6: Encadear factory + sessionManager por MainPage até ServicesPage**

Em `lib/src/core/theme/main_page.dart`:

6a. Adicionar imports no topo:

```dart
import 'package:tafeito_flutter/src/features/chat/domain/repositories/chat_repository.dart';
```

6b. Adicionar o campo e o parâmetro do construtor:

```dart
  const MainPage({
    required this.sessionManager,
    required this.profileRepository,
    required this.servicesRepository,
    required this.chatRepositoryFactory,
    super.key,
  });

  static const routeName = '/main';

  final SessionManager sessionManager;
  final ProfileRepository profileRepository;
  final ServicesRepository servicesRepository;
  final ChatRepository Function() chatRepositoryFactory;
```

6c. Passar para `ServicesPage` no `build`:

```dart
      ServicesPage(
        servicesRepository: widget.servicesRepository,
        sessionManager: widget.sessionManager,
        chatRepositoryFactory: widget.chatRepositoryFactory,
      ),
```

- [ ] **Step 7: Botão "Conversar" na lista Explorar abrindo a thread**

Em `lib/src/features/auth/presentation/views/services_page.dart`:

7a. Adicionar imports no topo:

```dart
import 'package:tafeito_flutter/src/core/session/session_manager.dart';
import 'package:tafeito_flutter/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:tafeito_flutter/src/features/chat/presentation/views/chat_thread_page.dart';
```

7b. Adicionar os campos no `ServicesPage`:

```dart
class ServicesPage extends StatefulWidget {
  const ServicesPage({
    required this.servicesRepository,
    required this.sessionManager,
    required this.chatRepositoryFactory,
    super.key,
  });

  final ServicesRepository servicesRepository;
  final SessionManager sessionManager;
  final ChatRepository Function() chatRepositoryFactory;
```

7c. Passar os dados ao `_ServiceTile` no `itemBuilder`:

```dart
            itemBuilder: (context, index) {
              return _ServiceTile(
                service: _viewModel.services[index],
                sessionManager: widget.sessionManager,
                chatRepositoryFactory: widget.chatRepositoryFactory,
              );
            },
```

7d. Atualizar `_ServiceTile` para receber os novos campos e renderizar o botão. Substituir a classe `_ServiceTile` inteira por:

```dart
class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.service,
    required this.sessionManager,
    required this.chatRepositoryFactory,
  });

  final ServiceDto service;
  final SessionManager sessionManager;
  final ChatRepository Function() chatRepositoryFactory;

  void _openChat(BuildContext context) {
    final session = sessionManager.session;
    if (session == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatThreadPage(
          repository: chatRepositoryFactory(),
          serviceId: service.id,
          recipientId: service.providerId,
          title: service.name.isEmpty ? 'Conversa' : service.name,
          currentUserId: session.user.id,
          token: session.accessToken,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duration = service.duration;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.inputBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    service.name.isEmpty ? 'Servico' : service.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (service.price.isNotEmpty)
                  Text(
                    'R\$ ${service.price}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (service.description.isNotEmpty)
              Text(
                service.description,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (service.category.isNotEmpty)
                  _MetaChip(label: service.category),
                if (duration != null) _MetaChip(label: duration),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _openChat(context),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text(
                  'Conversar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 8: Rodar a suíte inteira e o analyzer**

Run: `flutter analyze`
Expected: "No issues found!" (zero errors).

Run: `flutter test`
Expected: todos os testes passam (incluindo os de chat e o `widget_test.dart` existente).

Nota: se `widget_test.dart` instanciar `MainPage`/`ServicesPage` diretamente, atualizar a chamada de teste para passar `sessionManager` e `chatRepositoryFactory` (usar um fake que retorne um `ChatRepository` simples). Se ele só monta `TaFeitoApp`, nenhuma mudança é necessária.

- [ ] **Step 9: Commit**

```bash
git add lib/src/features/services/data/models/service_dto.dart lib/src/features/auth/presentation/views/services_page.dart lib/src/core/theme/main_page.dart lib/src/app.dart test/features/chat/service_dto_provider_test.dart
git commit -m "feat(chat): wire chat thread entry from services list"
```

---

## Validação manual (após todas as tasks)

1. Subir a API local em `localhost:3000` com o banco migrado.
2. Rodar o app: `flutter run -d chrome --dart-define=TAFEITO_API_BASE_URL=http://localhost:3000 --dart-define=TAFEITO_WS_BASE_URL=http://localhost:3000`.
3. Logar com dois usuários distintos (duas abas/dispositivos), ambos abrindo "Conversar" no mesmo serviço.
4. Enviar mensagem de A → aparece em A e B em tempo real.
5. Fechar e reabrir a thread → histórico persiste (carregado via REST).
6. Sinalizar limitação conhecida: WebSocket em produção (atrás do nginx) requer proxy de upgrade em `/socket.io`; não testável só com o cliente.

## Notas finais

- **Indicador de digitação (#5)** é a próxima branch (`feat/Indicador-chat`), montando sobre estas unidades: adiciona `typing` (emit) e `onUserTyping` (stream) no socket data source + repo + viewmodel, e um widget "digitando..." na thread.
- Nenhum endpoint novo de API é necessário para esta branch.
