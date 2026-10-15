# Bundled fonts

The `.ttf` files in this folder are bundled for offline use and resolve via
the `fonts:` block in `pubspec.yaml` with plain `TextStyle(fontFamily:)`
(`lib/src/theme/app_typography.dart`) — no `google_fonts` dependency, no
runtime fetching. Do NOT also list them under `assets:`; that would embed
each font twice.

Actual files shipped (6):

- `Megrim-Regular.ttf` — Megrim, OFL-licensed, source `ofl/megrim/Megrim.ttf`
  (renamed with `-Regular`)
- `SpaceMono-Regular.ttf` — Space Mono Regular, OFL, `ofl/spacemono/SpaceMono-Regular.ttf`
- `SpaceMono-Bold.ttf` — Space Mono Bold, OFL, `ofl/spacemono/SpaceMono-Bold.ttf`
- `SpaceGrotesk-Regular.ttf` — Space Grotesk Regular, OFL
- `SpaceGrotesk-Medium.ttf` — Space Grotesk Medium, OFL
- `SpaceGrotesk-Bold.ttf` — Space Grotesk Bold, OFL

## OFL attribution

All fonts above are licensed under the SIL Open Font License 1.1
(https://openfontlicense.org / https://scripts.sil.org/OFL).

- Megrim © Sorkin Type Co. (google/fonts `ofl/megrim`, OFL 1.1). See `OFL.txt` in the upstream repo.
- Space Mono © 2012, Colophon Foundry / Google Fonts (google/fonts
  `ofl/spacemono`, OFL 1.1).
- Space Grotesk © 2020, Florian Karsten / Google Fonts (google/fonts
  `ofl/spacegrotesk`, OFL 1.1).

License copies live upstream at https://github.com/google/fonts/tree/main/ofl
(`megrim/OFL.txt`, `spacemono/OFL.txt`, `spacegrotesk/OFL.txt`). If you
redistribute this app or these `.ttf` files, keep the font copyright notices
and make the OFL text available alongside them.
