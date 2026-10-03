import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models.dart';

class CacheService {
  Future<Directory> _cacheDir() async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory(p.join(root.path, 'gluk_wave_cache'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String?> cachedPath(Track track) async {
    if (track.isLocal && track.localPath != null) return track.localPath;
    final dir = await _cacheDir();
    final ext = p.extension(track.assetPath).isEmpty ? '.wav' : p.extension(track.assetPath);
    final file = File(p.join(dir.path, '${track.id}$ext'));
    return await file.exists() ? file.path : null;
  }

  Future<String> cacheTrack(Track track) async {
    if (track.isLocal && track.localPath != null) return track.localPath!;
    final data = await rootBundle.load(track.assetPath);
    final dir = await _cacheDir();
    final ext = p.extension(track.assetPath).isEmpty ? '.wav' : p.extension(track.assetPath);
    final file = File(p.join(dir.path, '${track.id}$ext'));
    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    return file.path;
  }

  Future<void> removeTrack(Track track) async {
    if (track.isLocal) return;
    final path = await cachedPath(track);
    if (path == null) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  Future<int> clear() async {
    final dir = await _cacheDir();
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) {
        total += await entity.length();
        await entity.delete();
      }
    }
    return total;
  }

  Future<int> size() async {
    final dir = await _cacheDir();
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list()) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }
}
