import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 130),
      children: <Widget>[
        PageHeading(
          eyebrow: 'Одна музыка на всех',
          title: 'Слушать вместе',
          subtitle: 'Комната, очередь, чат и права управления — почти как голосовой канал, только вокруг музыки.',
          trailing: GlukPill(
            label: state.roomConnected ? 'Выйти из ${state.roomCode}' : 'Создать комнату',
            icon: state.roomConnected ? Icons.logout_rounded : Icons.add_rounded,
            onTap: state.roomConnected ? state.leaveRoom : () => _showJoinDialog(context, state, create: true),
          ),
        ),
        const SizedBox(height: 24),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 900) {
              return Column(
                children: <Widget>[
                  _RoomBrowser(state: state),
                  const SizedBox(height: 16),
                  _RoomSession(state: state),
                  const SizedBox(height: 16),
                  _MembersPanel(state: state),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(width: 250, child: _RoomBrowser(state: state)),
                const SizedBox(width: 16),
                Expanded(child: _RoomSession(state: state)),
                const SizedBox(width: 16),
                SizedBox(width: 255, child: _MembersPanel(state: state)),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _showJoinDialog(BuildContext context, AppState state, {bool create = false}) async {
    final controller = TextEditingController(text: create ? 'WAVE-${100 + math.Random().nextInt(899)}' : state.roomCode);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(create ? 'Новая комната' : 'Войти в комнату'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(create ? 'Этот код можно отправить другу.' : 'Введи код приглашения.', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            TextField(controller: controller, autofocus: true, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(prefixIcon: Icon(Icons.tag_rounded), labelText: 'Код комнаты')),
          ],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(create ? 'Создать' : 'Войти')),
        ],
      ),
    );
    if (result != null) await state.joinRoom(code: result);
  }
}

class _RoomBrowser extends StatelessWidget {
  const _RoomBrowser({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: InkWell(
              onTap: () => state.joinRoom(code: 'WAVE-42'),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                height: 230,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[Color(0xFF2A3B33), Color(0xFF516655), Color(0xFFB49A78)]),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Row(children: <Widget>[Icon(Icons.circle, color: Color(0xFFA8CF9F), size: 8), SizedBox(width: 6), Text('ЖИВАЯ КОМНАТА', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2))]),
                    const Spacer(),
                    Row(children: <Widget>[
                      CircleAvatar(radius: 14, child: Text('А')),
                      Transform.translate(offset: Offset(-6, 0), child: CircleAvatar(radius: 14, child: Text('M'))),
                      Transform.translate(offset: Offset(-12, 0), child: CircleAvatar(radius: 14, child: Text('N'))),
                    ]),
                    const SizedBox(height: 9),
                    const Text('Тихое место', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -1)),
                    const Text('Lo-fi, разговоры и никакой спешки', style: TextStyle(color: Colors.white60, fontSize: 11)),
                    const SizedBox(height: 12),
                    const Text('WAVE-42  ↗', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: state.joinRoom,
            icon: const Icon(Icons.login_rounded),
            label: const Text('Войти по сохранённому коду'),
          ),
          if (state.roomError != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(state.roomError!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      );
}

class _RoomSession extends StatefulWidget {
  const _RoomSession({required this.state});
  final AppState state;

  @override
  State<_RoomSession> createState() => _RoomSessionState();
}

class _RoomSessionState extends State<_RoomSession> {
  final TextEditingController message = TextEditingController();

  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Eyebrow('Твоя комната', dot: false),
                    const SizedBox(height: 6),
                    Text(state.roomConnected ? state.roomCode : 'Локальный предпросмотр', style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: state.roomConnected ? const Color(0xFF88A58D).withValues(alpha: .18) : Theme.of(context).colorScheme.onSurface.withValues(alpha: .07), borderRadius: BorderRadius.circular(999)),
                child: Text(state.roomConnected ? 'ONLINE' : 'LOCAL', style: Theme.of(context).textTheme.labelSmall),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .05), borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: <Widget>[
                CoverArt(track: state.currentTrack, size: 58, radius: 13),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(state.currentTrack.title, style: Theme.of(context).textTheme.titleMedium), Text(state.currentTrack.artist, style: Theme.of(context).textTheme.bodySmall)])),
                IconButton(onPressed: state.previous, icon: const Icon(Icons.skip_previous_rounded)),
                FilledButton.tonalIcon(onPressed: state.togglePlay, icon: Icon(state.playing ? Icons.pause_rounded : Icons.play_arrow_rounded), label: Text(state.playing ? 'Пауза' : 'Играть')),
                if (MediaQuery.sizeOf(context).width > 660) IconButton(onPressed: state.next, icon: const Icon(Icons.skip_next_rounded)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: ListView.separated(
              reverse: true,
              itemCount: state.roomMessages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, reverseIndex) {
                final item = state.roomMessages[state.roomMessages.length - 1 - reverseIndex];
                final mine = item.author == 'Алишер';
                return Align(
                  alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
                    decoration: BoxDecoration(color: mine ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: .065), borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(item.text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: mine ? Theme.of(context).scaffoldBackgroundColor : null)),
                        const SizedBox(height: 3),
                        Text(item.author, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: mine ? Theme.of(context).scaffoldBackgroundColor.withValues(alpha: .55) : null, fontSize: 9)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: message,
            maxLength: 300,
            onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              counterText: '',
              hintText: 'Написать в комнату…',
              prefixIcon: const Icon(Icons.chat_bubble_outline_rounded),
              suffixIcon: IconButton(onPressed: _send, icon: const Icon(Icons.arrow_upward_rounded)),
            ),
          ),
        ],
      ),
    );
  }

  void _send() {
    widget.state.sendRoomMessage(message.text);
    message.clear();
  }
}

class _MembersPanel extends StatelessWidget {
  const _MembersPanel({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) => SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Eyebrow('Участники', dot: false),
            const SizedBox(height: 12),
            ...state.roomMembers.map(
              (member) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(radius: 16, backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: .08), child: Text(member.name.isEmpty ? "?" : member.name.substring(0, 1))),
                    const SizedBox(width: 9),
                    Expanded(child: Text(member.name, style: Theme.of(context).textTheme.titleMedium)),
                    if (member.isAdmin) const Icon(Icons.shield_rounded, size: 15, color: GlukColors.accent),
                  ],
                ),
              ),
            ),
            const Divider(height: 28),
            Row(
              children: <Widget>[
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(state.roomIsAdmin ? 'Управление музыкой' : 'Управление у администратора', style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(state.roomIsAdmin ? 'Разрешить всем менять треки' : 'Ты участник этой комнаты', style: const TextStyle(fontSize: 10))])),
                Switch(value: state.everyoneCanControlRoom, onChanged: (!state.roomConnected || state.roomIsAdmin) ? state.setEveryoneCanControl : null),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(onPressed: () => _showInvite(context, state.roomCode), icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('Пригласить')),
          ],
        ),
      );

  void _showInvite(BuildContext context, String code) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Приглашение'),
        content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[const Text('Отправь другу код комнаты:'), const SizedBox(height: 16), SelectableText(code, style: Theme.of(context).textTheme.headlineLarge)]),
        actions: <Widget>[TextButton(onPressed: () => Navigator.pop(context), child: const Text('Готово'))],
      ),
    );
  }
}

class LofiScreen extends StatefulWidget {
  const LofiScreen({super.key});

  @override
  State<LofiScreen> createState() => _LofiScreenState();
}

class _LofiScreenState extends State<LofiScreen> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  String scene = 'Лесное озеро';
  double rain = 0.18;
  bool zen = false;

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 130),
      children: <Widget>[
        if (!zen)
          PageHeading(
            eyebrow: 'Тише мир — громче музыка',
            title: 'Место для выдоха',
            subtitle: 'Живой пейзаж, тёплый звук и никакой спешки.',
            trailing: GlukPill(label: 'Скрыть всё', icon: Icons.fullscreen_rounded, onTap: () => setState(() => zen = true)),
          ),
        if (!zen) const SizedBox(height: 24),
        AspectRatio(
          aspectRatio: MediaQuery.sizeOf(context).width < 720 ? .86 : 1.75,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: <Widget>[
                Positioned.fill(child: AnimatedBuilder(animation: c, builder: (_, __) => CustomPaint(painter: _LivingScenePainter(c.value, scene: scene, rain: rain)))),
                Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[Colors.black.withValues(alpha: .08), Colors.transparent, Colors.black.withValues(alpha: .38)])))),
                Positioned(left: 20, top: 18, child: Text('GLUK LO-FI · ЖИВОЙ ПЕЙЗАЖ', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white70))),
                Positioned(right: 16, top: 14, child: IconButton.filledTonal(onPressed: () => setState(() => zen = !zen), icon: Icon(zen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded, color: Colors.white))),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      StreamBuilder<DateTime>(
                        stream: Stream<DateTime>.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
                        initialData: DateTime.now(),
                        builder: (context, snap) {
                          final now = snap.data!;
                          return Text('${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}', style: TextStyle(color: Colors.white.withValues(alpha: .88), fontSize: MediaQuery.sizeOf(context).width < 700 ? 62 : 84, fontWeight: FontWeight.w300, letterSpacing: -4));
                        },
                      ),
                      const Text('ты здесь. и этого достаточно.', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
                    ],
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 18,
                  child: Row(
                    children: <Widget>[
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(scene, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), const Text('Вода, свет и немного тишины.', style: TextStyle(color: Colors.white54, fontSize: 10))])),
                      FilledButton.tonalIcon(onPressed: () => state.playTrack(state.tracks.firstWhere((track) => track.id == 'quiet-room')), icon: const Icon(Icons.play_arrow_rounded), label: const Text('Lo-fi трек')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!zen) ...<Widget>[
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              GlukPill(label: 'Лес', icon: Icons.eco_rounded, compact: true, selected: scene == 'Лесное озеро', onTap: () => setState(() => scene = 'Лесное озеро')),
              GlukPill(label: 'Океан', icon: Icons.waves_rounded, compact: true, selected: scene == 'У тихого океана', onTap: () => setState(() => scene = 'У тихого океана')),
              GlukPill(label: 'Снег', icon: Icons.ac_unit_rounded, compact: true, selected: scene == 'Снег в лесу', onTap: () => setState(() => scene = 'Снег в лесу')),
              GlukPill(label: 'Ночь', icon: Icons.dark_mode_rounded, compact: true, selected: scene == 'Ночь в лесу', onTap: () => setState(() => scene = 'Ночь в лесу')),
            ],
          ),
          const SizedBox(height: 18),
          SurfaceCard(
            child: Row(
              children: <Widget>[
                const Icon(Icons.water_drop_outlined),
                const SizedBox(width: 10),
                const Expanded(child: Text('Дождь', style: TextStyle(fontWeight: FontWeight.w800))),
                SizedBox(width: 180, child: Slider(value: rain, onChanged: (value) => setState(() => rain = value))),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _LivingScenePainter extends CustomPainter {
  const _LivingScenePainter(this.t, {required this.scene, required this.rain});
  final double t;
  final String scene;
  final double rain;

  @override
  void paint(Canvas canvas, Size size) {
    final night = scene.contains('Ночь');
    final snow = scene.contains('Снег');
    final ocean = scene.contains('океана');
    final top = night ? const Color(0xFF1F2A31) : snow ? const Color(0xFF89979A) : ocean ? const Color(0xFF617E82) : const Color(0xFF52685A);
    final bottom = night ? const Color(0xFF3E4B47) : snow ? const Color(0xFFC7CBC2) : ocean ? const Color(0xFF9FAF9B) : const Color(0xFF8B9A79);
    final bg = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: <Color>[top, bottom]).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final moon = Paint()..color = const Color(0xFFE1DDBB).withValues(alpha: night ? .72 : .34);
    canvas.drawCircle(Offset(size.width * .73, size.height * .23), size.shortestSide * .055, moon);

    final far = Paint()..color = (night ? const Color(0xFF293A36) : const Color(0xFF405548)).withValues(alpha: .82);
    final hills = Path()..moveTo(0, size.height * .6);
    for (var i = 0; i <= 8; i++) {
      final x = size.width * i / 8;
      final y = size.height * (.54 + .07 * math.sin(i * 1.7 + t * math.pi * 2 * .12));
      hills.lineTo(x, y);
    }
    hills..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(hills, far);

    if (ocean) {
      final water = Paint()..color = const Color(0xFF365F67).withValues(alpha: .85);
      canvas.drawRect(Rect.fromLTWH(0, size.height * .64, size.width, size.height * .36), water);
      final glint = Paint()..strokeWidth = 1;
      for (var i = 0; i < 28; i++) {
        glint.color = Colors.white.withValues(alpha: .05 + .04 * math.sin(t * math.pi * 2 + i).abs());
        final y = size.height * (.68 + i * .011);
        final x = size.width * (.12 + (i * .13) % .76);
        canvas.drawLine(Offset(x, y), Offset(x + 25 + (i % 5) * 7, y), glint);
      }
    } else {
      final water = Paint()..color = (night ? const Color(0xFF1D3434) : const Color(0xFF2F4D45)).withValues(alpha: .9);
      canvas.drawRect(Rect.fromLTWH(0, size.height * .72, size.width, size.height * .28), water);
    }

    final random = math.Random(7);
    final particle = Paint();
    for (var i = 0; i < 48; i++) {
      final x = (random.nextDouble() * size.width + t * size.width * (snow ? .12 : .02) * (i % 3 + 1)) % size.width;
      final y = (random.nextDouble() * size.height + t * size.height * (snow ? .35 : .06) * (i % 4 + 1)) % size.height;
      particle.color = snow ? Colors.white.withValues(alpha: .5) : const Color(0xFFE1D894).withValues(alpha: .18 + .18 * math.sin(t * math.pi * 2 + i).abs());
      canvas.drawCircle(Offset(x, y), snow ? 1.6 : 1.2, particle);
    }

    if (rain > .02) {
      final rainPaint = Paint()..color = Colors.white.withValues(alpha: .08 + rain * .22)..strokeWidth = 1;
      for (var i = 0; i < (rain * 90).round(); i++) {
        final x = ((i * 83.7 + t * size.width * 1.8) % size.width);
        final y = ((i * 47.3 + t * size.height * 3.2) % size.height);
        canvas.drawLine(Offset(x, y), Offset(x - 3, y + 11), rainPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LivingScenePainter oldDelegate) => oldDelegate.t != t || oldDelegate.scene != scene || oldDelegate.rain != rain;
}
