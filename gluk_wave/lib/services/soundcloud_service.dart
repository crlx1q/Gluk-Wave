import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/soundcloud_track.dart';

class SoundCloudService {
  static const String _clientId = 'LBCcHmG8KS4lEQWEBgVjvuKvcgH1L3T0'; // Static client ID for simplicity
  static const String _baseUrl = 'https://api-v2.soundcloud.com';

  Future<List<SoundCloudTrack>> searchTracks(String query) async {
    final uri = Uri.parse('$_baseUrl/search/tracks?q=${Uri.encodeComponent(query)}&client_id=$_clientId&limit=20');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> tracksJson = jsonResponse['collection'];

      return tracksJson
          .map((json) => SoundCloudTrack.fromJson(json, _clientId))
          .where((track) => track.streamUrl.isNotEmpty)
          .toList();
    } else {
      throw Exception('Failed to search tracks');
    }
  }

  Future<String> getStreamingUrl(String transcodeUrl) async {
    final uri = Uri.parse(transcodeUrl);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['url'];
    } else {
      throw Exception('Failed to get streaming URL');
    }
  }

  Future<List<SoundCloudTrack>> getCharts() async {
    final uri = Uri.parse('$_baseUrl/charts?kind=top&genre=soundcloud:genres:all-music&client_id=$_clientId&limit=20');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> collection = jsonResponse['collection'];

      List<SoundCloudTrack> tracks = [];
      for(var item in collection) {
        if(item['track'] != null) {
          tracks.add(SoundCloudTrack.fromJson(item['track'], _clientId));
        }
      }
      return tracks;
    } else {
      throw Exception('Failed to get charts');
    }
  }
}
