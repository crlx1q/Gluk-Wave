import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models.dart';

class LocalImportService {
  Future<List<Track>> pickAndImport() async {
    const group = XTypeGroup(
      label: 'audio',
      extensions: <String>['mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'],
      mimeTypes: <String>['audio/*'],
      uniformTypeIdentifiers: <String>['public.audio'],
    );
    final files = await openFiles(acceptedTypeGroups: const <XTypeGroup>[group]);
    if (files.isEmpty) return const <Track>[];

    final root = await getApplicationDocumentsDirectory();
    final library = Directory(p.join(root.path, 'Gluk Wave', 'Local Music'));
    if (!await library.exists()) await library.create(recursive: true);

    final result = <Track>[];
    for (final selected in files) {
      final safeName = p.basename(selected.name).replaceAll(RegExp(r'[^a-zA-Z0-9._\-а-яА-ЯёЁ ]'), '_');
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final target = File(p.join(library.path, '${stamp}_$safeName'));
      final bytes = await selected.readAsBytes();
      await target.writeAsBytes(bytes, flush: true);
      final title = p.basenameWithoutExtension(selected.name).trim();
      result.add(
        Track(
          id: 'local-$stamp-${result.length}',
          title: title.isEmpty ? 'Локальный трек' : title,
          artist: 'На устройстве',
          album: 'Локальная музыка',
          assetPath: '',
          localPath: target.path,
          duration: Duration.zero,
          palette: const [
            Color(0xFF4B4A46),
            Color(0xFF9B8B78),
            Color(0xFFE6DED1),
          ],
          source: TrackSource.local,
          lyrics: const <LyricLine>[],
          moods: const <String>['локально'],
        ),
      );
    }
    return result;
  }
}
