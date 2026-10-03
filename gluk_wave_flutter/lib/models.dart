import 'dart:convert';

import 'package:flutter/material.dart';

enum AppPage { home, search, library, rooms, lofi, sources, settings }

enum TrackSource { gluk, local, soundcloud, spotify, yandex, youtubeMusic }

extension TrackSourceX on TrackSource {
  String get label => switch (this) {
        TrackSource.gluk => 'Gluk Sessions',
        TrackSource.local => 'На устройстве',
        TrackSource.soundcloud => 'SoundCloud',
        TrackSource.spotify => 'Spotify',
        TrackSource.yandex => 'Яндекс Музыка',
        TrackSource.youtubeMusic => 'YouTube Music',
      };

  IconData get icon => switch (this) {
        TrackSource.gluk => Icons.graphic_eq_rounded,
        TrackSource.local => Icons.folder_rounded,
        TrackSource.soundcloud => Icons.cloud_rounded,
        TrackSource.spotify => Icons.radar_rounded,
        TrackSource.yandex => Icons.auto_awesome_rounded,
        TrackSource.youtubeMusic => Icons.play_circle_rounded,
      };
}

class LyricLine {
  const LyricLine(this.time, this.text);
  final Duration time;
  final String text;
}

class CommentEntry {
  const CommentEntry({
    required this.id,
    required this.author,
    required this.text,
    required this.at,
    required this.createdAt,
  });

  final String id;
  final String author;
  final String text;
  final Duration at;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'text': text,
        'atMs': at.inMilliseconds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory CommentEntry.fromJson(Map<String, dynamic> json) => CommentEntry(
        id: json['id'] as String,
        author: json['author'] as String,
        text: json['text'] as String,
        at: Duration(milliseconds: json['atMs'] as int? ?? 0),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.assetPath,
    required this.duration,
    required this.palette,
    required this.source,
    required this.lyrics,
    this.localPath,
    this.moods = const <String>[],
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final String assetPath;
  final String? localPath;
  final Duration duration;
  final List<Color> palette;
  final TrackSource source;
  final List<LyricLine> lyrics;
  final List<String> moods;

  bool get isLocal => localPath != null || source == TrackSource.local;

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? assetPath,
    String? localPath,
    Duration? duration,
    List<Color>? palette,
    TrackSource? source,
    List<LyricLine>? lyrics,
    List<String>? moods,
  }) =>
      Track(
        id: id ?? this.id,
        title: title ?? this.title,
        artist: artist ?? this.artist,
        album: album ?? this.album,
        assetPath: assetPath ?? this.assetPath,
        localPath: localPath ?? this.localPath,
        duration: duration ?? this.duration,
        palette: palette ?? this.palette,
        source: source ?? this.source,
        lyrics: lyrics ?? this.lyrics,
        moods: moods ?? this.moods,
      );

  Map<String, dynamic> toPersistedJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'assetPath': assetPath,
        'localPath': localPath,
        'durationMs': duration.inMilliseconds,
        'palette': palette.map((color) => color.toARGB32()).toList(),
        'source': source.name,
        'moods': moods,
      };

  factory Track.fromPersistedJson(Map<String, dynamic> json) {
    final sourceName = json['source'] as String? ?? TrackSource.local.name;
    final source = TrackSource.values.firstWhere(
      (value) => value.name == sourceName,
      orElse: () => TrackSource.local,
    );
    final paletteRaw = (json['palette'] as List<dynamic>? ?? const <dynamic>[]).cast<int>();
    return Track(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Локальный трек',
      artist: json['artist'] as String? ?? 'На устройстве',
      album: json['album'] as String? ?? 'Локальная музыка',
      assetPath: json['assetPath'] as String? ?? '',
      localPath: json['localPath'] as String?,
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
      palette: paletteRaw.isEmpty
          ? const <Color>[Color(0xFF72685D), Color(0xFFC5B49E)]
          : paletteRaw.map(Color.new).toList(),
      source: source,
      lyrics: const <LyricLine>[],
      moods: (json['moods'] as List<dynamic>? ?? const <dynamic>[]).cast<String>(),
    );
  }
}

class Playlist {
  const Playlist({required this.id, required this.name, required this.description, required this.trackIds});
  final String id;
  final String name;
  final String description;
  final List<String> trackIds;
}

class RoomMember {
  const RoomMember({required this.id, required this.name, this.isAdmin = false, this.canControl = false});
  final String id;
  final String name;
  final bool isAdmin;
  final bool canControl;
}

class RoomMessage {
  const RoomMessage({required this.id, required this.author, required this.text, required this.at});
  final String id;
  final String author;
  final String text;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'text': text,
        'at': at.toIso8601String(),
      };

  factory RoomMessage.fromJson(Map<String, dynamic> json) => RoomMessage(
        id: json['id'] as String,
        author: json['author'] as String? ?? 'Гость',
        text: json['text'] as String? ?? '',
        at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
      );
}

String encodeJsonList(List<Map<String, dynamic>> value) => jsonEncode(value);

List<Map<String, dynamic>> decodeJsonList(String? value) {
  if (value == null || value.isEmpty) return const <Map<String, dynamic>>[];
  try {
    return (jsonDecode(value) as List<dynamic>).cast<Map<String, dynamic>>();
  } catch (_) {
    return const <Map<String, dynamic>>[];
  }
}
