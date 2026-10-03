import 'package:flutter_test/flutter_test.dart';
import 'package:gluk_wave/services/layout_fixer.dart';

void main() {
  test('understands Russian typed with English keyboard layout', () {
    expect(LayoutFixer.suggestion('ghbdtn'), 'привет');
  });
}
