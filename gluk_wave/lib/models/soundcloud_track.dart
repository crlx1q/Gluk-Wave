import 'dart:convert';
import 'package:http/http.dart' as http;

class SoundCloudTrack {
  final int id;
  final String title;
  final String artist;
  final String artworkUrl;
  final int durationMs;
  final String streamUrl;

  SoundCloudTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    required this.durationMs,
    required this.streamUrl,
  });

  factory SoundCloudTrack.fromJson(Map<String, dynamic> json, String clientId) {
    // Attempt to extract progressive streaming url
    String streamUrl = '';
    if (json['media'] != null && json['media']['transcodings'] != null) {
      for (var t in json['media']['transcodings']) {
        if (t['format']['protocol'] == 'progressive') {
          streamUrl = t['url'] + '?client_id=' + clientId;
          break;
        }
      }
      if (streamUrl.isEmpty) {
         // Fallback to first if progressive not found
         streamUrl = json['media']['transcodings'][0]['url'] + '?client_id=' + clientId;
      }
    }

    // Larger artwork
    String artwork = json['artwork_url'] ?? json['user']['avatar_url'] ?? '';
    artwork = artwork.replaceAll('large', 't500x500');

    return SoundCloudTrack(
      id: json['id'],
      title: json['title'] ?? 'Unknown Title',
      artist: json['user'] != null ? json['user']['username'] : 'Unknown Artist',
      artworkUrl: artwork,
      durationMs: json['duration'] ?? 0,
      streamUrl: streamUrl,
    );
  }
}
