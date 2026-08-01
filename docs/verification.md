# Verification notes

## Environment

- Workspace: `/Users/jwli/workspace/github/tvbox-harmonyos`
- Android source of truth: `/Users/jwli/workspace/github/tvbox`
- DevEco Studio path used: `/Applications/DevEco-Studio.app`

## Commands

```bash
/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin/ohpm install
```

Result: dependency resolution completed and generated `oh-package-lock.json5`.

```bash
/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --mode module -p product=default assembleHap
```

Result: blocked before source compilation because `DEVECO_SDK_HOME` is not configured.

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk/default \
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --mode module -p product=default assembleHap
```

Result: blocked before source compilation with `SDK component missing. Please verify the integrity of your SDK.`

Re-run after adding P1 config cache and AES config decoding produced the same SDK-level failure:

```text
> hvigor ERROR: SDK component missing. Please verify the integrity of your SDK.
> hvigor ERROR: BUILD FAILED in 219 ms
```

Re-run after adding local history/favorites/search persistence still fails at the same SDK layer:

```text
> hvigor ERROR: SDK component missing. Please verify the integrity of your SDK.
> hvigor ERROR: BUILD FAILED in 188 ms
```

Static scan after adding initial JSON `SourceService`, real search result wiring, and Detail page detail/favorite/history wiring:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|any" entry/src/main/ets README.md docs/android-parity.md
```

Result: no matches.

Static scan after wiring the initial Play page direct playback, current-group previous/next episode switching, and progress persistence:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|any" entry/src/main/ets README.md docs/android-parity.md
```

Result: no matches.

Static scan after adding the initial `PlaybackService`, JSON parse switching, raw/final playback URL persistence, and history resume updates:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|any" entry/src/main/ets README.md docs/android-parity.md
```

Result: no matches.

Static scan after adding type=4 playback API resolution and compact current-group history restoration:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|any" entry/src/main/ets README.md docs/android-parity.md
```

Result: no matches.

Re-run after adding initial JSON `SourceService`, real search result wiring, and Detail page detail/favorite/history wiring still fails at the same SDK layer:

```text
> hvigor ERROR: SDK component missing. Please verify the integrity of your SDK.
> hvigor ERROR: BUILD FAILED in 57 ms
```

Re-run after adding initial Play direct playback, current-group episode switching, and progress persistence still fails at the same SDK layer:

```text
> hvigor ERROR: SDK component missing. Please verify the integrity of your SDK.
> hvigor ERROR: BUILD FAILED in 65 ms
```

Re-run after adding the initial playback parse service and Play parse switching still fails at the same SDK layer:

```text
> hvigor ERROR: SDK component missing. Please verify the integrity of your SDK.
> hvigor ERROR: BUILD FAILED in 165 ms
```

Re-run after adding type=4 playback API resolution and current-group history restoration still fails at the same SDK layer:

```text
> hvigor ERROR: 00303168 Configuration Error
Error Message: SDK component missing.
> hvigor ERROR: BUILD FAILED in 2 s 571 ms
```

Static scan after adding initial Live page playback, M3U/TXT subscription parsing, channel/source switching, and live/EPG settings:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|any" entry/src/main/ets README.md docs/android-parity.md
```

Result: no matches.

Static scan after adding Alist Drive persistence/browsing/playback:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|any" entry/src/main/ets README.md docs/android-parity.md
```

Result: no matches.

Static scan after adding WebDAV Drive persistence/browsing/direct playback URL resolution and Play `playerCfg` header snapshot preservation:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|any" entry/src/main/ets README.md docs/android-parity.md
```

Result: no matches.

Static scan after adding Apps persisted launch items, Bundle/Ability lookup, startAbility launch, edit, and delete-list mode:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|any" entry/src/main/ets README.md docs/android-parity.md
```

Result: no matches.

Static scan after adding Drive local-directory browsing and `file://` playback URL resolution:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|any" entry/src/main/ets README.md docs/android-parity.md
```

Result: no matches.

Static scan after adding Push outbound remote protocol support:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|any" entry/src/main/ets README.md docs/android-parity.md
```

Result: no matches.

Static scan after adding API-type `push_agent` detail entry and Android `push://`/`b64:` decode handling:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|any" entry/src/main/ets README.md docs/android-parity.md
```

Result: no matches.

Static scan after adding Drive current-directory filename search:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|any" entry/src/main/ets README.md docs/android-parity.md
```

Result: no matches.

Static scan after adding Live EPG program lookup:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|any" entry/src/main/ets README.md docs/android-parity.md
```

Result: no matches.

Static scan after adding Live password-protected group prompts:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|any" entry/src/main/ets README.md docs/android-parity.md
```

Result: no matches.

Static scan after adding Live reverse/cross-group channel switching:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|any" entry/src/main/ets README.md docs/android-parity.md
```

Result: no matches.

Static scan after adding Live channel-number jump:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|any" entry/src/main/ets README.md docs/android-parity.md
```

Result: no matches.

Static scan after adding Android `epg_data.json` logo/name aliases:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|any" entry/src/main/ets README.md docs/android-parity.md
```

Result: no matches.

Static scan after adding Live remote-control channel/source key handling:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|any" entry/src/main/ets README.md docs/android-parity.md
```

Result: no matches.

Static scan after adding Live EPG time-shift playback:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|any" entry/src/main/ets README.md docs/android-parity.md
```

Result: no matches.

Re-run after adding Live EPG time-shift playback still fails at the local SDK layer before ArkTS compilation:

```text
> hvigor ERROR: 00303168 Configuration Error
Error Message: SDK component missing.
> hvigor ERROR: BUILD FAILED
```

Static scan after adding Live `livePlayHeaders` matching:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|any" entry/src/main/ets README.md docs/android-parity.md
```

Result: no matches.

Re-run after adding Live `livePlayHeaders` matching still fails at the local SDK layer before ArkTS compilation:

```text
> hvigor ERROR: 00303168 Configuration Error
Error Message: SDK component missing.
> hvigor ERROR: BUILD FAILED
```

Re-run after adding initial Live page playback, subscription parsing, and live/EPG settings still fails at the local SDK layer before ArkTS compilation:

```text
> hvigor ERROR: 00303168 Configuration Error
Error Message: SDK component missing.
> hvigor ERROR: BUILD FAILED in 4 s 133 ms
```

Re-run after adding Alist Drive persistence/browsing/playback still fails at the same local SDK layer before ArkTS compilation:

```text
> hvigor ERROR: 00303168 Configuration Error
Error Message: SDK component missing.
> hvigor ERROR: BUILD FAILED in 87 ms
```

Re-run after adding WebDAV Drive persistence/browsing/direct playback URL resolution and Play `playerCfg` header snapshot preservation still fails at the same local SDK layer before ArkTS compilation:

```text
> hvigor ERROR: 00303168 Configuration Error
Error Message: SDK component missing.
> hvigor ERROR: BUILD FAILED in 91 ms
```

Re-run after adding Apps persisted launcher support still fails at the same local SDK layer before ArkTS compilation:

```text
> hvigor ERROR: 00303168 Configuration Error
Error Message: SDK component missing.
> hvigor ERROR: BUILD FAILED in 70 ms
```

Re-run after adding Drive local-directory browsing still fails at the same local SDK layer before ArkTS compilation:

```text
> hvigor ERROR: 00303168 Configuration Error
Error Message: SDK component missing.
> hvigor ERROR: BUILD FAILED in 64 ms
```

Re-run after adding Push outbound remote protocol support still fails at the same local SDK layer before ArkTS compilation:

```text
> hvigor ERROR: 00303168 Configuration Error
Error Message: SDK component missing.
> hvigor ERROR: BUILD FAILED in 63 ms
```

Re-run after adding API-type `push_agent` detail entry still fails at the same local SDK layer before ArkTS compilation:

```text
> hvigor ERROR: 00303168 Configuration Error
Error Message: SDK component missing.
> hvigor ERROR: BUILD FAILED in 120 ms
```

Re-run after adding Drive current-directory filename search still fails at the same local SDK layer before ArkTS compilation:

```text
> hvigor ERROR: 00303168 Configuration Error
Error Message: SDK component missing.
> hvigor ERROR: BUILD FAILED in 63 ms
```

Re-run after adding Live EPG program lookup still fails at the same local SDK layer before ArkTS compilation:

```text
> hvigor ERROR: 00303168 Configuration Error
Error Message: SDK component missing.
> hvigor ERROR: BUILD FAILED in 60 ms
```

Re-run after adding Live password-protected group prompts still fails at the same local SDK layer before ArkTS compilation:

```text
> hvigor ERROR: 00303168 Configuration Error
Error Message: SDK component missing.
> hvigor ERROR: BUILD FAILED in 47 ms
```

Re-run after adding Live reverse/cross-group channel switching still fails at the same local SDK layer before ArkTS compilation:

```text
> hvigor ERROR: 00303168 Configuration Error
Error Message: SDK component missing.
> hvigor ERROR: BUILD FAILED in 118 ms
```

Re-run after adding Live channel-number jump still fails at the same local SDK layer before ArkTS compilation:

```text
> hvigor ERROR: 00303168 Configuration Error
Error Message: SDK component missing.
> hvigor ERROR: BUILD FAILED in 51 ms
```

Re-run after adding Android `epg_data.json` logo/name aliases still fails at the same local SDK layer before ArkTS compilation:

```text
> hvigor ERROR: 00303168 Configuration Error
Error Message: SDK component missing.
> hvigor ERROR: BUILD FAILED in 46 ms
```

Re-run after adding Live remote-control channel/source key handling still fails at the same local SDK layer before ArkTS compilation:

```text
> hvigor ERROR: 00303168 Configuration Error
Error Message: SDK component missing.
> hvigor ERROR: BUILD FAILED in 109 ms
```

## Current conclusion

The project structure and dependencies are in place, but CLI build verification is blocked by the local DevEco SDK installation. Re-run `assembleHap` after installing the complete HarmonyOS SDK components in DevEco Studio SDK Manager.

## Android parity milestone (build now succeeds)

Before this milestone the project had never compiled. Three blocking classes of failure were fixed:

1. `hvigor/hvigor-config.json5` failed schema validation (missing `dependencies`).
2. `entry/src/main/module.json5` declared `ohos.permission.READ_MEDIA` / `WRITE_MEDIA` without the
   mandatory `reason` and `usedScene` fields.
3. 26 ArkTS strict-mode compile errors (`arkts-no-any-unknown`, `arkts-no-untyped-obj-literals`,
   `arkts-no-obj-literals-as-types`, `arkts-no-noninferrable-arr-literals`, `arkts-no-delete`,
   self-referential type aliases, and a `struct Search` collision with the built-in `Search` component).

Reproducible build:

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk ./scripts/verify-build.sh
```

Result:

```text
> hvigor BUILD SUCCESSFUL
HAP output:
entry/build/default/outputs/default/entry-default-unsigned.hap
```

Environment used: DevEco Studio bundled SDK, HarmonyOS 6.0.2 (API 22).
`build-profile.json5` keeps `compatibleSdkVersion` 5.0.3(15) and `targetSdkVersion` 6.0.2(22).

### Not yet verified on device

The build is verified; on-device playback has not been replayed here. The following need a
real device or emulator run:

- AVPlayer header injection against a Referer-protected source and a WebDAV Basic-auth file.
- Audio/subtitle track enumeration (depends on the media container).
- D-pad focus traversal on a TV form factor.

## Theme and language parity slice

Static implementation check after wiring Android-compatible `THEME_SELECT` / `HOME_LOCALE` into
Home and Settings:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|any" entry/src/main/ets README.md docs/android-parity.md
```

Result: no matches.

Build verification:

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk ./scripts/verify-build.sh
```

Result:

```text
> hvigor BUILD SUCCESSFUL in 26 s 859 ms
HAP output:
entry/build/default/outputs/default/entry-default-unsigned.hap
```

Expected device replay:

1. Open Settings, switch theme through all seven Android-compatible theme names, and confirm the
   Settings screen recolors immediately.
2. Switch language from Chinese to English and confirm Home/Settings primary labels and status
   messages update after returning to Home or reopening Settings.
3. Switch back to Chinese and confirm `theme_select` / `language` persist across app restart.

## Theme coverage expansion

Static implementation check after extending `THEME_SELECT` to Search, FastSearch, History,
Favorites, and Push:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|\bany\b" entry/src/main/ets
```

Result: no matches.

Build verification:

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk ./scripts/verify-build.sh
```

Result:

```text
> hvigor BUILD SUCCESSFUL in 14 s 43 ms
HAP output:
entry/build/default/outputs/default/entry-default-unsigned.hap
```

Expected device replay: switch every theme in Settings, then open Search, FastSearch, History,
Favorites, and Push from Home and confirm page background, cards, history chips, empty states, and
primary/muted text colors follow the selected palette.

## Theme coverage expansion 2

Static implementation check after extending `THEME_SELECT` to Category, Detail, Drive, and Apps:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|\bany\b" entry/src/main/ets
```

Result: no matches.

Build verification:

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk ./scripts/verify-build.sh
```

Result:

```text
> hvigor BUILD SUCCESSFUL in 12 s 326 ms
HAP output:
entry/build/default/outputs/default/entry-default-unsigned.hap
```

Expected device replay: switch every theme in Settings, then open Category, Detail, Drive, and
Apps from Home and confirm page background, cards, filter chips, detail episode groups, drive rows,
and app launcher cards follow the selected palette.

## Playback Theme Coverage

Static implementation check after extending `THEME_SELECT` to Play and Live overlays:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|\bany\b" entry/src/main/ets
```

Result: no matches.

Build verification:

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk ./scripts/verify-build.sh
```

Result:

```text
> hvigor BUILD SUCCESSFUL in 32 s 582 ms
HAP output:
entry/build/default/outputs/default/entry-default-unsigned.hap
```

Expected device replay: switch every theme in Settings, then open Play and Live. Confirm the video
surface remains black, while the playback controls, chips, sliders, live channel/group rows, EPG
rows, and password dialog use the selected palette without losing contrast.

## Feature Localization Expansion 1

Static implementation check after extending `HOME_LOCALE` to Search, FastSearch, History,
Favorites, and Push:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|\bany\b" entry/src/main/ets
```

Result: no matches.

Build verification:

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk ./scripts/verify-build.sh
```

Result:

```text
> hvigor BUILD SUCCESSFUL in 54 s 178 ms
HAP output:
entry/build/default/outputs/default/entry-default-unsigned.hap
```

Expected device replay: switch Settings language between Chinese and English, then open Search,
FastSearch, History, Favorites, and Push. Confirm static labels, placeholders, empty states, status
messages, delete-mode hints, counts, and toasts follow the selected language.

## Feature Localization Expansion 2

Static implementation check after extending `HOME_LOCALE` to Drive, Apps, Category, Detail, Play,
and Live:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|\bany\b" entry/src/main/ets
```

Result: no matches.

Build verification:

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk ./scripts/verify-build.sh
```

Result:

```text
> hvigor BUILD SUCCESSFUL in 24 s 134 ms
HAP output:
entry/build/default/outputs/default/entry-default-unsigned.hap
```

Expected device replay: switch Settings language between Chinese and English, then open Drive,
Apps, Category, Detail, Play, and Live. Confirm titles, back buttons, status messages, empty
states, placeholders, filter chips, episode groups, playback controls, live channel/group
labels, EPG date buttons, and password dialogs follow the selected language.

## Danmu and External Subtitle Support

Static implementation check after adding `DanmuService`, `SubtitleService`,
`DanmuOverlay`, `SubtitleOverlay`, danmu Hawk config keys, and Play page integration:

```bash
rg -n "Record<string, Object>|Object\[\]|\(item: Object\)|replaceAll|padStart|TODO|FIXME|Number\.parseInt|console\.log|implicitAny|\bany\b" entry/src/main/ets
```

Result: no matches.

Build verification:

```bash
DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk ./scripts/verify-build.sh
```

Result:

```text
> hvigor BUILD SUCCESSFUL in 11 s 453 ms
HAP output:
entry/build/default/outputs/default/entry-default-unsigned.hap
```

Expected device replay: play a type=4 source that returns `danmaku` and `subt` fields in the
play-result JSON. Confirm danmu scrolls across the video surface synced to playback position,
and the subtitle text appears at the bottom timed to the video. Toggle danmu and subtitle on/off
via the control buttons. Adjust danmu settings (speed, max lines, alpha, size, color) via Hawk
keys and confirm the overlay respects the changes on next playback.
