import 'package:flutter/material.dart';

import 'app.dart';
import 'state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  runApp(AppScope(state: state, child: const GlukWaveApp()));
  await state.initialize();
}
