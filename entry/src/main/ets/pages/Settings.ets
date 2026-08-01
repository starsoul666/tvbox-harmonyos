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
import { appearanceService, SettingsLabels, ThemePalette } from '../services/AppearanceService';
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
  @State proxyServer: string = '';
  @State homeSearchPosition: boolean = false;
  @State homeMenuPosition: boolean = true;
  @State homeRecStyle: boolean = false;
  @State backupList: string[] = [];

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
    await appearanceService.init();
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
    appearanceService.setLocale(this.homeLocale);
    appearanceService.setTheme(this.themeSelect);
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
    this.proxyServer = await settingsStore.get<string>(HawkConfig.PROXY_SERVER, '');
    this.homeSearchPosition = await settingsStore.get<boolean>(HawkConfig.HOME_SEARCH_POSITION, false);
    this.homeMenuPosition = await settingsStore.get<boolean>(HawkConfig.HOME_MENU_POSITION, true);
    this.homeRecStyle = await settingsStore.get<boolean>(HawkConfig.HOME_REC_STYLE, false);
    this.backupList = settingsStore.listBackups();

    this.refreshSources();
  }

  refreshSources(): void {
    const state = apiConfigService.state;
    const all: SourceBean[] = Object.keys(state.sourceBeanList).map((key: string) => state.sourceBeanList[key]);
    this.sources = all.filter((item: SourceBean) => item.hide === 0);
    this.sourceCount = all.length;
    if (this.sourceCount > 0 && this.status === '未加载') {
      const labels = this.labels();
      this.status = `${labels.loadSuccessPrefix}${this.sourceCount}${labels.loadSuccessSuffix}`;
    }
  }

  theme(): ThemePalette {
    return appearanceService.themeByIndex(this.themeSelect);
  }

  labels(): SettingsLabels {
    appearanceService.setLocale(this.homeLocale);
    return appearanceService.settingsLabels();
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
      promptAction.showToast({ message: this.labels().pleaseInputConfig });
      return;
    }
    try {
      this.status = this.labels().loadConfig;
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
      const labels = this.labels();
      this.status = `${labels.loadSuccessPrefix}${this.sourceCount}${labels.loadSuccessSuffix}`;
      promptAction.showToast({ message: this.status });
    } catch (error) {
      this.status = `${this.labels().loadFailedPrefix}${errorMessage(error as Error)}`;
      promptAction.showToast({ message: this.status });
    }
  }

  async selectHomeSource(source: SourceBean): Promise<void> {
    await apiConfigService.setHomeSource(source);
    this.homeApi = source.key;
    this.panel = '';
    promptAction.showToast({ message: `${this.labels().homeSourcePrefix}${source.name}` });
  }

  /** Android `ResetDialog` / `ConfirmClearDialog` equivalents. */
  async clearCache(): Promise<void> {
    apiConfigService.clearConfigCache(this.apiUrl);
    this.status = this.labels().cacheCleared;
    promptAction.showToast({ message: this.status });
  }

  async clearHistoryRecords(): Promise<void> {
    vodDataStore.deleteVodRecordAll();
    promptAction.showToast({ message: this.labels().watchHistoryCleared });
  }

  async clearSearchRecords(): Promise<void> {
    vodDataStore.clearSearchKeywords();
    promptAction.showToast({ message: this.labels().searchHistoryCleared });
  }

  async createBackup(): Promise<void> {
    const name = await settingsStore.createBackup();
    if (name.length > 0) {
      this.backupList = settingsStore.listBackups();
      promptAction.showToast({ message: this.labels().backupCreated });
    } else {
      promptAction.showToast({ message: this.labels().backupFailed });
    }
  }

  async restoreBackup(fileName: string): Promise<void> {
    const ok = await settingsStore.restoreBackup(fileName);
    if (ok) {
      promptAction.showToast({ message: this.labels().backupRestored });
      await this.initPage();
    } else {
      promptAction.showToast({ message: this.labels().backupFailed });
    }
  }

  deleteBackupEntry(fileName: string): void {
    settingsStore.deleteBackup(fileName);
    this.backupList = settingsStore.listBackups();
  }

  async resetApp(): Promise<void> {
    await settingsStore.clearAll();
    vodDataStore.deleteVodRecordAll();
    vodDataStore.deleteVodCollectAll();
    vodDataStore.clearSearchKeywords();
    this.apiUrl = '';
    this.liveUrl = '';
    this.epgUrl = '';
    this.panel = '';
    await this.initPage();
    promptAction.showToast({ message: this.labels().resetDone });
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
      .fontColor(this.theme().text)
      .width('100%')
      .margin({ top: 22, bottom: 8 })
  }

  @Builder
  switchRow(label: string, key: string, value: boolean, apply: (next: boolean) => void) {
    Row() {
      Column() {
        Text(label).fontSize(17).fontColor(this.theme().text)
        Text(key).fontSize(12).fontColor(this.theme().subtleText).margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(value ? this.labels().enabled : this.labels().disabled)
        .fontSize(15)
        .fontColor(value ? this.theme().primarySoft : this.theme().mutedText)
    }
    .width('100%')
    .padding(16)
    .margin({ top: 8 })
    .backgroundColor(this.theme().cardBg)
    .borderRadius(12)
    .focusable(true)
    .onClick(() => apply(!value))
  }

  @Builder
  optionRow(label: string, key: string, current: string, panelName: string) {
    Row() {
      Column() {
        Text(label).fontSize(17).fontColor(this.theme().text)
        Text(key).fontSize(12).fontColor(this.theme().subtleText).margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      Text(current).fontSize(15).fontColor(this.theme().primarySoft)
    }
    .width('100%')
    .padding(16)
    .margin({ top: 8 })
    .backgroundColor(this.panel === panelName ? this.theme().cardActiveBg : this.theme().cardBg)
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
          .fontColor(this.theme().text)
          .padding({ left: 14, right: 14, top: 8, bottom: 8 })
          .margin({ right: 8, top: 8 })
          .backgroundColor(selected === index ? this.theme().primary : this.theme().panelBg)
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
          .fontColor(this.theme().text)
          .width(56)
          .textAlign(TextAlign.Center)
          .focusable(true)
          .onClick(() => router.back())
        Text(this.labels().title)
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme().text)
          .layoutWeight(1)
        Text(this.status)
          .fontSize(14)
          .fontColor(this.theme().mutedText)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .height(72)
      .padding({ left: 24, right: 40 })

      Scroll() {
        Column() {
          this.sectionTitle(this.labels().config)

          Column() {
            Text(this.labels().configUrl).fontSize(17).fontColor(this.theme().text).width('100%')
            TextInput({ text: this.apiUrl, placeholder: this.labels().configPlaceholder })
              .height(46)
              .fontSize(15)
              .margin({ top: 10 })
              .onChange((value: string) => this.apiUrl = value)
            Row() {
              Button(this.labels().loadConfig).height(40).onClick(() => this.loadConfig())
              Button(this.labels().clearCache).height(40).margin({ left: 10 }).onClick(() => this.clearCache())
              Button(`${this.labels().history} ${this.apiHistory.length}`)
                .height(40)
                .margin({ left: 10 })
                .enabled(this.apiHistory.length > 0)
                .onClick(() => this.togglePanel('apiHistory'))
              Button(`${this.labels().homeSource} ${this.sources.length}`)
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
                    .fontColor(item === this.apiUrl ? this.theme().primarySoft : this.theme().text)
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
                    Text(source.name).fontSize(14).fontColor(this.theme().text).layoutWeight(1)
                    Text(`type=${source.type}`).fontSize(12).fontColor(this.theme().subtleText)
                  }
                  .width('100%')
                  .padding({ top: 9, bottom: 9 })
                  .backgroundColor(source.key === this.homeApi ? this.theme().cardActiveBg : Color.Transparent)
                  .focusable(true)
                  .onClick(() => this.selectHomeSource(source))
                }, (source: SourceBean) => source.key)
              }
              .width('100%')
              .margin({ top: 8 })
            }

            TextInput({ text: this.liveUrl, placeholder: this.labels().livePlaceholder })
              .height(46)
              .fontSize(15)
              .margin({ top: 14 })
              .onChange((value: string) => {
                this.liveUrl = value;
                this.putString(HawkConfig.LIVE_URL, value);
              })
            TextInput({ text: this.epgUrl, placeholder: this.labels().epgPlaceholder })
              .height(46)
              .fontSize(15)
              .margin({ top: 10 })
              .onChange((value: string) => {
                this.epgUrl = value;
                this.putString(HawkConfig.EPG_URL, value);
              })
            TextInput({ text: this.proxyServer, placeholder: this.labels().proxyPlaceholder })
              .height(46)
              .fontSize(15)
              .margin({ top: 10 })
              .onChange((value: string) => {
                this.proxyServer = value;
                this.putString(HawkConfig.PROXY_SERVER, value);
              })
          }
          .width('100%')
          .padding(18)
          .backgroundColor(this.theme().panelBg)
          .borderRadius(14)

          this.sectionTitle(this.labels().home)
          this.switchRow(this.labels().sourceDisplay, HawkConfig.HOME_SHOW_SOURCE, this.homeShowSource, (next: boolean) => {
            this.homeShowSource = next;
            this.putBoolean(HawkConfig.HOME_SHOW_SOURCE, next);
          })
          this.switchRow(this.labels().launchLive, HawkConfig.HOME_DEFAULT_SHOW, this.homeDefaultShow, (next: boolean) => {
            this.homeDefaultShow = next;
            this.putBoolean(HawkConfig.HOME_DEFAULT_SHOW, next);
          })
          this.optionRow(this.labels().recommendation, HawkConfig.HOME_REC, this.optionLabel(HomeRecOptions, this.homeRec), 'homeRec')
          if (this.panel === 'homeRec') {
            this.optionChips(HomeRecOptions, this.homeRec, (index: number) => {
              this.homeRec = index;
              this.putNumber(HawkConfig.HOME_REC, index);
            })
          }
          this.optionRow(this.labels().historyCount, HawkConfig.HOME_NUM, this.homeNumLabel(), 'homeNum')
          if (this.panel === 'homeNum') {
            this.optionChips(HomeNumValues.map((value: number) => `${value}条`), this.homeNum, (index: number) => {
              this.homeNum = index;
              this.putNumber(HawkConfig.HOME_NUM, index);
            })
          }
          this.switchRow(this.labels().searchPosition, HawkConfig.HOME_SEARCH_POSITION, this.homeSearchPosition, (next: boolean) => {
            this.homeSearchPosition = next;
            this.putBoolean(HawkConfig.HOME_SEARCH_POSITION, next);
          })
          this.switchRow(this.labels().menuPosition, HawkConfig.HOME_MENU_POSITION, this.homeMenuPosition, (next: boolean) => {
            this.homeMenuPosition = next;
            this.putBoolean(HawkConfig.HOME_MENU_POSITION, next);
          })
          this.switchRow(this.labels().recStyle, HawkConfig.HOME_REC_STYLE, this.homeRecStyle, (next: boolean) => {
            this.homeRecStyle = next;
            this.putBoolean(HawkConfig.HOME_REC_STYLE, next);
          })

          this.sectionTitle(this.labels().player)
          this.optionRow(this.labels().scale, HawkConfig.PLAY_SCALE, this.optionLabel(ScaleOptions, this.playScale), 'playScale')
          if (this.panel === 'playScale') {
            this.optionChips(ScaleOptions, this.playScale, (index: number) => {
              this.playScale = index;
              this.putNumber(HawkConfig.PLAY_SCALE, index);
            })
          }
          this.optionRow(this.labels().playerType, HawkConfig.PLAY_TYPE, this.optionLabel(PlayerOptions, this.playType), 'playType')
          if (this.panel === 'playType') {
            Column() {
              Text(this.labels().playerCompatNotice)
                .fontSize(12)
                .fontColor(this.theme().warningText)
                .width('100%')
                .padding({ left: 8, top: 6 })
              this.optionChips(PlayerOptions, this.playType, (index: number) => {
                this.playType = index;
                this.putNumber(HawkConfig.PLAY_TYPE, index);
              })
            }
            .width('100%')
          }
          this.optionRow(this.labels().renderMode, HawkConfig.PLAY_RENDER, this.optionLabel(RenderOptions, this.playRender), 'playRender')
          if (this.panel === 'playRender') {
            this.optionChips(RenderOptions, this.playRender, (index: number) => {
              this.playRender = index;
              this.putNumber(HawkConfig.PLAY_RENDER, index);
            })
          }
          this.optionRow(this.labels().codec, HawkConfig.IJK_CODEC, this.ijkCodec, 'ijkCodec')
          if (this.panel === 'ijkCodec') {
            this.optionChips(IjkCodecOptions, IjkCodecOptions.indexOf(this.ijkCodec), (index: number) => {
              this.ijkCodec = IjkCodecOptions[index];
              this.putString(HawkConfig.IJK_CODEC, this.ijkCodec);
            })
          }
          this.optionRow(this.labels().backgroundPlay, HawkConfig.BACKGROUND_PLAY_TYPE, this.optionLabel(BackgroundPlayOptions, this.backgroundPlay), 'bgPlay')
          if (this.panel === 'bgPlay') {
            this.optionChips(BackgroundPlayOptions, this.backgroundPlay, (index: number) => {
              this.backgroundPlay = index;
              this.putNumber(HawkConfig.BACKGROUND_PLAY_TYPE, index);
            })
          }
          this.optionRow(this.labels().seekStep, HawkConfig.PLAY_TIME_STEP, `${this.playTimeStep}s`, 'timeStep')
          if (this.panel === 'timeStep') {
            this.optionChips(['5s', '10s', '15s', '30s'], [5, 10, 15, 30].indexOf(this.playTimeStep), (index: number) => {
              this.playTimeStep = [5, 10, 15, 30][index];
              this.putNumber(HawkConfig.PLAY_TIME_STEP, this.playTimeStep);
            })
          }
          this.switchRow(this.labels().preview, HawkConfig.SHOW_PREVIEW, this.showPreview, (next: boolean) => {
            this.showPreview = next;
            this.putBoolean(HawkConfig.SHOW_PREVIEW, next);
          })
          this.switchRow(this.labels().purify, HawkConfig.VIDEO_PURIFY, this.videoPurify, (next: boolean) => {
            this.videoPurify = next;
            this.putBoolean(HawkConfig.VIDEO_PURIFY, next);
          })

          this.sectionTitle(this.labels().live)
          this.switchRow(this.labels().reverseChannel, HawkConfig.LIVE_CHANNEL_REVERSE, this.liveChannelReverse, (next: boolean) => {
            this.liveChannelReverse = next;
            this.putBoolean(HawkConfig.LIVE_CHANNEL_REVERSE, next);
          })
          this.switchRow(this.labels().crossGroup, HawkConfig.LIVE_CROSS_GROUP, this.liveCrossGroup, (next: boolean) => {
            this.liveCrossGroup = next;
            this.putBoolean(HawkConfig.LIVE_CROSS_GROUP, next);
          })
          this.switchRow(this.labels().showTime, HawkConfig.LIVE_SHOW_TIME, this.liveShowTime, (next: boolean) => {
            this.liveShowTime = next;
            this.putBoolean(HawkConfig.LIVE_SHOW_TIME, next);
          })
          this.switchRow(this.labels().showNetSpeed, HawkConfig.LIVE_SHOW_NET_SPEED, this.liveShowNetSpeed, (next: boolean) => {
            this.liveShowNetSpeed = next;
            this.putBoolean(HawkConfig.LIVE_SHOW_NET_SPEED, next);
          })
          this.switchRow(this.labels().skipPassword, HawkConfig.LIVE_SKIP_PASSWORD, this.liveSkipPassword, (next: boolean) => {
            this.liveSkipPassword = next;
            this.putBoolean(HawkConfig.LIVE_SKIP_PASSWORD, next);
          })
          this.optionRow(this.labels().liveTimeout, HawkConfig.LIVE_CONNECT_TIMEOUT, this.optionLabel(LiveTimeoutOptions, this.liveConnectTimeout), 'liveTimeout')
          if (this.panel === 'liveTimeout') {
            this.optionChips(LiveTimeoutOptions, this.liveConnectTimeout, (index: number) => {
              this.liveConnectTimeout = index;
              this.putNumber(HawkConfig.LIVE_CONNECT_TIMEOUT, index);
            })
          }

          this.sectionTitle(this.labels().system)
          this.optionRow(this.labels().searchView, HawkConfig.SEARCH_VIEW, this.optionLabel(SearchViewOptions, this.searchView), 'searchView')
          if (this.panel === 'searchView') {
            this.optionChips(SearchViewOptions, this.searchView, (index: number) => {
              this.searchView = index;
              this.putNumber(HawkConfig.SEARCH_VIEW, index);
            })
          }
          this.switchRow(this.labels().fastSearch, HawkConfig.FAST_SEARCH_MODE, this.fastSearchMode, (next: boolean) => {
            this.fastSearchMode = next;
            this.putBoolean(HawkConfig.FAST_SEARCH_MODE, next);
          })
          this.optionRow(this.labels().locale, HawkConfig.HOME_LOCALE, this.optionLabel(LocaleOptions, this.homeLocale), 'locale')
          if (this.panel === 'locale') {
            this.optionChips(LocaleOptions, this.homeLocale, (index: number) => {
              this.homeLocale = index;
              appearanceService.setLocale(index);
              this.putNumber(HawkConfig.HOME_LOCALE, index);
            })
          }
          this.optionRow(this.labels().theme, HawkConfig.THEME_SELECT, this.optionLabel(ThemeOptions, this.themeSelect), 'theme')
          if (this.panel === 'theme') {
            this.optionChips(ThemeOptions, this.themeSelect, (index: number) => {
              this.themeSelect = index;
              appearanceService.setTheme(index);
              this.putNumber(HawkConfig.THEME_SELECT, index);
            })
          }
          this.optionRow(this.labels().dns, HawkConfig.DOH_URL, this.optionLabel(DnsOptions, this.dohUrl), 'dns')
          if (this.panel === 'dns') {
            this.optionChips(DnsOptions, this.dohUrl, (index: number) => {
              this.dohUrl = index;
              this.putNumber(HawkConfig.DOH_URL, index);
            })
          }
          this.switchRow(this.labels().sniffWebView, HawkConfig.PARSE_WEBVIEW, this.parseWebView, (next: boolean) => {
            this.parseWebView = next;
            this.putBoolean(HawkConfig.PARSE_WEBVIEW, next);
          })
          this.switchRow(this.labels().debug, HawkConfig.DEBUG_OPEN, this.debugOpen, (next: boolean) => {
            this.debugOpen = next;
            this.putBoolean(HawkConfig.DEBUG_OPEN, next);
          })

          this.sectionTitle(this.labels().data)
          Row() {
            Button(this.labels().clearWatchHistory).height(40).onClick(() => this.clearHistoryRecords())
            Button(this.labels().clearSearchHistory).height(40).margin({ left: 10 }).onClick(() => this.clearSearchRecords())
          }
          .width('100%')
          .margin({ top: 8 })

          Row() {
            Button(this.labels().backup).height(40).onClick(() => this.createBackup())
            Button(this.labels().restore).height(40).margin({ left: 10 }).onClick(() => this.togglePanel('backupList'))
            Button(this.labels().resetApp).height(40).margin({ left: 10 }).onClick(() => this.resetApp())
          }
          .width('100%')
          .margin({ top: 8 })

          if (this.panel === 'backupList') {
            Column() {
              if (this.backupList.length === 0) {
                Text(this.labels().noBackup)
                  .fontSize(14)
                  .fontColor(this.theme().mutedText)
                  .padding({ top: 8, bottom: 8 })
              } else {
                ForEach(this.backupList, (item: string) => {
                  Row() {
                    Text(item)
                      .fontSize(13)
                      .fontColor(this.theme().text)
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Button(this.labels().restore).height(32).fontSize(12).margin({ right: 8 }).onClick(() => this.restoreBackup(item))
                    Button('删除').height(32).fontSize(12).onClick(() => this.deleteBackupEntry(item))
                  }
                  .width('100%')
                  .padding({ top: 6, bottom: 6 })
                }, (item: string) => item)
              }
            }
            .width('100%')
            .margin({ top: 8 })
          }
          Blank().height(40)
        }
        .width('100%')
      }
      .padding({ left: 48, right: 48 })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.theme().pageBg)
  }
}
