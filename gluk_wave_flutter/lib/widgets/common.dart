import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.dot = true});
  final String text;
  final bool dot;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (dot) ...<Widget>[
            const DecoratedBox(
              decoration: BoxDecoration(color: GlukColors.accent, shape: BoxShape.circle),
              child: SizedBox(width: 5, height: 5),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(child: Text(text.toUpperCase(), style: Theme.of(context).textTheme.labelSmall)),
        ],
      );
}

class PageHeading extends StatelessWidget {
  const PageHeading({super.key, required this.eyebrow, required this.title, required this.subtitle, this.trailing});
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 700;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Eyebrow(eyebrow),
        const SizedBox(height: 10),
        Text('$title.', style: narrow ? Theme.of(context).textTheme.headlineLarge : Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 9),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color)),
      ],
    );
    if (trailing == null) return text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(child: text),
        const SizedBox(width: 16),
        trailing!,
      ],
    );
  }
}

class GlukPill extends StatelessWidget {
  const GlukPill({super.key, required this.label, this.icon, this.onTap, this.selected = false, this.compact = false});
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return Material(
      color: selected ? ink : Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
      shape: StadiumBorder(side: BorderSide(color: ink.withValues(alpha: selected ? 0 : 0.09))),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 11 : 14, vertical: compact ? 8 : 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: compact ? 14 : 16, color: selected ? Theme.of(context).scaffoldBackgroundColor : null),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: compact ? 10 : 11,
                      color: selected ? Theme.of(context).scaffoldBackgroundColor : null,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WaveLogo extends StatefulWidget {
  const WaveLogo({super.key, this.size = 38, this.animate = false, this.withWordmark = false, this.inverse = false});
  final double size;
  final bool animate;
  final bool withWordmark;
  final bool inverse;

  @override
  State<WaveLogo> createState() => _WaveLogoState();
}

class _WaveLogoState extends State<WaveLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant WaveLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      widget.animate ? _controller.repeat() : _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = widget.inverse ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).colorScheme.onSurface;
    final bg = widget.inverse ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface;
    final mark = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(widget.size * .33)),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: _WaveLogoPainter(color: widget.inverse ? Theme.of(context).scaffoldBackgroundColor : Theme.of(context).scaffoldBackgroundColor, phase: widget.animate ? _controller.value * math.pi * 2 : 0),
        ),
      ),
    );
    if (!widget.withWordmark) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        mark,
        const SizedBox(width: 9),
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(text: 'gluk', style: TextStyle(fontWeight: FontWeight.w900, color: ink)),
              TextSpan(text: 'wave', style: TextStyle(fontWeight: FontWeight.w500, color: ink)),
              const TextSpan(text: '·', style: TextStyle(color: GlukColors.accent, fontWeight: FontWeight.w900)),
            ],
          ),
          style: TextStyle(fontSize: widget.size * .63, letterSpacing: -1.2),
        ),
      ],
    );
  }
}

class _WaveLogoPainter extends CustomPainter {
  const _WaveLogoPainter({required this.color, required this.phase});
  final Color color;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    const samples = 34;
    for (var i = 0; i < samples; i++) {
      final x = size.width * (.16 + .68 * i / (samples - 1));
      final normalized = i / (samples - 1);
      final base = math.sin(normalized * math.pi * 4 - .45 + phase * .09);
      final pulse = 1 + .06 * math.sin(phase + normalized * math.pi * 2);
      final y = size.height * (.51 + base * .19 * pulse);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaveLogoPainter oldDelegate) => oldDelegate.phase != phase || oldDelegate.color != color;
}

class CoverArt extends StatelessWidget {
  const CoverArt({super.key, required this.track, this.size = 56, this.radius = 14, this.showText = true});
  final Track track;
  final double size;
  final double radius;
  final bool showText;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: track.palette,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 24, offset: const Offset(0, 12)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            children: <Widget>[
              Positioned.fill(child: CustomPaint(painter: _CoverTexturePainter(track.id.hashCode))),
              if (showText)
                Positioned(
                  left: size * .1,
                  bottom: size * .1,
                  right: size * .08,
                  child: Text(
                    '${track.title.toLowerCase()}.',
                    maxLines: 2,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .92),
                      fontWeight: FontWeight.w900,
                      height: .9,
                      fontSize: size * .16,
                      letterSpacing: -1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}

class _CoverTexturePainter extends CustomPainter {
  const _CoverTexturePainter(this.seed);
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(seed);
    final line = Paint()..strokeWidth = 1;
    for (var i = 0; i < 16; i++) {
      line.color = Colors.white.withValues(alpha: .025 + random.nextDouble() * .035);
      final y = random.nextDouble() * size.height;
      canvas.drawLine(Offset(-10, y), Offset(size.width + 10, y + random.nextDouble() * 18 - 9), line);
    }
    final glow = Paint()
      ..shader = RadialGradient(colors: <Color>[Colors.white.withValues(alpha: .14), Colors.transparent]).createShader(Rect.fromCircle(center: Offset(size.width * .72, size.height * .22), radius: size.width * .6));
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant _CoverTexturePainter oldDelegate) => oldDelegate.seed != seed;
}

class TrackTile extends StatelessWidget {
  const TrackTile({super.key, required this.track, this.compact = false, this.showSource = true});
  final Track track;
  final bool compact;
  final bool showSource;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final active = state.currentTrack.id == track.id;
    final liked = state.likedIds.contains(track.id);
    final downloaded = state.downloadedIds.contains(track.id) || track.isLocal;
    return Material(
      color: active ? Theme.of(context).colorScheme.onSurface.withValues(alpha: .055) : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => state.playTrack(track),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 8, vertical: compact ? 7 : 8),
          child: Row(
            children: <Widget>[
              CoverArt(track: track, size: compact ? 42 : 50, radius: compact ? 10 : 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(child: Text(track.title, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium)),
                        if (active) ...<Widget>[
                          const SizedBox(width: 7),
                          const _LiveBars(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (showSource && MediaQuery.sizeOf(context).width > 720) ...<Widget>[
                SizedBox(
                  width: 142,
                  child: Row(
                    children: <Widget>[
                      Icon(track.source.icon, size: 15),
                      const SizedBox(width: 7),
                      Flexible(child: Text(track.source.label, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall)),
                    ],
                  ),
                ),
              ],
              IconButton(
                tooltip: downloaded ? 'Удалить из офлайна' : 'Скачать',
                onPressed: track.isLocal ? null : () => state.toggleDownload(track),
                icon: Icon(downloaded ? Icons.download_done_rounded : Icons.download_rounded, size: 19),
              ),
              IconButton(
                tooltip: liked ? 'Убрать из любимых' : 'В любимые',
                onPressed: () => state.toggleLike(track),
                icon: Icon(liked ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 19, color: liked ? GlukColors.accent : null),
              ),
              SizedBox(
                width: 42,
                child: Text(
                  _formatDuration(track.duration),
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDuration(Duration value) {
  if (value <= Duration.zero) return '—';
  final minutes = value.inMinutes;
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class _LiveBars extends StatefulWidget {
  const _LiveBars();
  @override
  State<_LiveBars> createState() => _LiveBarsState();
}

class _LiveBarsState extends State<_LiveBars> with SingleTickerProviderStateMixin {
  late final AnimationController controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, child) => Row(
          children: List<Widget>.generate(3, (i) {
            final h = 5 + 6 * (.5 + .5 * math.sin(controller.value * math.pi * 2 + i));
            return Container(width: 2, height: h, margin: const EdgeInsets.only(right: 2), decoration: BoxDecoration(color: GlukColors.accent, borderRadius: BorderRadius.circular(3)));
          }),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.eyebrow, required this.title, this.trailing});
  final String eyebrow;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Eyebrow(eyebrow, dot: false),
                const SizedBox(height: 7),
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      );
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.radius = 22, this.onTap});
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final body = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Padding(padding: padding, child: child),
    );
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: .78),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: BorderSide(color: ink.withValues(alpha: .07))),
      child: body,
    );
  }
}
