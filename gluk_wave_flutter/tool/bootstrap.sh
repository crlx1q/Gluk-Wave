#!/usr/bin/env sh
set -eu
TMP=.gluk_platforms
rm -rf "$TMP"
flutter create --project-name gluk_wave --platforms=android,ios,windows,linux,macos "$TMP"
for d in android ios windows linux macos; do
  rm -rf "$d"
  mv "$TMP/$d" "$d"
done
rm -rf "$TMP"
flutter pub get
printf '\nGluk Wave is ready. Example:\n  flutter run -d windows\n  flutter run -d android\n\n'
