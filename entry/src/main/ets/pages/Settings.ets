import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import {
  BackgroundPlayOptions,
  DnsOptions,
  HomeNumValues,
  HomeRecOptions,
  IjkCodecOptions,
  LiveTimeoutOptions,
  LocaleOptions,
  PlayerOptions,
  RenderOptions,
  ScaleOptions,
  SearchViewOptions,
  ThemeOptions
} from '../constants/AppDefaults';
import { HawkConfig } from '../constants/HawkConfig';
import { SourceBean } from '../models/TvBoxModels';
import { apiConfigService } from '../services/ApiConfigService';
import { settingsStore } from '../services/SettingsStore';
import { vodDataStore } from '../services/VodDataStore';
import { errorMessage } from '../utils/ErrorUtil';

@Entry
@Component
struct Settings {
  @State apiUrl: string = '';
  @State liveUrl: string = '';
  @State epgUrl: string = '';
  @State apiHistory: string[] = [];
  @State status: string = '未加载';
  @State sourceCount: number = 0;
  @State sources: SourceBean[] = [];
  @State homeApi: string = '';
  @State panel: string = '';

  @State debugOpen: boolean = false;
  @State homeShowSource: boolean = true;
  @State homeDefaultShow: boolean = false;
  @State homeRec: number = 1;
  @State homeNum: number = 4;
  @State showPreview: boolean = true;
  @State playScale: number = 0;
  @State backgroundPlay: number = 0;
  @State playType: number = 1;
  @State playRender: number = 0;
  @State ijkCodec: string = '硬解码';
  @State playTimeStep: number = 5;
  @State videoPurify: boolean = true;
  @State homeLocale: number = 0;
  @State themeSelect: number = 0;
  @State searchView: number = 1;
  @State fastSearchMode: boolean = false;
  @State parseWebView: boolean = true;
  @State dohUrl: number = 0;
  @State liveChannelReverse: boolean = false;
  @State liveCrossGroup: boolean = false;
  @State liveShowTime: boolean = false;
  @State liveShowNetSpeed: boolean = false;
  @State liveSkipPassword: boolean = false;
  @State liveConnectTimeout: number = 1;

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
    this.apiUrl = await settingsStore.get<string>(HawkConfig.API_URL, '');
    this.liveUrl = await settingsStore.get<string>(HawkConfig.LIVE_URL, '');
    this.epgUrl = await settingsStore.get<string>(HawkConfig.EPG_URL, '');
    this.homeApi = await settingsStore.get<string>(HawkConfig.HOME_API, '');
    this.apiHistory = await this.readHistory();

    this.debugOpen = await settingsStore.get<boolean>(HawkConfig.DEBUG_OPEN, false);
    this.homeShowSource = await settingsStore.get<boolean>(HawkConfig.HOME_SHOW_SOURCE, true);
    this.homeDefaultShow = await settingsStore.get<boolean>(HawkConfig.HOME_DEFAULT_SHOW, false);
    this.homeRec = await settingsStore.get<number>(HawkConfig.HOME_REC, 1);
    this.homeNum = await settingsStore.get<number>(HawkConfig.HOME_NUM, 4);
    this.showPreview = await settingsStore.get<boolean>(HawkConfig.SHOW_PREVIEW, true);
    this.playScale = await settingsStore.get<number>(HawkConfig.PLAY_SCALE, 0);
    this.backgroundPlay = await settingsStore.get<number>(HawkConfig.BACKGROUND_PLAY_TYPE, 0);
    this.playType = await settingsStore.get<number>(HawkConfig.PLAY_TYPE, 1);
    this.playRender = await settingsStore.get<number>(HawkConfig.PLAY_RENDER, 0);
    this.ijkCodec = await settingsStore.get<string>(HawkConfig.IJK_CODEC, '硬解码');
    this.playTimeStep = await settingsStore.get<number>(HawkConfig.PLAY_TIME_STEP, 5);
    this.videoPurify = await settingsStore.get<boolean>(HawkConfig.VIDEO_PURIFY, true);
    this.homeLocale = await settingsStore.get<number>(HawkConfig.HOME_LOCALE, 0);
    this.themeSelect = await settingsStore.get<number>(HawkConfig.THEME_SELECT, 0);
    this.searchView = await settingsStore.get<number>(HawkConfig.SEARCH_VIEW, 1);
    this.fastSearchMode = await settingsStore.get<boolean>(HawkConfig.FAST_SEARCH_MODE, false);
    this.parseWebView = await settingsStore.get<boolean>(HawkConfig.PARSE_WEBVIEW, true);
    this.dohUrl = await settingsStore.get<number>(HawkConfig.DOH_URL, 0);
    this.liveChannelReverse = await settingsStore.get<boolean>(HawkConfig.LIVE_CHANNEL_REVERSE, false);
    this.liveCrossGroup = await settingsStore.get<boolean>(HawkConfig.LIVE_CROSS_GROUP, false);
    this.liveShowTime = await settingsStore.get<boolean>(HawkConfig.LIVE_SHOW_TIME, false);
    this.liveShowNetSpeed = await settingsStore.get<boolean>(HawkConfig.LIVE_SHOW_NET_SPEED, false);
    this.liveSkipPassword = await settingsStore.get<boolean>(HawkConfig.LIVE_SKIP_PASSWORD, false);
    this.liveConnectTimeout = await settingsStore.get<number>(HawkConfig.LIVE_CONNECT_TIMEOUT, 1);

    this.refreshSources();
  }

  refreshSources(): void {
    const state = apiConfigService.state;
    const all: SourceBean[] = Object.keys(state.sourceBeanList).map((key: string) => state.sourceBeanList[key]);
    this.sources = all.filter((item: SourceBean) => item.hide === 0);
    this.sourceCount = all.length;
    if (this.sourceCount > 0 && this.status === '未加载') {
      this.status = `已加载 ${this.sourceCount} 个源`;
    }
  }

  /** Android stores `API_HISTORY` as a serialized list; ArkTS preferences only holds strings. */
  async readHistory(): Promise<string[]> {
    const raw = await settingsStore.get<string>(HawkConfig.API_HISTORY, '');
    if (raw.length === 0) {
      return [];
    }
    return raw.split('\n').filter((item: string) => item.trim().length > 0);
  }

  async appendHistory(url: string): Promise<void> {
    const value = url.trim();
    if (value.length === 0) {
      return;
    }
    const next: string[] = [value];
    for (const item of this.apiHistory) {
      if (item !== value && next.length < 20) {
        next.push(item);
      }
    }
    this.apiHistory = next;
    await settingsStore.put(HawkConfig.API_HISTORY, next.join('\n'));
  }

  async putBoolean(key: string, value: boolean): Promise<void> {
    await settingsStore.put(key, value);
  }

  async putNumber(key: string, value: number): Promise<void> {
    await settingsStore.put(key, value);
  }

  async putString(key: string, value: string): Promise<void> {
    await settingsStore.put(key, value);
  }

  async loadConfig(): Promise<void> {
    if (this.apiUrl.trim().length === 0) {
      promptAction.showToast({ message: '请先填写配置地址' });
      return;
    }
    try {
      this.status = '加载中...';
      await settingsStore.put(HawkConfig.API_URL, this.apiUrl.trim());
      await apiConfigService.loadConfig(this.apiUrl.trim(), false);
      await this.appendHistory(this.apiUrl.trim());
      this.refreshSources();
      if (this.liveUrl.length === 0 && apiConfigService.state.liveSourceUrl.length > 0) {
        this.liveUrl = apiConfigService.state.liveSourceUrl;
        await settingsStore.put(HawkConfig.LIVE_URL, this.liveUrl);
      }
      if (this.epgUrl.length === 0 && apiConfigService.state.liveEpgUrl.length > 0) {
        this.epgUrl = apiConfigService.state.liveEpgUrl;
        await settingsStore.put(HawkConfig.EPG_URL, this.epgUrl);
      }
      this.status = `加载成功：${this.sourceCount} 个源`;
      promptAction.showToast({ message: this.status });
    } catch (error) {
      this.status = `加载失败：${errorMessage(error as Error)}`;
      promptAction.showToast({ message: this.status });
    }
  }

  async selectHomeSource(source: SourceBean): Promise<void> {
    await apiConfigService.setHomeSource(source);
    this.homeApi = source.key;
    this.panel = '';
    promptAction.showToast({ message: `首页源：${source.name}` });
  }

  /** Android `ResetDialog` / `ConfirmClearDialog` equivalents. */
  async clearCache(): Promise<void> {
    apiConfigService.clearConfigCache(this.apiUrl);
    this.status = '已清除配置缓存';
    promptAction.showToast({ message: this.status });
  }

  async clearHistoryRecords(): Promise<void> {
    vodDataStore.deleteVodRecordAll();
    promptAction.showToast({ message: '已清空观看历史' });
  }

  async clearSearchRecords(): Promise<void> {
    vodDataStore.clearSearchKeywords();
    promptAction.showToast({ message: '已清空搜索历史' });
  }

  togglePanel(name: string): void {
    this.panel = this.panel === name ? '' : name;
  }

  homeNumLabel(): string {
    const index = this.homeNum >= 0 && this.homeNum < HomeNumValues.length ? this.homeNum : 0;
    return `${HomeNumValues[index]}条`;
  }

  optionLabel(options: string[], index: number): string {
    return index >= 0 && index < options.length ? options[index] : options[0];
  }

  @Builder
  sectionTitle(text: string) {
    Text(text)
      .fontSize(20)
      .fontWeight(FontWeight.Bold)
      .fontColor(Color.White)
      .width('100%')
      .margin({ top: 22, bottom: 8 })
  }

  @Builder
  switchRow(label: string, key: string, value: boolean, apply: (next: boolean) => void) {
    Row() {
      Column() {
        Text(label).fontSize(17).fontColor(Color.White)
        Text(key).fontSize(12).fontColor('#64748b').margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(value ? '开启' : '关闭')
        .fontSize(15)
        .fontColor(value ? '#60a5fa' : '#94a3b8')
    }
    .width('100%')
    .padding(16)
    .margin({ top: 8 })
    .backgroundColor('#151d2b')
    .borderRadius(12)
    .focusable(true)
    .onClick(() => apply(!value))
  }

  @Builder
  optionRow(label: string, key: string, current: string, panelName: string) {
    Row() {
      Column() {
        Text(label).fontSize(17).fontColor(Color.White)
        Text(key).fontSize(12).fontColor('#64748b').margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(current).fontSize(15).fontColor('#60a5fa')
    }
    .width('100%')
    .padding(16)
    .margin({ top: 8 })
    .backgroundColor(this.panel === panelName ? '#243044' : '#151d2b')
    .borderRadius(12)
    .focusable(true)
    .onClick(() => this.togglePanel(panelName))
  }

  @Builder
  optionChips(options: string[], selected: number, apply: (index: number) => void) {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(options, (name: string, index: number) => {
        Text(name)
          .fontSize(14)
          .fontColor(Color.White)
          .padding({ left: 14, right: 14, top: 8, bottom: 8 })
          .margin({ right: 8, top: 8 })
          .backgroundColor(selected === index ? '#2563eb' : '#1f2937')
          .borderRadius(8)
          .focusable(true)
          .onClick(() => {
            apply(index);
            this.panel = '';
          })
      }, (name: string) => name)
    }
    .width('100%')
    .padding({ left: 8, right: 8, bottom: 8 })
  }

  build() {
    Column() {
      Row() {
        Text('<')
          .fontSize(28)
          .fontColor(Color.White)
          .width(56)
          .textAlign(TextAlign.Center)
          .focusable(true)
          .onClick(() => router.back())
        Text('设置')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .layoutWeight(1)
        Text(this.status)
          .fontSize(14)
          .fontColor('#93a4b8')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .height(72)
      .padding({ left: 24, right: 40 })

      Scroll() {
        Column() {
          this.sectionTitle('配置')

          Column() {
            Text('配置地址').fontSize(17).fontColor(Color.White).width('100%')
            TextInput({ text: this.apiUrl, placeholder: '请输入 TVBox JSON 配置地址' })
              .height(46)
              .fontSize(15)
              .margin({ top: 10 })
              .onChange((value: string) => this.apiUrl = value)
            Row() {
              Button('加载配置').height(40).onClick(() => this.loadConfig())
              Button('清除缓存').height(40).margin({ left: 10 }).onClick(() => this.clearCache())
              Button(`历史 ${this.apiHistory.length}`)
                .height(40)
                .margin({ left: 10 })
                .enabled(this.apiHistory.length > 0)
                .onClick(() => this.togglePanel('apiHistory'))
              Button(`首页源 ${this.sources.length}`)
                .height(40)
                .margin({ left: 10 })
                .enabled(this.sources.length > 0)
                .onClick(() => this.togglePanel('homeSource'))
            }
            .width('100%')
            .margin({ top: 12 })

            if (this.panel === 'apiHistory') {
              Column() {
                ForEach(this.apiHistory, (item: string) => {
                  Text(item)
                    .fontSize(13)
                    .fontColor(item === this.apiUrl ? '#60a5fa' : '#cbd5e1')
                    .width('100%')
                    .padding({ top: 8, bottom: 8 })
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .focusable(true)
                    .onClick(() => {
                      this.apiUrl = item;
                      this.panel = '';
                      this.loadConfig();
                    })
                }, (item: string) => item)
              }
              .width('100%')
              .margin({ top: 8 })
            }

            if (this.panel === 'homeSource') {
              Column() {
                ForEach(this.sources, (source: SourceBean) => {
                  Row() {
                    Text(source.name).fontSize(14).fontColor(Color.White).layoutWeight(1)
                    Text(`type=${source.type}`).fontSize(12).fontColor('#64748b')
                  }
                  .width('100%')
                  .padding({ top: 9, bottom: 9 })
                  .backgroundColor(source.key === this.homeApi ? '#243044' : Color.Transparent)
                  .focusable(true)
                  .onClick(() => this.selectHomeSource(source))
                }, (source: SourceBean) => source.key)
              }
              .width('100%')
              .margin({ top: 8 })
            }

            TextInput({ text: this.liveUrl, placeholder: '直播 M3U/TXT 地址' })
              .height(46)
              .fontSize(15)
              .margin({ top: 14 })
              .onChange((value: string) => {
                this.liveUrl = value;
                this.putString(HawkConfig.LIVE_URL, value);
              })
            TextInput({ text: this.epgUrl, placeholder: 'EPG 地址' })
              .height(46)
              .fontSize(15)
              .margin({ top: 10 })
              .onChange((value: string) => {
                this.epgUrl = value;
                this.putString(HawkConfig.EPG_URL, value);
              })
          }
          .width('100%')
          .padding(18)
          .backgroundColor('#1f2937')
          .borderRadius(14)

          this.sectionTitle('首页')
          this.switchRow('数据源显示', HawkConfig.HOME_SHOW_SOURCE, this.homeShowSource, (next: boolean) => {
            this.homeShowSource = next;
            this.putBoolean(HawkConfig.HOME_SHOW_SOURCE, next);
          })
          this.switchRow('启动进入直播', HawkConfig.HOME_DEFAULT_SHOW, this.homeDefaultShow, (next: boolean) => {
            this.homeDefaultShow = next;
            this.putBoolean(HawkConfig.HOME_DEFAULT_SHOW, next);
          })
          this.optionRow('推荐来源', HawkConfig.HOME_REC, this.optionLabel(HomeRecOptions, this.homeRec), 'homeRec')
          if (this.panel === 'homeRec') {
            this.optionChips(HomeRecOptions, this.homeRec, (index: number) => {
              this.homeRec = index;
              this.putNumber(HawkConfig.HOME_REC, index);
            })
          }
          this.optionRow('历史条数', HawkConfig.HOME_NUM, this.homeNumLabel(), 'homeNum')
          if (this.panel === 'homeNum') {
            this.optionChips(HomeNumValues.map((value: number) => `${value}条`), this.homeNum, (index: number) => {
              this.homeNum = index;
              this.putNumber(HawkConfig.HOME_NUM, index);
            })
          }

          this.sectionTitle('播放器')
          this.optionRow('画面缩放', HawkConfig.PLAY_SCALE, this.optionLabel(ScaleOptions, this.playScale), 'playScale')
          if (this.panel === 'playScale') {
            this.optionChips(ScaleOptions, this.playScale, (index: number) => {
              this.playScale = index;
              this.putNumber(HawkConfig.PLAY_SCALE, index);
            })
          }
          this.optionRow('播放器类型', HawkConfig.PLAY_TYPE, this.optionLabel(PlayerOptions, this.playType), 'playType')
          if (this.panel === 'playType') {
            Column() {
              Text('HarmonyOS 使用系统 AVPlayer，其余内核仅保留配置兼容。')
                .fontSize(12)
                .fontColor('#fbbf24')
                .width('100%')
                .padding({ left: 8, top: 6 })
              this.optionChips(PlayerOptions, this.playType, (index: number) => {
                this.playType = index;
                this.putNumber(HawkConfig.PLAY_TYPE, index);
              })
            }
            .width('100%')
          }
          this.optionRow('渲染方式', HawkConfig.PLAY_RENDER, this.optionLabel(RenderOptions, this.playRender), 'playRender')
          if (this.panel === 'playRender') {
            this.optionChips(RenderOptions, this.playRender, (index: number) => {
              this.playRender = index;
              this.putNumber(HawkConfig.PLAY_RENDER, index);
            })
          }
          this.optionRow('IJK 解码', HawkConfig.IJK_CODEC, this.ijkCodec, 'ijkCodec')
          if (this.panel === 'ijkCodec') {
            this.optionChips(IjkCodecOptions, IjkCodecOptions.indexOf(this.ijkCodec), (index: number) => {
              this.ijkCodec = IjkCodecOptions[index];
              this.putString(HawkConfig.IJK_CODEC, this.ijkCodec);
            })
          }
          this.optionRow('后台播放', HawkConfig.BACKGROUND_PLAY_TYPE, this.optionLabel(BackgroundPlayOptions, this.backgroundPlay), 'bgPlay')
          if (this.panel === 'bgPlay') {
            this.optionChips(BackgroundPlayOptions, this.backgroundPlay, (index: number) => {
              this.backgroundPlay = index;
              this.putNumber(HawkConfig.BACKGROUND_PLAY_TYPE, index);
            })
          }
          this.optionRow('快进步长', HawkConfig.PLAY_TIME_STEP, `${this.playTimeStep}s`, 'timeStep')
          if (this.panel === 'timeStep') {
            this.optionChips(['5s', '10s', '15s', '30s'], [5, 10, 15, 30].indexOf(this.playTimeStep), (index: number) => {
              this.playTimeStep = [5, 10, 15, 30][index];
              this.putNumber(HawkConfig.PLAY_TIME_STEP, this.playTimeStep);
            })
          }
          this.switchRow('窗口预览', HawkConfig.SHOW_PREVIEW, this.showPreview, (next: boolean) => {
            this.showPreview = next;
            this.putBoolean(HawkConfig.SHOW_PREVIEW, next);
          })
          this.switchRow('广告过滤', HawkConfig.VIDEO_PURIFY, this.videoPurify, (next: boolean) => {
            this.videoPurify = next;
            this.putBoolean(HawkConfig.VIDEO_PURIFY, next);
          })

          this.sectionTitle('直播')
          this.switchRow('换台反转', HawkConfig.LIVE_CHANNEL_REVERSE, this.liveChannelReverse, (next: boolean) => {
            this.liveChannelReverse = next;
            this.putBoolean(HawkConfig.LIVE_CHANNEL_REVERSE, next);
          })
          this.switchRow('跨分组换台', HawkConfig.LIVE_CROSS_GROUP, this.liveCrossGroup, (next: boolean) => {
            this.liveCrossGroup = next;
            this.putBoolean(HawkConfig.LIVE_CROSS_GROUP, next);
          })
          this.switchRow('显示时间', HawkConfig.LIVE_SHOW_TIME, this.liveShowTime, (next: boolean) => {
            this.liveShowTime = next;
            this.putBoolean(HawkConfig.LIVE_SHOW_TIME, next);
          })
          this.switchRow('显示网速', HawkConfig.LIVE_SHOW_NET_SPEED, this.liveShowNetSpeed, (next: boolean) => {
            this.liveShowNetSpeed = next;
            this.putBoolean(HawkConfig.LIVE_SHOW_NET_SPEED, next);
          })
          this.switchRow('跳过密码分组', HawkConfig.LIVE_SKIP_PASSWORD, this.liveSkipPassword, (next: boolean) => {
            this.liveSkipPassword = next;
            this.putBoolean(HawkConfig.LIVE_SKIP_PASSWORD, next);
          })
          this.optionRow('直播超时', HawkConfig.LIVE_CONNECT_TIMEOUT, this.optionLabel(LiveTimeoutOptions, this.liveConnectTimeout), 'liveTimeout')
          if (this.panel === 'liveTimeout') {
            this.optionChips(LiveTimeoutOptions, this.liveConnectTimeout, (index: number) => {
              this.liveConnectTimeout = index;
              this.putNumber(HawkConfig.LIVE_CONNECT_TIMEOUT, index);
            })
          }

          this.sectionTitle('系统')
          this.optionRow('搜索展示', HawkConfig.SEARCH_VIEW, this.optionLabel(SearchViewOptions, this.searchView), 'searchView')
          if (this.panel === 'searchView') {
            this.optionChips(SearchViewOptions, this.searchView, (index: number) => {
              this.searchView = index;
              this.putNumber(HawkConfig.SEARCH_VIEW, index);
            })
          }
          this.switchRow('快速搜索', HawkConfig.FAST_SEARCH_MODE, this.fastSearchMode, (next: boolean) => {
            this.fastSearchMode = next;
            this.putBoolean(HawkConfig.FAST_SEARCH_MODE, next);
          })
          this.optionRow('语言', HawkConfig.HOME_LOCALE, this.optionLabel(LocaleOptions, this.homeLocale), 'locale')
          if (this.panel === 'locale') {
            this.optionChips(LocaleOptions, this.homeLocale, (index: number) => {
              this.homeLocale = index;
              this.putNumber(HawkConfig.HOME_LOCALE, index);
            })
          }
          this.optionRow('主题', HawkConfig.THEME_SELECT, this.optionLabel(ThemeOptions, this.themeSelect), 'theme')
          if (this.panel === 'theme') {
            this.optionChips(ThemeOptions, this.themeSelect, (index: number) => {
              this.themeSelect = index;
              this.putNumber(HawkConfig.THEME_SELECT, index);
            })
          }
          this.optionRow('安全 DNS', HawkConfig.DOH_URL, this.optionLabel(DnsOptions, this.dohUrl), 'dns')
          if (this.panel === 'dns') {
            this.optionChips(DnsOptions, this.dohUrl, (index: number) => {
              this.dohUrl = index;
              this.putNumber(HawkConfig.DOH_URL, index);
            })
          }
          this.switchRow('嗅探 WebView', HawkConfig.PARSE_WEBVIEW, this.parseWebView, (next: boolean) => {
            this.parseWebView = next;
            this.putBoolean(HawkConfig.PARSE_WEBVIEW, next);
          })
          this.switchRow('调试模式', HawkConfig.DEBUG_OPEN, this.debugOpen, (next: boolean) => {
            this.debugOpen = next;
            this.putBoolean(HawkConfig.DEBUG_OPEN, next);
          })

          this.sectionTitle('数据')
          Row() {
            Button('清空观看历史').height(40).onClick(() => this.clearHistoryRecords())
            Button('清空搜索历史').height(40).margin({ left: 10 }).onClick(() => this.clearSearchRecords())
          }
          .width('100%')
          .margin({ top: 8, bottom: 40 })
        }
        .width('100%')
      }
      .padding({ left: 48, right: 48 })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0b1020')
  }
}
