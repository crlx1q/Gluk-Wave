import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../widgets/common.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String filter = 'all';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final visible = switch (filter) {
      'liked' => state.tracks.where((track) => state.likedIds.contains(track.id)).toList(),
      'local' => state.tracks.where((track) => track.isLocal).toList(),
      _ => state.tracks,
    };
    return ListView(
      padding: const EdgeInsets.only(bottom: 130),
      children: <Widget>[
        PageHeading(
          eyebrow: 'Всё, что откликается',
          title: 'Медиатека',
          subtitle: 'Любимые миры — в одном месте.',
          trailing: GlukPill(label: 'Добавить музыку', icon: Icons.add_rounded, onTap: state.importLocalMusic),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            GlukPill(label: 'Треки', selected: filter == 'all', compact: true, onTap: () => setState(() => filter = 'all')),
            GlukPill(label: 'Любимые', selected: filter == 'liked', compact: true, onTap: () => setState(() => filter = 'liked')),
            GlukPill(label: 'Локальные', selected: filter == 'local', compact: true, onTap: () => setState(() => filter = 'local')),
            GlukPill(label: 'Плейлисты', selected: filter == 'playlists', compact: true, onTap: () => setState(() => filter = 'playlists')),
          ],
        ),
        const SizedBox(height: 24),
        if (filter == 'playlists')
          _PlaylistGrid(state: state)
        else if (visible.isEmpty)
          const _EmptyLibrary()
        else ...<Widget>[
          if (MediaQuery.sizeOf(context).width > 760)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: <Widget>[
                  const Expanded(child: Eyebrow('Трек / исполнитель', dot: false)),
                  SizedBox(width: 142, child: Text('ИСТОЧНИК', style: Theme.of(context).textTheme.labelSmall)),
                  const SizedBox(width: 52),
                  const SizedBox(width: 52),
                  const SizedBox(width: 42),
                ],
              ),
            ),
          ...visible.map((track) => TrackTile(track: track)),
        ],
      ],
    );
  }
}

class _PlaylistGrid extends StatelessWidget {
  const _PlaylistGrid({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final count = constraints.maxWidth > 1100 ? 4 : constraints.maxWidth > 720 ? 3 : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: count, crossAxisSpacing: 14, mainAxisSpacing: 18, childAspectRatio: .86),
            itemCount: state.playlists.length,
            itemBuilder: (context, index) {
              final playlist = state.playlists[index];
              final track = state.tracks.firstWhere((item) => item.id == playlist.trackIds.first, orElse: () => state.currentTrack);
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => state.playTrack(track),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: LayoutBuilder(builder: (context, box) => CoverArt(track: track, size: box.maxWidth, radius: 18))),
                    const SizedBox(height: 10),
                    Text(playlist.name, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(playlist.description, style: Theme.of(context).textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          );
        },
      );
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: <Widget>[
            Icon(Icons.library_music_outlined, size: 48, color: Theme.of(context).textTheme.bodySmall?.color),
            const SizedBox(height: 12),
            Text('Здесь пока тихо', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text('Добавь локальную музыку или импортируй библиотеку.', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
}

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final results = state.searchResults;
    return ListView(
      padding: const EdgeInsets.only(bottom: 130),
      children: <Widget>[
        const PageHeading(
          eyebrow: 'Найдём то самое',
          title: 'В поисках звука',
          subtitle: 'Раскладка не помеха: ghbdtn будет понято как «привет».',
        ),
        const SizedBox(height: 22),
        TextField(
          controller: TextEditingController(text: state.searchQuery)
            ..selection = TextSelection.collapsed(offset: state.searchQuery.length),
          autofocus: MediaQuery.sizeOf(context).width > 800,
          onChanged: state.updateSearch,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            hintText: 'Трек, исполнитель или настроение',
            suffixIcon: state.searchQuery.isEmpty
                ? null
                : IconButton(onPressed: () => state.updateSearch(''), icon: const Icon(Icons.close_rounded)),
          ),
        ),
        if (state.searchSuggestion != null) ...<Widget>[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              avatar: const Icon(Icons.keyboard_rounded, size: 16),
              label: Text('Возможно: ${state.searchSuggestion}'),
              onPressed: state.applySearchSuggestion,
            ),
          ),
        ],
        const SizedBox(height: 18),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              GlukPill(label: 'Все сервисы', compact: true, selected: state.searchSource == null, onTap: () => state.setSearchSource(null)),
              const SizedBox(width: 7),
              ...<TrackSource>[TrackSource.soundcloud, TrackSource.spotify, TrackSource.yandex, TrackSource.youtubeMusic, TrackSource.local]
                  .map((source) => Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: GlukPill(label: source.label, icon: source.icon, compact: true, selected: state.searchSource == source, onTap: () => state.setSearchSource(source)),
                      )),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 50),
            child: Column(
              children: <Widget>[
                const Icon(Icons.travel_explore_rounded, size: 44),
                const SizedBox(height: 12),
                Text('Ничего не нашлось', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text('Попробуй настроение, артиста или другую раскладку.', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          )
        else
          ...results.map((track) => TrackTile(track: track)),
      ],
    );
  }
}
