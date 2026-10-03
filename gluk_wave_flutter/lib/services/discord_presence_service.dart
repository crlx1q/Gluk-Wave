import 'dart:io';

import 'package:discord_rich_presence/discord_rich_presence.dart';

import '../models.dart';

class DiscordPresenceService {
  static const String applicationId = String.fromEnvironment('DISCORD_APP_ID', defaultValue: '');
  Client? _client;
  bool _connected = false;
  String? lastError;

  bool get available => Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  bool get connected => _connected;
  bool get configured => applicationId.isNotEmpty;

  Future<bool> connect() async {
    if (!available || !configured) return false;
    if (_connected) return true;
    try {
      final client = Client(clientId: applicationId);
      await client.connect();
      _client = client;
      _connected = true;
      lastError = null;
      return true;
    } catch (error) {
      lastError = error.toString();
      _connected = false;
      return false;
    }
  }

  Future<void> update(Track track, Duration position, {String? roomCode}) async {
    if (!await connect()) return;
    final now = DateTime.now();
    final start = now.subtract(position);
    final remaining = track.duration > position ? track.duration - position : Duration.zero;
    final end = now.add(remaining);
    try {
      await _client!.setActivity(
        Activity(
          name: 'Gluk Wave',
          type: ActivityType.listening,
          details: track.title,
          state: roomCode == null ? track.artist : '${track.artist} · комната $roomCode',
          timestamps: ActivityTimestamps(start: start, end: end),
          assets: const ActivityAssets(
            largeImage: 'gluk_wave',
            largeText: 'Gluk Wave',
          ),
        ),
      );
      lastError = null;
    } catch (error) {
      lastError = error.toString();
    }
  }

  Future<void> disconnect() async {
    final client = _client;
    _client = null;
    _connected = false;
    if (client == null) return;
    try {
      await client.disconnect();
    } catch (_) {}
  }
}
