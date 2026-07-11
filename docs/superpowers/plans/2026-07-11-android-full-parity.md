# TVBox HarmonyOS Android Full-Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the approved Android-to-HarmonyOS parity scope through independently testable player, parsing, Spider, proxy, native-runtime, and page-delivery milestones.

**Architecture:** Keep ArkUI pages thin and route behavior through domain services and stable adapter contracts. Official HarmonyOS APIs provide the default path; independently built NAPI modules add QuickJS, Python, FFmpeg, local-server, and P2P compatibility without coupling native lifecycle to page lifecycle.

**Tech Stack:** HarmonyOS NEXT API 15-22, ArkTS/ArkUI, AVPlayer, Web, Preferences/file APIs, Hypium, C++17, NAPI, CMake, QuickJS, CPython, FFmpeg, HTTP/WebSocket.

---

## Plan structure and execution order

This program contains several independent subsystems. Implement them in this dependency order and create a dedicated child plan before starting each native subsystem:

1. Build/test baseline.
2. Player contract and AVPlayer path.
3. Parse matrix and Web sniffing.
4. Local proxy and remote-control server.
5. JavaScript Spider.
6. Python Spider.
7. Remote Jar compatibility client.
8. FFmpeg compatibility player.
9. Danmu, subtitle, and advanced controls.
10. P2P and special protocols.
11. Page/settings parity.
12. Stability and release verification.

Do not start Python, FFmpeg, or P2P work until the corresponding feasibility spike in this plan passes.

## Target file structure

```text
entry/src/main/ets/
  domain/source/               Source contracts and orchestration
  domain/playback/             Player contracts, state, and controls
  domain/parse/                Parse selection and result rotation
  domain/remote/               Local-server client and remote events
  adapters/player/             AVPlayer and external-player adapters
  adapters/source/             HTTP, JS, Python, and remote-Jar adapters
  adapters/web/                Web sniffing controller
  components/player/           ArkUI player surface and controls
  repositories/                Settings, history, favorites, drives, cache
entry/src/test/                ArkTS unit tests
native/
  quickjs_runtime/
  python_runtime/
  ffmpeg_player/
  local_server/
  p2p_runtime/
scripts/                       Reproducible verification helpers
docs/verification/             Per-milestone device evidence
```

### Task 1: Establish a reproducible build baseline

**Files:**
- Modify: `build-profile.json5`
- Modify: `README.md`
- Modify: `docs/verification.md`
- Create: `scripts/verify-build.sh`
- Create: `docs/verification/device-matrix.md`

- [ ] **Step 1: Record the required toolchain**

Document DevEco Studio, HarmonyOS SDK 5.0.3 compatible API, target API 22, NDK, CMake, Node, and ohpm versions in `README.md`. Keep `build-profile.json5` aligned with an SDK that is actually installed rather than changing versions only to silence the build.

- [ ] **Step 2: Add the verification script**

Create `scripts/verify-build.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

: "${DEVECO_SDK_HOME:?Set DEVECO_SDK_HOME to the installed HarmonyOS SDK}"
OHPM="/Applications/DevEco-Studio.app/Contents/tools/ohpm/bin/ohpm"
HVIGOR="/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw"

"$OHPM" install
"$HVIGOR" --mode module -p product=default assembleHap
```

- [ ] **Step 3: Run the build and preserve decisive output**

Run:

```bash
chmod +x scripts/verify-build.sh
DEVECO_SDK_HOME=/absolute/path/to/sdk ./scripts/verify-build.sh
```

Expected: `BUILD SUCCESSFUL` and a generated HAP under `entry/build/default/outputs/default/`.

- [ ] **Step 4: Record device coverage**

Add rows for TV, phone, tablet, and 2-in-1 to `docs/verification/device-matrix.md`, including OS version, resolution, input method, build result, launch result, and owner.

- [ ] **Step 5: Commit**

```bash
git add build-profile.json5 README.md docs/verification.md docs/verification/device-matrix.md scripts/verify-build.sh
git commit -m "build: establish HarmonyOS verification baseline"
```

### Task 2: Add unit-test scaffolding and pure-domain fixtures

**Files:**
- Modify: `entry/oh-package.json5`
- Create: `entry/src/main/ets/domain/playback/PlaybackOrder.ts`
- Create: `entry/src/test/List.test.ets`
- Create: `entry/src/test/PlaybackOrder.test.ets`
- Create: `entry/src/test/fixtures/playback.ts`

- [ ] **Step 1: Write the failing playback-order tests**

```ts
import { describe, expect, it } from '@ohos/hypium';
import { nextEpisodeIndex, previousEpisodeIndex } from '../main/ets/domain/playback/PlaybackOrder';

export default function playbackOrderTest(): void {
  describe('PlaybackOrder', () => {
    it('uses visible order for next episode', 0, () => {
      expect(nextEpisodeIndex(0, 3, false)).assertEqual(1);
      expect(nextEpisodeIndex(0, 3, true)).assertEqual(-1);
    });
    it('uses visible order for previous episode', 0, () => {
      expect(previousEpisodeIndex(2, 3, false)).assertEqual(1);
      expect(previousEpisodeIndex(2, 3, true)).assertEqual(-1);
    });
  });
}
```

- [ ] **Step 2: Run the test and verify failure**

Run the DevEco module test target.

Expected: failure because `domain/playback/PlaybackOrder` does not exist.

- [ ] **Step 3: Add the minimal order helper**

Create `entry/src/main/ets/domain/playback/PlaybackOrder.ts`:

```ts
export function nextEpisodeIndex(index: number, count: number, reverse: boolean): number {
  const next = reverse ? index - 1 : index + 1;
  return next >= 0 && next < count ? next : -1;
}

export function previousEpisodeIndex(index: number, count: number, reverse: boolean): number {
  const previous = reverse ? index + 1 : index - 1;
  return previous >= 0 && previous < count ? previous : -1;
}
```

- [ ] **Step 4: Register and rerun tests**

Import `playbackOrderTest` from `List.test.ets`, run the module test target, and expect all PlaybackOrder cases to pass.

- [ ] **Step 5: Commit**

```bash
git add entry/oh-package.json5 entry/src/test entry/src/main/ets/domain/playback/PlaybackOrder.ts
git commit -m "test: add playback domain test baseline"
```

### Task 3: Introduce player contracts without changing behavior

**Files:**
- Create: `entry/src/main/ets/domain/playback/MediaPlayerAdapter.ts`
- Create: `entry/src/main/ets/domain/playback/PlaybackModels.ts`
- Create: `entry/src/main/ets/domain/playback/PlaybackSession.ts`
- Test: `entry/src/test/PlaybackSession.test.ets`

- [ ] **Step 1: Write a failing session lifecycle test**

Test that `setSource()` releases the previous source, forwards headers, and emits `preparing`, while `release()` is idempotent.

- [ ] **Step 2: Define stable playback types**

```ts
export interface MediaSource {
  url: string;
  headers: Record<string, string>;
  startPositionMs: number;
}

export interface MediaTrack {
  id: string;
  label: string;
  language: string;
}

export interface MediaPlayerAdapter {
  setSource(source: MediaSource): Promise<void>;
  prepare(): Promise<void>;
  play(): void;
  pause(): void;
  seek(positionMs: number): void;
  audioTracks(): MediaTrack[];
  subtitleTracks(): MediaTrack[];
  selectAudioTrack(trackId: string): void;
  selectSubtitleTrack(trackId: string): void;
  setScaleMode(mode: string): void;
  setSpeed(speed: number): void;
  release(): void;
}
```

- [ ] **Step 3: Implement `PlaybackSession`**

Keep player ownership, source replacement, lifecycle state, and event forwarding in the session. Do not import ArkUI page types into the domain directory.

- [ ] **Step 4: Run tests**

Expected: lifecycle tests pass and `scripts/verify-build.sh` remains successful.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/domain/playback entry/src/test/PlaybackSession.test.ets
git commit -m "refactor: add player adapter contract"
```

### Task 4: Implement the official AVPlayer adapter

**Files:**
- Create: `entry/src/main/ets/adapters/player/AvPlayerAdapter.ts`
- Create: `entry/src/main/ets/adapters/player/AvPlayerFactory.ts`
- Create: `entry/src/main/ets/components/player/PlayerSurface.ets`
- Modify: `entry/src/main/ets/pages/Play.ets`
- Modify: `entry/src/main/ets/pages/Live.ets`
- Test: `entry/src/test/AvPlayerSource.test.ets`

- [ ] **Step 1: Write source-conversion tests**

Verify that URL, Referer, User-Agent, Cookie, Authorization, and arbitrary headers are preserved when converting `MediaSource` to the AVPlayer media-source descriptor.

- [ ] **Step 2: Implement `AvPlayerAdapter`**

Use official media APIs for state callbacks, source headers, prepare, play, pause, seek, speed, tracks, error reporting, and release. Keep platform callbacks inside the adapter.

- [ ] **Step 3: Add `PlayerSurface`**

The component owns the rendering surface only. Controls consume `PlaybackSession` state and never call AVPlayer directly.

- [ ] **Step 4: Migrate VOD and live playback**

Replace `VideoController` and direct `Video({ src })` ownership in `Play.ets` and `Live.ets` with the shared session. Merge headers from parse results, `playerCfg`, live rules, and drive credentials before `setSource()`.

- [ ] **Step 5: Verify on device**

Test direct MP4, HLS, a Referer-protected URL, a WebDAV Basic URL, seek, background/foreground, and release/reopen.

- [ ] **Step 6: Commit**

```bash
git add entry/src/main/ets/adapters/player entry/src/main/ets/components/player entry/src/main/ets/pages/Play.ets entry/src/main/ets/pages/Live.ets entry/src/test/AvPlayerSource.test.ets
git commit -m "feat: route playback through AVPlayer adapter"
```

### Task 5: Complete shared playback controls

**Files:**
- Create: `entry/src/main/ets/domain/playback/PlaybackController.ts`
- Create: `entry/src/main/ets/domain/playback/SubtitleManager.ts`
- Create: `entry/src/main/ets/components/player/PlaybackControls.ets`
- Create: `entry/src/main/ets/components/player/TrackSelector.ets`
- Modify: `entry/src/main/ets/pages/Play.ets`
- Modify: `entry/src/main/ets/constants/HawkConfig.ts`
- Test: `entry/src/test/PlaybackController.test.ets`

- [ ] **Step 1: Add failing tests**

Cover automatic next episode, reversed episode order, resume threshold, speed bounds, aspect-mode rotation, and subtitle offset.

- [ ] **Step 2: Implement controller behavior**

Persist speed, aspect ratio, selected track, skip-intro, and skip-outro through Android-compatible or explicitly namespaced HarmonyOS keys.

- [ ] **Step 3: Add TV-focused controls**

Implement D-pad navigation for play/pause, previous/next, seek, parse, speed, aspect, audio, subtitle, and danmu entries. Touch must not be required.

- [ ] **Step 4: Verify**

Run unit tests and a device sequence covering normal order, reverse order, finish-to-next, manual seek, app background, and track selection.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/domain/playback entry/src/main/ets/components/player entry/src/main/ets/pages/Play.ets entry/src/main/ets/constants/HawkConfig.ts entry/src/test/PlaybackController.test.ets
git commit -m "feat: complete shared playback controls"
```

### Task 6: Extract and complete the parse engine

**Files:**
- Create: `entry/src/main/ets/domain/parse/ParseAdapter.ts`
- Create: `entry/src/main/ets/domain/parse/ParseEngine.ts`
- Create: `entry/src/main/ets/domain/parse/ParseModels.ts`
- Modify: `entry/src/main/ets/services/PlaybackService.ts`
- Test: `entry/src/test/ParseEngine.test.ets`
- Test fixtures: `entry/src/test/fixtures/parse-responses.ts`

- [ ] **Step 1: Add failing parse-matrix tests**

Cover direct URLs, type 0 sniff, type 1 JSON, type 2 extended JSON, type 3 aggregate, type 4 source player response, SuperParse selection, failed-line rotation, and returned headers/subtitles.

- [ ] **Step 2: Define parse results**

```ts
export interface ParsedMedia {
  url: string;
  headers: Record<string, string>;
  subtitleUrls: string[];
  parseName: string;
  requiresProxy: boolean;
}
```

- [ ] **Step 3: Move orchestration out of `PlaybackService`**

`PlaybackService` resolves source-specific player data, while `ParseEngine` owns parse type dispatch, priority, rotation, timeout, and cancellation.

- [ ] **Step 4: Run tests and build**

Expected: every parse type has deterministic fixture coverage; existing direct/type-4 behavior remains green.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/domain/parse entry/src/main/ets/services/PlaybackService.ts entry/src/test/ParseEngine.test.ets entry/src/test/fixtures/parse-responses.ts
git commit -m "feat: add complete parse orchestration"
```

### Task 7: Add Web sniffing

**Files:**
- Create: `entry/src/main/ets/adapters/web/SniffController.ts`
- Create: `entry/src/main/ets/adapters/web/SniffRules.ts`
- Create: `entry/src/main/ets/components/player/SniffWebView.ets`
- Create: `entry/src/main/resources/rawfile/sniff_bridge.js`
- Modify: `entry/src/main/ets/domain/parse/ParseEngine.ts`
- Test: `entry/src/test/SniffRules.test.ets`

- [ ] **Step 1: Test media and ad classification**

Use fixtures for HLS, DASH, MP4, FLV, blob URLs, analytics, image ads, redirected media, and configured regex rules.

- [ ] **Step 2: Add the Web bridge**

Instrument fetch, XHR, media `src`, navigation, and performance entries. Emit only structured request metadata to ArkTS.

- [ ] **Step 3: Add lifecycle controls**

Support one active sniff per playback session, explicit cancellation, a fixed timeout, result deduplication, and Web instance disposal.

- [ ] **Step 4: Integrate parse type 0**

Return the first validated non-ad media candidate with captured headers and cookies. Rotate to the next parse on timeout.

- [ ] **Step 5: Verify and commit**

```bash
git add entry/src/main/ets/adapters/web entry/src/main/ets/components/player/SniffWebView.ets entry/src/main/resources/rawfile/sniff_bridge.js entry/src/main/ets/domain/parse/ParseEngine.ts entry/src/test/SniffRules.test.ets
git commit -m "feat: add Web media sniffing"
```

### Task 8: Build the local HTTP/WebSocket runtime

**Files:**
- Create: `native/local_server/CMakeLists.txt`
- Create: `native/local_server/include/local_server.h`
- Create: `native/local_server/src/local_server.cpp`
- Create: `native/local_server/src/napi_module.cpp`
- Create: `entry/src/main/ets/domain/remote/LocalServer.ts`
- Create: `entry/src/main/resources/rawfile/remote/index.html`
- Create: `entry/src/test/LocalRoute.test.ets`

- [ ] **Step 1: Write a child plan**

Create `docs/superpowers/plans/2026-07-11-local-server-runtime.md` after selecting the HTTP/WebSocket library and confirming its HarmonyOS build.

- [ ] **Step 2: Implement a loopback health endpoint first**

Expose `start(bindAddress, port, token)`, `stop()`, and `port()` through NAPI. Add `/health` returning fixed JSON.

- [ ] **Step 3: Add secured routes**

Implement `/action`, `/api/updateUrl`, playback control, state WebSocket, static remote UI, rate limiting, temporary token validation, and path allowlists.

- [ ] **Step 4: Add proxy routes**

Support header forwarding, redirects, M3U8 rewriting, segments, Spider proxy output, and `clan://localhost` mapping.

- [ ] **Step 5: Verify**

Test loopback-only mode, LAN opt-in, invalid tokens, traversal attempts, oversized bodies, repeated start/stop, and port release.

- [ ] **Step 6: Commit**

```bash
git add native/local_server entry/src/main/ets/domain/remote entry/src/main/resources/rawfile/remote entry/src/test/LocalRoute.test.ets docs/superpowers/plans/*local-server-runtime.md
git commit -m "feat: add secured local proxy and remote server"
```

### Task 9: Introduce the unified Spider contract

**Files:**
- Create: `entry/src/main/ets/domain/source/SpiderAdapter.ts`
- Create: `entry/src/main/ets/domain/source/SourceEngine.ts`
- Create: `entry/src/main/ets/adapters/source/HttpSourceAdapter.ts`
- Modify: `entry/src/main/ets/services/SourceService.ts`
- Modify: `entry/src/main/ets/pages/Home.ets`
- Modify: `entry/src/main/ets/pages/Detail.ets`
- Modify: `entry/src/main/ets/pages/Search.ets`
- Modify: `entry/src/main/ets/pages/FastSearch.ets`
- Test: `entry/src/test/SourceEngine.test.ets`

- [ ] **Step 1: Add contract tests around the existing HTTP behavior**

Use fake adapters to test home, category, paging, detail, search, player, cancellation, and per-source errors.

- [ ] **Step 2: Move XML/JSON/type-4 behavior into `HttpSourceAdapter`**

Preserve existing public results while moving page-independent orchestration to `SourceEngine`.

- [ ] **Step 3: Migrate pages**

Pages select a source and render state; they do not branch on source type.

- [ ] **Step 4: Verify and commit**

```bash
git add entry/src/main/ets/domain/source entry/src/main/ets/adapters/source/HttpSourceAdapter.ts entry/src/main/ets/services/SourceService.ts entry/src/main/ets/pages/{Home,Detail,Search,FastSearch}.ets entry/src/test/SourceEngine.test.ets
git commit -m "refactor: add unified source engine"
```

### Task 10: Implement QuickJS Spider runtime

**Files:**
- Create: `docs/superpowers/plans/2026-07-11-quickjs-spider-runtime.md`
- Create: `native/quickjs_runtime/CMakeLists.txt`
- Create: `native/quickjs_runtime/include/quickjs_runtime.h`
- Create: `native/quickjs_runtime/src/napi_module.cpp`
- Create: `entry/src/main/ets/adapters/source/JsSpiderAdapter.ts`
- Create: `entry/src/main/ets/domain/source/JsBridge.ts`
- Create: `entry/src/test/JsSpiderContract.test.ets`
- Create: `entry/src/test/fixtures/js-spiders/`

- [ ] **Step 1: Complete the feasibility spike**

Build QuickJS arm64, execute `1 + 1`, interrupt an infinite loop, enforce a memory limit, and release the runtime repeatedly. Record evidence in the child plan.

- [ ] **Step 2: Implement the minimal Spider methods**

Add `init`, `home`, `homeVideo`, `category`, `detail`, `search`, `player`, and `proxy` calls with JSON-safe arguments/results.

- [ ] **Step 3: Add controlled bridge APIs**

Provide request, encoding, hashing, AES/RSA helpers, HTML parsing helpers, storage cache, and time APIs. Do not expose arbitrary filesystem or process APIs.

- [ ] **Step 4: Validate ten JS fixtures**

Require successful home-detail-play flows, cancellation, timeout, script exception, cache reload, and proxy output.

- [ ] **Step 5: Commit**

```bash
git add native/quickjs_runtime entry/src/main/ets/adapters/source/JsSpiderAdapter.ts entry/src/main/ets/domain/source/JsBridge.ts entry/src/test/JsSpiderContract.test.ets entry/src/test/fixtures/js-spiders docs/superpowers/plans/*quickjs-spider-runtime.md
git commit -m "feat: add sandboxed QuickJS Spider runtime"
```

### Task 11: Implement Python Spider runtime

**Files:**
- Create: `docs/superpowers/plans/2026-07-11-python-spider-runtime.md`
- Create: `native/python_runtime/CMakeLists.txt`
- Create: `native/python_runtime/include/python_runtime.h`
- Create: `native/python_runtime/src/napi_module.cpp`
- Create: `entry/src/main/ets/adapters/source/PythonSpiderAdapter.ts`
- Create: `entry/src/test/PythonSpiderContract.test.ets`
- Create: `entry/src/test/fixtures/python-spiders/`

- [ ] **Step 1: Complete the feasibility spike**

Build CPython arm64, import the packaged standard library, execute a pure-Python Spider fixture, interrupt long-running work, and verify repeated interpreter creation/release.

- [ ] **Step 2: Freeze the supported dependency policy**

List pure-Python packages shipped with the app and reject unapproved binary extensions with a specific error code.

- [ ] **Step 3: Implement the pyramid-compatible bridge**

Map the same `SpiderAdapter` methods and controlled networking, crypto, parsing, and cache capabilities.

- [ ] **Step 4: Verify and commit**

```bash
git add native/python_runtime entry/src/main/ets/adapters/source/PythonSpiderAdapter.ts entry/src/test/PythonSpiderContract.test.ets entry/src/test/fixtures/python-spiders docs/superpowers/plans/*python-spider-runtime.md
git commit -m "feat: add sandboxed Python Spider runtime"
```

### Task 12: Add remote Jar compatibility

**Files:**
- Create: `entry/src/main/ets/adapters/source/RemoteJarAdapter.ts`
- Create: `entry/src/main/ets/domain/source/RemoteSpiderProtocol.ts`
- Modify: `entry/src/main/ets/pages/Settings.ets`
- Modify: `entry/src/main/ets/constants/HawkConfig.ts`
- Test: `entry/src/test/RemoteJarAdapter.test.ets`
- Create: `docs/remote-spider-protocol.md`

- [ ] **Step 1: Define the protocol**

Specify versioned JSON requests for every Spider method, authentication headers, response envelopes, proxy streaming, health checks, timeouts, and error codes.

- [ ] **Step 2: Add mocked contract tests**

Cover success, authentication failure, version mismatch, timeout, malformed response, server error, and source-specific isolation.

- [ ] **Step 3: Implement settings and adapter**

Add user-controlled service URL/token fields and a connection-test action. Never enable remote execution implicitly.

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/adapters/source/RemoteJarAdapter.ts entry/src/main/ets/domain/source/RemoteSpiderProtocol.ts entry/src/main/ets/pages/Settings.ets entry/src/main/ets/constants/HawkConfig.ts entry/src/test/RemoteJarAdapter.test.ets docs/remote-spider-protocol.md
git commit -m "feat: add remote Jar Spider compatibility"
```

### Task 13: Implement the FFmpeg compatibility player

**Files:**
- Create: `docs/superpowers/plans/2026-07-11-ffmpeg-player-runtime.md`
- Create: `native/ffmpeg_player/CMakeLists.txt`
- Create: `native/ffmpeg_player/include/ffmpeg_player.h`
- Create: `native/ffmpeg_player/src/`
- Create: `entry/src/main/ets/adapters/player/FfmpegPlayerAdapter.ts`
- Modify: `entry/src/main/ets/domain/playback/PlaybackSession.ts`
- Test: `entry/src/test/PlayerFallback.test.ets`

- [ ] **Step 1: Complete the rendering feasibility spike**

Decode bundled H.264/AAC media, render video through XComponent/NativeWindow, output audio through AudioRenderer, seek, pause, and release without leaks.

- [ ] **Step 2: Write the child implementation plan**

Lock FFmpeg version/configuration, LGPL/GPL choices, demux/decode threads, queues, clocks, buffer limits, hardware-decode probing, and error mapping.

- [ ] **Step 3: Implement adapter parity**

Support the shared source, header, track, subtitle, speed, aspect, seek, event, and release contract.

- [ ] **Step 4: Add deterministic fallback**

Use AVPlayer by default. Switch only after a classified unsupported-format/protocol failure or explicit user selection; never loop between players.

- [ ] **Step 5: Verify and commit**

Test HLS, DASH, RTSP, RTMP, FLV, TS, MKV, track selection, subtitles, network recovery, and two-hour playback.

```bash
git add native/ffmpeg_player entry/src/main/ets/adapters/player/FfmpegPlayerAdapter.ts entry/src/main/ets/domain/playback/PlaybackSession.ts entry/src/test/PlayerFallback.test.ets docs/superpowers/plans/*ffmpeg-player-runtime.md
git commit -m "feat: add FFmpeg compatibility player"
```

### Task 14: Add danmu and subtitle services

**Files:**
- Create: `entry/src/main/ets/domain/playback/DanmuManager.ts`
- Create: `entry/src/main/ets/domain/playback/SubtitleSearchService.ts`
- Create: `entry/src/main/ets/components/player/DanmuLayer.ets`
- Create: `entry/src/main/ets/components/player/SubtitleLayer.ets`
- Modify: `entry/src/main/ets/components/player/PlaybackControls.ets`
- Modify: `entry/src/main/ets/services/DriveService.ts`
- Test: `entry/src/test/DanmuTimeline.test.ets`
- Test: `entry/src/test/SubtitleMatch.test.ets`

- [ ] **Step 1: Add failing timeline and filename tests**

Cover pause, resume, seek, speed changes, duplicate danmu, SRT/VTT/ASS encoding, same-name subtitle ranking, and drive/local paths.

- [ ] **Step 2: Implement player-independent managers**

Managers receive clock events from `PlaybackSession`; they do not access AVPlayer or FFmpeg directly.

- [ ] **Step 3: Add TV controls and persisted styles**

Support visibility, opacity, font size, speed, region, subtitle offset, font size, color, and position.

- [ ] **Step 4: Verify and commit**

```bash
git add entry/src/main/ets/domain/playback/{DanmuManager,SubtitleSearchService}.ts entry/src/main/ets/components/player/{DanmuLayer,SubtitleLayer,PlaybackControls}.ets entry/src/main/ets/services/DriveService.ts entry/src/test/{DanmuTimeline,SubtitleMatch}.test.ets
git commit -m "feat: add synchronized danmu and subtitles"
```

### Task 15: Resolve P2P and special protocols

**Files:**
- Create: `docs/superpowers/plans/2026-07-11-p2p-runtime.md`
- Create: `docs/p2p-library-audit.md`
- Create: `native/p2p_runtime/`
- Create: `entry/src/main/ets/domain/playback/P2pSession.ts`
- Test: `entry/src/test/P2pLifecycle.test.ets`

- [ ] **Step 1: Audit before coding**

Record source availability, license, supported ABI, external symbols, storage behavior, network ports, and whether the Android library can legally and technically be rebuilt.

- [ ] **Step 2: Choose exactly one path**

Use a native port when source and license permit it; otherwise use an explicit external compatibility service. Do not ship opaque Android `.so` files as HarmonyOS libraries.

- [ ] **Step 3: Normalize output through local HTTP**

Expose start, pause, resume, progress, speed, local URL, stop, and cleanup. Route the local URL through `PlaybackSession`.

- [ ] **Step 4: Verify and commit**

Test task cancellation, cache quota, app exit, network loss, port release, and unsupported protocol errors.

```bash
git add docs/p2p-library-audit.md docs/superpowers/plans/*p2p-runtime.md native/p2p_runtime entry/src/main/ets/domain/playback/P2pSession.ts entry/src/test/P2pLifecycle.test.ets
git commit -m "feat: add P2P compatibility runtime"
```

### Task 16: Complete page-level parity

**Files:**
- Modify: `entry/src/main/ets/pages/Home.ets`
- Modify: `entry/src/main/ets/pages/Detail.ets`
- Modify: `entry/src/main/ets/pages/Search.ets`
- Modify: `entry/src/main/ets/pages/FastSearch.ets`
- Modify: `entry/src/main/ets/pages/History.ets`
- Modify: `entry/src/main/ets/pages/Favorites.ets`
- Modify: `entry/src/main/ets/pages/Live.ets`
- Modify: `entry/src/main/ets/pages/Drive.ets`
- Create: `entry/src/main/ets/components/common/`
- Create: `entry/src/test/PageState.test.ets`

- [ ] **Step 1: Create a page acceptance matrix**

Add `docs/verification/page-parity.md` mapping every retained Android action to implemented, substituted, or intentionally excluded HarmonyOS behavior.

- [ ] **Step 2: Complete home/detail/search slices**

Add filters, paging, layouts, site switching, detail preview, source search, description behavior, source selection, all/none actions, persistent search filters, remote keyboard, and incremental fast-search updates.

- [ ] **Step 3: Complete history/favorites/live/drive slices**

Add delete modes, confirmations, hidden live channels, controller overlays, player settings, system directory authorization, recursive search, and subtitle matching.

- [ ] **Step 4: Verify TV focus**

Replay all primary flows with only D-pad, OK, Back, Menu, and numeric keys. Record focus traps and fixes in `page-parity.md`.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/pages entry/src/main/ets/components/common entry/src/test/PageState.test.ets docs/verification/page-parity.md
git commit -m "feat: complete TV page parity"
```

### Task 17: Complete settings, backup, and data migration

**Files:**
- Modify: `entry/src/main/ets/pages/Settings.ets`
- Modify: `entry/src/main/ets/constants/HawkConfig.ts`
- Create: `entry/src/main/ets/repositories/`
- Create: `entry/src/main/ets/services/BackupService.ts`
- Create: `entry/src/main/ets/services/DnsService.ts`
- Test: `entry/src/test/BackupService.test.ets`
- Test: `entry/src/test/SettingsMigration.test.ets`

- [ ] **Step 1: Add failing backup and migration tests**

Cover manifest version, settings/history/favorites/search/drives round trip, default credential exclusion, optional secret export, older schema migration, corrupt archive rejection, and partial restore.

- [ ] **Step 2: Introduce repositories**

Move persistence ownership out of pages and keep existing Hawk-compatible keys. Repositories expose typed defaults and migrations.

- [ ] **Step 3: Complete settings**

Add config history, home/search/live/player options, DNS/DoH, theme, language, backup, restore, category-specific reset, and full reset. Keep application enumeration and privileged package APIs absent.

- [ ] **Step 4: Verify and commit**

```bash
git add entry/src/main/ets/pages/Settings.ets entry/src/main/ets/constants/HawkConfig.ts entry/src/main/ets/repositories entry/src/main/ets/services/{BackupService,DnsService}.ts entry/src/test/{BackupService,SettingsMigration}.test.ets
git commit -m "feat: complete settings and backup parity"
```

### Task 18: Run final stability and security verification

**Files:**
- Modify: `docs/android-parity.md`
- Modify: `docs/verification.md`
- Modify: `docs/verification/device-matrix.md`
- Create: `docs/verification/stability-report.md`
- Create: `docs/verification/security-review.md`
- Create: `scripts/verify-release.sh`

- [ ] **Step 1: Add release verification automation**

`scripts/verify-release.sh` must run dependency install, unit tests, static scans, release HAP build, native symbol checks, and package-size reporting, failing on any failed step.

- [ ] **Step 2: Execute stability scenarios**

Run two-hour VOD and live playback, 100 channel switches, 100 source switches, 50 player open/close cycles, network interruption, invalid configs, JS/Python infinite loops, repeated local-server start/stop, and backup migration.

- [ ] **Step 3: Execute security scenarios**

Test LAN control authentication, path traversal, oversized requests, script filesystem access, script network restrictions, secret redaction, Web bridge injection, and proxy header leakage.

- [ ] **Step 4: Reconcile parity documentation**

Mark an item complete only with device evidence. Record ordinary-app platform substitutions and keep the two excluded package-management features out of the target matrix.

- [ ] **Step 5: Run final verification**

```bash
./scripts/verify-release.sh
git diff --check
git status --short
```

Expected: release build and tests succeed; only intended documentation/report changes remain.

- [ ] **Step 6: Commit**

```bash
git add docs/android-parity.md docs/verification.md docs/verification scripts/verify-release.sh
git commit -m "docs: verify Android parity release"
```

## Program exit criteria

- All retained Android activity behaviors are implemented or have an approved ordinary-app substitution.
- Installed-app enumeration and privileged package-management APIs remain excluded.
- The default AVPlayer path and FFmpeg fallback share one control and persistence model.
- XML, JSON, type-4, JS, Python, and remote-Jar sources use one Spider contract.
- Header-sensitive playback, Web sniffing, `clan://localhost`, Spider proxying, inbound push, and remote control work end to end.
- Native runtimes pass lifecycle, timeout, memory, and resource-release tests on target devices.
- `docs/android-parity.md` links each completed capability to replayable verification evidence.
