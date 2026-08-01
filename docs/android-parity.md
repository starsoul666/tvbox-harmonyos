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
  sliders, lists, and status text. `HOME_LOCALE` now switches all page labels: Home, Settings,
  Search, FastSearch, History, Favorites, Push, Drive, Apps, Category, Detail, Play, and Live.

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
- Danmu rendering: Bilibili XML parsing (`DanmuService`), scrolling ArkUI overlay
  (`DanmuOverlay`) synced to `PlaybackSession.currentPositionMs`, configurable
  speed/max-line/alpha/size/color via Android-compatible Hawk keys.
- External subtitle loading: SRT/VTT parsing (`SubtitleService`), timed text overlay
  (`SubtitleOverlay`) with configurable font size, delay, and text style. Subtitle
  URL auto-detected from source `subt`/`subs` play-result fields.

## Known gaps

### Native / privileged-API gaps (require C++/NAPI or platform capabilities)

1. **Spider type=3 sources** - QuickJS JS spiders, Python `pyramid` spiders, and Java jar
   loaders. Type=3 is common in real-world TVBox configs, so many configs will only expose
   their type 0/1/4 sites.
2. **WebView sniffing (parse type=0)** and parse types 2/3/SuperParse. Currently type=0 parses
   fall back to URL concatenation.
3. **Local HTTP server** - inbound push receive endpoints, remote-control web UI, `clan://localhost`
   proxy, and M3U8 proxy rewriting.
4. **FFmpeg fallback player** for formats/protocols AVPlayer rejects (RTSP, RTMP, some TS/MKV).
5. **P2P / Thunder protocols.**
6. **Remote subtitle search** (assrt.net scraping) and ASS/STL/TTML subtitle format support.
   Bilibili XML danmu and SRT/VTT external subtitle loading are implemented.
7. **Installed-app enumeration and uninstall** in the Apps page - the HarmonyOS bundle query and
   uninstall APIs are privileged/enterprise-only, so this stays a manually curated launcher list.
8. **Player kernel matrix** - IJK/Exo/Ali/MX/Reex/Kodi cannot be shipped; everything maps onto
   AVPlayer. The setting is retained for config compatibility only.

### ArkTS-implementable gaps (no native dependency)

These features exist in Android but are partially or fully missing in the HarmonyOS port.
Items marked with `[x]` are implemented; items marked with `[ ]` remain pending.

9. [x] **Data backup/restore** (`BackupDialog` / `AppDataManager`) - Android exports/imports all
   app data (Hawk preferences + local DB) to external storage as timestamped JSON files, with
   a list UI to restore or delete past backups. Implemented in `SettingsStore.createBackup()` /
   `restoreBackup()` / `listBackups()` / `deleteBackup()`, with a backup list panel in Settings.

10. [x] **Wallpaper** (`wallpaper` config field + `llWp`/`llWpRecovery`) - Android downloads the
    `wallpaper` URL from the config and applies it as the Home page background. Implemented:
    `Home.ets` reads `apiConfigService.state.wallpaper` and renders it as a semi-transparent
    background layer behind the page content.

11. [x] **Home button position** (`HOME_SEARCH_POSITION` / `HOME_MENU_POSITION`) - Android
    `HomeIconDialog` + `UserFragment` toggle whether the search and settings buttons appear
    at the top or bottom of the Home screen. Implemented: Settings page has toggle switches;
    `Home.ets` reads the settings and routes search/settings buttons to a top bar when
    position is "up", or keeps them in the main grid when "down".

12. [x] **Home recommendation style** (`HOME_REC_STYLE`) - Android toggles between Grid and Line
    layout for the home recommendation strip. Implemented: Settings has a toggle switch;
    `Home.ets` renders a 4-column Grid when true, a List when false.

13. [x] **Proxy server** (`PROXY_SERVER`) - Android `ApiDialog` has a proxy input field and routes
    all HTTP traffic through it via OkGo. Implemented: Settings has a proxy input field;
    `HttpClient.ts` reads `PROXY_SERVER` and sets `usingProxy: true` on all HTTP requests when
    a proxy is configured.

14. [x] **DNS-over-HTTPS** (`DOH_URL`) - Android applies the selected DoH resolver ( Tencent /
    Alibaba / 360 / Google / AdGuard / Quad9 ) to the OkGo HTTP client. Implemented:
    `HttpClient.ts` reads `DOH_URL` and sets `dnsOverHttps` on all HTTP requests when a DoH
    resolver is selected.

15. [ ] **Ad blocking** (`VIDEO_PURIFY` + `ads` config + `AdBlocker`) - Android parses the `ads`
    array from the config, maintains an ad-host blocklist, and blocks matching requests
    during WebView sniffing. The HarmonyOS port parses `ads` into `ApiConfigService` but
    never applies any blocking (partly depends on WebView sniffing, gap #2).

16. [ ] **Parse rules** (`VideoParseRuler` / `rules` config block) - Android parses the `rules`
    block (per-host `rule`/`filter`/`regex`/`script` arrays) and applies them during WebView
    sniffing to filter or block specific URLs. The HarmonyOS port parses `parseRules` into
    `ApiConfigService` but never uses them (depends on WebView sniffing, gap #2).

17. [ ] **Picture-in-Picture** (`PIC_IN_PIP` / `BACKGROUND_PLAY_TYPE=2`) - Android enters PiP
    mode when the user presses Home during playback. The HarmonyOS port has the key and the
    "画中画" option label but no PiP implementation.

18. [x] **Screen display toggle** (`SCREEN_DISPLAY`) - Android player has a "屏显" button that
    toggles the top info overlay visibility. Implemented: `Play.ets` has a screen display
    toggle button that shows/hides the title/episode/status row; the setting persists.

19. [x] **Search filter keyword** (`SEARCH_FILTER_KEY`) - Android Search page has a filter keyword
    input that pre-filters search results by title. Implemented: `Search.ets` has a filter
    input row; results are filtered by title substring; the filter persists across sessions.

20. [ ] **Player media settings dialog** (`MediaSettingDialog`) - Android has an in-player dialog
    to cycle `IJK_CODEC` / `IJK_CACHE_PLAY` / `EXO_RENDERER` / `EXO_RENDERER_MODE` /
    `VOD_PLAYER_PREFERRED`. Keys exist but no dialog. Most options are IJK/Exo-specific and
    not applicable to AVPlayer, but the UI surface is missing.

21. [x] **Full app reset** (`ResetDialog`) - Android has a full app reset that clears all Hawk
    data and resets to defaults. Implemented: `SettingsStore.clearAll()` clears all
    preferences and re-applies defaults; `Settings.ets` has a reset button that also clears
    VOD records, favorites, and search history.

22. [x] **Home icon position dialog** (`HomeIconDialog`) - Android has a dialog to toggle search
    and menu button positions. Implemented as toggle switches in the Settings page (gap #11).

### Localization and theme coverage

`HOME_LOCALE` is applied across Home, Settings, Search, FastSearch, History, Favorites, Push,
Drive, Apps, Category, Detail, Play, and Live. `THEME_SELECT` is applied across all pages,
with Play/Live intentionally preserving black video surfaces for playback contrast.
