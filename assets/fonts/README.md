# Bundled fonts (drop-in)

Download these 5 files into this folder (all OFL-licensed, google/fonts):

- `Megrim-Regular.ttf` — `ofl/megrim/Megrim.ttf` (renamed: google_fonts with
  `allowRuntimeFetching = false` looks up `Megrim-Regular.ttf` via AssetManifest,
  so the file MUST keep the `-Regular` suffix and be listed under `assets:` in
  `pubspec.yaml`, not just `fonts:`)
- `SpaceMono-Regular.ttf` — `ofl/spacemono/SpaceMono-Regular.ttf`
- `SpaceMono-Bold.ttf` — `ofl/spacemono/SpaceMono-Bold.ttf`
- `SpaceMono-Italic.ttf` — `ofl/spacemono/SpaceMono-Italic.ttf`
- `SpaceMono-BoldItalic.ttf` — `ofl/spacemono/SpaceMono-BoldItalic.ttf`

Then:

1. Uncomment the `fonts:` block in `pubspec.yaml`.
2. Remove `google_fonts` from dependencies and run `flutter pub get`.
3. `AppTypography.precache()` becomes an instant no-op — no other code changes.

Until then, type resolves via the Google Fonts runtime cache warmed at startup.
