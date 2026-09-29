import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/soundcloud_track.dart';
import '../services/soundcloud_service.dart';
import '../services/audio_handler.dart';

class AppState extends ChangeNotifier {
  final AudioPlayerHandler _audioHandler;
  final SoundCloudService _soundcloudService = SoundCloudService();

  List<SoundCloudTrack> _searchResults = [];
  List<SoundCloudTrack> get searchResults => _searchResults;

  List<SoundCloudTrack> _charts = [];
  List<SoundCloudTrack> get charts => _charts;

  SoundCloudTrack? _currentTrack;
  SoundCloudTrack? get currentTrack => _currentTrack;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  Duration _currentPosition = Duration.zero;
  Duration get currentPosition => _currentPosition;

  Duration _totalDuration = Duration.zero;
  Duration get totalDuration => _totalDuration;

  AppState(this._audioHandler) {
    _audioHandler.playbackState.listen((state) {
      _isPlaying = state.playing;
      _currentPosition = state.updatePosition;
      notifyListeners();
    });

    _audioHandler.mediaItem.listen((item) {
      if (item != null) {
        _totalDuration = item.duration ?? Duration.zero;
        notifyListeners();
      }
    });

    AudioService.position.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
  }

  Future<void> fetchCharts() async {
    _isLoading = true;
    notifyListeners();
    try {
      _charts = await _soundcloudService.getCharts();
    } catch (e) {
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> search(String query) async {
    _isLoading = true;
    notifyListeners();
    try {
      _searchResults = await _soundcloudService.searchTracks(query);
    } catch (e) {
      print(e);
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> playTrack(SoundCloudTrack track) async {
    _currentTrack = track;
    notifyListeners();

    final item = MediaItem(
      id: track.id.toString(),
      album: 'Gluk Wave',
      title: track.title,
      artist: track.artist,
      duration: Duration(milliseconds: track.durationMs),
      artUri: track.artworkUrl.isNotEmpty ? Uri.parse(track.artworkUrl) : null,
      extras: {'streamUrl': track.streamUrl},
    );

    await _audioHandler.playMediaItem(item);
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _audioHandler.pause();
    } else {
      await _audioHandler.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioHandler.seek(position);
  }
}
