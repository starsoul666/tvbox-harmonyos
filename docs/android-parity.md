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

## Current implemented baseline

- Harmony project scaffold, entry ability, resources, and Android activity page mapping.
- Android Hawk-compatible setting keys and `App.initParams()` defaults.
- TVBox JSON config parsing for `sites`, `parses`, `lives`, `flags`, `rules`, `ijk`, `ads`, `spider`, `wallpaper`, `jarCache`, and `livePlayHeaders`.
- Android-compatible home source selection using `HawkConfig.HOME_API`.
- Home auto-loads saved config URL, renders visible source list, and now loads basic home categories/recommendations for XML/JSON/type=4 sources.
- Settings page saves `HawkConfig.API_URL`, `LIVE_URL`, and `EPG_URL`, and triggers config loading.
- Android-compatible config cache fallback using `MD5(apiUrl)` under app `filesDir`.
- Android image/Base64 embedded JSON config extraction, `;pk;` AES ECB config decoding, `2423` AES CBC config decoding, and `./` relative path rewrite.
- `RoomDataManger`-style local JSON persistence for playback history, favorites, and search keywords.
- History/Favorites/Search pages now render persisted local records and support basic delete/clear interactions.
- Initial `SourceViewModel` parity for type=0 XML, type=1 JSON, and type=4 API sources: home content, category list, detail, single-source search, quick search, and all-visible-source search request/parse flow.
- Search page is wired to real XML/JSON/type=4 source search results, preserves search history, groups hits by source, and navigates result rows toward `DetailActivity` parity.
- FastSearch page is no longer a placeholder: it uses `quickSearch=1` sources, groups incremental-style multi-source results, and opens detail pages.
- Push page supports manual direct URL playback through the Play page and Android-compatible outbound remote push to another TVBox server, using `POST /action` with `do=push&url=...` plus a `/api/updateUrl?url=...` compatibility fallback. Local HTTP server receive endpoints and QR entry remain pending.
- Live page now supports Android/FongMi `lives` direct group/channel config, remote M3U/TXT subscription loading, group/channel/source switching, `LIVE_CHANNEL_GROUP`/`LIVE_CHANNEL` persistence, and direct ArkUI `Video` playback. EPG detail rendering, password prompts, player kernel mapping, live headers, time-shift, and remote-control numeric channel switching remain pending.
- Drive page now persists Android-compatible `StorageDrive` records, supports adding/editing/deleting Local/Alist/WebDAV drives, browses local filesystem paths available to the HarmonyOS app sandbox, browses Alist v3 `/api/fs/list` and v2 `/api/public/path`, browses WebDAV with `PROPFIND Depth: 1`, applies `HawkConfig.STORAGE_DRIVE_SORT`, detects common video file extensions, resolves local `file://`, Alist `/d/path`, and WebDAV direct file URLs, and opens drive videos through Play/history with `sourceKey="_drive"` and `playFlag="drive"`. WebDAV credentials are stored as Android-compatible `url`/`username`/`password`/`initPath` config and copied into `VodInfo.playerCfg` as a Basic Authorization header snapshot. HarmonyOS system file-picker/authorization UX, file search, and actual Video request-header injection remain pending.
- Apps page is no longer a placeholder: it persists user-added HarmonyOS launch items, can resolve a typed Bundle Name through `launcherBundleManager`/`bundleManager` when platform permissions allow it, saves Bundle/Ability/Module metadata, starts entries through `UIAbilityContext.startAbility`, supports edit mode, and maps Android delete mode to removal from the saved launcher list. Full Android-style automatic enumeration of all non-system launchable apps and ACTION_DELETE uninstall cannot be claimed for a normal HarmonyOS app because the relevant bundle query and uninstall APIs are privileged or enterprise-only.
- Detail page now consumes `sourceKey`/`vodId`, loads JSON source detail data, renders metadata/description/play groups, supports favorite toggle, and records a compact history entry when an episode is selected.
- Play page now consumes `sourceKey`/`vodId`/`playFlag`/`playIndex`/`playUrl`/`rawUrl`, resolves Android-style playback for type=0/1 sources through the initial `PlaybackService`, supports type=4 playback API requests, supports type=1 JSON parse APIs and parse switching, preserves `playerCfg` header snapshots, plays the resolved URL through ArkUI `Video`, supports pause/resume, seek, and previous/next episode within the current detail group, restores saved progress, and persists `progress`/`duration`/raw URL/final URL plus the current play group back into history. History rows resume playback with the saved raw URL and restore the saved play group when available.

## Next parity targets

1. Complete `clan://localhost` LAN proxy behavior; non-local `clan://host/path` URL rewriting is present.
2. Expand source parity from XML/JSON/type=4 HTTP APIs to spider type=3 behavior, including Jar/JS/Python loader equivalents.
3. Expand Play page from the current JSON-parse/type=4/direct ArkUI `Video` flow to full Android `PlayActivity` parity: WebView sniffing rules, parse type=2/3/4/SuperParse, subtitle/audio/danmu controls, display scale, and player-kernel mapping.
4. Expand live parity from the current direct M3U/TXT playback to Android EPG detail rendering, password/hidden-channel prompts, live headers, time-shift, player-kernel mapping, and numeric remote switching.
5. Complete Push/remote parity for local HTTP server receive endpoints, QR entry, and push-agent detail handling.
6. Complete Drive parity for HarmonyOS file-picker directory authorization, file search, and player-level WebDAV header injection.
7. Expand Apps parity if a privileged/system distribution path is available: automatic installed-app enumeration, launcher icon resources, and system uninstall handoff.
8. Start player capability mapping against HarmonyOS AVPlayer and external-player limitations.
