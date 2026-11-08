import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef MessageHandler = void Function(Map<String, dynamic> message);

class LanService {
  HttpServer? _server;
  final Map<WebSocket, String> _clients = {};
  WebSocketChannel? _client;
  StreamSubscription? _clientSub;
  MessageHandler? onMessage;
  void Function(String)? onClientConnected;
  void Function(String)? onClientDisconnected;

  bool get isHosting => _server != null;

  Future<int> startHost({int port = 4040}) async {
    await stop();
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port, shared: true);
    _server!.listen((request) async {
      if (!WebSocketTransformer.isUpgradeRequest(request)) {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
        return;
      }
      final socket = await WebSocketTransformer.upgrade(request);
      final id = DateTime.now().microsecondsSinceEpoch.toString();
      _clients[socket] = id;
      onClientConnected?.call(id);
      socket.listen((raw) {
        try {
          final decoded = jsonDecode(raw as String);
          if (decoded is Map<String, dynamic>) {
            decoded['_clientId'] = id;
            onMessage?.call(decoded);
          }
        } catch (_) {}
      }, onDone: () {
        _clients.remove(socket);
        onClientDisconnected?.call(id);
      }, onError: (_) {
        _clients.remove(socket);
        onClientDisconnected?.call(id);
      });
    });
    return _server!.port;
  }

  Future<void> joinHost(String ip, {int port = 4040}) async {
    await leaveHost();
    final channel = IOWebSocketChannel.connect(
      Uri(scheme: 'ws', host: ip.trim(), port: port, path: '/game'),
      connectTimeout: const Duration(seconds: 8),
    );
    _client = channel;
    await channel.ready;
    _clientSub = channel.stream.listen((raw) {
      try {
        final decoded = jsonDecode(raw as String);
        if (decoded is Map<String, dynamic>) onMessage?.call(decoded);
      } catch (_) {}
    }, onError: (_) {}, onDone: () {});
  }

  void sendToHost(Map<String, dynamic> message) {
    _client?.sink.add(jsonEncode(message));
  }

  void broadcast(Map<String, dynamic> message) {
    final encoded = jsonEncode(message);
    for (final socket in _clients.keys.toList()) {
      if (socket.readyState == WebSocket.open) {
        socket.add(encoded);
      }
    }
  }

  void sendToClient(String id, Map<String, dynamic> message) {
    final socket = _clients.entries.where((e) => e.value == id).map((e) => e.key).firstOrNull;
    if (socket != null && socket.readyState == WebSocket.open) socket.add(jsonEncode(message));
  }

  Future<void> leaveHost() async {
    await _clientSub?.cancel();
    _clientSub = null;
    await _client?.sink.close();
    _client = null;
  }

  Future<void> stop() async {
    await leaveHost();
    for (final socket in _clients.keys.toList()) {
      await socket.close();
    }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
