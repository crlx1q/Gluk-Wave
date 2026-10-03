import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 130),
      children: <Widget>[
        PageHeading(
          eyebrow: 'Музыка ближе, чем кажется',
          title: 'Твоя музыка',
          subtitle: 'Привет, Алишер. Рады снова слышаться.',
          trailing: MediaQuery.sizeOf(context).width > 680
              ? GlukPill(
                  label: 'Вся музыка вместе',
                  icon: Icons.hub_rounded,
                  onTap: () => state.navigate(AppPage.sources),
                )
              : null,
        ),
        const SizedBox(height: 26),
        _QuickAccess(state: state),
        const SizedBox(height: 20),
        const _WaveHero(),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            if (MediaQuery.sizeOf(context).width > 560)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text('Сейчас хочется', style: Theme.of(context).textTheme.bodySmall),
              ),
            const GlukPill(label: 'Под меня', icon: Icons.auto_awesome_rounded, selected: true, compact: true),
            const GlukPill(label: 'Выдохнуть', icon: Icons.eco_rounded, compact: true),
            const GlukPill(label: 'В потоке', icon: Icons.center_focus_strong_rounded, compact: true),
            const GlukPill(label: 'Почувствовать всё', icon: Icons.bolt_rounded, compact: true),
            const GlukPill(label: 'Помечтать', icon: Icons.dark_mode_rounded, compact: true),
          ],
        ),
        const SizedBox(height: 32),
        SectionTitle(
          eyebrow: 'Маленькие миры',
          title: 'Твой саундтрек',
          trailing: TextButton.icon(
            onPressed: () => state.navigate(AppPage.library),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward_rounded, size: 17),
            label: const Text('Все подборки'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.playlists.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) => _PlaylistCard(playlist: state.playlists[index], index: index),
          ),
        ),
        const SizedBox(height: 32),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns = constraints.maxWidth > 840;
            final recent = _RecentTracks(state: state);
            final lofi = _LofiPromo(onTap: () => state.navigate(AppPage.lofi));
            if (!twoColumns) {
              return Column(children: <Widget>[recent, const SizedBox(height: 24), lofi]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 6, child: recent),
                const SizedBox(width: 24),
                Expanded(flex: 4, child: lofi),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _QuickAccess extends StatelessWidget {
  const _QuickAccess({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    Widget tile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap, required List<Color> colors}) {
      return SurfaceCard(
        padding: const EdgeInsets.all(11),
        radius: 16,
        onTap: onTap,
        child: Row(
          children: <Widget>[
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(gradient: LinearGradient(colors: colors), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18),
          ],
        ),
      );
    }

    final items = <Widget>[
      tile(
        icon: Icons.favorite_rounded,
        title: 'Любимые треки',
        subtitle: '${state.likedIds.length} треков',
        onTap: () {
          state.navigate(AppPage.library);
        },
        colors: const <Color>[Color(0xFFA3A790), Color(0xFF525F50)],
      ),
      tile(
        icon: Icons.library_music_rounded,
        title: 'Мои плейлисты',
        subtitle: 'Всё по настроению',
        onTap: () => state.navigate(AppPage.library),
        colors: const <Color>[Color(0xFFCEC0AD), Color(0xFF8A7661)],
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 620
          ? Column(children: <Widget>[items[0], const SizedBox(height: 10), items[1]])
          : Row(children: <Widget>[Expanded(child: items[0]), const SizedBox(width: 12), Expanded(child: items[1])]),
    );
  }
}

class _WaveHero extends StatefulWidget {
  const _WaveHero();

  @override
  State<_WaveHero> createState() => _WaveHeroState();
}

class _WaveHeroState extends State<_WaveHero> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 620;
    return Container(
      height: narrow ? 300 : 320,
      decoration: BoxDecoration(color: GlukColors.ink, borderRadius: BorderRadius.circular(26)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) => CustomPaint(painter: _WaveFieldPainter(controller.value)),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: <Color>[GlukColors.ink, GlukColors.ink.withValues(alpha: .93), GlukColors.ink.withValues(alpha: .08)],
                  stops: const <double>[0, .38, .82],
                ),
              ),
            ),
          ),
          Positioned(
            left: narrow ? 22 : 32,
            top: 24,
            child: Row(
              children: <Widget>[
                Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFFD5BDA0), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Text('БЕСКОНЕЧНО ТВОЯ', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFFD8D2C4))),
              ],
            ),
          ),
          Positioned(right: 28, top: 24, child: Text('GW / 003', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white54))),
          Positioned(
            left: narrow ? 22 : 32,
            top: narrow ? 72 : 78,
            right: narrow ? 20 : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Моя волна', style: TextStyle(color: const Color(0xFFF3F0E6), fontSize: narrow ? 42 : 52, fontWeight: FontWeight.w800, letterSpacing: -2.3, height: .98)),
                const SizedBox(height: 12),
                const Text('Любимое. Неожиданное. Твоё.\nМузыка, которая чувствует тебя.', style: TextStyle(color: Color(0xFFBDB9AE), height: 1.65, fontSize: 12)),
                const SizedBox(height: 22),
                Row(
                  children: <Widget>[
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF1EEE4), foregroundColor: GlukColors.ink, padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13)),
                      onPressed: () => state.playTrack(state.tracks.first),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Поймать волну'),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.tune_rounded, color: Color(0xFFF1EEE4))),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: narrow ? 22 : 32,
            right: 26,
            bottom: 18,
            child: Row(
              children: <Widget>[
                const _HeroBars(),
                const SizedBox(width: 10),
                const Expanded(child: Text('Подстраивается под тебя', style: TextStyle(color: Colors.white54, fontSize: 9))),
                const Text('∞', style: TextStyle(color: Color(0xFFE6DED0), fontSize: 28)),
                if (!narrow) const SizedBox(width: 7),
                if (!narrow) const Text('без повторения дня', style: TextStyle(color: Colors.white54, fontSize: 8)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveFieldPainter extends CustomPainter {
  const _WaveFieldPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .72, size.height * .5);
    for (var layer = 0; layer < 38; layer++) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = layer % 7 == 0 ? 1.15 : .55
        ..color = Color.lerp(const Color(0xFFD6B99B), const Color(0xFF6D746A), layer / 38)!.withValues(alpha: .08 + (38 - layer) / 38 * .16);
      final path = Path();
      for (var i = 0; i <= 84; i++) {
        final x = size.width * .38 + i / 84 * size.width * .76;
        final nx = (x - center.dx) / size.width;
        final amp = size.height * (.12 + layer * .0045);
        final y = center.dy + math.sin(i / 84 * math.pi * 4 + t * math.pi * 2 + layer * .17) * amp * math.exp(-nx.abs() * .8) + math.sin(i * .21 + layer) * 4;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveFieldPainter oldDelegate) => oldDelegate.t != t;
}

class _HeroBars extends StatefulWidget {
  const _HeroBars();
  @override
  State<_HeroBars> createState() => _HeroBarsState();
}

class _HeroBarsState extends State<_HeroBars> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  @override
  void dispose() { c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        builder: (_, __) => Row(
          children: List.generate(5, (i) => Container(width: 2, height: 5 + 8 * (.5 + .5 * math.sin(c.value * math.pi * 2 + i)), margin: const EdgeInsets.only(right: 3), color: const Color(0xFFD8C6B1))),
        ),
      );
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({required this.playlist, required this.index});
  final Playlist playlist;
  final int index;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final firstId = playlist.trackIds.isEmpty ? state.currentTrack.id : playlist.trackIds.first;
    final coverTrack = state.tracks.firstWhere((track) => track.id == firstId, orElse: () => state.currentTrack);
    return SizedBox(
      width: 180,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (playlist.trackIds.isNotEmpty) state.playTrack(coverTrack);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: <Widget>[
                CoverArt(track: coverTrack, size: 180, radius: 18),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFFF3EEE3E6), foregroundColor: GlukColors.ink),
                    onPressed: () => state.playTrack(coverTrack),
                    icon: const Icon(Icons.play_arrow_rounded, size: 19),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
            Text(playlist.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _RecentTracks extends StatelessWidget {
  const _RecentTracks({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionTitle(eyebrow: 'Хочется повторить', title: 'Ещё один раз'),
          const SizedBox(height: 12),
          ...state.tracks.take(4).map((track) => TrackTile(track: track, compact: true, showSource: false)),
        ],
      );
}

class _LofiPromo extends StatelessWidget {
  const _LofiPromo({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 1.55,
        child: Material(
          color: const Color(0xFF243028),
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: <Widget>[
                const Positioned.fill(child: CustomPaint(painter: _LofiPreviewPainter())),
                Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Colors.transparent, Colors.black.withValues(alpha: .56)])))),
                const Positioned(left: 22, top: 20, child: Text('●  LO-FI КОМНАТА', style: TextStyle(color: Color(0xFFD5D9C9), fontWeight: FontWeight.w800, fontSize: 9, letterSpacing: 1.4))),
                const Positioned(left: 22, bottom: 49, child: Text('Можно просто\nпобыть.', style: TextStyle(color: Colors.white, fontSize: 30, height: 1.02, fontWeight: FontWeight.w800, letterSpacing: -1.2))),
                const Positioned(left: 22, right: 18, bottom: 17, child: Row(children: <Widget>[Expanded(child: Text('Меньше мира. Больше музыки.', style: TextStyle(color: Colors.white60, fontSize: 9))), Icon(Icons.arrow_outward_rounded, color: Colors.white, size: 18)])),
              ],
            ),
          ),
        ),
      );
}

class _LofiPreviewPainter extends CustomPainter {
  const _LofiPreviewPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()..color = const Color(0xFF576658);
    canvas.drawRect(Offset.zero & size, sky);
    final moon = Paint()..color = const Color(0xFFD6D5B6).withValues(alpha: .65);
    canvas.drawCircle(Offset(size.width * .72, size.height * .25), size.shortestSide * .09, moon);
    final hill = Paint()..color = const Color(0xFF314238);
    final p1 = Path()..moveTo(0, size.height * .64)..quadraticBezierTo(size.width * .3, size.height * .34, size.width * .56, size.height * .64)..quadraticBezierTo(size.width * .78, size.height * .48, size.width, size.height * .67)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(p1, hill);
    final water = Paint()..color = const Color(0xFF263A35);
    canvas.drawRect(Rect.fromLTWH(0, size.height * .73, size.width, size.height * .27), water);
    final glow = Paint()..color = const Color(0xFFD6D5B6).withValues(alpha: .12);
    for (var i = 0; i < 8; i++) {
      final y = size.height * (.76 + i * .025);
      canvas.drawRect(Rect.fromCenter(center: Offset(size.width * .7, y), width: size.width * (.25 - i * .018), height: 1), glow);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
