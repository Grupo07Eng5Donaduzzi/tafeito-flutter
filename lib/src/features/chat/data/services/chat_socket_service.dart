import 'dart:async';
import 'dart:developer';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../models/chat_message_dto.dart';

class ChatSocketService {
  io.Socket? _socket;
  final _messageStreamController =
      StreamController<ChatMessageDto>.broadcast();

  Stream<ChatMessageDto> get messages => _messageStreamController.stream;
  bool get isConnected => _socket?.connected ?? false;

  void connect({
    required String serverUrl,
    required String token,
    required String conversationId,
  }) {
    if (_socket != null) return;

    final url = serverUrl.endsWith('/') ? '${serverUrl}chat' : '$serverUrl/chat';
    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      log('[ChatSocket] connected, joining room $conversationId');
      _socket!.emit('join-service', {'serviceId': conversationId});
    });

    _socket!.on('new-message', (data) {
      if (data is! Map) return;
      final msgData = data['message'];
      if (msgData is! Map) return;
      try {
        final msg = ChatMessageDto.fromJson(
          msgData.map((k, v) => MapEntry(k.toString(), v)),
        );
        if (!_messageStreamController.isClosed) {
          _messageStreamController.add(msg);
        }
      } catch (e) {
        log('[ChatSocket] failed to parse new-message: $e');
      }
    });

    _socket!.onConnectError((e) => log('[ChatSocket] connect error: $e'));
    _socket!.onError((e) => log('[ChatSocket] error: $e'));
    _socket!.onDisconnect((_) => log('[ChatSocket] disconnected'));

    _socket!.connect();
  }

  void sendMessage({
    required String conversationId,
    required String recipientId,
    required String content,
  }) {
    _socket?.emit('send-message', {
      'serviceId': conversationId,
      'recipientId': recipientId,
      'content': content,
    });
  }

  void leaveAndDisconnect(String conversationId) {
    _socket?.emit('leave-service');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    _messageStreamController.close();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
