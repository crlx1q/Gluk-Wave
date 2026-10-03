import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'screens/home_screen.dart';
import 'screens/library_search_screen.dart';
import 'screens/now_playing_screen.dart';
import 'screens/rooms_lofi_screen.dart';
import 'screens/sources_settings_screen.dart';
import 'state.dart';
import 'theme.dart';
import 'widgets/common.dart';
import 'widgets/player_bar.dart';

class GlukWaveApp extends StatelessWidget {
  const GlukWaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gluk Wave',
      theme: GlukTheme.light(),
      darkTheme: GlukTheme.dark(),
      themeMode: state.darkMode ? ThemeMode.dark : ThemeMode.light,
      home: const _Bootstrap(),
    );
  }
}

class _Bootstrap extends StatelessWidget {
  const _Bootstrap();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (!state.initialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              WaveLogo(size: 58, animate: true),
              SizedBox(height: 18),
              Text('glukwave', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -1)),
              SizedBox(height: 18),
              SizedBox(width: 110, child: LinearProgressIndicator(minHeight: 2)),
            ],
          ),
        ),
      );
    }
    return const AppShell();
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final FocusNode searchFocus = FocusNode();
  late final TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (searchController.text != state.searchQuery && !searchFocus.hasFocus) {
      searchController.value = TextEditingValue(text: state.searchQuery, selection: TextSelection.collapsed(offset: state.searchQuery.length));
    }
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 760;
    final compactRail = width >= 760 && width < 1040;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          searchFocus.requestFocus();
          state.navigate(AppPage.search);
        },
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () {
          searchFocus.requestFocus();
          state.navigate(AppPage.search);
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Stack(
            children: <Widget>[
              Row(
                children: <Widget>[
                  if (!mobile) _Sidebar(compact: compactRail),
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        _TopBar(
                          mobile: mobile,
                          compactRail: compactRail,
                          controller: searchController,
                          focusNode: searchFocus,
                          onSearch: (value) {
                            state.updateSearch(value);
                            if (value.isNotEmpty) state.navigate(AppPage.search);
                          },
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              mobile ? 18 : width > 1280 ? 48 : 28,
                              mobile ? 20 : 28,
                              mobile ? 18 : width > 1280 ? 48 : 28,
                              0,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: KeyedSubtree(key: ValueKey<AppPage>(state.page), child: _pageFor(state.page)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                left: mobile ? 0 : (compactRail ? 80 : 232),
                right: 0,
                bottom: 0,
                child: PlayerBar(onOpen: () => _openNowPlaying(context)),
              ),
              if (mobile) const Positioned(left: 0, right: 0, bottom: 0, child: _MobileNav()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageFor(AppPage page) => switch (page) {
        AppPage.home => const HomeScreen(),
        AppPage.search => const SearchScreen(),
        AppPage.library => const LibraryScreen(),
        AppPage.rooms => const RoomsScreen(),
        AppPage.lofi => const LofiScreen(),
        AppPage.sources => const SourcesScreen(),
        AppPage.settings => const SettingsScreen(),
      };

  void _openNowPlaying(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (context, animation, secondaryAnimation) => const NowPlayingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, .045), end: Offset.zero).animate(curved), child: child),
          );
        },
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    return Container(
      width: compact ? 80 : 232,
      decoration: BoxDecoration(border: Border(right: BorderSide(color: Theme.of(context).dividerColor))),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(compact ? 12 : 20, 26, compact ? 12 : 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Align(alignment: compact ? Alignment.center : Alignment.centerLeft, child: WaveLogo(size: 38, animate: state.animatedLogo, withWordmark: !compact)),
              const SizedBox(height: 38),
              if (!compact) ...<Widget>[Text('ТВОЁ ПРОСТРАНСТВО', style: Theme.of(context).textTheme.labelSmall), const SizedBox(height: 10)],
              _NavItem(compact: compact, icon: Icons.home_rounded, label: 'Главная', page: AppPage.home),
              _NavItem(compact: compact, icon: Icons.library_music_rounded, label: 'Моя библиотека', page: AppPage.library),
              _NavItem(compact: compact, icon: Icons.group_rounded, label: 'Слушать вместе', page: AppPage.rooms, badge: state.roomConnected ? 'LIVE' : null),
              _NavItem(compact: compact, icon: Icons.dark_mode_rounded, label: 'Lo-fi комната', page: AppPage.lofi),
              const SizedBox(height: 22),
              if (!compact) ...<Widget>[Text('МУЗЫКА БЕЗ ГРАНИЦ', style: Theme.of(context).textTheme.labelSmall), const SizedBox(height: 8)],
              _SourceLink(compact: compact, source: TrackSource.soundcloud),
              _SourceLink(compact: compact, source: TrackSource.spotify),
              _SourceLink(compact: compact, source: TrackSource.yandex),
              _SourceLink(compact: compact, source: TrackSource.youtubeMusic),
              if (!compact) ...<Widget>[
                const SizedBox(height: 22),
                Text('ТВОИ ПЛЕЙЛИСТЫ', style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 7),
                ...state.playlists.take(2).map((playlist) {
                  final track = state.tracks.firstWhere((item) => item.id == playlist.trackIds.first, orElse: () => state.currentTrack);
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => state.playTrack(track),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 5),
                      child: Row(children: <Widget>[CoverArt(track: track, size: 32, radius: 8), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelLarge), Text(playlist.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)]))]),
                    ),
                  );
                }),
              ],
              const Spacer(),
              _NavItem(compact: compact, icon: Icons.tune_rounded, label: 'Настройки', page: AppPage.settings),
              if (!compact) ...<Widget>[
                const SizedBox(height: 12),
                Row(children: <Widget>[Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF87A28C), shape: BoxShape.circle)), const SizedBox(width: 7), Expanded(child: Text('Всё в твоём ритме', style: TextStyle(fontSize: 10, color: muted))), Text('v.03', style: TextStyle(fontSize: 9, color: muted))]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.compact, required this.icon, required this.label, required this.page, this.badge});
  final bool compact;
  final IconData icon;
  final String label;
  final AppPage page;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final selected = state.page == page;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: () => state.navigate(page),
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 13, vertical: 12),
            child: Row(
              mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: <Widget>[
                Icon(icon, size: 20, color: selected ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).textTheme.bodySmall?.color),
                if (!compact) ...<Widget>[
                  const SizedBox(width: 12),
                  Expanded(child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: selected ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).textTheme.bodySmall?.color))),
                  if (badge != null) Text(badge!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: selected ? GlukColors.accent : null)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceLink extends StatelessWidget {
  const _SourceLink({required this.compact, required this.source});
  final bool compact;
  final TrackSource source;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: () => state.navigate(AppPage.sources),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 11, vertical: 8),
        child: Row(
          mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: <Widget>[
            Container(width: 25, height: 25, decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .06)), child: Icon(source.icon, size: 15)),
            if (!compact) ...<Widget>[const SizedBox(width: 10), Expanded(child: Text(source.label, style: Theme.of(context).textTheme.bodyMedium)), Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)))],
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.mobile, required this.compactRail, required this.controller, required this.focusNode, required this.onSearch});
  final bool mobile;
  final bool compactRail;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return SafeArea(
      bottom: false,
      child: Container(
        height: mobile ? 72 : 82,
        padding: EdgeInsets.symmetric(horizontal: mobile ? 16 : 24),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
        child: Row(
          children: <Widget>[
            if (mobile) ...<Widget>[
              WaveLogo(size: 34, animate: state.animatedLogo, withWordmark: true),
              const SizedBox(width: 12),
            ] else ...<Widget>[
              IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_left_rounded)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.chevron_right_rounded)),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onSearch,
                  onTap: () => state.navigate(AppPage.search),
                  decoration: InputDecoration(
                    hintText: mobile ? 'Поиск' : 'Трек, исполнитель или настроение',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: mobile ? null : Padding(padding: const EdgeInsets.all(12), child: Container(alignment: Alignment.center, width: 48, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .06), borderRadius: BorderRadius.circular(8)), child: Text('Ctrl K', style: Theme.of(context).textTheme.labelSmall))),
                  ),
                ),
              ),
            ),
            const Spacer(),
            if (!mobile) ...<Widget>[
              IconButton(onPressed: () => state.setDarkMode(!state.darkMode), tooltip: 'Тема', icon: Icon(state.darkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded)),
              IconButton(onPressed: () => state.navigate(AppPage.settings), tooltip: 'Настройки', icon: const Icon(Icons.tune_rounded)),
              const SizedBox(width: 6),
            ],
            InkWell(
              onTap: () => state.navigate(AppPage.settings),
              borderRadius: BorderRadius.circular(100),
              child: Container(width: 38, height: 38, alignment: Alignment.center, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface, shape: BoxShape.circle), child: Text('А', style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor, fontWeight: FontWeight.w900))),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileNav extends StatelessWidget {
  const _MobileNav();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    const items = <(AppPage, IconData, String)>[
      (AppPage.home, Icons.home_rounded, 'Главная'),
      (AppPage.search, Icons.search_rounded, 'Поиск'),
      (AppPage.library, Icons.library_music_rounded, 'Медиатека'),
      (AppPage.rooms, Icons.group_rounded, 'Комнаты'),
      (AppPage.lofi, Icons.dark_mode_rounded, 'Lo-fi'),
    ];
    return SafeArea(
      top: false,
      child: Container(
        height: 70,
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, border: Border(top: BorderSide(color: Theme.of(context).dividerColor))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            final selected = state.page == item.$1;
            return Expanded(
              child: InkWell(
                onTap: () => state.navigate(item.$1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(item.$2, size: 21, color: selected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).textTheme.bodySmall?.color),
                    const SizedBox(height: 3),
                    Text(item.$3, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 8, color: selected ? Theme.of(context).colorScheme.onSurface : null)),
                    const SizedBox(height: 3),
                    AnimatedContainer(duration: const Duration(milliseconds: 180), width: selected ? 4 : 0, height: selected ? 4 : 0, decoration: const BoxDecoration(color: GlukColors.accent, shape: BoxShape.circle)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
