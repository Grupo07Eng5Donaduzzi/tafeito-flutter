import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tafeito_flutter/src/core/result/result.dart';
import 'package:tafeito_flutter/src/features/chat/domain/entities/chat_message.dart';
import 'package:tafeito_flutter/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:tafeito_flutter/src/features/chat/presentation/viewmodels/conversation_list_view_model.dart';
import 'package:tafeito_flutter/src/features/services/data/models/service_dto.dart';
import 'package:tafeito_flutter/src/features/services/domain/repositories/services_repository.dart';

class _FakeChatRepo implements ChatRepository {
  _FakeChatRepo({this.userMessages = const <ChatMessage>[], this.fail = false});

  final List<ChatMessage> userMessages;
  final bool fail;

  @override
  Future<Result<List<ChatMessage>>> loadUserMessages(String userId) async {
    if (fail) return const Failure('erro');
    return Success(userMessages);
  }

  // Unused by the conversation list.
  @override
  Future<Result<List<ChatMessage>>> loadHistory(String serviceId) async =>
      const Success(<ChatMessage>[]);
  @override
  void connect(String token) {}
  @override
  void joinService(String serviceId) {}
  @override
  void sendMessage({
    required String serviceId,
    required String recipientId,
    required String content,
  }) {}
  @override
  Stream<ChatMessage> get messages => const Stream.empty();
  @override
  Stream<String> get errors => const Stream.empty();
  @override
  void dispose() {}
}

class _FakeServicesRepo implements ServicesRepository {
  _FakeServicesRepo(this.services);

  final List<ServiceDto> services;

  @override
  Future<Result<List<ServiceDto>>> findAll({String? category}) async =>
      Success(services);
}

ChatMessage _msg(
  String id, {
  required String serviceId,
  required String sender,
  required String recipient,
  required String content,
  required DateTime createdAt,
}) =>
    ChatMessage(
      id: id,
      serviceId: serviceId,
      senderId: sender,
      recipientId: recipient,
      content: content,
      status: 'sent',
      createdAt: createdAt,
    );

ServiceDto _service(String id, String name) => ServiceDto(
      id: id,
      name: name,
      description: '',
      category: '',
      price: '',
      providerId: 'prov',
    );

void main() {
  test('groups messages by service and keeps the latest per conversation',
      () async {
    final repo = _FakeChatRepo(userMessages: [
      _msg('m1',
          serviceId: 's1',
          sender: 'me',
          recipient: 'u2',
          content: 'oi',
          createdAt: DateTime.utc(2026, 6, 11, 10)),
      _msg('m2',
          serviceId: 's1',
          sender: 'u2',
          recipient: 'me',
          content: 'tudo bem?',
          createdAt: DateTime.utc(2026, 6, 11, 11)),
      _msg('m3',
          serviceId: 's2',
          sender: 'me',
          recipient: 'u3',
          content: 'ola',
          createdAt: DateTime.utc(2026, 6, 11, 9)),
    ]);
    final services = _FakeServicesRepo([
      _service('s1', 'Encanamento'),
      _service('s2', 'Pintura'),
    ]);
    final vm = ConversationListViewModel(
      chatRepository: repo,
      servicesRepository: services,
      currentUserId: 'me',
    );

    await vm.load();

    expect(vm.conversations, hasLength(2));
    // Sorted by most recent first: s1 (11h) before s2 (9h).
    final first = vm.conversations[0];
    expect(first.serviceId, 's1');
    expect(first.title, 'Encanamento');
    expect(first.lastMessage, 'tudo bem?');
    expect(first.counterpartId, 'u2');
    expect(vm.isLoading, isFalse);
  });

  test('counterpart is the other party of the latest message', () async {
    final repo = _FakeChatRepo(userMessages: [
      _msg('m1',
          serviceId: 's1',
          sender: 'me',
          recipient: 'u2',
          content: 'oi',
          createdAt: DateTime.utc(2026, 6, 11, 10)),
    ]);
    final vm = ConversationListViewModel(
      chatRepository: repo,
      servicesRepository: _FakeServicesRepo(const []),
      currentUserId: 'me',
    );

    await vm.load();

    expect(vm.conversations.single.counterpartId, 'u2');
  });

  test('falls back to a generic title when the service is unknown', () async {
    final repo = _FakeChatRepo(userMessages: [
      _msg('m1',
          serviceId: 'sX',
          sender: 'u2',
          recipient: 'me',
          content: 'oi',
          createdAt: DateTime.utc(2026, 6, 11, 10)),
    ]);
    final vm = ConversationListViewModel(
      chatRepository: repo,
      servicesRepository: _FakeServicesRepo(const []),
      currentUserId: 'me',
    );

    await vm.load();

    expect(vm.conversations.single.title, 'Conversa');
  });

  test('sets error message when loading fails', () async {
    final repo = _FakeChatRepo(fail: true);
    final vm = ConversationListViewModel(
      chatRepository: repo,
      servicesRepository: _FakeServicesRepo(const []),
      currentUserId: 'me',
    );

    await vm.load();

    expect(vm.errorMessage, 'erro');
    expect(vm.conversations, isEmpty);
  });
}
