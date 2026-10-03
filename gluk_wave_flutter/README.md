# Gluk Wave 3 — Flutter

Flutter music application with adaptive mobile and desktop UI.

## Included

- responsive navigation and player screens;
- bundled demo audio tracks;
- library, favorites, playlists and search;
- local audio import and cache;
- rooms with a lightweight WebSocket server in `server/`;
- Lo-fi room, themes and desktop Discord Rich Presence integration.

## Build locally

The archive omits generated platform folders. Create Android files with:

```sh
flutter create --platforms=android .
flutter pub get
flutter build apk --release
```

Minimum versions: Dart 3.10 and Flutter 3.38.

For rooms, run the Dart server from `server/` and configure the WebSocket endpoint in the app settings.

CI builds the Android APK with the stable Flutter 3.47.6 toolchain.
