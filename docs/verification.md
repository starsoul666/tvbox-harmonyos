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

## Current conclusion

The project structure and dependencies are in place, but CLI build verification is blocked by the local DevEco SDK installation. Re-run `assembleHap` after installing the complete HarmonyOS SDK components in DevEco Studio SDK Manager.
