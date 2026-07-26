import router from '@ohos.router';
import { ParseBean, VodInfo, VodSeries } from '../models/TvBoxModels';
import { apiConfigService } from '../services/ApiConfigService';
import { PlaybackResolveResult, playbackService } from '../services/PlaybackService';
import { settingsStore } from '../services/SettingsStore';
import { vodDataStore } from '../services/VodDataStore';
import { asArray, asRecord, JsonNode, parseJson, safeString } from '../utils/JsonUtil';
import { errorMessage } from '../utils/ErrorUtil';

@Entry
@Component
struct Play {
  private controller: VideoController = new VideoController();
  private resolveSeq: number = 0;
  private parseManuallySelected: boolean = false;

  @State sourceKey: string = '';
  @State vodId: string = '';
  @State playFlag: string = '';
  @State playIndex: number = 0;
  @State rawUrl: string = '';
  @State playUrl: string = '';
  @State title: string = '播放';
  @State episodeName: string = '';
  @State currentTime: number = 0;
  @State duration: number = 0;
  @State isPlaying: boolean = true;
  @State statusText: string = '准备播放';
  @State errorText: string = '';
  @State parseStatus: string = '';
  @State parseWarning: string = '';
  @State playerCfg: string = '';
  @State resolving: boolean = false;
  @State selectedParseName: string = '';
  @State parses: ParseBean[] = [];
  @State recordVod: VodInfo | null = null;
  @State episodes: VodSeries[] = [];

  aboutToAppear(): void {
    this.initPage();
  }

  aboutToDisappear(): void {
    this.savePlaybackRecord();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
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
    this.playUrl = requestedPlayUrl;
    const requestedEpisodeName = params['episodeName'] === undefined ? '' : String(params['episodeName']);
    this.playerCfg = params['playerCfg'] === undefined ? '' : String(params['playerCfg']);
    this.episodes = this.parseEpisodes(params['episodesJson']);

    const saved = this.sourceKey.length > 0 && this.vodId.length > 0
      ? vodDataStore.getVodInfo(this.sourceKey, this.vodId)
      : undefined;
    if (saved !== undefined) {
      this.recordVod = saved;
      this.title = saved.name;
      this.episodeName = requestedEpisodeName.length > 0
        ? requestedEpisodeName
        : saved.playNote === undefined ? this.playFlag : saved.playNote;
      if (this.rawUrl.length === 0 && saved.rawUrl !== undefined) {
        this.rawUrl = saved.rawUrl;
      }
      if (this.playerCfg.length === 0 && saved.playerCfg !== undefined) {
        this.playerCfg = saved.playerCfg;
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
        this.currentTime = saved.progress;
      }
    } else {
      this.recordVod = this.createMinimalVod();
      this.episodeName = requestedEpisodeName.length > 0 ? requestedEpisodeName : this.playFlag;
    }

    if (this.rawUrl.length === 0 && this.recordVod !== null && this.recordVod.rawUrl !== undefined) {
      this.rawUrl = this.recordVod.rawUrl;
    }
    if (this.rawUrl.length === 0 && this.recordVod !== null && this.recordVod.last !== undefined) {
      this.rawUrl = this.recordVod.last;
    }
    if (this.rawUrl.length === 0) {
      this.statusText = '缺少播放地址';
      this.errorText = '无法播放：playUrl 为空';
      this.isPlaying = false;
    } else {
      await this.resolveCurrentUrl();
    }
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
            name: safeString(row, 'name', `第${result.length + 1}集`),
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
      name: this.vodId.length > 0 ? this.vodId : '外部播放',
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
      this.controller.pause();
      this.isPlaying = false;
      this.statusText = '已暂停';
    } else {
      this.controller.start();
      this.isPlaying = true;
      this.statusText = '正在播放';
    }
  }

  seekTo(value: number): void {
    const target = value < 0 ? 0 : value;
    this.currentTime = target;
    this.controller.setCurrentTime(target, SeekMode.ClosestKeyframe);
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
    this.currentTime = 0;
    this.duration = 0;
    this.errorText = '';
    this.parseWarning = '';
    this.parseStatus = '';
    this.isPlaying = true;
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

  async resolveCurrentUrl(): Promise<void> {
    if (this.rawUrl.length === 0) {
      this.playUrl = '';
      this.statusText = '缺少播放地址';
      this.errorText = '无法播放：playUrl 为空';
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
    this.statusText = '解析中';
    try {
      const parseName = this.parseManuallySelected ? this.selectedParseName : '';
      const result = await playbackService.resolve(this.sourceKey, this.playFlag, this.rawUrl, parseName);
      if (seq !== this.resolveSeq) {
        return;
      }
      this.applyResolveResult(result);
    } catch (error) {
      if (seq !== this.resolveSeq) {
        return;
      }
      this.playUrl = this.rawUrl;
      this.parseWarning = '解析失败，暂用原始地址';
      this.parseStatus = errorMessage(error);
      this.errorText = this.parseStatus;
      this.statusText = '解析失败';
      this.isPlaying = true;
    } finally {
      if (seq === this.resolveSeq) {
        this.resolving = false;
      }
    }
  }

  applyResolveResult(result: PlaybackResolveResult): void {
    this.playUrl = result.url;
    this.parseStatus = result.status;
    this.parseWarning = result.warning === undefined ? '' : result.warning;
    if (result.headers !== undefined && Object.keys(result.headers).length > 0) {
      this.appendParseWarning('解析返回 headers，当前 Video 暂未注入请求头');
    }
    if (this.hasPlayerCfgHeaders()) {
      this.appendParseWarning('playerCfg 包含 headers，当前 Video 暂未注入请求头');
    }
    this.statusText = result.status;
    this.errorText = '';
    this.isPlaying = true;
  }

  isParseSelected(parse: ParseBean): boolean {
    if (this.selectedParseName.length > 0) {
      return parse.name === this.selectedParseName;
    }
    return parse.isDefault;
  }

  appendParseWarning(message: string): void {
    this.parseWarning = this.parseWarning.length > 0 ? `${this.parseWarning}；${message}` : message;
  }

  hasPlayerCfgHeaders(): boolean {
    return Object.keys(this.playerCfgHeaders()).length > 0;
  }

  playerCfgHeaders(): Record<string, string> {
    if (this.playerCfg.length === 0) {
      return {};
    }
    try {
      const root: Record<string, JsonNode> = asRecord(parseJson(this.playerCfg));
      const rows: JsonNode[] = asArray(root['headers']);
      const result: Record<string, string> = {};
      for (const item of rows) {
        const row = asRecord(item);
        const name = safeString(row, 'name');
        const value = safeString(row, 'value');
        if (name.length > 0 && value.length > 0) {
          result[name] = value;
        }
      }
      return result;
    } catch (_error) {
      return {};
    }
  }

  savePlaybackRecord(): void {
    if (this.sourceKey.length === 0 || this.vodId.length === 0 || (this.playUrl.length === 0 && this.rawUrl.length === 0)) {
      return;
    }
    const base = this.recordVod === null ? this.createMinimalVod() : JSON.parse(JSON.stringify(this.recordVod)) as VodInfo;
    base.id = this.vodId;
    base.playFlag = this.playFlag;
    base.playIndex = this.playIndex;
    base.playNote = this.episodeName;
    base.progress = this.currentTime;
    base.duration = this.duration;
    base.rawUrl = this.rawUrl.length > 0 ? this.rawUrl : this.playUrl;
    base.last = this.playUrl.length > 0 ? this.playUrl : this.rawUrl;
    base.sourceKey = this.sourceKey;
    if (this.playerCfg.length > 0) {
      base.playerCfg = this.playerCfg;
    }
    vodDataStore.insertVodRecord(this.sourceKey, base);
  }

  formatTime(seconds: number): string {
    const safeSeconds = Number.isFinite(seconds) && seconds > 0 ? Math.floor(seconds) : 0;
    const hour = Math.floor(safeSeconds / 3600);
    const minute = Math.floor((safeSeconds % 3600) / 60);
    const second = safeSeconds % 60;
    const mm = minute < 10 ? `0${minute}` : `${minute}`;
    const ss = second < 10 ? `0${second}` : `${second}`;
    return hour > 0 ? `${hour}:${mm}:${ss}` : `${mm}:${ss}`;
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        if (this.playUrl.length > 0) {
          Video({
            src: this.playUrl,
            currentProgressRate: PlaybackSpeed.Speed_Forward_1_00_X,
            controller: this.controller
          })
            .width('100%')
            .height('100%')
            .autoPlay(true)
            .controls(false)
            .objectFit(ImageFit.Contain)
            .onPrepared((event) => {
              this.duration = event.duration;
              if (this.currentTime > 0) {
                this.controller.setCurrentTime(this.currentTime, SeekMode.ClosestKeyframe);
              }
              this.statusText = '正在播放';
            })
            .onUpdate((event) => {
              this.currentTime = event.time;
            })
            .onFinish(() => {
              this.isPlaying = false;
              this.statusText = '播放结束';
            })
            .onError(() => {
              this.errorText = '播放失败，请检查视频地址或解析结果';
              this.statusText = '播放失败';
              this.isPlaying = false;
            })
        } else {
          Column() {
            Text(this.resolving ? '正在解析播放地址' : '无播放地址')
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            Text(this.errorText.length > 0 ? this.errorText : this.rawUrl)
              .fontSize(16)
              .fontColor('#fca5a5')
              .margin({ top: 12 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)

      Column() {
        Row() {
          Text('< 返回')
            .fontSize(18)
            .fontColor(Color.White)
            .onClick(() => router.back())
          Column() {
            Text(this.title)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(`${this.playFlag} ${this.episodeName}`)
              .fontSize(14)
              .fontColor('#cbd5e1')
              .margin({ top: 4 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .layoutWeight(1)
          .margin({ left: 24 })
          Text(this.statusText)
            .fontSize(14)
            .fontColor(this.errorText.length > 0 ? '#fca5a5' : '#93c5fd')
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        if (this.errorText.length > 0) {
          Text(this.errorText)
            .fontSize(14)
            .fontColor('#fca5a5')
            .margin({ top: 12 })
            .width('100%')
        }

        if (this.parseStatus.length > 0 || this.parseWarning.length > 0) {
          Text(this.parseWarning.length > 0 ? `${this.parseStatus}（${this.parseWarning}）` : this.parseStatus)
            .fontSize(13)
            .fontColor(this.parseWarning.length > 0 ? '#fbbf24' : '#cbd5e1')
            .margin({ top: 10 })
            .width('100%')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        if (this.parses.length > 0) {
          Row() {
            Text('解析')
              .fontSize(14)
              .fontColor('#cbd5e1')
              .margin({ right: 12 })
            Scroll() {
              Row() {
                ForEach(this.parses, (parse: ParseBean) => {
                  Text(parse.name)
                    .fontSize(13)
                    .fontColor(Color.White)
                    .padding({ left: 12, right: 12, top: 7, bottom: 7 })
                    .margin({ right: 8 })
                    .backgroundColor(this.isParseSelected(parse) ? '#2563eb' : '#1f2937')
                    .borderRadius(8)
                    .onClick(() => {
                      this.selectParse(parse);
                    })
                }, (parse: ParseBean) => parse.name)
              }
            }
            .scrollable(ScrollDirection.Horizontal)
            .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .margin({ top: 14 })
        }

        Row() {
          Button(this.isPlaying ? '暂停' : '播放')
            .width(92)
            .height(42)
            .enabled(this.playUrl.length > 0 && !this.resolving)
            .onClick(() => this.togglePlay())
          Button('上一集')
            .width(92)
            .height(42)
            .margin({ left: 12 })
            .enabled(this.playIndex > 0 && this.episodes.length > 0 && !this.resolving)
            .onClick(() => {
              this.openEpisode(this.playIndex - 1);
            })
          Button('下一集')
            .width(92)
            .height(42)
            .margin({ left: 12 })
            .enabled(this.playIndex + 1 < this.episodes.length && !this.resolving)
            .onClick(() => {
              this.openEpisode(this.playIndex + 1);
            })
          Text(this.formatTime(this.currentTime))
            .fontSize(14)
            .fontColor('#e5e7eb')
            .margin({ left: 18 })
          Slider({
            value: this.currentTime,
            min: 0,
            max: this.duration > 0 ? this.duration : 1,
            step: 1
          })
            .layoutWeight(1)
            .margin({ left: 14, right: 14 })
            .selectedColor('#60a5fa')
            .trackColor('#334155')
            .blockColor(Color.White)
            .onChange((value: number, mode: SliderChangeMode) => {
              this.currentTime = value;
              if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
                this.seekTo(value);
              }
            })
          Text(this.formatTime(this.duration))
            .fontSize(14)
            .fontColor('#e5e7eb')
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .margin({ top: 18 })
      }
      .width('100%')
      .padding({ left: 48, right: 48, top: 28, bottom: 34 })
      .backgroundColor('#99000000')
    }
    .width('100%')
    .height('100%')
  }
}
