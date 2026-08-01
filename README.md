# TVBox HarmonyOS Next

HarmonyOS Next / ArkTS port of `/Users/jwli/workspace/github/tvbox`.

The Android project remains the source of truth. `docs/android-parity.md` tracks what is
implemented, what is substituted, and what is still missing.

## Build

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk ./scripts/verify-build.sh
```

Produces `entry/build/default/outputs/default/entry-default-unsigned.hap`.

Requires DevEco Studio with the HarmonyOS 6.0.2 (API 22) SDK. Or open the directory in
DevEco Studio and let it sync `oh-package.json5` / `hvigorfile.ts`.

## What works

- **Playback on AVPlayer with real HTTP header injection** — Referer/User-Agent protected
  sources, WebDAV Basic auth, and Android `livePlayHeaders` rules all work. Play and Live share
  one `PlaybackSession`.
- **Player controls** — play/pause, seek, prev/next episode, episode picker, speed, display
  scale, audio/subtitle track selection, skip intro/outro with auto-advance, parse switching,
  D-pad navigation, danmu overlay (Bilibili XML), external subtitle overlay (SRT/VTT).
  Per-VOD settings persist in the Android `playerCfg` JSON shape.
- **Config loading** — TVBox JSON configs including image/Base64 embedded, `;pk;` AES ECB,
  `2423` AES CBC, `./` relative rewrite, and `MD5(apiUrl)` disk cache fallback.
- **Sources** — type=0 XML, type=1 JSON and type=4 API for home, category, detail, search and
  quick search.
- **Browsing** — category page with filter groups, paging and infinite scroll; Detail with
  change-source, reverse order and flag groups; Search with per-source selection.
- **Live TV** — channel groups, EPG with time-shift, group passwords, remote-control switching,
  numeric channel jump, M3U/TXT subscriptions.
- **Drive** — Local, Alist and WebDAV browsing and playback.
- **Settings** — the full Android setting matrix, using Android-compatible Hawk keys.
- **Local data** — playback history, favorites, search history, storage drives.

## What does not work yet

Native (C++/NAPI) or privileged-API subsystems. See `docs/android-parity.md` for detail.

- Spider type=3 sources (QuickJS JS, Python, Java jar loaders)
- WebView sniffing (parse type=0) and parse types 2/3/SuperParse
- Local HTTP server: inbound push, remote-control UI, `clan://localhost` proxy
- FFmpeg fallback player, P2P/Thunder protocols
- Danmu rendering is implemented (Bilibili XML); remote subtitle search (assrt.net) and ASS/STL formats are not
- Installed-app enumeration and uninstall (privileged HarmonyOS APIs)
- Theme and locale switching are persisted and applied across all pages

## Main Android references

- Android project: `/Users/jwli/workspace/github/tvbox`
- App entry/defaults: `app/src/main/java/com/github/tvbox/osc/base/App.java`
- Config parser: `app/src/main/java/com/github/tvbox/osc/api/ApiConfig.java`
- Screens: `app/src/main/java/com/github/tvbox/osc/ui/activity/*Activity.java`
- Settings UI: `app/src/main/java/com/github/tvbox/osc/ui/fragment/ModelSettingFragment.java`
- Models: `app/src/main/java/com/github/tvbox/osc/bean/*`
- Settings keys: `app/src/main/java/com/github/tvbox/osc/util/HawkConfig.java`

## Layout

```text
entry/src/main/ets/
  components/player/   ArkUI player surface
  constants/           Hawk keys and Android defaults
  domain/playback/     Player session, config, ordering
  models/              Android-compatible data models
  pages/               One page per Android activity
  services/            Config, source, playback, live, drive, storage
  utils/               JSON, AES, hashing, base64, errors
```

## Migration rule

Do not treat a page as complete until it matches the Android behavior in
`docs/android-parity.md` and has a replayable verification note in `docs/verification.md`.
