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


  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (this.wallpaperUrl.length > 0) {
        Image(this.wallpaperUrl)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .opacity(0.15)
      }

      Column() {
        Row() {
          Column() {
            Text('TVBox')
              .fontSize(34)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.theme().text)
            Text(this.statusText)
              .fontSize(16)
              .fontColor(this.theme().mutedText)
              .margin({ top: 8 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          if (this.topEntries().length > 0) {
            Row() {
              ForEach(this.topEntries(), (entry: HomeEntry) => {
                Text(this.entryTitle(entry.title))
                  .fontSize(15)
                  .fontColor(this.theme().text)
                  .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                  .margin({ left: 8 })
                  .backgroundColor(this.theme().panelBg)
                  .borderRadius(16)
                  .focusable(true)
                  .onClick(() => this.open(entry.page))
              }, (entry: HomeEntry) => entry.title)
            }
            .alignItems(VerticalAlign.Center)
          }

          Column() {
            Text(this.labels().currentSource)
              .fontSize(14)
              .fontColor(this.theme().mutedText)
            Text(this.sourceName)
              .fontSize(18)
              .fontColor(this.theme().text)
              .fontWeight(FontWeight.Medium)
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.End)
          .margin({ left: 16 })
        }
        .width('100%')
        .padding({ left: 48, right: 48, top: 32, bottom: 24 })

        Grid() {
          ForEach(this.gridEntries(), (entry: HomeEntry) => {
            GridItem() {
              Column() {
                Text(this.entryTitle(entry.title))
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.theme().text)
                Text(entry.desc)
                  .fontSize(13)
                  .fontColor(this.theme().mutedText)
                  .margin({ top: 10 })
              }
              .width('100%')
              .height('100%')
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .borderRadius(18)
              .backgroundColor(this.theme().panelBg)
              .focusable(true)
              .onClick(() => this.open(entry.page))
            }
          }, (entry: HomeEntry) => entry.title)
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsGap(18)
        .columnsGap(18)
        .padding({ left: 48, right: 48 })

        if (this.sources.length > 0 && this.showSource) {
          Column() {
            if (this.contentStatus.length > 0) {
              Row() {
                Text(this.labels().homeContent)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.theme().text)
                Text(this.contentLoading ? this.labels().loading : this.contentStatus)
                  .fontSize(14)
                  .fontColor(this.theme().mutedText)
                  .margin({ left: 12 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .alignItems(VerticalAlign.Center)
            }

            if (this.categories.length > 0) {
              Scroll() {
                Row() {
                  ForEach(this.categories, (category: MovieSort) => {
                    Text(category.sortName)
                      .fontSize(15)
                      .fontColor(this.theme().text)
                      .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                      .margin({ right: 10 })
                      .backgroundColor(this.theme().panelBg)
                      .borderRadius(16)
                      .focusable(true)
                      .onClick(() => this.openCategory(category))
                  }, (category: MovieSort) => category.sortId)
                }
              }
              .scrollable(ScrollDirection.Horizontal)
              .width('100%')
              .margin({ top: 12 })
            }

            if (this.recommendations.length > 0) {
              if (this.homeRecStyle) {
                Grid() {
                  ForEach(this.recommendations.slice(0, 8), (vod: VodInfo) => {
                    GridItem() {
                      Column() {
                        Text(vod.name)
                          .fontSize(14)
                          .fontColor(this.theme().text)
                          .maxLines(2)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                        Text(vod.note === undefined ? '' : vod.note)
                          .fontSize(11)
                          .fontColor(this.theme().mutedText)
                          .margin({ top: 4 })
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                      }
                      .width('100%')
                      .height('100%')
                      .padding(8)
                      .backgroundColor(this.theme().fieldBg)
                      .borderRadius(10)
                      .onClick(() => this.openVod(vod))
                    }
                  }, (vod: VodInfo) => `${vod.sourceKey || ''}:${vod.id}`)
                }
                .columnsTemplate('1fr 1fr 1fr 1fr')
                .rowsGap(8)
                .columnsGap(8)
                .height(150)
                .margin({ top: 10 })
              } else {
                List() {
                  ForEach(this.recommendations.slice(0, 8), (vod: VodInfo) => {
                    ListItem() {
                      Row() {
                        Text(vod.name)
                          .fontSize(16)
                          .fontColor(this.theme().text)
                          .layoutWeight(1)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                        Text(vod.note === undefined ? '' : vod.note)
                          .fontSize(12)
                          .fontColor(this.theme().mutedText)
                          .width(160)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                      }
                      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
                      .backgroundColor(this.theme().fieldBg)
                      .borderRadius(10)
                      .onClick(() => this.openVod(vod))
                    }.margin({ top: 8 })
                  }, (vod: VodInfo) => `${vod.sourceKey || ''}:${vod.id}`)
                }
                .height(150)
                .margin({ top: 10 })
              }
            }

            Row() {
              Text(this.labels().dataSources)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.theme().text)
              Text(`${this.sources.length}${this.labels().visibleSourceSuffix}`)
                .fontSize(14)
                .fontColor(this.theme().mutedText)
                .margin({ left: 12 })
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .margin({ top: 18 })

            List() {
              ForEach(this.sources, (source: SourceBean) => {
                ListItem() {
                  Row() {
                    Text(source.name)
                      .fontSize(17)
                      .fontColor(this.theme().text)
                      .layoutWeight(1)
                    Text(source.api)
                      .fontSize(12)
                      .fontColor(this.theme().mutedText)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('50%')
                  }
                  .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                  .backgroundColor(source.key === apiConfigService.state.homeSource?.key ? this.theme().cardActiveBg : this.theme().cardBg)
                  .borderRadius(12)
                  .focusable(true)
                  .onClick(() => {
                    this.selectHomeSource(source);
                  })
                }
              })
            }
            .height(170)
            .margin({ top: 12 })
          }
          .padding({ left: 48, right: 48, top: 24, bottom: 40 })
          .layoutWeight(1)
        } else {
          Blank()
            .layoutWeight(1)
        }
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.theme().pageBg)
  }
}
