import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';

class SettingsStore {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<bool> getBool(String key, bool fallback) async => await _prefs.getBool(key) ?? fallback;
  Future<double> getDouble(String key, double fallback) async => await _prefs.getDouble(key) ?? fallback;
  Future<String> getString(String key, String fallback) async => await _prefs.getString(key) ?? fallback;
  Future<List<String>> getStringList(String key) async => await _prefs.getStringList(key) ?? const <String>[];

  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  Future<void> setDouble(String key, double value) => _prefs.setDouble(key, value);
  Future<void> setString(String key, String value) => _prefs.setString(key, value);
  Future<void> setStringList(String key, List<String> value) => _prefs.setStringList(key, value);

  Future<List<Track>> loadLocalTracks() async {
    final raw = await _prefs.getString('local_tracks');
    if (raw == null || raw.isEmpty) return const <Track>[];
    try {
      final data = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
      return data.map(Track.fromPersistedJson).toList();
    } catch (_) {
      return const <Track>[];
    }
  }

  Future<void> saveLocalTracks(List<Track> tracks) => _prefs.setString(
        'local_tracks',
        jsonEncode(tracks.map((track) => track.toPersistedJson()).toList()),
      );

  Future<Map<String, List<CommentEntry>>> loadComments() async {
    final raw = await _prefs.getString('track_comments');
    if (raw == null || raw.isEmpty) return <String, List<CommentEntry>>{};
    try {
      final decoded = (jsonDecode(raw) as Map<String, dynamic>);
      return decoded.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>)
              .map((item) => CommentEntry.fromJson((item as Map<dynamic, dynamic>).cast<String, dynamic>()))
              .toList(),
        ),
      );
    } catch (_) {
      return <String, List<CommentEntry>>{};
    }
  }

  Future<void> saveComments(Map<String, List<CommentEntry>> comments) => _prefs.setString(
        'track_comments',
        jsonEncode(
          comments.map(
            (key, value) => MapEntry(key, value.map((item) => item.toJson()).toList()),
          ),
        ),
      );
}
