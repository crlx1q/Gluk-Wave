import 'dart:async';
import 'dart:convert';
import 'dart:io';

final Map<String, _Room> rooms = <String, _Room>{};

Future<void> main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8787;
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('Gluk Wave rooms: ws://0.0.0.0:$port/ws');
  await for (final request in server) {
    if (request.uri.path == '/health') {
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(<String, Object>{'ok': true, 'rooms': rooms.length}))
        ..close();
      continue;
    }
    if (request.uri.path != '/ws' || !WebSocketTransformer.isUpgradeRequest(request)) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Gluk Wave room server')
        ..close();
      continue;
    }
    final socket = await WebSocketTransformer.upgrade(request);
    unawaited(_handle(socket));
  }
}

Future<void> _handle(WebSocket socket) async {
  _Client? client;
  try {
    await for (final raw in socket) {
      if (raw is! String) continue;
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) continue;
      final type = data['type'] as String? ?? '';
      final payload = (data['payload'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
      final roomCode = (payload['room'] as String? ?? client?.room ?? 'WAVE-42').toUpperCase();
      final room = rooms.putIfAbsent(roomCode, () => _Room(roomCode));

      switch (type) {
        case 'join':
          client?.detach();
          final isAdmin = room.clients.isEmpty;
          client = _Client(socket: socket, room: roomCode, name: payload['name'] as String? ?? 'Гость', isAdmin: isAdmin);
          room.clients.add(client);
          room.broadcast('presence', <String, dynamic>{'room': roomCode, 'name': client.name, 'joined': true});
          if (room.lastPlayback != null) room.send(client, 'playback', room.lastPlayback!);
          room.send(client, 'role', <String, dynamic>{'isAdmin': client.isAdmin, 'everyoneCanControl': room.everyoneCanControl});
          room.send(client, 'permission', <String, dynamic>{'everyoneCanControl': room.everyoneCanControl});
          break;
        case 'chat':
          if (client == null) break;
          room.broadcast('chat', <String, dynamic>{'room': roomCode, 'name': client.name, 'text': payload['text'] as String? ?? ''}, except: client);
          break;
        case 'playback':
          if (client == null) break;
          if (!client.isAdmin && !room.everyoneCanControl) {
            room.send(client, 'error', <String, dynamic>{'message': 'Только администратор управляет музыкой'});
            break;
          }
          room.lastPlayback = <String, dynamic>{
            'room': roomCode,
            'trackId': payload['trackId'],
            'playing': payload['playing'] == true,
            'positionMs': payload['positionMs'] is int ? payload['positionMs'] : 0,
          };
          room.broadcast('playback', room.lastPlayback!, except: client);
          break;
        case 'permission':
          if (client == null || !client.isAdmin) break;
          room.everyoneCanControl = payload['everyoneCanControl'] == true;
          room.broadcast('permission', <String, dynamic>{'everyoneCanControl': room.everyoneCanControl});
          break;
      }
    }
  } catch (_) {
    // Disconnects are normal for this tiny prototype server.
  } finally {
    if (client != null) {
      final room = rooms[client.room];
      final wasAdmin = client.isAdmin;
      client.detach();
      room?.broadcast('presence', <String, dynamic>{'room': client.room, 'name': client.name, 'joined': false});
      if (room != null && room.clients.isEmpty) {
        rooms.remove(client.room);
      } else if (room != null && wasAdmin) {
        final nextAdmin = room.clients.first;
        nextAdmin.isAdmin = true;
        room.send(nextAdmin, 'role', <String, dynamic>{'isAdmin': true, 'everyoneCanControl': room.everyoneCanControl});
      }
    }
  }
}

class _Room {
  _Room(this.code);
  final String code;
  final Set<_Client> clients = <_Client>{};
  bool everyoneCanControl = false;
  Map<String, dynamic>? lastPlayback;

  void send(_Client client, String type, Map<String, dynamic> payload) {
    if (client.socket.readyState == WebSocket.open) {
      client.socket.add(jsonEncode(<String, dynamic>{'type': type, 'payload': payload}));
    }
  }

  void broadcast(String type, Map<String, dynamic> payload, {_Client? except}) {
    for (final client in clients.toList()) {
      if (identical(client, except)) continue;
      send(client, type, payload);
    }
  }
}

class _Client {
  _Client({required this.socket, required this.room, required this.name, required this.isAdmin});
  final WebSocket socket;
  final String room;
  final String name;
  bool isAdmin;

  void detach() {
    rooms[room]?.clients.remove(this);
  }
}
