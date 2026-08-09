import router from '@ohos.router';
import { HawkConfig } from '../constants/HawkConfig';
import { HomeNumValues } from '../constants/AppDefaults';
import { MovieSort, SourceBean, VodInfo } from '../models/TvBoxModels';
import { vodDataStore } from '../services/VodDataStore';
import { apiConfigService } from '../services/ApiConfigService';
import { appearanceService, HomeLabels, ThemePalette } from '../services/AppearanceService';
import { settingsStore } from '../services/SettingsStore';
import { sourceService } from '../services/SourceService';
import { errorMessage } from '../utils/ErrorUtil';

interface HomeEntry {
  title: string;
  page: string;
  desc: string;
}

@Entry
@Component
struct Home {
  @State sourceName: string = '';
  @State statusText: string = '';
  @State contentStatus: string = '';
  @State contentLoading: boolean = false;
  @State sourceCount: number = 0;
  @State sources: SourceBean[] = [];
  @State categories: MovieSort[] = [];
  @State recommendations: VodInfo[] = [];
  @State homeRec: number = 1;
  @State showSource: boolean = true;
  @State themeSelect: number = 0;
  @State homeLocale: number = 0;
  @State homeSearchPosition: boolean = false;
  @State homeMenuPosition: boolean = true;
  @State homeRecStyle: boolean = false;
  @State wallpaperUrl: string = '';
  @State entries: HomeEntry[] = [
    { title: 'live', page: 'pages/Live', desc: 'LivePlayActivity' },
    { title: 'search', page: 'pages/Search', desc: 'SearchActivity' },
    { title: 'fastSearch', page: 'pages/FastSearch', desc: 'FastSearchActivity' },
    { title: 'history', page: 'pages/History', desc: 'HistoryActivity' },
    { title: 'favorites', page: 'pages/Favorites', desc: 'CollectActivity' },
    { title: 'push', page: 'pages/Push', desc: 'PushActivity' },
    { title: 'drive', page: 'pages/Drive', desc: 'DriveActivity' },
    { title: 'apps', page: 'pages/Apps', desc: 'AppsActivity' },
    { title: 'settings', page: 'pages/Settings', desc: 'SettingActivity' }
  ];
  private readonly homeBg = '#050505';
  private readonly homeCardBg = '#2f2f2f';
  private readonly homeCardBgSoft = 'rgba(47, 47, 47, 0.92)';
  private readonly homeText = '#ffffff';
  private readonly homeTextSoft = '#b9b9b9';
  private readonly homeAccent = '#e02a2a';
  private readonly homeBottomBg = '#f6f6f6';
  private readonly homeBottomHandle = '#e2e2e2';
  private readonly homeMenuLabels: string[] = ['首页', '我的豆瓣', '热门电影', '热播剧集', '热播综艺', '电影筛选', '电视筛选', '电影排行'];
  private readonly homeActions: Array<{ title: string; icon: string; page: string }> = [
    { title: '历史', icon: '↻', page: 'pages/History' },
    { title: '直播', icon: '▶', page: 'pages/Live' },
    { title: '收藏', icon: '★', page: 'pages/Favorites' },
    { title: '推送', icon: '⚡', page: 'pages/Push' },
    { title: '文件', icon: '▣', page: 'pages/Drive' }
  ];

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
    await appearanceService.init();
    this.homeRec = await settingsStore.get<number>(HawkConfig.HOME_REC, 1);
    this.showSource = await settingsStore.get<boolean>(HawkConfig.HOME_SHOW_SOURCE, true);
    this.themeSelect = await settingsStore.get<number>(HawkConfig.THEME_SELECT, 0);
    this.homeLocale = await settingsStore.get<number>(HawkConfig.HOME_LOCALE, 0);
    this.homeSearchPosition = await settingsStore.get<boolean>(HawkConfig.HOME_SEARCH_POSITION, false);
    this.homeMenuPosition = await settingsStore.get<boolean>(HawkConfig.HOME_MENU_POSITION, true);
    this.homeRecStyle = await settingsStore.get<boolean>(HawkConfig.HOME_REC_STYLE, false);
    appearanceService.setTheme(this.themeSelect);
    appearanceService.setLocale(this.homeLocale);
    // Android `HOME_DEFAULT_SHOW`: jump straight into live playback on launch.
    if (await settingsStore.get<boolean>(HawkConfig.HOME_DEFAULT_SHOW, false)) {
      router.pushUrl({ url: 'pages/Live' });
    }
    const apiUrl = await settingsStore.get<string>(HawkConfig.API_URL, '');
    if (apiUrl && Object.keys(apiConfigService.state.sourceBeanList).length === 0) {
      try {
        this.statusText = this.labels().loadingConfig;
        await apiConfigService.loadConfigFromSettings(true);
      } catch (error) {
        this.statusText = `${this.labels().configLoadFailedPrefix}${JSON.stringify(error)}`;
      }
    }
    this.refreshConfigSummary();
    await this.loadHomeContent();
  }

  refreshConfigSummary(): void {
    const state = apiConfigService.state;
    const sources: SourceBean[] = Object.keys(state.sourceBeanList).map((key: string) => state.sourceBeanList[key]);
    this.sources = sources.filter((source: SourceBean) => source.hide === 0);
    this.sourceCount = sources.length;
    const labels = this.labels();
    this.sourceName = state.homeSource?.name || labels.unloadedConfig;
    this.statusText = sources.length > 0
      ? `${labels.configReadyPrefix}${sources.length}${labels.configReadySuffix}`
      : labels.configEmpty;
  }

  theme(): ThemePalette {
    return appearanceService.themeByIndex(this.themeSelect);
  }

  labels(): HomeLabels {
    appearanceService.setLocale(this.homeLocale);
    return appearanceService.homeLabels();
  }

  entryTitle(key: string): string {
    const labels = this.labels();
    switch (key) {
      case 'live':
        return labels.live;
      case 'search':
        return labels.search;
      case 'fastSearch':
        return labels.fastSearch;
      case 'history':
        return labels.history;
      case 'favorites':
        return labels.favorites;
      case 'push':
        return labels.push;
      case 'drive':
        return labels.drive;
      case 'apps':
        return labels.apps;
      case 'settings':
        return labels.settings;
      default:
        return key;
    }
  }

  open(page: string): void {
    router.pushUrl({ url: page });
  }

  async selectHomeSource(source: SourceBean): Promise<void> {
    await apiConfigService.setHomeSource(source);
    this.refreshConfigSummary();
    await this.loadHomeContent();
  }

  async loadHomeContent(): Promise<void> {
    const source = apiConfigService.state.homeSource;
    this.wallpaperUrl = apiConfigService.state.wallpaper || '';
    this.categories = [];
    this.recommendations = [];
    if (source === undefined) {
      this.contentStatus = '';
      return;
    }
    if (source.type !== 0 && source.type !== 1 && source.type !== 4) {
      const labels = this.labels();
      this.contentStatus = `${labels.spiderPendingPrefix}${source.name}${labels.spiderPendingMiddle}${source.type}${labels.spiderPendingSuffix}`;
      return;
    }
    this.contentLoading = true;
    this.contentStatus = `${this.labels().loadingHomePrefix}${source.name}`;
    try {
      const content = await sourceService.getHomeContent(source);
      this.categories = content.classes;
      if (this.homeRec === 2) {
        // Android `HOME_REC` 2 shows watch history instead of site recommendations.
        const limitIndex = await settingsStore.get<number>(HawkConfig.HOME_NUM, 4);
        const limit = limitIndex >= 0 && limitIndex < HomeNumValues.length
          ? HomeNumValues[limitIndex]
          : HomeNumValues[0];
        this.recommendations = vodDataStore.getAllVodRecord(limit);
        const labels = this.labels();
        this.contentStatus = `${labels.homeCategoryPrefix}${content.classes.length}${labels.homeCategoryMiddleHistory}${this.recommendations.length}${labels.homeCategorySuffix}`;
      } else {
        this.recommendations = content.list;
        const labels = this.labels();
        this.contentStatus = `${labels.homeCategoryPrefix}${content.classes.length}${labels.homeCategoryMiddleRecommend}${content.list.length}${labels.homeCategorySuffix}`;
      }
    } catch (error) {
      this.contentStatus = `${this.labels().homeContentFailedPrefix}${errorMessage(error)}`;
    } finally {
      this.contentLoading = false;
    }
  }

  openCategory(category: MovieSort): void {
    const source = apiConfigService.state.homeSource;
    if (source === undefined) {
      return;
    }
    router.pushUrl({
      url: 'pages/Category',
      params: {
        sourceKey: source.key,
        typeId: category.sortId
      }
    });
  }

  openVod(vod: VodInfo): void {
    const sourceKey = vod.sourceKey === undefined ? apiConfigService.state.homeSource?.key || '' : vod.sourceKey;
    if (sourceKey.length === 0 || vod.id.length === 0) {
      return;
    }
    router.pushUrl({
      url: 'pages/Detail',
      params: {
        sourceKey,
        vodId: vod.id
      }
    });
  }

  private gridEntries(): HomeEntry[] {
    return this.entries.filter((entry: HomeEntry) => {
      if (entry.title === 'search' && this.homeSearchPosition) {
        return false;
      }
      if (entry.title === 'settings' && this.homeMenuPosition) {
        return false;
      }
      return true;
    });
  }

  private topEntries(): HomeEntry[] {
    return this.entries.filter((entry: HomeEntry) => {
      if (entry.title === 'search' && this.homeSearchPosition) {
        return true;
      }
      if (entry.title === 'settings' && this.homeMenuPosition) {
        return true;
      }
      return false;
    });
  }

  private openQuick(page: string): void {
    this.open(page);
  }


  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.homeBg)

      if (this.wallpaperUrl.length > 0) {
        Image(this.wallpaperUrl)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .opacity(0.08)
      }

      Row()
        .width(760)
        .height(760)
        .borderRadius(380)
        .border({ width: 18, color: 'rgba(255, 255, 255, 0.04)' })
        .backgroundColor('rgba(255, 255, 255, 0.02)')
        .position({ x: 1080, y: -220 })

      Row()
        .width(560)
        .height(560)
        .borderRadius(280)
        .border({ width: 12, color: 'rgba(255, 255, 255, 0.05)' })
        .backgroundColor('rgba(255, 255, 255, 0.015)')
        .position({ x: 1280, y: -120 })

      Row()
        .width(350)
        .height(350)
        .borderRadius(175)
        .border({ width: 10, color: 'rgba(255, 255, 255, 0.07)' })
        .backgroundColor('rgba(255, 255, 255, 0.02)')
        .position({ x: 1570, y: 50 })

      Column() {
        Row() {
          Row()
            .width(6)
            .height(56)
            .backgroundColor(this.homeAccent)
            .borderRadius(4)

          Row() {
            Text('🐰')
              .fontSize(42)
              .fontColor(this.homeText)
              .margin({ right: 6 })
            Text('蔡home')
              .fontSize(40)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.homeText)
          }
          .alignItems(VerticalAlign.Center)
          .margin({ left: 18 })

          Row() {
            ForEach(this.homeActions, (action: { title: string; icon: string; page: string }) => {
              Column() {
                Text(action.icon)
                  .fontSize(34)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.homeText)
                  .textAlign(TextAlign.Center)
                  .width(44)
                Text(action.title)
                  .fontSize(12)
                  .fontColor(this.homeTextSoft)
                  .margin({ top: 2 })
              }
              .width(68)
              .alignItems(HorizontalAlign.Center)
              .margin({ left: 26 })
              .focusable(true)
              .onClick(() => this.openQuick(action.page))
            }, (action: { title: string; icon: string; page: string }) => action.title)

            Text('08月08日, 周六 18:51')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.homeText)
              .margin({ left: 30 })
          }
          .alignItems(VerticalAlign.Center)
          .layoutWeight(1)
          .justifyContent(FlexAlign.End)
        }
        .width('100%')
        .padding({ left: 48, right: 48, top: 22, bottom: 0 })

        Scroll() {
          Row() {
            ForEach(this.homeMenuLabels, (title: string, index: number) => {
              Text(title)
                .fontSize(index === 0 ? 36 : 30)
                .fontWeight(index === 0 ? FontWeight.Medium : FontWeight.Regular)
                .fontColor(index === 0 ? this.homeText : this.homeTextSoft)
                .margin({ right: 72 })
                .focusable(true)
            }, (title: string) => title)
          }
          .alignItems(VerticalAlign.Center)
          .padding({ left: 4, right: 4 })
        }
        .scrollable(ScrollDirection.Horizontal)
        .width('100%')
        .height(74)
        .margin({ left: 48, right: 48, top: 8 })

        Row() {
          ForEach(this.homeActions, (action: { title: string; icon: string; page: string }) => {
            Row() {
              Text(action.icon)
                .fontSize(30)
                .fontWeight(FontWeight.Medium)
                .fontColor(this.homeText)
                .width(40)
                .textAlign(TextAlign.Center)
              Text(action.title)
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.homeText)
                .margin({ left: 18 })
            }
            .width(210)
            .height(148)
            .padding({ left: 24, right: 20 })
            .backgroundColor(this.homeCardBgSoft)
            .borderRadius(20)
            .alignItems(VerticalAlign.Center)
            .focusable(true)
            .onClick(() => this.openQuick(action.page))
            .margin({ right: 14 })
          }, (action: { title: string; icon: string; page: string }) => action.title)
        }
        .alignItems(VerticalAlign.Center)
        .margin({ left: 48, top: 28 })

        Blank()
          .layoutWeight(1)

        Row() {
          Blank().layoutWeight(1)
          Row()
            .width(520)
            .height(10)
            .backgroundColor(this.homeBottomHandle)
            .borderRadius(5)
          Blank().layoutWeight(1)
        }
        .width('100%')
        .height(40)
        .backgroundColor(this.homeBottomBg)
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.theme().pageBg)
  }
}
