import 'dart:async';

import 'package:flutter/foundation.dart';
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
    _socket?.dispose();
    _socket = null;
    final url = '$_wsBaseUrl/chat';
    debugPrint('[chat-socket] connecting to $url');
    final socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'token': token})
          .enableForceNew()
          .build(),
    );

    socket.onConnect((_) {
      debugPrint('[chat-socket] connected (id: ${socket.id})');
      final serviceId = _serviceId;
      if (serviceId != null) {
        socket.emit('join-service', {'serviceId': serviceId});
      }
    });

    socket.onConnectError((data) {
      debugPrint('[chat-socket] connect_error: $data');
    });

    socket.onError((data) {
      debugPrint('[chat-socket] error: $data');
    });

    socket.onDisconnect((reason) {
      debugPrint('[chat-socket] disconnected: $reason');
    });

    socket.on('new-message', (data) {
      if (data is! Map) return;
      final raw = data['message'] is Map ? data['message'] : data;
      if (raw is Map && raw['id'] != null) {
        try {
          _messageController.add(ChatMessageDto.fromJson(asJsonObject(raw)));
        } catch (_) {
          // Ignore malformed message payloads rather than crashing the socket.
        }
      }
    });

    socket.on('error', (data) {
      final text = data is Map ? data['message']?.toString() : data?.toString();
      _errorController.add(text ?? 'Erro no chat.');
    });

    // NestJS emits WS validation/handler failures on the 'exception' event.
    // Without this they fail silently (e.g. a rejected send-message payload).
    socket.on('exception', (data) {
      debugPrint('[chat-socket] exception: $data');
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
    _serviceId = null;
    _messageController.close();
    _errorController.close();
  }
}
