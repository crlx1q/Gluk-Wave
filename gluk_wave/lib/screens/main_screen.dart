import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../models/soundcloud_track.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomeView(),
    SearchView(),
    LibraryView(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).fetchCharts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEDE3),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _pages[_currentIndex]),
            MiniPlayer(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFEFEDE3),
        selectedItemColor: const Color(0xFFD19D75),
        unselectedItemColor: const Color(0xFF302F2C),
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Поиск'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Медиатека'),
        ],
      ),
    );
  }
}

class HomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Gluk Wave', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF302F2C))),
            const SizedBox(height: 8),
            const Text('Популярное', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF302F2C))),
            const SizedBox(height: 16),
            ...state.charts.map((track) => TrackTile(track: track)).toList(),
          ],
        );
      },
    );
  }
}

class SearchView extends StatefulWidget {
  @override
  _SearchViewState createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Поиск треков...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onTap: () {
                  if (_searchController.text.isNotEmpty) {
                    Provider.of<AppState>(context, listen: false).search(_searchController.text);
                  }
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
              filled: true,
              fillColor: const Color(0xFFF7F6F0),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                Provider.of<AppState>(context, listen: false).search(value);
              }
            },
          ),
        ),
        Expanded(
          child: Consumer<AppState>(
            builder: (context, state, child) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.searchResults.isEmpty) {
                return const Center(child: Text('Нет результатов'));
              }
              return ListView.builder(
                itemCount: state.searchResults.length,
                itemBuilder: (context, index) {
                  return TrackTile(track: state.searchResults[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class LibraryView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Медиатека (В разработке)'));
  }
}

class TrackTile extends StatelessWidget {
  final SoundCloudTrack track;

  const TrackTile({required this.track});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: track.artworkUrl.isNotEmpty ? track.artworkUrl : 'https://via.placeholder.com/150',
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(color: Colors.grey[300]),
          errorWidget: (context, url, error) => const Icon(Icons.music_note),
        ),
      ),
      title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () {
        Provider.of<AppState>(context, listen: false).playTrack(track);
      },
    );
  }
}

class MiniPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, child) {
        if (state.currentTrack == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => FullPlayer(),
            );
          },
          child: Container(
            color: const Color(0xFFF7F6F0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: state.currentTrack!.artworkUrl.isNotEmpty ? state.currentTrack!.artworkUrl : 'https://via.placeholder.com/150',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const Icon(Icons.music_note),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(state.currentTrack!.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(state.currentTrack!.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () => state.togglePlayPause(),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class FullPlayer extends StatefulWidget {
  @override
  _FullPlayerState createState() => _FullPlayerState();
}

class _FullPlayerState extends State<FullPlayer> with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final track = state.currentTrack;

    if (track == null) return const SizedBox.shrink();

    if (state.isPlaying) {
      _rotationController.repeat();
    } else {
      _rotationController.stop();
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFEFEDE3),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 32),
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 32),
          // Wave Animation
          SizedBox(
            height: 60,
            width: double.infinity,
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: WavePainter(isPlaying: state.isPlaying),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          // 3D Vinyl
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateX(0.1) // Slight tilt
                      ..rotateY(_rotationController.value * 2 * math.pi), // Spin
                    alignment: FractionalOffset.center,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                        ],
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(
                            track.artworkUrl.isNotEmpty ? track.artworkUrl : 'https://via.placeholder.com/500'
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Center(
                         child: Container(
                           width: 50,
                           height: 50,
                           decoration: BoxDecoration(
                             shape: BoxShape.circle,
                             color: Colors.white,
                             border: Border.all(color: Colors.black12, width: 2)
                           ),
                         )
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(track.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1),
          const SizedBox(height: 8),
          Text(track.artist, style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center, maxLines: 1),
          const SizedBox(height: 24),
          // Progress
          Slider(
            activeColor: const Color(0xFFD19D75),
            inactiveColor: Colors.grey[300],
            value: state.currentPosition.inMilliseconds.toDouble().clamp(0.0, state.totalDuration.inMilliseconds.toDouble() > 0 ? state.totalDuration.inMilliseconds.toDouble() : 1.0),
            max: state.totalDuration.inMilliseconds.toDouble() > 0 ? state.totalDuration.inMilliseconds.toDouble() : 1.0,
            onChanged: (val) {
              state.seek(Duration(milliseconds: val.toInt()));
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(state.currentPosition)),
                Text(_formatDuration(state.totalDuration)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.skip_previous, size: 40), onPressed: () {}),
              const SizedBox(width: 16),
              FloatingActionButton(
                backgroundColor: const Color(0xFF302F2C),
                onPressed: () => state.togglePlayPause(),
                child: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow, size: 32, color: const Color(0xFFEFEDE3)),
              ),
              const SizedBox(width: 16),
              IconButton(icon: const Icon(Icons.skip_next, size: 40), onPressed: () {}),
            ],
          )
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}

class WavePainter extends CustomPainter {
  final bool isPlaying;

  WavePainter({required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD19D75).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();
    double time = DateTime.now().millisecondsSinceEpoch / 500;

    if(!isPlaying) time = 0;

    for (double i = 0; i <= size.width; i++) {
      double wave1 = math.sin((i / size.width * 2 * math.pi) + time);
      double wave2 = math.cos((i / size.width * 3 * math.pi) - time * 0.5);

      double y = size.height / 2 + (wave1 + wave2) * 10;

      if (i == 0) {
        path.moveTo(i, y);
      } else {
        path.lineTo(i, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) {
    return isPlaying; // Repaint constantly if playing
  }
}
