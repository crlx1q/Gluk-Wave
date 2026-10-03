import 'dart:async';

import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class SourcesScreen extends StatefulWidget {
  const SourcesScreen({super.key});

  @override
  State<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends State<SourcesScreen> {
  TrackSource? importing;
  double progress = 0;
  String status = '';
  Timer? timer;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 130),
      children: <Widget>[
        const PageHeading(
          eyebrow: 'Собрать своё в одном месте',
          title: 'Музыка без границ',
          subtitle: 'Сценарий переноса уже живой: выбираешь сервис, библиотеку и видишь прогресс. OAuth/API можно подключить следующим слоем.',
        ),
        const SizedBox(height: 20),
        SurfaceCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.info_outline_rounded, color: GlukColors.accent),
              const SizedBox(width: 10),
              Expanded(child: Text('Подключения YouTube Music / Spotify / SoundCloud / Яндекс здесь намеренно работают как визуальный импорт без входа в реальные аккаунты.', style: Theme.of(context).textTheme.bodySmall)),
            ],
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, box) {
            final count = box.maxWidth > 1050 ? 4 : box.maxWidth > 650 ? 2 : 1;
            final sources = <TrackSource>[TrackSource.youtubeMusic, TrackSource.spotify, TrackSource.soundcloud, TrackSource.yandex];
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: count, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: count == 1 ? 2.5 : 1.65),
              itemCount: sources.length,
              itemBuilder: (context, index) => _SourceCard(
                source: sources[index],
                busy: importing == sources[index],
                progress: importing == sources[index] ? progress : null,
                onImport: () => _simulateImport(sources[index]),
              ),
            );
          },
        ),
        if (importing != null) ...<Widget>[
          const SizedBox(height: 16),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(children: <Widget>[Icon(importing!.icon), const SizedBox(width: 9), Expanded(child: Text(status, style: Theme.of(context).textTheme.titleMedium)), Text('${(progress * 100).round()}%', style: Theme.of(context).textTheme.bodySmall)]),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: progress, borderRadius: BorderRadius.circular(8)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 26),
        SectionTitle(eyebrow: 'На устройстве', title: 'Локальная музыка', trailing: GlukPill(label: 'Выбрать файлы', icon: Icons.add_rounded, onTap: state.importLocalMusic)),
        const SizedBox(height: 12),
        Text('Импортированные аудиофайлы копируются в папку приложения и остаются доступны после перезапуска.', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  void _simulateImport(TrackSource source) {
    timer?.cancel();
    setState(() {
      importing = source;
      progress = 0;
      status = 'Подключаем ${source.label}…';
    });
    timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!mounted) return;
      setState(() {
        progress = (progress + .08).clamp(0.0, 1.0).toDouble();
        status = progress < .25
            ? 'Подключаем ${source.label}…'
            : progress < .55
                ? 'Читаем плейлисты…'
                : progress < .82
                    ? 'Сверяем треки и дубликаты…'
                    : progress < 1
                        ? 'Собираем медиатеку…'
                        : 'Готово: предпросмотр импорта завершён';
      });
      if (progress >= 1) {
        timer.cancel();
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => importing = null);
        });
      }
    });
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source, required this.busy, required this.progress, required this.onImport});
  final TrackSource source;
  final bool busy;
  final double? progress;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final tint = switch (source) {
      TrackSource.soundcloud => const Color(0xFFDF8350),
      TrackSource.spotify => const Color(0xFF44745D),
      TrackSource.yandex => const Color(0xFFC4932B),
      TrackSource.youtubeMusic => const Color(0xFFC96051),
      _ => GlukColors.accent,
    };
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(width: 42, height: 42, decoration: BoxDecoration(color: tint.withValues(alpha: .13), shape: BoxShape.circle), child: Icon(source.icon, color: tint)),
          const Spacer(),
          Text(source.label, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('Плейлисты · любимое · история', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          if (busy)
            LinearProgressIndicator(value: progress, borderRadius: BorderRadius.circular(8))
          else
            FilledButton.tonalIcon(onPressed: onImport, icon: const Icon(Icons.sync_rounded), label: const Text('Перенести сюда')),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  TextEditingController? roomUrl;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    roomUrl ??= TextEditingController(text: AppScope.of(context).roomServerUrl);
  }

  @override
  void dispose() {
    roomUrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 130),
      children: <Widget>[
        const PageHeading(eyebrow: 'Совсем твой Gluk', title: 'Настройки', subtitle: 'Музыка, внешний вид, кеш, Discord и комнаты.'),
        const SizedBox(height: 22),
        _SettingsGroup(
          title: 'Музыка и офлайн',
          children: <Widget>[
            _SwitchRow(title: 'Кешировать музыку локально', subtitle: 'Включено по умолчанию. Прослушанный демотрек автоматически остаётся офлайн.', value: state.cacheMusic, onChanged: state.setCacheMusic),
            const Divider(height: 1),
            _ActionRow(
              icon: Icons.storage_rounded,
              title: 'Кеш занимает ${state.formatBytes(state.cacheBytes)}',
              subtitle: 'Ручные загрузки отмечены значком ✓ у трека.',
              action: TextButton(onPressed: state.cacheBytes == 0 ? null : state.clearCache, child: const Text('Очистить')),
            ),
            const Divider(height: 1),
            _SwitchRow(title: 'Текст под обложкой', subtitle: 'Показывать текущие строки прямо в плеере.', value: state.lyricsUnderCover, onChanged: state.setLyricsUnderCover),
          ],
        ),
        const SizedBox(height: 16),
        _SettingsGroup(
          title: 'Discord Rich Presence',
          children: <Widget>[
            _SwitchRow(title: 'Показывать, что играет', subtitle: state.discord.configured ? 'Desktop RPC настроен через DISCORD_APP_ID.' : 'Нужен DISCORD_APP_ID при запуске desktop-сборки.', value: state.discordEnabled, onChanged: state.setDiscordEnabled),
            const Divider(height: 1),
            _DiscordPreview(state: state),
          ],
        ),
        const SizedBox(height: 16),
        _SettingsGroup(
          title: 'Комнаты',
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Text('WebSocket сервер', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('Для реальной синхронизации между устройствами запусти server/bin/server.dart и укажи его адрес.', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 12),
                TextField(controller: roomUrl!, decoration: const InputDecoration(prefixIcon: Icon(Icons.dns_rounded), hintText: 'ws://192.168.1.10:8787/ws'), onSubmitted: state.setRoomServerUrl),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: FilledButton.tonal(onPressed: () => state.setRoomServerUrl(roomUrl!.text), child: const Text('Сохранить адрес'))),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SettingsGroup(
          title: 'Интерфейс',
          children: <Widget>[
            _SwitchRow(title: 'Тёмная тема', subtitle: 'Сохраняет мягкую тёплую палитру макета.', value: state.darkMode, onChanged: state.setDarkMode),
            const Divider(height: 1),
            _SwitchRow(title: 'Живой логотип', subtitle: 'Внутри приложения волна слегка дышит. Статичная версия остаётся в системных местах.', value: state.animatedLogo, onChanged: state.setAnimatedLogo),
            const Divider(height: 1),
            _SwitchRow(title: 'Компактный режим', subtitle: 'Меньше воздуха, больше треков на экране.', value: state.compactMode, onChanged: state.setCompactMode),
          ],
        ),
        const SizedBox(height: 22),
        SurfaceCard(
          child: Row(
            children: <Widget>[
              Image.asset('assets/branding/logo_reference.png', width: 110, height: 62, fit: BoxFit.cover),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text('Gluk Wave / 03', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 4), Text('Flutter mobile + desktop prototype', style: Theme.of(context).textTheme.bodySmall)])),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(padding: const EdgeInsets.only(left: 4, bottom: 8), child: Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelSmall)),
          SurfaceCard(padding: EdgeInsets.zero, child: Column(children: children)),
        ],
      );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.title, required this.subtitle, required this.value, required this.onChanged});
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(title, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 3), Text(subtitle, style: Theme.of(context).textTheme.bodySmall)])),
            const SizedBox(width: 12),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.icon, required this.title, required this.subtitle, required this.action});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget action;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: <Widget>[Icon(icon), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[Text(title, style: Theme.of(context).textTheme.titleMedium), const SizedBox(height: 3), Text(subtitle, style: Theme.of(context).textTheme.bodySmall)])), action]),
      );
}

class _DiscordPreview extends StatelessWidget {
  const _DiscordPreview({required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(0xFF5865F2).withValues(alpha: .09), borderRadius: BorderRadius.circular(17)),
          child: Row(
            children: <Widget>[
              Container(width: 45, height: 45, decoration: BoxDecoration(color: const Color(0xFF5865F2), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.sports_esports_rounded, color: Colors.white)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[const Text('СЛУШАЕТ GLUK WAVE', style: TextStyle(color: Color(0xFF5865F2), fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 1)), const SizedBox(height: 2), Text(state.currentTrack.title, style: Theme.of(context).textTheme.titleMedium), Text(state.currentTrack.artist, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 8), Wrap(spacing: 6, runSpacing: 6, children: <Widget>[OutlinedButton(onPressed: () {}, child: const Text('Послушать')), OutlinedButton(onPressed: () => state.navigate(AppPage.rooms), child: const Text('Слушать вместе'))])])),
            ],
          ),
        ),
      );
}
