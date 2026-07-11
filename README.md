# TVBox HarmonyOS Next

HarmonyOS Next / ArkTS version of `/Users/jwli/workspace/github/tvbox`.

This repository is intentionally structured around feature parity with the Android project. The Android project remains the source of truth until each item in `docs/android-parity.md` is implemented and verified on HarmonyOS.

## Current baseline

- Stage model HarmonyOS app scaffold.
- TV landscape-first routing and pages matching Android activities.
- Core Android-compatible data models for source, parse, VOD, live, history, and settings.
- Config parsing service for TVBox JSON config (`sites`, `parses`, `lives`, `flags`, `rules`, `ijk`, `ads`) with Android-compatible cache fallback.
- Settings defaults mirrored from Android `App.initParams()`.
- Home source selection persists with the Android-compatible `home_api` key.
- Settings can edit Android-compatible config, live subscription, and EPG URL keys.
- Android image/Base64 embedded JSON config extraction, `;pk;` AES ECB configs, and `2423` AES CBC configs are supported.
- Initial type=0 XML, type=1 JSON, and type=4 API source flow is present for home content, category list, detail, search, and quick search; Home/Search/FastSearch/Detail pages use this flow for real result and metadata rendering.
- Detail page supports favorite toggle and writes a compact playback history snapshot before opening Play.
- Push page supports manual direct URL playback through Play, Android-compatible outbound remote push to another TVBox (`POST /action do=push`, with `/api/updateUrl` fallback), and API-type `push_agent` detail entry for manually entered URLs; local receiving server remains pending.
- Live page supports config `lives` direct channel groups plus M3U/TXT live subscriptions, group/channel/source switching, last channel persistence, EPG program lookup, and ArkUI `Video` playback.
- Drive page supports Android-compatible storage drive records plus Local/Alist/WebDAV add/edit/delete, folder browsing, current-directory filename search, persisted sort mode, video file detection, direct playback through Play, and WebDAV Basic Authorization snapshots in `VodInfo.playerCfg`.
- Apps page now supports persisted HarmonyOS app launch items, Bundle/Ability lookup when platform permissions allow it, direct `startAbility` launching, editing, and a delete-mode list removal fallback for the Android uninstall flow.
- Play page now uses ArkUI `Video` for playback, pause/resume, seeking, previous/next episode within the current group, resume-position restore, playback-history progress persistence, current-group history restoration, `playerCfg` header snapshot preservation, and an initial Android-style JSON/type=4 parse switching flow.

## Main Android references

- Android project: `/Users/jwli/workspace/github/tvbox`
- App entry/defaults: `app/src/main/java/com/github/tvbox/osc/base/App.java`
- Config parser: `app/src/main/java/com/github/tvbox/osc/api/ApiConfig.java`
- Screens: `app/src/main/java/com/github/tvbox/osc/ui/activity/*Activity.java`
- Models: `app/src/main/java/com/github/tvbox/osc/bean/*`
- Settings keys: `app/src/main/java/com/github/tvbox/osc/util/HawkConfig.java`

## Build/import

Open this directory in DevEco Studio and let it sync `oh-package.json5` / `hvigorfile.ts`.

CLI build depends on local DevEco/Harmony SDK configuration.
Current local CLI verification is recorded in `docs/verification.md`.

## Migration rule

Do not treat a Harmony page as complete until it matches the Android behavior listed in `docs/android-parity.md` and has a replayable verification note.
