# Android feature parity map

Source of truth: `/Users/jwli/workspace/github/tvbox`.

## Global app behavior

Android references:

- `base/App.java`
- `util/HawkConfig.java`
- `api/ApiConfig.java`
- `server/*`
- `data/*`, `cache/*`

Parity requirements:

- Keep all persisted settings keys compatible with Android Hawk keys where possible.
- Preserve default values from `App.initParams()`.
- Preserve TV landscape navigation and remote-control focus behavior.
- Preserve source config loading, cache fallback, parse source selection, live URL/EPG extraction, and ad/sniffing rule parsing.
- Preserve local playback history, favorites, search history, and storage drive records.
- Preserve remote control server capabilities where HarmonyOS APIs permit it.

## Activity to Harmony page map

| Android activity | Harmony page | Required behavior |
| --- | --- | --- |
| `HomeActivity` | `pages/Home` | Load source config, top status/network/time, source/category tabs, recommendations, history shortcut, live/search/push/drive/favorite/settings entry buttons. |
| `DetailActivity` | `pages/Detail` | VOD detail, source search, play flag groups, series selection, reverse order, favorite toggle, push URL, description expand/collapse. |
| `PlayActivity` | `pages/Play` | VOD playback, parse switching, next/previous, progress persistence, subtitles, audio tracks, danmu, aspect ratio, background/PiP behavior where supported. |
| `LivePlayActivity` | `pages/Live` | Live channel groups, channel switching, EPG, password/hidden channels, player type, network speed/time display. |
| `SearchActivity` | `pages/Search` | Keyboard input, remote input, search history, source selection, all/none toggle, quick search entry, result navigation. |
| `FastSearchActivity` | `pages/FastSearch` | Multi-source parallel search, result grouping, source filters, incremental updates. |
| `HistoryActivity` | `pages/History` | Playback history list, delete mode, resume playback. |
| `CollectActivity` | `pages/Favorites` | Favorite list, delete mode, detail navigation. |
| `SettingActivity` | `pages/Settings` | Config URL/history, home source, player, codec, scale, DNS, language, theme, backup/restore, reset. |
| `PushActivity` | `pages/Push` | Manual URL push and play. |
| `DriveActivity` | `pages/Drive` | Local, Alist, WebDAV browsing, add/edit/delete storage drive, file playback. |
| `AppsActivity` | `pages/Apps` | Installed app list and launch/uninstall equivalent where HarmonyOS permits it. |
| `GridFragment` (in `HomeActivity`) | `pages/Category` | Category tabs, filter groups, paging, infinite scroll. |

## High-risk Android-only subsystems

These need explicit HarmonyOS design decisions before parity can be claimed:

1. IJK/Exo/Ali/MX/Reex/Kodi player matrix.
2. QuickJS `JsLoader`, Java jar spider loader, and Python `pyramid` loader.
3. XWalk/System WebView sniffing and parse rule execution.
4. Native `p2p`/Thunder libraries.
5. AndServer/NanoHTTPD local proxy and remote control server.
6. Android package manager features in `AppsActivity`.
7. External storage access and backup/restore package format.

## Implementation checkpoints

- P0: Project compiles and launches Home.
- P1: Settings/defaults + config URL loading + config cache.
- P2: JSON/XML source list + category/list/detail/search.
- P3: VOD playback with progress/history/favorites.
- P4: Live TV + EPG.
- P5: Spider/JS/Python/ext source compatibility.
- P6: Drive/WebDAV/Alist + remote push/server.
- P7: Android feature matrix edge cases and TV focus polish.

## Build status

`scripts/verify-build.sh` produces `entry/build/default/outputs/default/entry-default-unsigned.hap`
against HarmonyOS SDK 6.0.2(22).

Note: before this milestone the project had never compiled. `hvigor/hvigor-config.json5` was
schema-invalid, `module.json5` was missing `reason`/`usedScene` for user-grant permissions, and
26 ArkTS strict-mode errors were present. All are fixed.

## Current implemented baseline

### Playback (Play + Live)

- Both screens run on `media.AVPlayer` through `domain/playback/PlaybackSession`, rendering into
  an `XComponent` surface (`components/player/PlayerSurface.ets`).
- **HTTP request headers are actually sent** via `media.createMediaSourceWithUrl(url, headers)`.
  This was the single largest functional gap: the previous ArkUI `Video` component could not send
  headers, so Referer/User-Agent protected sources, WebDAV Basic auth, and Android
  `livePlayHeaders` rules were all silently broken.
- Headers merge in Android order: `playerCfg` snapshot first, then parse-returned headers.
- Play page controls: play/pause, seek, previous/next episode, episode picker, speed
  (0.5x-3x), display scale, audio-track and subtitle-track selection, skip-intro/skip-outro
  with auto-advance, parse switching, and D-pad key handling (left/right seek, up/down episode,
  OK play/pause, Back closes panel).
- Per-VOD player settings persist in the Android-compatible `playerCfg` JSON shape
  (`pl`/`pr`/`ijk`/`sc`/`sp`/`st`/`et` plus a `headers` extension) via `domain/playback/PlayerConfig`.
- Live page injects matched `livePlayHeaders`, supports the optional on-screen clock, and honors
  `LIVE_SKIP_PASSWORD`.

### Settings

Full Android `ModelSettingFragment` parity for the options an ordinary HarmonyOS app can honor:
config URL + load + cache clear + URL history, home source picker, live/EPG URLs,
`HOME_SHOW_SOURCE`, `HOME_DEFAULT_SHOW`, `HOME_REC`, `HOME_NUM`, `PLAY_SCALE`, `PLAY_TYPE`,
`PLAY_RENDER`, `IJK_CODEC`, `BACKGROUND_PLAY_TYPE`, `PLAY_TIME_STEP`, `SHOW_PREVIEW`,
`VIDEO_PURIFY`, all six live settings, `SEARCH_VIEW`, `FAST_SEARCH_MODE`, `HOME_LOCALE`,
`THEME_SELECT`, `DOH_URL`, `PARSE_WEBVIEW`, `DEBUG_OPEN`, plus history/search data clearing.

### Browsing and discovery

- `pages/Category` implements Android `GridFragment`: category tabs, per-category filter groups
  parsed from the config `filters` block, filter selection, paging and infinite scroll.
  Filters encode per Android rules (query params + `f` for type 0/1, base64 `ext` for type 4).
- Home categories are clickable and route into the category page; `HOME_REC=2` shows watch
  history instead of site recommendations; `HOME_DEFAULT_SHOW` launches straight into Live.
- Detail page: play-flag group switching, reverse episode order, last-watched episode
  highlighting, description expand/collapse, favorite toggle, push handoff, and Android-style
  **change source** via multi-site quick search.
- Search page: per-source selection persisted in the Android `SOURCES_FOR_SEARCH` shape
  (`{apiUrl: {siteKey: "1"}}`), all/none toggles, `SEARCH_VIEW` list/thumbnail modes,
  `FAST_SEARCH_MODE`, and search-history reuse.
- History and Favorites: delete mode, clear-all, progress percentage, `HOME_NUM` row limit,
  and poster grid for favorites.
- `THEME_SELECT` now affects all pages: regular pages use the selected HarmonyOS color palette,
  while Play and Live keep the video surface black and apply the palette to control overlays,
  sliders, lists, and status text. `HOME_LOCALE` currently switches Home, Settings, Search,
  FastSearch, History, Favorites, and Push labels/status text.

### Data and config

- TVBox JSON config parsing for `sites`, `parses`, `lives`, `flags`, `rules`, `ijk`, `ads`,
  `spider`, `wallpaper`, `jarCache`, `livePlayHeaders`.
- Android image/Base64 embedded config, `;pk;` AES ECB, `2423` AES CBC, `./` relative rewrite,
  and `MD5(apiUrl)` cache fallback under `filesDir`.
- Local JSON persistence for playback history, favorites, search keywords and storage drives.
- Source flow for type=0 XML, type=1 JSON and type=4 API: home, category, detail, search,
  quick search.
- Drive page: Local/Alist/WebDAV browsing, add/edit/delete, sorting, filename filter,
  and WebDAV playback with working Basic auth headers.

## Known gaps

These require native (C++/NAPI) work or privileged platform APIs and remain unimplemented:

1. **Spider type=3 sources** — QuickJS JS spiders, Python `pyramid` spiders, and Java jar
   loaders. Type=3 is common in real-world TVBox configs, so many configs will only expose
   their type 0/1/4 sites.
2. **WebView sniffing (parse type=0)** and parse types 2/3/SuperParse. Currently type=0 parses
   fall back to URL concatenation.
3. **Local HTTP server** — inbound push receive endpoints, remote-control web UI, `clan://localhost`
   proxy, and M3U8 proxy rewriting.
4. **FFmpeg fallback player** for formats/protocols AVPlayer rejects (RTSP, RTMP, some TS/MKV).
5. **P2P / Thunder protocols.**
6. **Danmu rendering** and external subtitle search/loading.
7. **Installed-app enumeration and uninstall** in the Apps page — the HarmonyOS bundle query and
   uninstall APIs are privileged/enterprise-only, so this stays a manually curated launcher list.
8. **Player kernel matrix** — IJK/Exo/Ali/MX/Reex/Kodi cannot be shipped; everything maps onto
   AVPlayer. The setting is retained for config compatibility only.
9. **Localization coverage** is partial: Home, Settings, Search, FastSearch, History, Favorites,
   and Push apply `HOME_LOCALE`, while Drive, Apps, Category, Detail, Play, and Live labels are
   still static Chinese. `THEME_SELECT` is now applied across all pages, with Play/Live
   intentionally preserving black video surfaces for playback contrast.
