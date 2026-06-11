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
