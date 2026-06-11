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
      expect(message.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });
}
