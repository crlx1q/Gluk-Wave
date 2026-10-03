import 'dart:async';
import 'dart:convert';
import 'dart:io';

class RoomEvent {
  const RoomEvent(this.type, this.payload);
  final String type;
  final Map<String, dynamic> payload;
}

class RoomClient {
  WebSocket? _socket;
  final StreamController<RoomEvent> _events = StreamController<RoomEvent>.broadcast();
  Stream<RoomEvent> get events => _events.stream;
  bool get connected => _socket != null;

  Future<void> connect(String url) async {
    await disconnect();
    final socket = await WebSocket.connect(url).timeout(const Duration(seconds: 4));
    _socket = socket;
    socket.listen(
      (message) {
        try {
          final data = (jsonDecode(message as String) as Map<dynamic, dynamic>).cast<String, dynamic>();
          final type = data['type'] as String? ?? 'unknown';
          final nested = data['payload'];
          final payload = nested is Map
              ? nested.cast<String, dynamic>()
              : Map<String, dynamic>.from(data)..remove('type');
          _events.add(RoomEvent(type, payload));
        } catch (_) {}
      },
      onDone: () {
        _socket = null;
        _events.add(const RoomEvent('disconnected', <String, dynamic>{}));
      },
      onError: (_) {
        _socket = null;
        _events.add(const RoomEvent('disconnected', <String, dynamic>{}));
      },
    );
  }

  void send(String type, Map<String, dynamic> payload) {
    _socket?.add(jsonEncode(<String, dynamic>{'type': type, 'payload': payload}));
  }

  void join({required String room, required String name}) => send('join', <String, dynamic>{'room': room, 'name': name});
  void chat({required String room, required String text}) => send('chat', <String, dynamic>{'room': room, 'text': text});
  void playback({required String room, required String trackId, required bool playing, required int positionMs}) => send(
        'playback',
        <String, dynamic>{'room': room, 'trackId': trackId, 'playing': playing, 'positionMs': positionMs},
      );
  void permission({required String room, required bool everyoneCanControl}) => send(
        'permission',
        <String, dynamic>{'room': room, 'everyoneCanControl': everyoneCanControl},
      );

  Future<void> disconnect() async {
    final socket = _socket;
    _socket = null;
    if (socket != null) await socket.close();
  }

  Future<void> dispose() async {
    await disconnect();
    await _events.close();
  }
}
