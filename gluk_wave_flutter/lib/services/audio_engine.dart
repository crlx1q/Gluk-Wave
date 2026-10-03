import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import '../models.dart';
import 'cache_service.dart';

class AudioEngine {
  AudioEngine(this.cacheService);

  final CacheService cacheService;
  final AudioPlayer player = AudioPlayer();
  Track? loadedTrack;

  Stream<PlayerState> get playerStateStream => player.playerStateStream;
  Stream<Duration> get positionStream => player.positionStream;
  Stream<Duration?> get durationStream => player.durationStream;
  Stream<double> get volumeStream => player.volumeStream;

  Future<void> initialize() async {
    if (Platform.isWindows || Platform.isLinux) {
      JustAudioMediaKit.ensureInitialized(windows: Platform.isWindows, linux: Platform.isLinux);
    }
  }

  Future<void> load(Track track, {bool autoplay = false}) async {
    if (loadedTrack?.id == track.id) {
      if (autoplay) await player.play();
      return;
    }
    loadedTrack = track;
    final cached = await cacheService.cachedPath(track);
    if (cached != null && File(cached).existsSync()) {
      await player.setAudioSource(AudioSource.file(cached));
    } else if (track.localPath != null && File(track.localPath!).existsSync()) {
      await player.setAudioSource(AudioSource.file(track.localPath!));
    } else {
      await player.setAudioSource(AudioSource.asset(track.assetPath));
    }
    if (autoplay) await player.play();
  }

  Future<void> toggle() async {
    if (player.playing) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> seek(Duration position) => player.seek(position);
  Future<void> setVolume(double value) => player.setVolume(value.clamp(0.0, 1.0).toDouble());
  Future<void> setLoop(bool enabled) => player.setLoopMode(enabled ? LoopMode.one : LoopMode.off);

  Future<void> dispose() => player.dispose();
}
