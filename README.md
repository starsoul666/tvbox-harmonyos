# TVBox HarmonyOS Next

HarmonyOS Next / ArkTS version of `/Users/jwli/workspace/github/tvbox`.

This repository is intentionally structured around feature parity with the Android project. The Android project remains the source of truth until each item in `docs/android-parity.md` is implemented and verified on HarmonyOS.

## Current baseline

- Stage model HarmonyOS app scaffold.
- TV landscape-first routing and pages matching Android activities; Drive/Apps are still placeholder-level.
- Core Android-compatible data models for source, parse, VOD, live, history, and settings.
- Config parsing service for TVBox JSON config (`sites`, `parses`, `lives`, `flags`, `rules`, `ijk`, `ads`) with Android-compatible cache fallback.
- Settings defaults mirrored from Android `App.initParams()`.
- Home source selection persists with the Android-compatible `home_api` key.
- Settings can edit Android-compatible config, live subscription, and EPG URL keys.
- Android image/Base64 embedded JSON config extraction, `;pk;` AES ECB configs, and `2423` AES CBC configs are supported.
- Initial type=0 XML, type=1 JSON, and type=4 API source flow is present for home content, category list, detail, search, and quick search; Home/Search/FastSearch/Detail pages use this flow for real result and metadata rendering.
- Detail page supports favorite toggle and writes a compact playback history snapshot before opening Play.
- Push page supports manual direct URL playback through Play; remote server push remains pending.
- Live page supports config `lives` direct channel groups plus M3U/TXT live subscriptions, group/channel/source switching, last channel persistence, and ArkUI `Video` playback.
- Play page now uses ArkUI `Video` for playback, pause/resume, seeking, previous/next episode within the current group, resume-position restore, playback-history progress persistence, current-group history restoration, and an initial Android-style JSON/type=4 parse switching flow.

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
