class LayoutFixer {
  static const String _en = "qwertyuiop[]asdfghjkl;'zxcvbnm,.`";
  static const String _ru = 'йцукенгшщзхъфывапролджэячсмитьбюё';

  static String toRussian(String input) => _translate(input, _en, _ru);
  static String toEnglish(String input) => _translate(input, _ru, _en);

  static String _translate(String input, String from, String to) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      final lower = char.toLowerCase();
      final index = from.indexOf(lower);
      if (index == -1) {
        buffer.write(char);
        continue;
      }
      final mapped = to[index];
      buffer.write(char == lower ? mapped : mapped.toUpperCase());
    }
    return buffer.toString();
  }

  static String? suggestion(String input) {
    final trimmed = input.trim();
    if (trimmed.length < 3) return null;
    final hasLatin = RegExp(r'[a-zA-Z]').hasMatch(trimmed);
    final hasCyrillic = RegExp(r'[а-яА-ЯёЁ]').hasMatch(trimmed);
    if (hasLatin && !hasCyrillic) {
      final fixed = toRussian(trimmed);
      if (fixed != trimmed) return fixed;
    }
    if (hasCyrillic && !hasLatin) {
      final fixed = toEnglish(trimmed);
      if (fixed != trimmed) return fixed;
    }
    return null;
  }
}
