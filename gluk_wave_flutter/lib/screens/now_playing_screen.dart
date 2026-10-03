import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> with SingleTickerProviderStateMixin {
  int tab = 0;
  double tiltX = -0.08;
  double tiltY = 0.13;
  bool vinyl = true;
  final TextEditingController comment = TextEditingController();
  late final AnimationController breathe;

  @override
  void initState() {
    super.initState();
    breathe = AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat(reverse: true);
  }

  @override
  void dispose() {
    breathe.dispose();
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final track = state.currentTrack;
    final size = MediaQuery.sizeOf(context);
    final mobile = size.width < 760;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: _Backdrop(track: track, animation: breathe)),
          SafeArea(
            child: Column(
              children: <Widget>[
                _Header(track: track, onClose: () => Navigator.of(context).maybePop()),
                _Tabs(index: tab, onChanged: (value) => setState(() => tab = value)),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: switch (tab) {
                      0 => _playerTab(context, state, mobile),
                      1 => _lyricsTab(context, state),
                      2 => _commentsTab(context, state),
                      _ => _queueTab(context, state),
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerTab(BuildContext context, AppState state, bool mobile) {
    final track = state.currentTrack;
    final content = <Widget>[
      Expanded(
        flex: mobile ? 0 : 6,
        child: Align(
          alignment: mobile ? Alignment.topCenter : Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: mobile ? 460 : 620),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _AlbumObject(
                  track: track,
                  vinyl: vinyl,
                  tiltX: tiltX,
                  tiltY: tiltY,
                  onPan: (delta) => setState(() {
                    tiltY = (tiltY + delta.dx * .006).clamp(-.65, .65).toDouble();
                    tiltX = (tiltX - delta.dy * .006).clamp(-.48, .48).toDouble();
                  }),
                  onReset: () => setState(() {
                    tiltX = -.08;
                    tiltY = .13;
                  }),
                  onKind: () => setState(() => vinyl = !vinyl),
                ),
                const SizedBox(height: 18),
                _TrackHeading(state: state),
                const SizedBox(height: 16),
                _Timeline(state: state, showComments: true),
                const SizedBox(height: 9),
                _Transport(state: state),
                if (state.lyricsUnderCover && track.lyrics.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 18),
                  _InlineLyrics(state: state),
                ],
              ],
            ),
          ),
        ),
      ),
      if (!mobile) ...<Widget>[
        const SizedBox(width: 34),
        Expanded(
          flex: 4,
          child: _SidePanel(
            state: state,
            onLyrics: () => setState(() => tab = 1),
            onComments: () => setState(() => tab = 2),
          ),
        ),
      ],
    ];

    return Padding(
      key: const ValueKey<String>('player'),
      padding: EdgeInsets.fromLTRB(mobile ? 18 : 38, 18, mobile ? 18 : 38, 28),
      child: mobile
          ? ListView(
              children: <Widget>[
                ...content.where((widget) => widget is! Expanded),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    children: <Widget>[
                      _AlbumObject(
                        track: track,
                        vinyl: vinyl,
                        tiltX: tiltX,
                        tiltY: tiltY,
                        onPan: (delta) => setState(() {
                          tiltY = (tiltY + delta.dx * .006).clamp(-.65, .65).toDouble();
                          tiltX = (tiltX - delta.dy * .006).clamp(-.48, .48).toDouble();
                        }),
                        onReset: () => setState(() {
                          tiltX = -.08;
                          tiltY = .13;
                        }),
                        onKind: () => setState(() => vinyl = !vinyl),
                      ),
                      const SizedBox(height: 18),
                      _TrackHeading(state: state),
                      const SizedBox(height: 16),
                      _Timeline(state: state, showComments: true),
                      const SizedBox(height: 9),
                      _Transport(state: state),
                      if (state.lyricsUnderCover && track.lyrics.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 18),
                        _InlineLyrics(state: state),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _SidePanel(state: state, onLyrics: () => setState(() => tab = 1), onComments: () => setState(() => tab = 2)),
              ],
            )
          : Row(crossAxisAlignment: CrossAxisAlignment.center, children: content),
    );
  }

  Widget _lyricsTab(BuildContext context, AppState state) {
    final track = state.currentTrack;
    final lyrics = track.lyrics;
    final active = _activeLyricIndex(track, state.position);
    return ListView(
      key: const ValueKey<String>('lyrics'),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 130),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Eyebrow('Слова в ритме'),
                    const Spacer(),
                    Switch(value: state.lyricsUnderCover, onChanged: state.setLyricsUnderCover),
                    const SizedBox(width: 4),
                    Text('под обложкой', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 18),
                if (lyrics.isEmpty)
                  SurfaceCard(child: Text('Для локального трека текст пока не добавлен.', style: Theme.of(context).textTheme.bodyLarge))
                else
                  ...List<Widget>.generate(lyrics.length, (index) {
                    final line = lyrics[index];
                    final selected = index == active;
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => state.seek(line.time),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: selected ? Theme.of(context).colorScheme.onSurface.withValues(alpha: .07) : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SizedBox(width: 52, child: Text(_shortTime(line.time), style: Theme.of(context).textTheme.labelSmall)),
                            Expanded(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 240),
                                style: (selected ? Theme.of(context).textTheme.headlineMedium : Theme.of(context).textTheme.titleLarge)!.copyWith(
                                  color: selected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: .48),
                                  height: 1.25,
                                ),
                                child: Text(line.text),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _commentsTab(BuildContext context, AppState state) {
    final comments = state.currentComments;
    return ListView(
      key: const ValueKey<String>('comments'),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 130),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Eyebrow('Комментарии на волне'),
                const SizedBox(height: 6),
                Text('Оставляй мысль ровно в тот момент, где она появилась.', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 18),
                _Timeline(state: state, showComments: true),
                const SizedBox(height: 18),
                SurfaceCard(
                  child: Row(
                    children: <Widget>[
                      Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: GlukColors.accentSoft, borderRadius: BorderRadius.circular(11)), child: const Text('А', style: TextStyle(fontWeight: FontWeight.w900))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: comment,
                          maxLength: 220,
                          decoration: InputDecoration(counterText: '', hintText: 'Комментарий на ${_shortTime(state.position)}'),
                          onSubmitted: (_) => _sendComment(state),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(onPressed: () => _sendComment(state), icon: const Icon(Icons.arrow_upward_rounded)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (comments.isEmpty)
                  SurfaceCard(child: Text('Пока тишина. Будешь первым.', style: Theme.of(context).textTheme.bodyLarge))
                else
                  ...comments.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => state.seek(entry.at),
                          borderRadius: BorderRadius.circular(18),
                          child: SurfaceCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(width: 38, height: 38, alignment: Alignment.center, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .07), borderRadius: BorderRadius.circular(12)), child: Text(entry.author.isEmpty ? '?' : entry.author.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.w900))),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Row(children: <Widget>[Expanded(child: Text(entry.author, style: Theme.of(context).textTheme.titleMedium)), Text(_shortTime(entry.at), style: Theme.of(context).textTheme.labelSmall)]), const SizedBox(height: 5), Text(entry.text, style: Theme.of(context).textTheme.bodyLarge)])),
                              ],
                            ),
                          ),
                        ),
                      )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _queueTab(BuildContext context, AppState state) {
    final ordered = <Track>[];
    for (var i = 1; i < state.tracks.length; i++) {
      ordered.add(state.tracks[(state.currentIndex + i) % state.tracks.length]);
    }
    return ListView(
      key: const ValueKey<String>('queue'),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 130),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Eyebrow('Дальше по волне'),
                const SizedBox(height: 5),
                Text('Очередь продолжится сама', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                ...ordered.asMap().entries.map((entry) => TrackTile(track: entry.value)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _sendComment(AppState state) async {
    final text = comment.text;
    comment.clear();
    await state.addComment(text);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.track, required this.onClose});
  final Track track;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
        child: Row(
          children: <Widget>[
            IconButton(onPressed: onClose, icon: const Icon(Icons.keyboard_arrow_down_rounded), tooltip: 'Свернуть'),
            Expanded(child: Column(children: <Widget>[Text('СЕЙЧАС ИГРАЕТ', style: Theme.of(context).textTheme.labelSmall), const SizedBox(height: 2), Text(track.album, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium)])),
            IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz_rounded)),
          ],
        ),
      );
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = <String>['Плеер', 'Слова', 'Комментарии', 'Очередь'];
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .055), borderRadius: BorderRadius.circular(15)),
          child: Row(
            children: List<Widget>.generate(labels.length, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: ChoiceChip(label: Text(labels[i]), selected: i == index, showCheckmark: false, onSelected: (_) => onChanged(i), side: BorderSide.none),
                )),
          ),
        ),
      ),
    );
  }
}

class _AlbumObject extends StatelessWidget {
  const _AlbumObject({required this.track, required this.vinyl, required this.tiltX, required this.tiltY, required this.onPan, required this.onReset, required this.onKind});
  final Track track;
  final bool vinyl;
  final double tiltX;
  final double tiltY;
  final ValueChanged<Offset> onPan;
  final VoidCallback onReset;
  final VoidCallback onKind;

  @override
  Widget build(BuildContext context) {
    final width = math.min(MediaQuery.sizeOf(context).width * .66, 330.0);
    return Column(
      children: <Widget>[
        GestureDetector(
          onPanUpdate: (details) => onPan(details.delta),
          onDoubleTap: onReset,
          child: SizedBox(
            height: width * 1.03,
            width: width * 1.24,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                if (vinyl)
                  Transform.translate(
                    offset: Offset(width * .20, width * .015),
                    child: Container(
                      width: width * .92,
                      height: width * .92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(colors: <Color>[Color(0xFFB48A6D), Color(0xFF252522), Color(0xFF0E0E0D)], stops: <double>[0, .19, 1]),
                        boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: 28, offset: const Offset(9, 17))],
                      ),
                      child: CustomPaint(painter: _GroovePainter()),
                    ),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  transformAlignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, .0012)
                    ..rotateX(tiltX)
                    ..rotateY(tiltY),
                  width: width,
                  height: width,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withValues(alpha: .23), blurRadius: 34, offset: const Offset(0, 18))]),
                  child: CoverArt(track: track, size: width, radius: 24, showText: true),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('↔  потяни, чтобы покрутить', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(width: 8),
            IconButton(onPressed: onReset, tooltip: 'Сбросить', icon: const Icon(Icons.center_focus_strong_rounded, size: 18)),
            TextButton(onPressed: onKind, child: Text(vinyl ? 'VINYL' : 'SLEEVE')),
          ],
        ),
      ],
    );
  }
}

class _GroovePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final max = size.shortestSide / 2;
    for (var i = 9; i < 30; i++) {
      paint
        ..color = Colors.white.withValues(alpha: i.isEven ? .06 : .025)
        ..strokeWidth = .7;
      canvas.drawCircle(center, max * (.26 + i * .023), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrackHeading extends StatelessWidget {
  const _TrackHeading({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final track = state.currentTrack;
    return Row(
      children: <Widget>[
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.headlineLarge), const SizedBox(height: 3), Text('${track.artist} · ${track.source.label}', style: Theme.of(context).textTheme.bodyMedium)])),
        IconButton(onPressed: () => state.toggleLike(track), icon: Icon(state.likedIds.contains(track.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded), color: state.likedIds.contains(track.id) ? GlukColors.accent : null),
        IconButton(onPressed: track.isLocal ? null : () => state.toggleDownload(track), icon: Icon(state.downloadedIds.contains(track.id) ? Icons.download_done_rounded : Icons.download_for_offline_outlined)),
      ],
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.state, required this.showComments});
  final AppState state;
  final bool showComments;

  @override
  Widget build(BuildContext context) {
    final durationMs = math.max(state.duration.inMilliseconds, 1);
    final value = state.position.inMilliseconds.clamp(0, durationMs).toDouble();
    return Column(
      children: <Widget>[
        SizedBox(
          height: 26,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                top: 9,
                child: Slider(value: value, min: 0, max: durationMs.toDouble(), onChanged: (v) => state.seek(Duration(milliseconds: v.round()))),
              ),
              if (showComments)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(painter: _CommentMarkersPainter(comments: state.currentComments, durationMs: durationMs, color: GlukColors.accent)),
                  ),
                ),
            ],
          ),
        ),
        Row(children: <Widget>[Text(_shortTime(state.position), style: Theme.of(context).textTheme.labelSmall), const Spacer(), if (state.currentComments.isNotEmpty) Text('${state.currentComments.length} комментария на таймлайне', style: Theme.of(context).textTheme.labelSmall), const Spacer(), Text(_shortTime(state.duration), style: Theme.of(context).textTheme.labelSmall)]),
      ],
    );
  }
}

class _CommentMarkersPainter extends CustomPainter {
  const _CommentMarkersPainter({required this.comments, required this.durationMs, required this.color});
  final List<CommentEntry> comments;
  final int durationMs;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (durationMs <= 0) return;
    final paint = Paint()..color = color;
    for (final entry in comments) {
      final x = (entry.at.inMilliseconds / durationMs).clamp(0.0, 1.0).toDouble() * size.width;
      canvas.drawCircle(Offset(x, 5), 2.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CommentMarkersPainter oldDelegate) => oldDelegate.comments != comments || oldDelegate.durationMs != durationMs;
}

class _Transport extends StatelessWidget {
  const _Transport({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          IconButton(onPressed: state.toggleShuffle, icon: const Icon(Icons.shuffle_rounded), color: state.shuffle ? GlukColors.accent : null),
          IconButton(onPressed: () => state.previous(), icon: const Icon(Icons.skip_previous_rounded), iconSize: 30),
          SizedBox(width: 62, height: 62, child: FilledButton(onPressed: () => state.togglePlay(), style: FilledButton.styleFrom(shape: const CircleBorder(), padding: EdgeInsets.zero), child: Icon(state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 33))),
          IconButton(onPressed: () => state.next(), icon: const Icon(Icons.skip_next_rounded), iconSize: 30),
          IconButton(onPressed: () => state.toggleRepeat(), icon: const Icon(Icons.repeat_rounded), color: state.repeat ? GlukColors.accent : null),
        ],
      );
}

class _InlineLyrics extends StatelessWidget {
  const _InlineLyrics({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final lines = state.currentTrack.lyrics;
    final active = _activeLyricIndex(state.currentTrack, state.position);
    final start = math.max(0, active - 1);
    final end = math.min(lines.length, start + 4);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .045), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(children: <Widget>[const Eyebrow('В словах'), const Spacer(), TextButton(onPressed: () {}, child: const Text('построчно'))]),
          const SizedBox(height: 6),
          for (var i = start; i < end; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(lines[i].text, style: (i == active ? Theme.of(context).textTheme.titleLarge : Theme.of(context).textTheme.bodyMedium)!.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: i == active ? 1 : .42))),
            ),
        ],
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({required this.state, required this.onLyrics, required this.onComments});
  final AppState state;
  final VoidCallback onLyrics;
  final VoidCallback onComments;

  @override
  Widget build(BuildContext context) {
    final next = state.tracks[(state.currentIndex + 1) % state.tracks.length];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SurfaceCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Row(children: <Widget>[const Eyebrow('В словах'), const Spacer(), TextButton(onPressed: onLyrics, child: const Text('Открыть'))]), const SizedBox(height: 8), _InlineLyrics(state: state)]),
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Row(children: <Widget>[const Eyebrow('На этом моменте'), const Spacer(), TextButton(onPressed: onComments, child: Text('${state.currentComments.length} комм.'))]), const SizedBox(height: 9), if (state.currentComments.isEmpty) Text('Никто ещё не оставил след.', style: Theme.of(context).textTheme.bodyMedium) else Text('“${state.currentComments.first.text}”', style: Theme.of(context).textTheme.titleMedium)]),
          ),
          const SizedBox(height: 12),
          SurfaceCard(
            child: Row(children: <Widget>[SizedBox(width: 54, height: 54, child: CoverArt(track: next, radius: 14)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[const Eyebrow('Следом'), Text(next.title, style: Theme.of(context).textTheme.titleMedium), Text(next.artist, style: Theme.of(context).textTheme.bodySmall)])), IconButton(onPressed: () => state.playTrack(next), icon: const Icon(Icons.play_arrow_rounded))]),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              GlukPill(label: state.roomConnected ? state.roomCode : 'Слушать вместе', icon: Icons.group_rounded, onTap: () => state.navigate(AppPage.rooms)),
              GlukPill(label: state.currentTrack.source.label, icon: state.currentTrack.source.icon),
              if (state.downloadedIds.contains(state.currentTrack.id)) const GlukPill(label: 'Офлайн', icon: Icons.download_done_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.track, required this.animation});
  final Track track;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(animation.value);
          return Stack(
            children: <Widget>[
              Positioned.fill(child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor)),
              Positioned(top: -120 + t * 16, right: -110, child: _blob(track.palette.last.withValues(alpha: .14), 430)),
              Positioned(bottom: -170, left: -120 + t * 22, child: _blob(track.palette.first.withValues(alpha: .10), 520)),
            ],
          );
        },
      );

  Widget _blob(Color color, double size) => IgnorePointer(child: Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: <BoxShadow>[BoxShadow(color: color, blurRadius: 90, spreadRadius: 35)])));
}

int _activeLyricIndex(Track track, Duration position) {
  if (track.lyrics.isEmpty) return 0;
  var active = 0;
  for (var i = 0; i < track.lyrics.length; i++) {
    if (track.lyrics[i].time <= position) active = i;
  }
  return active;
}

String _shortTime(Duration value) {
  final seconds = math.max(0, value.inSeconds);
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return '$minutes:${rest.toString().padLeft(2, '0')}';
}
