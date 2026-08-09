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
  @State pickVisible: boolean = false;
  @State pickTitle: string = '';
  @State pickOptions: string[] = [];
  @State pickSelected: number = 0;
  private pickAction: (index: number) => void = () => {};

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
  private readonly pageBg = '#050505';
  private readonly cardBg = 'rgba(52, 52, 52, 0.82)';
  private readonly cardBgStrong = 'rgba(68, 68, 68, 0.82)';
  private readonly textMain = '#ffffff';
  private readonly textSoft = '#d7d7d7';
  private readonly textMuted = '#a5a5a5';
  private readonly accent = '#e02a2a';

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

  showPicker(title: string, options: string[], selected: number, apply: (index: number) => void): void {
    this.pickTitle = title;
    this.pickOptions = options;
    this.pickSelected = selected >= 0 && selected < options.length ? selected : 0;
    this.pickAction = apply;
    this.pickVisible = true;
  }

  pickSelect(index: number): void {
    this.pickAction(index);
    this.pickVisible = false;
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
    Row() {
      Row()
        .width(6)
        .height(24)
        .backgroundColor(this.accent)
        .borderRadius(3)
      Text(text)
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textMain)
        .margin({ left: 12 })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .margin({ top: 24, bottom: 14 })
  }

  @Builder
  cell(label: string, subLabel: string, value: string, isSwitch: boolean, swValue: boolean, panelName: string, onToggle: (next: boolean) => void, pickOptions: string[] = [], pickSelected: number = 0, onPick: (index: number) => void = () => {}) {
    Row() {
      Column() {
        Text(label)
          .fontSize(18)
          .fontColor(this.textMain)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (subLabel.length > 0) {
          Text(subLabel)
            .fontSize(12)
            .fontColor(this.textMuted)
            .margin({ top: 4 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (isSwitch) {
        Text(swValue ? this.labels().enabled : this.labels().disabled)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(swValue ? '#ffffff' : this.textSoft)
      } else {
        Row() {
          Text(value)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.textSoft)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text('>')
            .fontSize(20)
            .fontColor(this.textSoft)
            .margin({ left: 8 })
        }
        .alignItems(VerticalAlign.Center)
      }
    }
    .width('100%')
    .height(62)
    .layoutWeight(1)
    .padding({ left: 22, right: 22 })
    .backgroundColor(this.panel === panelName ? this.cardBgStrong : this.cardBg)
    .borderRadius(12)
    .focusable(true)
    .onClick(() => {
      if (isSwitch) {
        onToggle(!swValue);
      } else {
        this.showPicker(label, pickOptions, pickSelected, onPick);
      }
    })
  }

  @Builder
  renderPicker() {
    Stack() {
      Row()
        .width('100%')
        .height('100%')
        .backgroundColor('#90000000')
        .onClick(() => this.pickVisible = false)

      Column() {
        Row() {
          Row()
            .width(6)
            .height(22)
            .backgroundColor(this.accent)
            .borderRadius(3)
          Text(this.pickTitle)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.textMain)
            .margin({ left: 10 })
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .padding({ bottom: 14 })

        Scroll() {
          Column() {
            ForEach(this.pickOptions, (item: string, index: number) => {
              Row() {
                Text(item)
                  .fontSize(16)
                  .fontColor(index === this.pickSelected ? '#ffffff' : this.textMain)
                  .layoutWeight(1)
                if (index === this.pickSelected) {
                  Text('✓')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.accent)
                }
              }
              .width('100%')
              .height(46)
              .padding({ left: 14, right: 14 })
              .backgroundColor(index === this.pickSelected ? this.cardBgStrong : this.cardBg)
              .borderRadius(10)
              .margin({ bottom: 8 })
              .focusable(true)
              .onClick(() => this.pickSelect(index))
            })
          }
          .width('100%')
        }
        .scrollable(ScrollDirection.Vertical)
        .width('100%')
        .layoutWeight(1)
      }
      .width(420)
      .height(344)
      .padding(22)
      .backgroundColor('#1f1f1f')
      .borderRadius(16)
    }
    .width('100%')
    .height('100%')
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Blank()
            .width(56)
          Row() {
            Row()
              .width(6)
              .height(28)
              .backgroundColor(this.accent)
              .borderRadius(4)
            Text(this.labels().title)
              .fontSize(38)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.textMain)
              .margin({ left: 12 })
          }
          .alignItems(VerticalAlign.Center)
          .layoutWeight(1)
          Text(this.status)
            .fontSize(14)
            .fontColor(this.textSoft)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .height(80)
        .alignItems(VerticalAlign.Center)
      }
      .padding({ left: 48, right: 48, top: 20 })

      Scroll() {
        Column() {
          Column() {
            Text(this.labels().configUrl)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.textMain)
              .width('100%')
            Row() {
              TextInput({ text: this.apiUrl, placeholder: this.labels().configPlaceholder })
                .height(52)
                .fontSize(16)
                .backgroundColor(Color.Transparent)
                .borderRadius(10)
                .layoutWeight(1)
                .onChange((value: string) => this.apiUrl = value)
                .onSubmit(() => this.loadConfig())
              Button(this.labels().history)
                .width(62)
                .height(52)
                .margin({ left: 14 })
                .backgroundColor(this.cardBgStrong)
                .fontSize(16)
                .fontColor(this.textMain)
                .onClick(() => this.togglePanel('apiHistory'))
            }
            .width('100%')
            .margin({ top: 12 })

            Row() {
              Button(this.labels().loadConfig)
                .height(44)
                .backgroundColor(this.accent)
                .fontSize(16)
                .fontColor(this.textMain)
                .onClick(() => this.loadConfig())
              Button(this.labels().clearCache)
                .height(44)
                .margin({ left: 12 })
                .backgroundColor(this.cardBgStrong)
                .fontSize(16)
                .fontColor(this.textMain)
                .onClick(() => this.clearCache())
              Button(`${this.labels().homeSource} ${this.sources.length}`)
                .height(44)
                .margin({ left: 12 })
                .backgroundColor(this.cardBgStrong)
                .fontSize(16)
                .fontColor(this.textMain)
                .enabled(this.sources.length > 0)
                .onClick(() => this.togglePanel('homeSource'))
            }
            .width('100%')
            .margin({ top: 12 })

            if (this.panel === 'apiHistory') {
              Column() {
                ForEach(this.apiHistory, (item: string) => {
                  Row() {
                    Text(item)
                      .fontSize(13)
                      .fontColor(item === this.apiUrl ? this.accent : this.textMain)
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .width('100%')
                  .height(44)
                  .padding({ left: 14, right: 14 })
                  .backgroundColor(this.cardBg)
                  .borderRadius(10)
                  .margin({ bottom: 8 })
                  .focusable(true)
                  .onClick(() => {
                    this.apiUrl = item;
                    this.panel = '';
                    this.loadConfig();
                  })
                }, (item: string) => item)
              }
              .width('100%')
              .margin({ top: 10 })
            }

            if (this.panel === 'homeSource') {
              Column() {
                ForEach(this.sources, (source: SourceBean) => {
                  Row() {
                    Text(source.name)
                      .fontSize(14)
                      .fontColor(this.textMain)
                      .layoutWeight(1)
                    Text(`type=${source.type}`)
                      .fontSize(12)
                      .fontColor(this.textMuted)
                  }
                  .width('100%')
                  .height(42)
                  .padding({ left: 14, right: 14 })
                  .backgroundColor(source.key === this.homeApi ? this.cardBgStrong : this.cardBg)
                  .borderRadius(10)
                  .margin({ bottom: 8 })
                  .focusable(true)
                  .onClick(() => this.selectHomeSource(source))
                }, (source: SourceBean) => source.key)
              }
              .width('100%')
              .margin({ top: 10 })
            }

            Row() {
              TextInput({ text: this.liveUrl, placeholder: this.labels().livePlaceholder })
                .height(52)
                .fontSize(16)
                .backgroundColor(Color.Transparent)
                .borderRadius(10)
                .layoutWeight(1)
                .onChange((value: string) => {
                  this.liveUrl = value;
                  this.putString(HawkConfig.LIVE_URL, value);
                })
              TextInput({ text: this.epgUrl, placeholder: this.labels().epgPlaceholder })
                .height(52)
                .fontSize(16)
                .backgroundColor(Color.Transparent)
                .borderRadius(10)
                .layoutWeight(1)
                .margin({ left: 12 })
                .onChange((value: string) => {
                  this.epgUrl = value;
                  this.putString(HawkConfig.EPG_URL, value);
                })
              TextInput({ text: this.proxyServer, placeholder: this.labels().proxyPlaceholder })
                .height(52)
                .fontSize(16)
                .backgroundColor(Color.Transparent)
                .borderRadius(10)
                .layoutWeight(1)
                .margin({ left: 12 })
                .onChange((value: string) => {
                  this.proxyServer = value;
                  this.putString(HawkConfig.PROXY_SERVER, value);
                })
            }
            .width('100%')
            .margin({ top: 12 })
          }
          .width('100%')
          .padding(18)
          .backgroundColor(this.cardBg)
          .borderRadius(14)

          this.sectionTitle(this.labels().home)

          Row() {
            this.cell(this.labels().sourceDisplay, '', '', true, this.homeShowSource, '', (next: boolean) => {
              this.homeShowSource = next;
              this.putBoolean(HawkConfig.HOME_SHOW_SOURCE, next);
            })
            this.cell(this.labels().launchLive, '', '', true, this.homeDefaultShow, '', (next: boolean) => {
              this.homeDefaultShow = next;
              this.putBoolean(HawkConfig.HOME_DEFAULT_SHOW, next);
            })
          }
          .width('100%')
          .margin({ top: 8 })

          Row() {
            this.cell(this.labels().recommendation, '', this.optionLabel(HomeRecOptions, this.homeRec), false, false, 'homeRec', (next: boolean) => { }, HomeRecOptions, this.homeRec, (index: number) => {
              this.homeRec = index;
              this.putNumber(HawkConfig.HOME_REC, index);
            })
            this.cell(this.labels().historyCount, '', this.homeNumLabel(), false, false, 'homeNum', (next: boolean) => { }, HomeNumValues.map((value: number) => `${value}条`), this.homeNum, (index: number) => {
              this.homeNum = index;
              this.putNumber(HawkConfig.HOME_NUM, index);
            })
          }
          .width('100%')
          .margin({ top: 8 })

          Row() {
            this.cell(this.labels().searchPosition, '', '', true, this.homeSearchPosition, '', (next: boolean) => {
              this.homeSearchPosition = next;
              this.putBoolean(HawkConfig.HOME_SEARCH_POSITION, next);
            })
            this.cell(this.labels().menuPosition, '', '', true, this.homeMenuPosition, '', (next: boolean) => {
              this.homeMenuPosition = next;
              this.putBoolean(HawkConfig.HOME_MENU_POSITION, next);
            })
          }
          .width('100%')
          .margin({ top: 8 })

          Row() {
            this.cell(this.labels().recStyle, '', '', true, this.homeRecStyle, '', (next: boolean) => {
              this.homeRecStyle = next;
              this.putBoolean(HawkConfig.HOME_REC_STYLE, next);
            })
            Blank()
          }
          .width('100%')
          .margin({ top: 8 })

          this.sectionTitle(this.labels().player)
          Row() {
            this.cell(this.labels().scale, '', this.optionLabel(ScaleOptions, this.playScale), false, false, 'playScale', (next: boolean) => { }, ScaleOptions, this.playScale, (index: number) => {
              this.playScale = index;
              this.putNumber(HawkConfig.PLAY_SCALE, index);
            })
            this.cell(this.labels().playerType, '', this.optionLabel(PlayerOptions, this.playType), false, false, 'playType', (next: boolean) => { }, PlayerOptions, this.playType, (index: number) => {
              this.playType = index;
              this.putNumber(HawkConfig.PLAY_TYPE, index);
            })
          }
          .width('100%')
          .margin({ top: 8 })

          Row() {
            this.cell(this.labels().renderMode, '', this.optionLabel(RenderOptions, this.playRender), false, false, 'playRender', (next: boolean) => { }, RenderOptions, this.playRender, (index: number) => {
              this.playRender = index;
              this.putNumber(HawkConfig.PLAY_RENDER, index);
            })
            this.cell(this.labels().codec, '', this.ijkCodec, false, false, 'ijkCodec', (next: boolean) => { }, IjkCodecOptions, IjkCodecOptions.indexOf(this.ijkCodec), (index: number) => {
              this.ijkCodec = IjkCodecOptions[index];
              this.putString(HawkConfig.IJK_CODEC, this.ijkCodec);
            })
          }
          .width('100%')
          .margin({ top: 8 })

          Row() {
            this.cell(this.labels().backgroundPlay, '', this.optionLabel(BackgroundPlayOptions, this.backgroundPlay), false, false, 'bgPlay', (next: boolean) => { }, BackgroundPlayOptions, this.backgroundPlay, (index: number) => {
              this.backgroundPlay = index;
              this.putNumber(HawkConfig.BACKGROUND_PLAY_TYPE, index);
            })
            this.cell(this.labels().seekStep, '', `${this.playTimeStep}s`, false, false, 'timeStep', (next: boolean) => { }, ['5s', '10s', '15s', '30s'], [5, 10, 15, 30].indexOf(this.playTimeStep), (index: number) => {
              this.playTimeStep = [5, 10, 15, 30][index];
              this.putNumber(HawkConfig.PLAY_TIME_STEP, this.playTimeStep);
            })
          }
          .width('100%')
          .margin({ top: 8 })

          Row() {
            this.cell(this.labels().preview, '', '', true, this.showPreview, '', (next: boolean) => {
              this.showPreview = next;
              this.putBoolean(HawkConfig.SHOW_PREVIEW, next);
            })
            this.cell(this.labels().purify, '', '', true, this.videoPurify, '', (next: boolean) => {
              this.videoPurify = next;
              this.putBoolean(HawkConfig.VIDEO_PURIFY, next);
            })
          }
          .width('100%')
          .margin({ top: 8 })

          this.sectionTitle(this.labels().live)
          Row() {
            this.cell(this.labels().reverseChannel, '', '', true, this.liveChannelReverse, '', (next: boolean) => {
              this.liveChannelReverse = next;
              this.putBoolean(HawkConfig.LIVE_CHANNEL_REVERSE, next);
            })
            this.cell(this.labels().crossGroup, '', '', true, this.liveCrossGroup, '', (next: boolean) => {
              this.liveCrossGroup = next;
              this.putBoolean(HawkConfig.LIVE_CROSS_GROUP, next);
            })
          }
          .width('100%')
          .margin({ top: 8 })

          Row() {
            this.cell(this.labels().showTime, '', '', true, this.liveShowTime, '', (next: boolean) => {
              this.liveShowTime = next;
              this.putBoolean(HawkConfig.LIVE_SHOW_TIME, next);
            })
            this.cell(this.labels().showNetSpeed, '', '', true, this.liveShowNetSpeed, '', (next: boolean) => {
              this.liveShowNetSpeed = next;
              this.putBoolean(HawkConfig.LIVE_SHOW_NET_SPEED, next);
            })
          }
          .width('100%')
          .margin({ top: 8 })

          Row() {
            this.cell(this.labels().skipPassword, '', '', true, this.liveSkipPassword, '', (next: boolean) => {
              this.liveSkipPassword = next;
              this.putBoolean(HawkConfig.LIVE_SKIP_PASSWORD, next);
            })
            this.cell(this.labels().liveTimeout, '', this.optionLabel(LiveTimeoutOptions, this.liveConnectTimeout), false, false, 'liveTimeout', (next: boolean) => { }, LiveTimeoutOptions, this.liveConnectTimeout, (index: number) => {
              this.liveConnectTimeout = index;
              this.putNumber(HawkConfig.LIVE_CONNECT_TIMEOUT, index);
            })
          }
          .width('100%')
          .margin({ top: 8 })

          this.sectionTitle(this.labels().system)
          Row() {
            this.cell(this.labels().searchView, '', this.optionLabel(SearchViewOptions, this.searchView), false, false, 'searchView', (next: boolean) => { }, SearchViewOptions, this.searchView, (index: number) => {
              this.searchView = index;
              this.putNumber(HawkConfig.SEARCH_VIEW, index);
            })
            this.cell(this.labels().fastSearch, '', '', true, this.fastSearchMode, '', (next: boolean) => {
              this.fastSearchMode = next;
              this.putBoolean(HawkConfig.FAST_SEARCH_MODE, next);
            })
          }
          .width('100%')
          .margin({ top: 8 })

          Row() {
            this.cell(this.labels().locale, '', this.optionLabel(LocaleOptions, this.homeLocale), false, false, 'locale', (next: boolean) => { }, LocaleOptions, this.homeLocale, (index: number) => {
              this.homeLocale = index;
              appearanceService.setLocale(index);
              this.putNumber(HawkConfig.HOME_LOCALE, index);
            })
            this.cell(this.labels().theme, '', this.optionLabel(ThemeOptions, this.themeSelect), false, false, 'theme', (next: boolean) => { }, ThemeOptions, this.themeSelect, (index: number) => {
              this.themeSelect = index;
              appearanceService.setTheme(index);
              this.putNumber(HawkConfig.THEME_SELECT, index);
            })
          }
          .width('100%')
          .margin({ top: 8 })

          Row() {
            this.cell(this.labels().dns, '', this.optionLabel(DnsOptions, this.dohUrl), false, false, 'dns', (next: boolean) => { }, DnsOptions, this.dohUrl, (index: number) => {
              this.dohUrl = index;
              this.putNumber(HawkConfig.DOH_URL, index);
            })
            this.cell(this.labels().sniffWebView, '', '', true, this.parseWebView, '', (next: boolean) => {
              this.parseWebView = next;
              this.putBoolean(HawkConfig.PARSE_WEBVIEW, next);
            })
          }
          .width('100%')
          .margin({ top: 8 })

          Row() {
            this.cell(this.labels().debug, '', '', true, this.debugOpen, '', (next: boolean) => {
              this.debugOpen = next;
              this.putBoolean(HawkConfig.DEBUG_OPEN, next);
            })
            Blank()
          }
          .width('100%')
          .margin({ top: 8 })

          this.sectionTitle(this.labels().data)
          Row() {
            Button(this.labels().clearWatchHistory)
              .height(42)
              .backgroundColor(this.cardBgStrong)
              .fontSize(16)
              .fontColor(this.textMain)
              .onClick(() => this.clearHistoryRecords())
            Button(this.labels().clearSearchHistory)
              .height(42)
              .margin({ left: 12 })
              .backgroundColor(this.cardBgStrong)
              .fontSize(16)
              .fontColor(this.textMain)
              .onClick(() => this.clearSearchRecords())
          }
          .width('100%')
          .margin({ top: 8 })

          Row() {
            Button(this.labels().backup)
              .height(42)
              .backgroundColor(this.cardBgStrong)
              .fontSize(16)
              .fontColor(this.textMain)
              .onClick(() => this.createBackup())
            Button(this.labels().restore)
              .height(42)
              .margin({ left: 12 })
              .backgroundColor(this.cardBgStrong)
              .fontSize(16)
              .fontColor(this.textMain)
              .onClick(() => this.togglePanel('backupList'))
            Button(this.labels().resetApp)
              .height(42)
              .margin({ left: 12 })
              .backgroundColor(this.accent)
              .fontSize(16)
              .fontColor(this.textMain)
              .onClick(() => this.resetApp())
          }
          .width('100%')
          .margin({ top: 8 })

          if (this.panel === 'backupList') {
            Column() {
              if (this.backupList.length === 0) {
                Text(this.labels().noBackup)
                  .fontSize(14)
                  .fontColor(this.textMuted)
                  .padding({ top: 8, bottom: 8 })
              } else {
                ForEach(this.backupList, (item: string) => {
                  Row() {
                    Text(item)
                      .fontSize(13)
                      .fontColor(this.textMain)
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Button(this.labels().restore)
                      .height(32)
                      .fontSize(12)
                      .margin({ right: 8 })
                      .backgroundColor(this.cardBgStrong)
                      .fontColor(this.textMain)
                      .onClick(() => this.restoreBackup(item))
                    Button('删除')
                      .height(32)
                      .fontSize(12)
                      .backgroundColor(this.accent)
                      .fontColor(this.textMain)
                      .onClick(() => this.deleteBackupEntry(item))
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

      if (this.pickVisible) {
        this.renderPicker()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.pageBg)
  }
}
