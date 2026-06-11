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

  testWidgets('renders a message arriving over the stream', (tester) async {
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

    repo.messageController.add(
      ChatMessage(
        id: 'm2',
        serviceId: 's1',
        senderId: 'me',
        recipientId: 'other',
        content: 'mensagem ao vivo',
        status: 'sent',
        createdAt: DateTime.utc(2026, 6, 11, 20, 5),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('mensagem ao vivo'), findsOneWidget);
  });
}
