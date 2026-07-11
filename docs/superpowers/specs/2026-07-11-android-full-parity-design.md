# TVBox HarmonyOS Android Full-Parity Design

## 1. Goal and scope

Bring the HarmonyOS NEXT application as close as practical to the Android project at `/Users/jwli/workspace/github/tvbox`, including advanced source runtimes, parsing, playback, local proxy, remote control, subtitles, danmu, and special protocols.

The target is a normal HarmonyOS application. Native C/C++ NAPI modules and third-party HarmonyOS dependencies are allowed. The following Android package-management features are explicitly excluded:

- Enumerating all installed applications.
- Privileged package-management APIs.

The Apps page will only manage manually configured Bundle/Ability/Module launch entries and may open public system settings where supported.

## 2. Current parity assessment

### 2.1 Implemented baseline

- Android-compatible settings keys and core defaults.
- TVBox JSON configuration loading, cache fallback, encrypted configuration decoding, and relative URL rewriting.
- XML, JSON, and type-4 HTTP source support for home, category, detail, search, and playback entry.
- Basic home, detail, search, fast search, history, favorites, settings, push, drive, apps, play, and live pages.
- Direct playback, pause/resume, seek, previous/next episode, progress restore, and history persistence.
- Live M3U/TXT parsing, channel groups, multiple channel URLs, numeric switching, EPG, logo aliases, time-shift URL generation, and live header-rule matching.
- Local, Alist, and WebDAV drive records and browsing.
- Outbound TVBox-compatible URL push.

### 2.2 Partial areas

- XML/JSON/type-4 sources lack complete filters, paging, sorting, extension-field, and malformed-response compatibility.
- Search lacks the complete source selection, all/none actions, persistent filters, remote keyboard, and Android display modes.
- Fast search lacks true parallel incremental updates and detailed per-source state.
- Detail lacks preview playback, source search, and complete Android interaction behavior.
- Playback headers are retained as metadata but are not injected into the player.
- Parse selection covers only the initial JSON/type-4 flow and not the complete Android parse matrix.
- Live supports the primary flow but lacks hidden channels, player-kernel mapping, header injection, and complete controller overlays.
- Drive browsing lacks system picker authorization, recursive search, subtitle matching, and real playback-header injection.
- Settings exposes only a small subset of Android options.

### 2.3 Missing subsystems

- Type-3 Spider runtime.
- QuickJS Spider runtime and JS bridge APIs.
- Python Spider runtime.
- Java/Jar Spider compatibility path.
- Web component sniffing and parse-rule execution.
- Local HTTP/WebSocket proxy and remote-control server.
- `clan://localhost` and Spider `proxy()` support.
- FFmpeg-compatible fallback player.
- Subtitle, audio-track, danmu, aspect-ratio, speed, skip-intro/outro, background playback, and PiP controls.
- P2P/Thunder and other special-protocol adapters.
- DNS/DoH, configuration history, backup/restore, reset, theme, and language parity.

## 3. Architecture

Use vertical delivery slices over a layered compatibility architecture:

```text
ArkUI Pages
  Home / Detail / Search / Play / Live / Settings / Drive / Push
                         |
Domain Services
  SourceEngine / PlaybackEngine / SearchEngine / LiveEngine
  DriveEngine / RemoteControlEngine
                         |
Compatibility Runtime
  ConfigCompat / SpiderRuntime / ParseRuntime / ProxyRuntime
  SubtitleRuntime / DanmuRuntime
                         |
             +-----------+-----------+
             |                       |
HarmonyOS Adapters                Native NAPI Modules
AVPlayer, Web, Want,              QuickJS, Python, FFmpeg,
Preferences, FilePicker           local server, P2P
```

Pages must not directly depend on source runtime, native runtime, or player implementation details.

## 4. Source compatibility runtime

Define one source contract for all source types:

```ts
interface SpiderAdapter {
  init(ext: string): Promise<void>;
  home(filter: boolean): Promise<HomeResult>;
  homeVideo(): Promise<VodItem[]>;
  category(typeId: string, page: number, filter: FilterMap): Promise<CategoryResult>;
  detail(vodId: string): Promise<VodDetail>;
  search(keyword: string, quick: boolean, page: number): Promise<SearchResult>;
  player(flag: string, id: string, vipFlags: string[]): Promise<PlayerResult>;
  proxy(params: ProxyRequest): Promise<ProxyResponse>;
}
```

Implementations:

- `HttpSourceAdapter` for XML, JSON, and type-4 HTTP sources.
- `JsSpiderAdapter` backed by QuickJS NAPI.
- `PythonSpiderAdapter` backed by an embedded Python runtime.
- `RemoteJarAdapter` for Android Jar-only sources.
- `NativeSpiderAdapter` for future HarmonyOS-native sources.

Android Jar code will not execute inside the HarmonyOS process. Jar-only sources will use an optional authenticated LAN or user-hosted compatibility service using the same Spider contract.

JS and Python scripts are untrusted. Each runtime must enforce memory limits, timeouts, cancellable work, restricted file access, controlled network APIs, and isolated error reporting.

## 5. Playback architecture

Replace direct page use of ArkUI `Video` with a player abstraction:

```ts
interface MediaPlayerAdapter {
  setSource(source: MediaSource): Promise<void>;
  prepare(): Promise<void>;
  play(): void;
  pause(): void;
  seek(positionMs: number): void;
  selectAudioTrack(trackId: string): void;
  selectSubtitleTrack(trackId: string): void;
  setScaleMode(mode: ScaleMode): void;
  setSpeed(speed: number): void;
  release(): void;
}
```

Initial adapters:

- `AvPlayerAdapter`: default implementation using the official HarmonyOS player APIs.
- `FfmpegPlayerAdapter`: NAPI fallback for unsupported containers, codecs, and protocols.
- `ExternalPlayerAdapter`: optional Want-based launch for user-configured external players.

Shared playback services will provide header and cookie injection, parse fallback, history, automatic next episode, subtitle and audio-track management, danmu synchronization, aspect ratio, speed, skip-intro/outro, and capability-gated background/PiP behavior.

The settings UI will use the terms "system player" and "compatibility player" instead of copying Android IJK/Exo/Ali labels. Only portable Android player options will be mapped.

## 6. Web sniffing and parsing

Use a controlled HarmonyOS `Web` component to discover media URLs:

- Observe fetch, XHR, navigation, video, and audio requests.
- Apply configured `rules`, `ads`, `flags`, and media suffix recognition.
- Carry cookies, headers, referers, and redirects into the playback result.
- Support parse types 0 through 4, SuperParse behavior, priority, automatic rotation, timeout, cancellation, and cleanup.
- Send header-sensitive results through the local proxy instead of exposing credentials in page state.

The Web component discovers media only; playback remains in the player layer.

## 7. Local server and proxy

Provide an isolated NAPI HTTP/WebSocket runtime for:

- `clan://localhost` routing.
- Spider `proxy()` output.
- Header/cookie forwarding.
- M3U8 and segment URL rewriting.
- P2P-to-local-HTTP conversion.
- TVBox-compatible `/action` and `/api/updateUrl` receive endpoints.
- Remote input, search, playback, seek, and state APIs.
- A Web remote-control page and QR entry.

The server will bind to loopback by default and expose LAN mode only when enabled. LAN control requires a temporary token, request rate limits, file-path allowlists, and lifecycle cleanup. It will not expose shell execution.

## 8. Native module boundaries

Keep native capabilities independently buildable:

```text
native/quickjs_runtime
native/python_runtime
native/ffmpeg_player
native/local_server
native/p2p_runtime
```

Each module needs a small NAPI surface, explicit ownership rules, a documented thread model, cancellation, timeouts, stable error codes, and resource cleanup. Arm64 is the primary ABI.

## 9. Persistence and backup

Retain Android-compatible Hawk key names and add repositories for settings, history, favorites, search history, drives, and configuration cache.

Use a versioned backup archive:

```text
tvbox-backup.zip
  manifest.json
  settings.json
  history.json
  favorites.json
  search-history.json
  drives.json
  config-cache/
```

Credentials are excluded by default. WebDAV and similar secrets are exported only after explicit user selection.

## 10. Delivery phases

### Phase 0: Build and verification baseline (1-2 weeks)

- Fix the current HarmonyOS SDK/toolchain build blocker.
- Pin DevEco, SDK, NDK, CMake, and package versions.
- Add unit, module, device smoke, and reproducible static checks.
- Split oversized Play, Live, and Drive pages along component/service boundaries.

### Phase 1: Complete official-player path (3-4 weeks)

- Add the player abstraction and AVPlayer adapter.
- Inject request headers and cookies.
- Add parse fallback, auto-next, order-safe navigation, speed, ratio, audio tracks, subtitles, media session, background, and PiP capability handling.
- Route VOD, live, and drive playback through the same layer.

### Phase 2: Complete parse matrix and Web sniffing (3-4 weeks)

- Implement parse types 0-4 and SuperParse behavior.
- Add controlled Web request observation, rule filtering, timeout, cancellation, result validation, and cleanup.

### Phase 3: Local proxy and remote control (3-4 weeks)

- Add the native HTTP/WebSocket service.
- Implement local proxying, `clan://localhost`, receive endpoints, Web control, QR entry, tokens, allowlists, and rate limits.

### Phase 4: JavaScript Spider (4-6 weeks)

- Port QuickJS to HarmonyOS arm64.
- Add the NAPI lifecycle and common TVBox JS bridge APIs.
- Integrate source, player, and proxy methods.
- Validate at least ten structurally different JS sources.

### Phase 5: Python Spider (5-8 weeks)

- Embed a HarmonyOS-compatible Python runtime and standard library.
- Bridge the Android pyramid-style contract.
- Support pure-Python sources and a controlled dependency allowlist.
- Convert Python failures into stable ArkTS errors.

Binary Python extensions that cannot be rebuilt for HarmonyOS are not guaranteed.

### Phase 6: Jar compatibility service integration (2-3 weeks)

- Define the remote Spider protocol and authentication.
- Add service health, timeout, retry, configuration, and proxy forwarding.
- Keep failures isolated from non-Jar source types.

This estimate excludes implementation of the separate JVM compatibility server.

### Phase 7: FFmpeg compatibility player (6-10 weeks)

- Build FFmpeg for HarmonyOS arm64.
- Implement demuxing, decoding, synchronization, XComponent/NativeWindow rendering, AudioRenderer output, seeking, tracks, subtitles, headers, proxy protocols, buffering, reconnect, and cleanup.
- Expose it through `MediaPlayerAdapter`.

### Phase 8: Danmu and advanced playback controls (2-3 weeks)

- Add timeline-based danmu rendering and synchronization.
- Add subtitle search, encoding detection, offset, style, and local/drive filename matching.
- Complete remote-control playback focus behavior.

### Phase 9: P2P and special protocols (4-8 weeks)

- Audit source availability and licensing of the Android native libraries.
- Port source-available libraries or use an external compatibility service.
- Expose streams through local HTTP and enforce cache limits and cleanup.

### Phase 10: Page and settings parity (4-6 weeks)

- Complete home filters, paging, layouts, and site switching.
- Complete detail preview, source search, description, and series behavior.
- Complete search source selection, display modes, incremental fast search, and remote keyboard.
- Complete history/favorites delete modes, live hidden channels, drive authorization and recursive search, DNS/DoH, config history, theme, language, backup/restore, and reset.
- Keep Apps limited to manually configured launch entries.

### Phase 11: Stability and release verification (3-4 weeks)

- Test TV, tablet, and phone layouts.
- Run long-play, channel-switching, source-switching, network-failure, script-timeout, and native-resource stress tests.
- Audit local-server security, script sandboxes, file access, credentials, migrations, and package size.

## 11. Acceptance strategy

Each phase must produce a runnable vertical slice and a replayable verification note. A feature is complete only when:

- The Android reference behavior and accepted HarmonyOS substitutions are documented.
- Remote-control operation works without touch for TV-critical paths.
- Loading, empty, failure, cancellation, and recovery states are covered.
- Native resources, ports, tasks, Web instances, and player instances are released.
- Target-device behavior is verified; static inspection alone is insufficient.

The estimated serial effort is 40-58 person-weeks. With two or three experienced developers, the expected calendar duration is approximately five to eight months. Python, FFmpeg, P2P, and the external Jar service are the largest uncertainty areas.
