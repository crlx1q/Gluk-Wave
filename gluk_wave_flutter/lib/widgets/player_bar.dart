import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import 'common.dart';

class PlayerBar extends StatelessWidget {
  const PlayerBar({super.key, required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final mobile = MediaQuery.sizeOf(context).width < 760;
    final track = state.currentTrack;
    final durationMs = (state.duration.inMilliseconds <= 0 ? track.duration.inMilliseconds : state.duration.inMilliseconds).toDouble();
    final currentMs = state.position.inMilliseconds.clamp(0, durationMs.toInt()).toDouble();

    if (mobile) {
      return Container(
        height: 70,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 78),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .08)),
          boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withValues(alpha: .12), blurRadius: 28, offset: const Offset(0, 12))],
        ),
        child: Stack(
          children: <Widget>[
            Row(
              children: <Widget>[
                const SizedBox(width: 9),
                GestureDetector(onTap: onOpen, child: CoverArt(track: track, size: 49, radius: 11)),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onOpen,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                        Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
                IconButton(onPressed: state.previous, icon: const Icon(Icons.skip_previous_rounded)),
                _PlayButton(compact: true),
                IconButton(onPressed: state.next, icon: const Icon(Icons.skip_next_rounded)),
                const SizedBox(width: 4),
              ],
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 0,
              child: LinearProgressIndicator(
                minHeight: 2,
                borderRadius: BorderRadius.circular(4),
                value: durationMs <= 0 ? 0 : currentMs / durationMs,
                backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: .08),
                valueColor: const AlwaysStoppedAnimation<Color>(GlukColors.accent),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 94,
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 20),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .08)),
        boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withValues(alpha: .11), blurRadius: 36, offset: const Offset(0, 18))],
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Row(
              children: <Widget>[
                GestureDetector(onTap: onOpen, child: CoverArt(track: track, size: 56, radius: 13)),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onOpen,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(track.title, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                        Text(track.artist, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => state.toggleLike(track),
                  icon: Icon(state.likedIds.contains(track.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: state.likedIds.contains(track.id) ? GlukColors.accent : null),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    IconButton(onPressed: state.toggleShuffle, icon: Icon(Icons.shuffle_rounded, color: state.shuffle ? GlukColors.accent : null)),
                    IconButton(onPressed: state.previous, icon: const Icon(Icons.skip_previous_rounded)),
                    _PlayButton(compact: false),
                    IconButton(onPressed: state.next, icon: const Icon(Icons.skip_next_rounded)),
                    IconButton(onPressed: state.toggleRepeat, icon: Icon(Icons.repeat_rounded, color: state.repeat ? GlukColors.accent : null)),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Text(_time(state.position), style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Slider(
                        min: 0,
                        max: durationMs <= 0 ? 1 : durationMs,
                        value: durationMs <= 0 ? 0 : currentMs,
                        onChanged: (value) => state.seek(Duration(milliseconds: value.round())),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(_time(state.duration), style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                IconButton(onPressed: onOpen, tooltip: 'Развернуть', icon: const Icon(Icons.open_in_full_rounded)),
                Icon(state.downloadedIds.contains(track.id) ? Icons.download_done_rounded : Icons.cloud_download_outlined, size: 17),
                const SizedBox(width: 8),
                const Icon(Icons.volume_up_rounded, size: 18),
                SizedBox(
                  width: 92,
                  child: Slider(value: state.volume, onChanged: state.setVolume),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final size = compact ? 38.0 : 44.0;
    return SizedBox(
      width: size,
      height: size,
      child: FilledButton(
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: const CircleBorder(),
          backgroundColor: Theme.of(context).colorScheme.onSurface,
          foregroundColor: Theme.of(context).scaffoldBackgroundColor,
        ),
        onPressed: state.togglePlay,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Icon(state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, key: ValueKey<bool>(state.playing), size: compact ? 24 : 28),
        ),
      ),
    );
  }
}

String _time(Duration duration) {
  final seconds = duration.inSeconds.clamp(0, 60 * 60 * 12).toInt();
  final m = seconds ~/ 60;
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
