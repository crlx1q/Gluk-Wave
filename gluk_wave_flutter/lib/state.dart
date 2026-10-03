import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'demo_data.dart';
import 'models.dart';
import 'services/audio_engine.dart';
import 'services/cache_service.dart';
import 'services/discord_presence_service.dart';
import 'services/layout_fixer.dart';
import 'services/local_import_service.dart';
import 'services/room_client.dart';
import 'services/settings_store.dart';

class AppState extends ChangeNotifier {
  AppState()
      : cacheService = CacheService(),
        settings = SettingsStore(),
        importer = LocalImportService(),
        discord = DiscordPresenceService(),
        roomClient = RoomClient() {
    audio = AudioEngine(cacheService);
  }

  late final AudioEngine audio;
  final CacheService cacheService;
  final SettingsStore settings;
  final LocalImportService importer;
  final DiscordPresenceService discord;
  final RoomClient roomClient;

  final List<Track> tracks = <Track>[...demoTracks];
  final List<Playlist> playlists = <Playlist>[...demoPlaylists];
  final Set<String> likedIds = <String>{'weightless', 'afterglow', 'night-bus', 'quiet-room'};
  final Set<String> downloadedIds = <String>{};
  final Map<String, List<CommentEntry>> comments = <String, List<CommentEntry>>{};
  final List<RoomMessage> roomMessages = <RoomMessage>[
    RoomMessage(id: 'hello', author: 'Gluk Wave', text: 'Комната готова. Включай музыку.', at: DateTime.now()),
  ];
  final List<RoomMember> roomMembers = <RoomMember>[
    const RoomMember(id: 'you', name: 'Алишер', isAdmin: true, canControl: true),
    const RoomMember(id: 'mira', name: 'Mira', canControl: false),
    const RoomMember(id: 'nox', name: 'Nox', canControl: false),
  ];

  AppPage page = AppPage.home;
  int currentIndex = 0;
  bool initialized = false;
  bool playing = false;
  bool shuffle = false;
  bool repeat = false;
  bool darkMode = false;
  bool compactMode = false;
  bool cacheMusic = true;
  bool discordEnabled = true;
  bool lyricsUnderCover = true;
  bool animatedLogo = true;
  bool everyoneCanControlRoom = false;
  bool roomConnected = false;
  bool roomIsAdmin = true;
  String roomCode = 'WAVE-42';
  String roomServerUrl = 'ws://localhost:8787/ws';
  String? roomError;
  Duration position = Duration.zero;
  Duration duration = const Duration(seconds: 14);
  double volume = 0.62;
  String searchQuery = '';
  TrackSource? searchSource;
  String? searchSuggestion;
  int cacheBytes = 0;

  final List<StreamSubscription<dynamic>> _subscriptions = <StreamSubscription<dynamic>>[];
  int _lastDiscordSecond = -100;

  Track get currentTrack {
    final safeIndex = currentIndex < 0
        ? 0
        : (currentIndex >= tracks.length ? tracks.length - 1 : currentIndex);
    return tracks[safeIndex];
  }
  List<CommentEntry> get currentComments => comments[currentTrack.id] ?? const <CommentEntry>[];

  Future<void> initialize() async {
    if (initialized) return;
    await audio.initialize();

    cacheMusic = await settings.getBool('cache_music', true);
    discordEnabled = await settings.getBool('discord_enabled', true);
    lyricsUnderCover = await settings.getBool('lyrics_under_cover', true);
    animatedLogo = await settings.getBool('animated_logo', true);
    darkMode = await settings.getBool('dark_mode', false);
    compactMode = await settings.getBool('compact_mode', false);
    volume = await settings.getDouble('volume', 0.62);
    roomServerUrl = await settings.getString('room_server_url', roomServerUrl);
    likedIds
      ..clear()
      ..addAll(await settings.getStringList('liked_ids'));
    if (likedIds.isEmpty) {
      likedIds.addAll(<String>{'weightless', 'afterglow', 'night-bus', 'quiet-room'});
    }

    final local = await settings.loadLocalTracks();
    tracks.addAll(local.where((incoming) => tracks.every((item) => item.id != incoming.id)));

    comments.addAll(seedComments.map((key, value) => MapEntry(key, List<CommentEntry>.from(value))));
    final savedComments = await settings.loadComments();
    for (final entry in savedComments.entries) {
      comments[entry.key] = entry.value;
    }

    await _refreshDownloads();
    cacheBytes = await cacheService.size();
    await audio.setVolume(volume);
    await audio.load(currentTrack);
    duration = audio.player.duration ?? currentTrack.duration;

    _subscriptions.add(audio.playerStateStream.listen((state) {
      final next = state.playing;
      if (playing != next) {
        playing = next;
        notifyListeners();
      }
    }));
    _subscriptions.add(audio.positionStream.listen((value) {
      position = value;
      final second = value.inSeconds;
      if (discordEnabled && playing && second - _lastDiscordSecond >= 5) {
        _lastDiscordSecond = second;
        unawaited(discord.update(currentTrack, value, roomCode: roomConnected ? roomCode : null));
      }
      notifyListeners();
    }));
    _subscriptions.add(audio.durationStream.listen((value) {
      if (value != null && value > Duration.zero) duration = value;
      notifyListeners();
    }));
    _subscriptions.add(roomClient.events.listen(_handleRoomEvent));

    initialized = true;
    notifyListeners();
  }

  Future<void> _refreshDownloads() async {
    downloadedIds.clear();
    for (final track in tracks) {
      final path = await cacheService.cachedPath(track);
      if (path != null) downloadedIds.add(track.id);
    }
  }

  void navigate(AppPage next) {
    page = next;
    notifyListeners();
  }

  Future<void> playTrack(Track track, {bool autoplay = true, bool broadcast = true}) async {
    final index = tracks.indexWhere((item) => item.id == track.id);
    if (index < 0) return;
    currentIndex = index;
    position = Duration.zero;
    duration = track.duration;
    await audio.load(track, autoplay: autoplay);
    duration = audio.player.duration ?? track.duration;
    if (cacheMusic && !track.isLocal) unawaited(_autoCache(track));
    if (discordEnabled && autoplay) unawaited(discord.update(track, Duration.zero, roomCode: roomConnected ? roomCode : null));
    if (roomConnected && broadcast) _broadcastPlayback();
    notifyListeners();
  }

  Future<void> _autoCache(Track track) async {
    if (downloadedIds.contains(track.id)) return;
    try {
      await cacheService.cacheTrack(track);
      downloadedIds.add(track.id);
      cacheBytes = await cacheService.size();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> togglePlay() async {
    if (audio.loadedTrack == null) await audio.load(currentTrack);
    if (cacheMusic && !currentTrack.isLocal && !downloadedIds.contains(currentTrack.id)) unawaited(_autoCache(currentTrack));
    await audio.toggle();
    if (discordEnabled) {
      if (audio.player.playing) {
        unawaited(discord.update(currentTrack, position, roomCode: roomConnected ? roomCode : null));
      } else {
        unawaited(discord.disconnect());
      }
    }
    if (roomConnected) _broadcastPlayback();
  }

  Future<void> seek(Duration value, {bool broadcast = true}) async {
    await audio.seek(value);
    position = value;
    if (roomConnected && broadcast) _broadcastPlayback();
    notifyListeners();
  }

  Future<void> previous() async {
    if (position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
      return;
    }
    final next = currentIndex <= 0 ? tracks.length - 1 : currentIndex - 1;
    await playTrack(tracks[next]);
  }

  Future<void> next() async {
    var nextIndex = currentIndex + 1;
    if (shuffle && tracks.length > 1) {
      final random = Random();
      do {
        nextIndex = random.nextInt(tracks.length);
      } while (nextIndex == currentIndex);
    }
    if (nextIndex >= tracks.length) nextIndex = 0;
    await playTrack(tracks[nextIndex]);
  }

  Future<void> toggleRepeat() async {
    repeat = !repeat;
    await audio.setLoop(repeat);
    notifyListeners();
  }

  void toggleShuffle() {
    shuffle = !shuffle;
    notifyListeners();
  }

  Future<void> setVolume(double value) async {
    volume = value.clamp(0.0, 1.0).toDouble();
    await audio.setVolume(volume);
    await settings.setDouble('volume', volume);
    notifyListeners();
  }

  void updateSearch(String value) {
    searchQuery = value;
    searchSuggestion = LayoutFixer.suggestion(value);
    if (value.trim().isNotEmpty && page != AppPage.search) page = AppPage.search;
    notifyListeners();
  }

  void applySearchSuggestion() {
    final suggestion = searchSuggestion;
    if (suggestion == null) return;
    searchQuery = suggestion;
    searchSuggestion = null;
    notifyListeners();
  }

  void setSearchSource(TrackSource? source) {
    searchSource = source;
    notifyListeners();
  }

  List<Track> get searchResults {
    final q = searchQuery.trim().toLowerCase();
    final candidates = <String>{q};
    final suggestion = LayoutFixer.suggestion(searchQuery);
    if (suggestion != null) candidates.add(suggestion.toLowerCase());
    return tracks.where((track) {
      if (searchSource != null && track.source != searchSource) return false;
      if (q.isEmpty) return true;
      final haystack = <String>[
        track.title,
        track.artist,
        track.album,
        track.source.label,
        ...track.moods,
      ].join(' ').toLowerCase();
      return candidates.any(haystack.contains);
    }).toList();
  }

  Future<void> toggleLike(Track track) async {
    if (!likedIds.add(track.id)) likedIds.remove(track.id);
    await settings.setStringList('liked_ids', likedIds.toList());
    notifyListeners();
  }

  Future<void> toggleDownload(Track track) async {
    if (track.isLocal) return;
    if (downloadedIds.contains(track.id)) {
      await cacheService.removeTrack(track);
      downloadedIds.remove(track.id);
    } else {
      await cacheService.cacheTrack(track);
      downloadedIds.add(track.id);
    }
    cacheBytes = await cacheService.size();
    notifyListeners();
  }

  Future<void> clearCache() async {
    await cacheService.clear();
    downloadedIds.removeWhere((id) => tracks.any((track) => track.id == id && !track.isLocal));
    cacheBytes = 0;
    notifyListeners();
  }

  Future<void> importLocalMusic() async {
    final imported = await importer.pickAndImport();
    if (imported.isEmpty) return;
    tracks.addAll(imported);
    downloadedIds.addAll(imported.map((track) => track.id));
    await settings.saveLocalTracks(tracks.where((track) => track.isLocal).toList());
    notifyListeners();
  }

  Future<void> addComment(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    final list = comments.putIfAbsent(currentTrack.id, () => <CommentEntry>[]);
    list.add(
      CommentEntry(
        id: 'comment-${DateTime.now().microsecondsSinceEpoch}',
        author: 'Алишер',
        text: clean,
        at: position,
        createdAt: DateTime.now(),
      ),
    );
    list.sort((a, b) => a.at.compareTo(b.at));
    await settings.saveComments(comments);
    notifyListeners();
  }

  Future<void> setCacheMusic(bool value) async {
    cacheMusic = value;
    await settings.setBool('cache_music', value);
    notifyListeners();
  }

  Future<void> setDiscordEnabled(bool value) async {
    discordEnabled = value;
    await settings.setBool('discord_enabled', value);
    if (!value) await discord.disconnect();
    if (value && playing) unawaited(discord.update(currentTrack, position, roomCode: roomConnected ? roomCode : null));
    notifyListeners();
  }

  Future<void> setLyricsUnderCover(bool value) async {
    lyricsUnderCover = value;
    await settings.setBool('lyrics_under_cover', value);
    notifyListeners();
  }

  Future<void> setAnimatedLogo(bool value) async {
    animatedLogo = value;
    await settings.setBool('animated_logo', value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    await settings.setBool('dark_mode', value);
    notifyListeners();
  }

  Future<void> setCompactMode(bool value) async {
    compactMode = value;
    await settings.setBool('compact_mode', value);
    notifyListeners();
  }

  Future<void> setRoomServerUrl(String value) async {
    roomServerUrl = value.trim();
    await settings.setString('room_server_url', roomServerUrl);
    notifyListeners();
  }

  Future<void> joinRoom({String? code}) async {
    roomCode = (code == null || code.trim().isEmpty) ? roomCode : code.trim().toUpperCase();
    roomError = null;
    if (roomServerUrl.isEmpty) {
      roomConnected = true;
      notifyListeners();
      return;
    }
    try {
      await roomClient.connect(roomServerUrl);
      roomClient.join(room: roomCode, name: 'Алишер');
      roomConnected = true;
    } catch (error) {
      roomConnected = false;
      roomError = 'Сетевой сервер недоступен. Комната работает локально. $error';
    }
    notifyListeners();
  }

  void leaveRoom() {
    unawaited(roomClient.disconnect());
    roomConnected = false;
    roomIsAdmin = true;
    notifyListeners();
  }

  void sendRoomMessage(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    roomMessages.add(
      RoomMessage(
        id: 'room-${DateTime.now().microsecondsSinceEpoch}',
        author: 'Алишер',
        text: clean,
        at: DateTime.now(),
      ),
    );
    if (roomClient.connected) roomClient.chat(room: roomCode, text: clean);
    notifyListeners();
  }

  void setEveryoneCanControl(bool value) {
    if (roomConnected && !roomIsAdmin) return;
    everyoneCanControlRoom = value;
    if (roomClient.connected) roomClient.permission(room: roomCode, everyoneCanControl: value);
    notifyListeners();
  }

  void _broadcastPlayback() {
    if (!roomClient.connected) return;
    roomClient.playback(
      room: roomCode,
      trackId: currentTrack.id,
      playing: playing,
      positionMs: position.inMilliseconds,
    );
  }

  void _handleRoomEvent(RoomEvent event) {
    switch (event.type) {
      case 'chat':
        final text = event.payload['text'] as String?;
        if (text == null) break;
        roomMessages.add(
          RoomMessage(
            id: 'remote-${DateTime.now().microsecondsSinceEpoch}',
            author: event.payload['name'] as String? ?? 'Гость',
            text: text,
            at: DateTime.now(),
          ),
        );
        break;
      case 'playback':
        unawaited(_applyRemotePlayback(event.payload));
        break;
      case 'permission':
        everyoneCanControlRoom = event.payload['everyoneCanControl'] == true;
        break;
      case 'role':
        roomIsAdmin = event.payload['isAdmin'] == true;
        everyoneCanControlRoom = event.payload['everyoneCanControl'] == true;
        break;
      case 'error':
        roomError = event.payload['message'] as String? ?? 'Room error';
        break;
      case 'disconnected':
        roomConnected = false;
        break;
      default:
        break;
    }
    notifyListeners();
  }

  Future<void> _applyRemotePlayback(Map<String, dynamic> payload) async {
    final trackId = payload['trackId'] as String?;
    final wantsPlaying = payload['playing'] == true;
    final index = tracks.indexWhere((track) => track.id == trackId);
    if (index >= 0 && index != currentIndex) {
      await playTrack(tracks[index], autoplay: wantsPlaying, broadcast: false);
    } else if (index >= 0) {
      if (wantsPlaying && !audio.player.playing) await audio.player.play();
      if (!wantsPlaying && audio.player.playing) await audio.player.pause();
    }
    final ms = payload['positionMs'] as int?;
    if (ms != null) await seek(Duration(milliseconds: ms), broadcast: false);
  }

  String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes Б';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} КБ';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} МБ';
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(audio.dispose());
    unawaited(discord.disconnect());
    unawaited(roomClient.dispose());
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this context');
    return scope!.notifier!;
  }
}
