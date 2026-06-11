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
