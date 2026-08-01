import router from '@ohos.router';
import { KeyCode } from '@ohos.multimodalInput.keyCode';
import { HawkConfig } from '../constants/HawkConfig';
import { PlayerSurface } from '../components/player/PlayerSurface';
import { DanmuOverlay } from '../components/player/DanmuOverlay';
import { SubtitleOverlay } from '../components/player/SubtitleOverlay';
import { MediaSourceRequest, MediaTrack, ScaleNames, SpeedValues } from '../domain/playback/PlaybackModels';
import { PlaybackSession } from '../domain/playback/PlaybackSession';
import { PlayerConfig } from '../domain/playback/PlayerConfig';
import { nextEpisodeIndex, previousEpisodeIndex } from '../domain/playback/PlaybackOrder';
import { ParseBean, VodInfo, VodSeries } from '../models/TvBoxModels';
import { apiConfigService } from '../services/ApiConfigService';
import { appearanceService, PlayLabels, ThemePalette } from '../services/AppearanceService';
import { PlaybackResolveResult, playbackService } from '../services/PlaybackService';
import { DanmuConfig, DanmuItem, danmuService } from '../services/DanmuService';
import { SubtitleCue, subtitleService } from '../services/SubtitleService';
import { settingsStore } from '../services/SettingsStore';
import { vodDataStore } from '../services/VodDataStore';
import { asArray, asRecord, JsonNode, parseJson, safeString } from '../utils/JsonUtil';
import { errorMessage } from '../utils/ErrorUtil';

@Entry
@Component
struct Play {
  private session: PlaybackSession = new PlaybackSession();
  private resolveSeq: number = 0;
  private parseManuallySelected: boolean = false;
  private controlsTimer: number = -1;
  private skipEndArmed: boolean = true;

  @State sourceKey: string = '';
  @State vodId: string = '';
  @State playFlag: string = '';
  @State playIndex: number = 0;
  @State rawUrl: string = '';
  @State playUrl: string = '';
  @State title: string = '';
  @State episodeName: string = '';
  @State currentTimeMs: number = 0;
  @State durationMs: number = 0;
  @State isPlaying: boolean = true;
  @State statusText: string = '';
  @State errorText: string = '';
  @State parseStatus: string = '';
  @State parseWarning: string = '';
  @State resolving: boolean = false;
  @State selectedParseName: string = '';
  @State parses: ParseBean[] = [];
  @State recordVod: VodInfo | null = null;
  @State episodes: VodSeries[] = [];
  @State controlsVisible: boolean = true;
  @State panel: string = '';

  @State playerConfig: PlayerConfig = new PlayerConfig();
  @State speed: number = 1.0;
  @State scaleMode: number = 0;
  @State skipStartSeconds: number = 0;
  @State skipEndSeconds: number = 0;
  @State audioTracks: MediaTrack[] = [];
  @State subtitleTracks: MediaTrack[] = [];
  @State selectedAudioTrack: number = -1;
  @State selectedSubtitleTrack: number = -1;
  @State themeSelect: number = 0;
  @State screenDisplay: boolean = true;

  @State danmuItems: DanmuItem[] = [];
  @State danmuConfig: DanmuConfig = { open: true, maxLine: 3, speed: 1.5, alpha: 0.9, sizeScale: 0.8, randomColor: false };
  @State danmuVisible: boolean = false;
  @State subtitleCues: SubtitleCue[] = [];
  @State subtitleVisible: boolean = true;
  @State subtitleFontSize: number = 24;
  @State subtitleDelayMs: number = 0;
  @State subtitleStyleIndex: number = 0;

  aboutToAppear(): void {
    this.bindSession();
    this.initPage();
  }

  aboutToDisappear(): void {
    this.savePlaybackRecord();
    this.clearControlsTimer();
    this.session.release();
  }

  bindSession(): void {
    this.session.onTimeUpdate = (positionMs: number) => {
      this.currentTimeMs = positionMs;
      this.applySkipEnd();
    };
    this.session.onDurationUpdate = (durationMs: number) => {
      this.durationMs = durationMs;
    };
    this.session.onStateChange = (state: string) => {
      const l = this.labels();
      if (state === 'playing') {
        this.isPlaying = true;
        this.statusText = this.labels().playing;
        this.errorText = '';
      } else if (state === 'paused') {
        this.isPlaying = false;
        this.statusText = this.labels().paused;
      }
    };
    this.session.onEndOfStream = () => {
      this.isPlaying = false;
      this.statusText = this.labels().ended;
      this.playNextEpisode();
    };
    this.session.onError = (message: string) => {
      const l = this.labels();
      this.errorText = `${this.labels().failedPrefix}${message}`;
      this.statusText = this.labels().failed;
      this.isPlaying = false;
    };
    this.session.onTracksReady = (audio: MediaTrack[], subtitle: MediaTrack[]) => {
      this.audioTracks = audio;
      this.subtitleTracks = subtitle;
    };
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
    await appearanceService.init();
    this.themeSelect = await settingsStore.get<number>(HawkConfig.THEME_SELECT, 0);
    this.screenDisplay = await settingsStore.get<boolean>(HawkConfig.SCREEN_DISPLAY, true);
    this.title = this.labels().defaultTitle;
    this.statusText = this.labels().preparing;
    await this.loadDanmuConfig();
    await this.loadSubtitleConfig();
    await this.ensureConfigLoaded();
    const rawParams = router.getParams();
    const params = rawParams === undefined ? {} as Record<string, string> : rawParams as Record<string, string>;
    this.sourceKey = params['sourceKey'] === undefined ? '' : String(params['sourceKey']);
    this.vodId = params['vodId'] === undefined ? '' : String(params['vodId']);
    this.playFlag = params['playFlag'] === undefined ? '' : String(params['playFlag']);
    this.playIndex = this.toNumber(params['playIndex']);
    this.rawUrl = params['rawUrl'] === undefined ? '' : String(params['rawUrl']);
    const requestedPlayUrl = params['playUrl'] === undefined ? '' : String(params['playUrl']);
    if (this.rawUrl.length === 0) {
      this.rawUrl = requestedPlayUrl;
    }
    const requestedEpisodeName = params['episodeName'] === undefined ? '' : String(params['episodeName']);
    let playerCfgJson = params['playerCfg'] === undefined ? '' : String(params['playerCfg']);
    this.episodes = this.parseEpisodes(params['episodesJson']);

    const saved = this.sourceKey.length > 0 && this.vodId.length > 0
      ? vodDataStore.getVodInfo(this.sourceKey, this.vodId)
      : undefined;
    let resumeMs = 0;
    if (saved !== undefined) {
      this.recordVod = saved;
      this.title = saved.name;
      this.episodeName = requestedEpisodeName.length > 0
        ? requestedEpisodeName
        : saved.playNote === undefined ? this.playFlag : saved.playNote;
      if (this.rawUrl.length === 0 && saved.rawUrl !== undefined) {
        this.rawUrl = saved.rawUrl;
      }
      if (playerCfgJson.length === 0 && saved.playerCfg !== undefined) {
        playerCfgJson = saved.playerCfg;
      }
      if (this.episodes.length === 0 && saved.playFlag !== undefined && saved.seriesMap[saved.playFlag] !== undefined) {
        this.episodes = saved.seriesMap[saved.playFlag];
      }
      const sameEpisode = saved.playIndex === this.playIndex &&
        ((saved.rawUrl !== undefined && saved.rawUrl === this.rawUrl) ||
          saved.last === undefined ||
          saved.last.length === 0 ||
          saved.last === requestedPlayUrl);
      if (sameEpisode && saved.progress !== undefined && saved.progress > 0) {
        resumeMs = saved.progress;
      }
    } else {
      this.recordVod = this.createMinimalVod();
      this.episodeName = requestedEpisodeName.length > 0 ? requestedEpisodeName : this.playFlag;
    }

    await this.applyPlayerConfig(playerCfgJson);
    this.currentTimeMs = resumeMs;

    if (this.rawUrl.length === 0 && this.recordVod !== null && this.recordVod.rawUrl !== undefined) {
      this.rawUrl = this.recordVod.rawUrl;
    }
    if (this.rawUrl.length === 0 && this.recordVod !== null && this.recordVod.last !== undefined) {
      this.rawUrl = this.recordVod.last;
    }
    if (this.rawUrl.length === 0) {
      this.statusText = this.labels().missingUrl;
      this.errorText = this.labels().cannotPlayEmpty;
      this.isPlaying = false;
    } else {
      await this.resolveCurrentUrl();
    }
    this.scheduleHideControls();
  }

  /** Android `PlayFragment.initPlayerCfg()`: playerCfg wins, Hawk defaults fill the gaps. */
  async applyPlayerConfig(playerCfgJson: string): Promise<void> {
    const config = PlayerConfig.parse(playerCfgJson);
    if (playerCfgJson.length === 0) {
      config.scale = await settingsStore.get<number>(HawkConfig.PLAY_SCALE, 0);
      config.playerType = await settingsStore.get<number>(HawkConfig.PLAY_TYPE, 1);
      config.renderType = await settingsStore.get<number>(HawkConfig.PLAY_RENDER, 0);
      config.ijkCodec = await settingsStore.get<string>(HawkConfig.IJK_CODEC, '硬解码');
    }
    this.playerConfig = config;
    this.speed = config.speed;
    this.scaleMode = config.scale;
    this.skipStartSeconds = config.skipStartSeconds;
    this.skipEndSeconds = config.skipEndSeconds;
    this.session.setSpeed(this.speed);
    this.session.setScale(this.scaleMode);
  }

  async ensureConfigLoaded(): Promise<void> {
    if (Object.keys(apiConfigService.state.sourceBeanList).length === 0) {
      try {
        await apiConfigService.loadConfigFromSettings(true);
      } catch (_error) {
      }
    }
    this.parses = apiConfigService.state.parseBeanList;
    if (this.selectedParseName.length === 0 && apiConfigService.state.defaultParse !== undefined) {
      this.selectedParseName = apiConfigService.state.defaultParse.name;
    }
  }

  toNumber(value: string | undefined): number {
    if (value === undefined || value.length === 0) {
      return 0;
    }
    const parsed = Number(value);
    return Number.isFinite(parsed) ? Math.trunc(parsed) : 0;
  }

  parseEpisodes(value: string | undefined): VodSeries[] {
    if (value === undefined || value.length === 0) {
      return [];
    }
    try {
      const rows: JsonNode[] = asArray(parseJson(value));
      const result: VodSeries[] = [];
      for (const item of rows) {
        const row: Record<string, JsonNode> = asRecord(item);
        const url = safeString(row, 'url');
        if (url.length > 0) {
          result.push({
            name: safeString(row, 'name', `${this.labels().episodeFallbackPrefix}${result.length + 1}${this.labels().episodeFallbackSuffix}`),
            url
          });
        }
      }
      return result;
    } catch (_error) {
      return [];
    }
  }

  createMinimalVod(): VodInfo {
    return {
      id: this.vodId.length > 0 ? this.vodId : this.rawUrl,
      name: this.vodId.length > 0 ? this.vodId : this.labels().externalTitle,
      seriesFlags: [],
      seriesMap: {},
      playIndex: this.playIndex,
      playGroup: 0,
      playGroupCount: 0,
      playFlag: this.playFlag,
      playNote: this.episodeName,
      sourceKey: this.sourceKey
    };
  }

  togglePlay(): void {
    if (this.playUrl.length === 0 || this.resolving) {
      return;
    }
    if (this.isPlaying) {
      this.session.pause();
    } else {
      this.session.play();
    }
  }

  seekTo(positionMs: number): void {
    const target = positionMs < 0 ? 0 : positionMs;
    this.currentTimeMs = target;
    this.session.seek(target);
  }

  seekBy(deltaSeconds: number): void {
    this.seekTo(this.currentTimeMs + deltaSeconds * 1000);
  }

  /** Android `VodController.setProgress()` auto-advances when the ending-skip window is hit. */
  applySkipEnd(): void {
    if (!this.skipEndArmed || this.skipEndSeconds <= 0 || this.durationMs <= 0 || this.currentTimeMs <= 0) {
      return;
    }
    if (this.currentTimeMs + this.skipEndSeconds * 1000 >= this.durationMs) {
      this.skipEndArmed = false;
      this.playNextEpisode();
    }
  }

  playNextEpisode(): void {
    const next = nextEpisodeIndex(this.playIndex, this.episodes.length);
    if (next >= 0) {
      this.openEpisode(next);
    }
  }

  playPreviousEpisode(): void {
    const previous = previousEpisodeIndex(this.playIndex, this.episodes.length);
    if (previous >= 0) {
      this.openEpisode(previous);
    }
  }

  async openEpisode(index: number): Promise<void> {
    if (index < 0 || index >= this.episodes.length) {
      return;
    }
    const episode = this.episodes[index];
    this.savePlaybackRecord();
    this.playIndex = index;
    this.rawUrl = episode.url;
    this.playUrl = '';
    this.episodeName = episode.name;
    this.currentTimeMs = 0;
    this.durationMs = 0;
    this.errorText = '';
    this.parseWarning = '';
    this.parseStatus = '';
    this.isPlaying = true;
    this.skipEndArmed = true;
    this.audioTracks = [];
    this.subtitleTracks = [];
    this.danmuItems = [];
    this.subtitleCues = [];
    this.danmuVisible = false;
    this.subtitleVisible = false;
    await this.resolveCurrentUrl();
  }

  async selectParse(parse: ParseBean): Promise<void> {
    if (this.resolving) {
      return;
    }
    this.parseManuallySelected = true;
    this.selectedParseName = parse.name;
    await apiConfigService.setDefaultParse(parse);
    this.parses = apiConfigService.state.parseBeanList;
    await this.resolveCurrentUrl();
  }

  async setSpeed(value: number): Promise<void> {
    this.speed = value;
    this.session.setSpeed(value);
    this.playerConfig.speed = value;
    this.savePlaybackRecord();
  }

  async setScale(value: number): Promise<void> {
    this.scaleMode = value;
    this.session.setScale(value);
    this.playerConfig.scale = value;
    await settingsStore.put(HawkConfig.PLAY_SCALE, value);
    this.savePlaybackRecord();
  }

  setSkipStart(seconds: number): void {
    this.skipStartSeconds = seconds < 0 ? 0 : seconds;
    this.playerConfig.skipStartSeconds = this.skipStartSeconds;
    this.savePlaybackRecord();
  }

  setSkipEnd(seconds: number): void {
    this.skipEndSeconds = seconds < 0 ? 0 : seconds;
    this.playerConfig.skipEndSeconds = this.skipEndSeconds;
    this.savePlaybackRecord();
  }

  selectAudioTrack(track: MediaTrack): void {
    this.selectedAudioTrack = track.index;
    this.session.selectTrack(track.index);
  }

  selectSubtitleTrack(track: MediaTrack): void {
    if (this.selectedSubtitleTrack === track.index) {
      this.selectedSubtitleTrack = -1;
      this.session.deselectTrack(track.index);
      return;
    }
    this.selectedSubtitleTrack = track.index;
    this.session.selectTrack(track.index);
  }

  async resolveCurrentUrl(): Promise<void> {
    const l = this.labels();
    if (this.rawUrl.length === 0) {
      this.playUrl = '';
      this.statusText = this.labels().missingUrl;
      this.errorText = this.labels().cannotPlayEmpty;
      this.isPlaying = false;
      return;
    }
    const seq = this.resolveSeq + 1;
    this.resolveSeq = seq;
    this.resolving = true;
    this.playUrl = '';
    this.errorText = '';
    this.parseWarning = '';
    this.parseStatus = '';
    this.statusText = this.labels().resolving;
    try {
      const parseName = this.parseManuallySelected ? this.selectedParseName : '';
      const result = await playbackService.resolve(this.sourceKey, this.playFlag, this.rawUrl, parseName);
      if (seq !== this.resolveSeq) {
        return;
      }
      await this.applyResolveResult(result);
    } catch (error) {
      if (seq !== this.resolveSeq) {
        return;
      }
      this.parseWarning = this.labels().resolveFailedFallback;
      this.parseStatus = errorMessage(error as Error);
      this.errorText = this.parseStatus;
      this.statusText = this.labels().resolveFailed;
      await this.startPlayback(this.rawUrl, {});
    } finally {
      if (seq === this.resolveSeq) {
        this.resolving = false;
      }
    }
  }

  async applyResolveResult(result: PlaybackResolveResult): Promise<void> {
    this.parseStatus = result.status;
    this.parseWarning = result.warning === undefined ? '' : result.warning;
    this.statusText = result.status;
    this.errorText = '';
    await this.startPlayback(result.url, result.headers === undefined ? {} : result.headers);
    await this.loadDanmuAndSubtitle(result);
  }

  async loadDanmuAndSubtitle(result: PlaybackResolveResult): Promise<void> {
    this.danmuItems = [];
    this.subtitleCues = [];
    this.danmuVisible = false;
    this.subtitleVisible = false;
    const danmuSource = result.danmu === undefined ? '' : result.danmu;
    if (danmuSource.length > 0 && this.danmuConfig.open) {
      try {
        this.danmuItems = await danmuService.load(danmuSource);
        this.danmuVisible = this.danmuItems.length > 0;
      } catch (_error) {
      }
    }
    const subtSource = result.subt === undefined ? '' : result.subt;
    if (subtSource.length > 0) {
      try {
        this.subtitleCues = await subtitleService.load(subtSource);
        this.subtitleVisible = this.subtitleCues.length > 0;
      } catch (_error) {
      }
    }
  }

  /** Merges parse-returned headers with the `playerCfg` snapshot; parse results win. */
  async startPlayback(url: string, parseHeaders: Record<string, string>): Promise<void> {
    if (url.length === 0) {
      return;
    }
    this.playUrl = url;
    this.skipEndArmed = true;
    const headers: Record<string, string> = {};
    for (const key of Object.keys(this.playerConfig.headers)) {
      headers[key] = this.playerConfig.headers[key];
    }
    for (const key of Object.keys(parseHeaders)) {
      headers[key] = parseHeaders[key];
    }
    const startMs = this.currentTimeMs > 0 ? this.currentTimeMs : this.skipStartSeconds * 1000;
    await this.session.setSource(new MediaSourceRequest(url, headers, startMs));
    this.isPlaying = true;
  }

  isParseSelected(parse: ParseBean): boolean {
    if (this.selectedParseName.length > 0) {
      return parse.name === this.selectedParseName;
    }
    return parse.isDefault;
  }

  savePlaybackRecord(): void {
    if (this.sourceKey.length === 0 || this.vodId.length === 0 || (this.playUrl.length === 0 && this.rawUrl.length === 0)) {
      return;
    }
    const base = this.recordVod === null
      ? this.createMinimalVod()
      : JSON.parse(JSON.stringify(this.recordVod)) as VodInfo;
    base.id = this.vodId;
    base.playFlag = this.playFlag;
    base.playIndex = this.playIndex;
    base.playNote = this.episodeName;
    base.progress = this.currentTimeMs;
    base.duration = this.durationMs;
    base.rawUrl = this.rawUrl.length > 0 ? this.rawUrl : this.playUrl;
    base.last = this.playUrl.length > 0 ? this.playUrl : this.rawUrl;
    base.sourceKey = this.sourceKey;
    base.playerCfg = this.playerConfig.stringify();
    vodDataStore.insertVodRecord(this.sourceKey, base);
  }

  formatTime(milliseconds: number): string {
    const totalSeconds = Number.isFinite(milliseconds) && milliseconds > 0 ? Math.floor(milliseconds / 1000) : 0;
    const hour = Math.floor(totalSeconds / 3600);
    const minute = Math.floor((totalSeconds % 3600) / 60);
    const second = totalSeconds % 60;
    const mm = minute < 10 ? `0${minute}` : `${minute}`;
    const ss = second < 10 ? `0${second}` : `${second}`;
    return hour > 0 ? `${hour}:${mm}:${ss}` : `${mm}:${ss}`;
  }

  showControls(): void {
    this.controlsVisible = true;
    this.scheduleHideControls();
  }

  scheduleHideControls(): void {
    this.clearControlsTimer();
    this.controlsTimer = setTimeout(() => {
      if (this.panel.length === 0) {
        this.controlsVisible = false;
      }
    }, 5000);
  }

  clearControlsTimer(): void {
    if (this.controlsTimer !== -1) {
      clearTimeout(this.controlsTimer);
      this.controlsTimer = -1;
    }
  }

  togglePanel(name: string): void {
    this.panel = this.panel === name ? '' : name;
    this.showControls();
  }

  theme(): ThemePalette {
    return appearanceService.themeByIndex(this.themeSelect);
  }

  labels(): PlayLabels {
    return appearanceService.playLabels();
  }

  async loadDanmuConfig(): Promise<void> {
    this.danmuConfig = {
      open: await settingsStore.get<boolean>(HawkConfig.DANMU_OPEN, true),
      maxLine: await settingsStore.get<number>(HawkConfig.DANMU_MAXLINE, 3),
      speed: await settingsStore.get<number>(HawkConfig.DANMU_SPEED, 1.5),
      alpha: await settingsStore.get<number>(HawkConfig.DANMU_ALPHA, 0.9),
      sizeScale: await settingsStore.get<number>(HawkConfig.DANMU_SIZESCALE, 0.8),
      randomColor: await settingsStore.get<boolean>(HawkConfig.DANMU_COLOR, false)
    };
  }

  async loadSubtitleConfig(): Promise<void> {
    this.subtitleFontSize = await settingsStore.get<number>(HawkConfig.SUBTITLE_TEXT_SIZE, 24);
    this.subtitleDelayMs = await settingsStore.get<number>(HawkConfig.SUBTITLE_TIME_DELAY, 0) * 1000;
    this.subtitleStyleIndex = await settingsStore.get<number>(HawkConfig.SUBTITLE_TEXT_STYLE, 0);
  }

  toggleDanmu(): void {
    this.danmuVisible = !this.danmuVisible;
  }

  toggleScreenDisplay(): void {
    this.screenDisplay = !this.screenDisplay;
    settingsStore.put(HawkConfig.SCREEN_DISPLAY, this.screenDisplay);
  }

  toggleSubtitle(): void {
    this.subtitleVisible = !this.subtitleVisible;
  }

  async toggleDanmuOpen(): Promise<void> {
    const c = this.danmuConfig;
    this.danmuConfig = {
      open: !c.open,
      maxLine: c.maxLine,
      speed: c.speed,
      alpha: c.alpha,
      sizeScale: c.sizeScale,
      randomColor: c.randomColor
    };
    await settingsStore.put(HawkConfig.DANMU_OPEN, this.danmuConfig.open);
    this.danmuVisible = this.danmuConfig.open && this.danmuItems.length > 0;
  }

  /** Android `VodController` D-pad mapping: left/right seek, up/down episode, OK play/pause. */
  handleKey(event: KeyEvent): void {
    if (event.type !== KeyType.Down) {
      return;
    }
    this.showControls();
    if (event.keyCode === KeyCode.KEYCODE_DPAD_LEFT) {
      this.seekBy(-10);
    } else if (event.keyCode === KeyCode.KEYCODE_DPAD_RIGHT) {
      this.seekBy(10);
    } else if (event.keyCode === KeyCode.KEYCODE_DPAD_UP) {
      this.playPreviousEpisode();
    } else if (event.keyCode === KeyCode.KEYCODE_DPAD_DOWN) {
      this.playNextEpisode();
    } else if (event.keyCode === KeyCode.KEYCODE_ENTER || event.keyCode === KeyCode.KEYCODE_DPAD_CENTER) {
      this.togglePlay();
    } else if (event.keyCode === KeyCode.KEYCODE_BACK) {
      if (this.panel.length > 0) {
        this.panel = '';
      } else {
        router.back();
      }
    }
  }

  @Builder
  chip(label: string, active: boolean, action: () => void) {
    Text(label)
      .fontSize(13)
      .fontColor(this.theme().text)
      .padding({ left: 12, right: 12, top: 7, bottom: 7 })
      .margin({ right: 8, top: 8 })
      .backgroundColor(active ? this.theme().primary : this.theme().panelBg)
      .borderRadius(8)
      .focusable(true)
      .onClick(action)
  }

  @Builder
  settingsPanel() {
    Column() {
      if (this.panel === 'speed') {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(SpeedValues, (value: number) => {
            this.chip(`${value}X`, Math.abs(this.speed - value) < 0.001, () => this.setSpeed(value))
          }, (value: number) => `speed-${value}`)
        }
      } else if (this.panel === 'scale') {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(ScaleNames, (name: string, index: number) => {
            this.chip(name, this.scaleMode === index, () => this.setScale(index))
          }, (name: string) => `scale-${name}`)
        }
      } else if (this.panel === 'skip') {
        Column() {
          Row() {
            Text(`${this.labels().skipStartPrefix}${this.skipStartSeconds}s`).fontSize(14).fontColor(this.theme().text).layoutWeight(1)
            Button(this.labels().minusSeconds).height(34).onClick(() => this.setSkipStart(this.skipStartSeconds - 30))
            Button(this.labels().plusSeconds).height(34).margin({ left: 8 }).onClick(() => this.setSkipStart(this.skipStartSeconds + 30))
            Button(this.labels().setToCurrent).height(34).margin({ left: 8 })
              .onClick(() => this.setSkipStart(Math.floor(this.currentTimeMs / 1000)))
          }.width('100%').alignItems(VerticalAlign.Center)
          Row() {
            Text(`${this.labels().skipEndPrefix}${this.skipEndSeconds}s`).fontSize(14).fontColor(this.theme().text).layoutWeight(1)
            Button(this.labels().minusSeconds).height(34).onClick(() => this.setSkipEnd(this.skipEndSeconds - 30))
            Button(this.labels().plusSeconds).height(34).margin({ left: 8 }).onClick(() => this.setSkipEnd(this.skipEndSeconds + 30))
            Button(this.labels().setToRemaining).height(34).margin({ left: 8 })
              .onClick(() => this.setSkipEnd(Math.floor((this.durationMs - this.currentTimeMs) / 1000)))
          }.width('100%').alignItems(VerticalAlign.Center).margin({ top: 10 })
        }.width('100%')
      } else if (this.panel === 'track') {
        Column() {
          Text(this.labels().audioTrack).fontSize(14).fontColor(this.theme().mutedText).width('100%')
          if (this.audioTracks.length === 0) {
            Text(this.labels().noAudioTrack).fontSize(13).fontColor(this.theme().subtleText).width('100%').margin({ top: 6 })
          } else {
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.audioTracks, (track: MediaTrack) => {
                this.chip(track.label, this.selectedAudioTrack === track.index, () => this.selectAudioTrack(track))
              }, (track: MediaTrack) => `audio-${track.index}`)
            }
          }
          Text(this.labels().subtitle).fontSize(14).fontColor(this.theme().mutedText).width('100%').margin({ top: 12 })
          if (this.subtitleTracks.length === 0) {
            Text(this.labels().noSubtitle).fontSize(13).fontColor(this.theme().subtleText).width('100%').margin({ top: 6 })
          } else {
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.subtitleTracks, (track: MediaTrack) => {
                this.chip(track.label, this.selectedSubtitleTrack === track.index, () => this.selectSubtitleTrack(track))
              }, (track: MediaTrack) => `sub-${track.index}`)
            }
          }
        }.width('100%')
      } else if (this.panel === 'episode') {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.episodes, (episode: VodSeries, index: number) => {
            this.chip(episode.name, this.playIndex === index, () => this.openEpisode(index))
          }, (episode: VodSeries) => `ep-${episode.url}`)
        }
      } else if (this.panel === 'parse') {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.parses, (parse: ParseBean) => {
            this.chip(parse.name, this.isParseSelected(parse), () => this.selectParse(parse))
          }, (parse: ParseBean) => `parse-${parse.name}`)
        }
      }
    }
    .width('100%')
    .padding({ top: 10, bottom: 4 })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        PlayerSurface({ session: this.session })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)

      DanmuOverlay({
        session: this.session,
        items: this.danmuItems,
        config: this.danmuConfig,
        visible: this.danmuVisible
      })

      SubtitleOverlay({
        session: this.session,
        cues: this.subtitleCues,
        visible: this.subtitleVisible,
        fontSize: this.subtitleFontSize,
        delayMs: this.subtitleDelayMs,
        styleIndex: this.subtitleStyleIndex
      })

      if (this.playUrl.length === 0) {
        Column() {
          Text(this.resolving ? this.labels().resolvingUrl : this.labels().noUrl)
            .fontSize(30)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.theme().text)
          Text(this.errorText.length > 0 ? this.errorText : this.rawUrl)
            .fontSize(16)
            .fontColor('#fca5a5')
            .margin({ top: 12 })
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }

      if (this.controlsVisible) {
        Column() {
          if (this.screenDisplay) {
            Row() {
              Text(this.labels().back)
                .fontSize(18)
                .fontColor(this.theme().text)
                .focusable(true)
                .onClick(() => router.back())
              Column() {
                Text(this.title)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.theme().text)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`${this.playFlag} ${this.episodeName}`)
                  .fontSize(14)
                  .fontColor(this.theme().text)
                  .margin({ top: 4 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .margin({ left: 24 })
              Text(this.statusText)
                .fontSize(14)
                .fontColor(this.errorText.length > 0 ? '#fca5a5' : this.theme().primarySoft)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)

            if (this.parseStatus.length > 0 || this.parseWarning.length > 0) {
              Text(this.parseWarning.length > 0 ? `${this.parseStatus}（${this.parseWarning}）` : this.parseStatus)
                .fontSize(13)
                .fontColor(this.parseWarning.length > 0 ? '#fbbf24' : this.theme().text)
                .margin({ top: 10 })
                .width('100%')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
          }

          if (this.panel.length > 0) {
            this.settingsPanel()
          }

          Row() {
            Text(this.formatTime(this.currentTimeMs))
              .fontSize(14)
              .fontColor(this.theme().text)
            Slider({
              value: this.currentTimeMs,
              min: 0,
              max: this.durationMs > 0 ? this.durationMs : 1,
              step: 1000
            })
              .layoutWeight(1)
              .margin({ left: 14, right: 14 })
              .selectedColor(this.theme().primarySoft)
              .trackColor(this.theme().cardActiveBg)
              .blockColor(Color.White)
              .onChange((value: number, mode: SliderChangeMode) => {
                this.currentTimeMs = value;
                if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
                  this.seekTo(value);
                }
              })
            Text(this.formatTime(this.durationMs))
              .fontSize(14)
              .fontColor(this.theme().text)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ top: 14 })

          Row() {
            Button(this.isPlaying ? this.labels().pause : this.labels().play)
              .height(40)
              .enabled(this.playUrl.length > 0 && !this.resolving)
              .onClick(() => this.togglePlay())
            Button(this.labels().prevEpisode)
              .height(40)
              .margin({ left: 10 })
              .enabled(this.playIndex > 0 && this.episodes.length > 0 && !this.resolving)
              .onClick(() => this.playPreviousEpisode())
            Button(this.labels().nextEpisode)
              .height(40)
              .margin({ left: 10 })
              .enabled(this.playIndex + 1 < this.episodes.length && !this.resolving)
              .onClick(() => this.playNextEpisode())
            Button(`${this.labels().selectEpisodePrefix}${this.episodes.length}`)
              .height(40)
              .margin({ left: 10 })
              .enabled(this.episodes.length > 0)
              .onClick(() => this.togglePanel('episode'))
            Button(`${this.speed}X`)
              .height(40)
              .margin({ left: 10 })
              .onClick(() => this.togglePanel('speed'))
            Button(ScaleNames[this.scaleMode])
              .height(40)
              .margin({ left: 10 })
              .onClick(() => this.togglePanel('scale'))
            Button(this.labels().trackSubtitle)
              .height(40)
              .margin({ left: 10 })
              .onClick(() => this.togglePanel('track'))
            Button(this.labels().skipIntroOutro)
              .height(40)
              .margin({ left: 10 })
              .onClick(() => this.togglePanel('skip'))
            if (this.danmuItems.length > 0) {
              Button(this.danmuVisible ? this.labels().danmuOn : this.labels().danmuOff)
                .height(40)
                .margin({ left: 10 })
                .backgroundColor(this.danmuVisible ? this.theme().primary : this.theme().cardActiveBg)
                .onClick(() => this.toggleDanmu())
            }
            if (this.subtitleCues.length > 0) {
              Button(this.subtitleVisible ? this.labels().subtitleOn : this.labels().subtitleOff)
                .height(40)
                .margin({ left: 10 })
                .backgroundColor(this.subtitleVisible ? this.theme().primary : this.theme().cardActiveBg)
                .onClick(() => this.toggleSubtitle())
            }
            Button(this.labels().parse)
              .height(40)
              .margin({ left: 10 })
              .enabled(this.parses.length > 0)
              .onClick(() => this.togglePanel('parse'))
            Button(this.labels().screenDisplay)
              .height(40)
              .margin({ left: 10 })
              .backgroundColor(this.screenDisplay ? this.theme().primary : this.theme().cardActiveBg)
              .onClick(() => this.toggleScreenDisplay())
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ top: 14 })
        }
        .width('100%')
        .padding({ left: 48, right: 48, top: 24, bottom: 30 })
        .backgroundColor('#b3000000')
      }
    }
    .width('100%')
    .height('100%')
    .focusable(true)
    .defaultFocus(true)
    .onKeyEvent((event: KeyEvent) => this.handleKey(event))
    .onClick(() => this.showControls())
  }
}
