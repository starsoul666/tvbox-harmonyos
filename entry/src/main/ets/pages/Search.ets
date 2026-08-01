import router from '@ohos.router';
import { HawkConfig } from '../constants/HawkConfig';
import { SourceBean, SourceSearchResult, VodInfo } from '../models/TvBoxModels';
import { appearanceService, FeatureLabels, ThemePalette } from '../services/AppearanceService';
import { searchSourceStore } from '../services/SearchSourceStore';
import { settingsStore } from '../services/SettingsStore';
import { sourceService } from '../services/SourceService';
import { SearchHistoryItem, vodDataStore } from '../services/VodDataStore';
import { errorMessage } from '../utils/ErrorUtil';

@Entry
@Component
struct SearchPage {
  @State keyword: string = '';
  @State histories: SearchHistoryItem[] = [];
  @State groups: SourceSearchResult[] = [];
  @State searching: boolean = false;
  @State statusText: string = '输入关键词后搜索已加载配置中的数据源';
  @State sources: SourceBean[] = [];
  @State checkedKeys: string[] = [];
  @State showSourcePicker: boolean = false;
  @State fastSearchMode: boolean = false;
  @State thumbnailView: boolean = true;
  @State themeSelect: number = 0;
  @State localeSelect: number = 0;
  @State filterKey: string = '';

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
    await appearanceService.init();
    this.themeSelect = await settingsStore.get<number>(HawkConfig.THEME_SELECT, 0);
    this.localeSelect = await settingsStore.get<number>(HawkConfig.HOME_LOCALE, 0);
    this.statusText = this.labels().searchInitialStatus;
    this.fastSearchMode = await settingsStore.get<boolean>(HawkConfig.FAST_SEARCH_MODE, false);
    this.thumbnailView = (await settingsStore.get<number>(HawkConfig.SEARCH_VIEW, 1)) === 1;
    this.filterKey = await settingsStore.get<string>(HawkConfig.SEARCH_FILTER_KEY, '');
    this.sources = searchSourceStore.searchableSources();
    this.checkedKeys = await searchSourceStore.getCheckedKeys();
    this.refreshHistory();
    const rawParams = router.getParams();
    if (rawParams !== undefined) {
      const params = rawParams as Record<string, string>;
      if (params['keyword'] !== undefined) {
        this.keyword = String(params['keyword']);
        this.submitSearch();
      }
    }
  }

  refreshHistory(): void {
    this.histories = vodDataStore.getSearchHistory().reverse();
  }

  isChecked(source: SourceBean): boolean {
    return this.checkedKeys.includes(source.key);
  }

  async toggleSource(source: SourceBean): Promise<void> {
    const next = this.isChecked(source)
      ? this.checkedKeys.filter((key: string) => key !== source.key)
      : this.checkedKeys.concat([source.key]);
    this.checkedKeys = next;
    await searchSourceStore.setCheckedKeys(next);
  }

  matchesFilter(vod: VodInfo): boolean {
    if (this.filterKey.trim().length === 0) {
      return true;
    }
    return vod.name.includes(this.filterKey.trim());
  }

  filteredList(group: SourceSearchResult): VodInfo[] {
    return group.result.list.filter((vod: VodInfo) => this.matchesFilter(vod));
  }

  async selectAllSources(): Promise<void> {
    this.checkedKeys = this.sources.map((source: SourceBean) => source.key);
    await searchSourceStore.setCheckedKeys(this.checkedKeys);
  }

  async selectNoSources(): Promise<void> {
    this.checkedKeys = [];
    await searchSourceStore.setCheckedKeys(this.checkedKeys);
  }

  async submitSearch(): Promise<void> {
    const value = this.keyword.trim();
    if (value.length === 0) {
      return;
    }
    if (this.checkedKeys.length === 0) {
      this.statusText = this.labels().searchNoSource;
      return;
    }
    vodDataStore.addSearchKeyword(value);
    this.refreshHistory();
    this.searching = true;
    this.statusText = `${this.labels().searchingPrefix}${value}`;
    this.groups = [];
    try {
      const results = await sourceService.searchAll(value, this.fastSearchMode, this.checkedKeys);
      this.groups = results.filter((item: SourceSearchResult) => item.result.list.length > 0 || !!item.error);
      const hitCount = results.reduce((count: number, item: SourceSearchResult) => count + item.result.list.length, 0);
      const errorCount = results.filter((item: SourceSearchResult) => !!item.error).length;
      if (hitCount > 0) {
        this.statusText = `${this.labels().searchFoundPrefix}${hitCount}${this.labels().searchFoundMiddle}${errorCount}${this.labels().searchFoundSuffix}`;
      } else {
        this.statusText = errorCount > 0 ? `${this.labels().searchNoResult}${this.labels().searchFoundMiddle}${errorCount}${this.labels().searchFoundSuffix}` : this.labels().searchNoResult;
      }
    } catch (error) {
      this.statusText = `${this.labels().searchFailedPrefix}${errorMessage(error as Error)}`;
    } finally {
      this.searching = false;
    }
  }

  openDetail(sourceKey: string, vodId: string): void {
    router.pushUrl({
      url: 'pages/Detail',
      params: { sourceKey, vodId }
    });
  }

  theme(): ThemePalette {
    return appearanceService.themeByIndex(this.themeSelect);
  }

  labels(): FeatureLabels {
    appearanceService.setLocale(this.localeSelect);
    return appearanceService.featureLabels();
  }

  build() {
    Column() {
      Row() {
        Text(this.labels().back)
          .fontSize(18)
          .fontColor(this.theme().text)
          .focusable(true)
          .onClick(() => router.back())
        Text(this.labels().searchTitle)
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme().text)
          .margin({ left: 20 })
          .layoutWeight(1)
        Button(`${this.labels().searchSourcesButtonPrefix}${this.checkedKeys.length}/${this.sources.length}`)
          .height(38)
          .enabled(this.sources.length > 0)
          .onClick(() => this.showSourcePicker = !this.showSourcePicker)
        Button(this.labels().fastSearchButton)
          .height(38)
          .margin({ left: 10 })
          .onClick(() => router.pushUrl({ url: 'pages/FastSearch', params: { keyword: this.keyword } }))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row() {
        TextInput({ text: this.keyword, placeholder: this.labels().searchInputPlaceholder })
          .height(50)
          .fontSize(17)
          .layoutWeight(1)
          .onChange((value: string) => this.keyword = value)
          .onSubmit(() => this.submitSearch())
        Button(this.searching ? this.labels().searchingButton : this.labels().searchButton)
          .height(50)
          .margin({ left: 12 })
          .enabled(!this.searching)
          .onClick(() => this.submitSearch())
      }
      .width('100%')
      .margin({ top: 18 })

      Row() {
        Text(this.labels().searchFilterPlaceholder)
          .fontSize(13)
          .fontColor(this.theme().mutedText)
          .width(80)
        TextInput({ text: this.filterKey, placeholder: this.labels().searchFilterPlaceholder })
          .height(40)
          .fontSize(14)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.filterKey = value;
            settingsStore.put(HawkConfig.SEARCH_FILTER_KEY, value);
          })
      }
      .width('100%')
      .margin({ top: 8 })

      Text(this.statusText)
        .fontSize(14)
        .fontColor(this.theme().mutedText)
        .margin({ top: 10 })
        .width('100%')

      if (this.showSourcePicker) {
        Column() {
          Row() {
            Text(this.labels().searchSourceTitle).fontSize(16).fontColor(this.theme().text).layoutWeight(1)
            Button(this.labels().selectAll).height(32).onClick(() => this.selectAllSources())
            Button(this.labels().selectNone).height(32).margin({ left: 8 }).onClick(() => this.selectNoSources())
            Text(this.labels().close)
              .fontSize(14)
              .fontColor('#fca5a5')
              .margin({ left: 12 })
              .focusable(true)
              .onClick(() => this.showSourcePicker = false)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.sources, (source: SourceBean) => {
              Text(source.name)
                .fontSize(13)
                .fontColor(this.theme().text)
                .padding({ left: 12, right: 12, top: 7, bottom: 7 })
                .margin({ right: 8, top: 8 })
                .backgroundColor(this.isChecked(source) ? this.theme().primary : this.theme().panelBg)
                .borderRadius(8)
                .focusable(true)
                .onClick(() => this.toggleSource(source))
            }, (source: SourceBean) => source.key)
          }
          .width('100%')
        }
        .width('100%')
        .padding(14)
        .margin({ top: 12 })
        .backgroundColor(this.theme().cardBg)
        .borderRadius(12)
      }

      if (this.groups.length === 0) {
        Row() {
          Text(this.labels().searchHistory).fontSize(17).fontColor(this.theme().text).layoutWeight(1)
          Text(this.labels().clear)
            .fontSize(14)
            .fontColor('#fca5a5')
            .focusable(true)
            .onClick(() => {
              vodDataStore.clearSearchKeywords();
              this.refreshHistory();
            })
        }
        .width('100%')
        .margin({ top: 22 })

        if (this.histories.length === 0) {
          Text(this.labels().emptySearchHistory).fontSize(15).fontColor(this.theme().subtleText).margin({ top: 12 }).width('100%')
        } else {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.histories, (item: SearchHistoryItem) => {
              Text(item.searchKeyWords)
                .fontSize(15)
                .fontColor(this.theme().text)
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .margin({ right: 10, top: 10 })
                .backgroundColor(this.theme().panelBg)
                .borderRadius(18)
                .focusable(true)
                .onClick(() => {
                  this.keyword = item.searchKeyWords;
                  this.submitSearch();
                })
            }, (item: SearchHistoryItem) => `${item.id}`)
          }
          .width('100%')
        }
        Blank().layoutWeight(1)
      } else {
        List() {
          ForEach(this.groups, (group: SourceSearchResult) => {
            ListItem() {
              Column() {
                Row() {
                  Text(group.source.name)
                    .fontSize(17)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.theme().text)
                    .layoutWeight(1)
                   Text(group.error !== undefined && group.error.length > 0 ? this.labels().failed : `${this.filteredList(group).length}${this.labels().resultSuffix}`)
                    .fontSize(13)
                    .fontColor(group.error !== undefined && group.error.length > 0 ? '#fca5a5' : this.theme().mutedText)
                }
                .width('100%')
                if (group.error !== undefined && group.error.length > 0) {
                  Text(group.error === undefined ? '' : group.error)
                    .fontSize(12)
                    .fontColor('#fca5a5')
                    .margin({ top: 8 })
                    .width('100%')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                } else if (this.thumbnailView) {
                  Flex({ wrap: FlexWrap.Wrap }) {
                    ForEach(this.filteredList(group), (vod: VodInfo) => {
                       Column() {
                         if (vod.pic !== undefined && vod.pic.length > 0) {
                          Image(vod.pic)
                            .width('100%')
                            .height(150)
                            .borderRadius(8)
                            .objectFit(ImageFit.Cover)
                            .alt($r('app.media.app_icon'))
                        } else {
                          Column() {
                            Text(this.labels().noCover).fontSize(12).fontColor(this.theme().subtleText)
                          }
                          .width('100%')
                          .height(150)
                          .borderRadius(8)
                          .justifyContent(FlexAlign.Center)
                          .backgroundColor(this.theme().fieldBg)
                        }
                        Text(vod.name)
                          .fontSize(13)
                          .fontColor(this.theme().text)
                          .width('100%')
                          .margin({ top: 6 })
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                        Text(vod.note === undefined ? '' : vod.note)
                          .fontSize(11)
                          .fontColor(this.theme().mutedText)
                          .width('100%')
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                      }
                      .width(120)
                      .margin({ right: 12, top: 10 })
                      .focusable(true)
                      .onClick(() => this.openDetail(group.source.key, vod.id))
                    }, (vod: VodInfo) => `${group.source.key}:${vod.id}`)
                  }
                  .width('100%')
                } else {
                  ForEach(this.filteredList(group), (vod: VodInfo) => {
                    Row() {
                      Text(vod.name)
                        .fontSize(15)
                        .fontColor(this.theme().text)
                        .layoutWeight(1)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text(`${vod.type === undefined || vod.type.length === 0 ? '' : vod.type} ${vod.note === undefined ? '' : vod.note}`)
                        .fontSize(12)
                        .fontColor(this.theme().mutedText)
                        .width(200)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    }
                    .width('100%')
                    .padding({ top: 10, bottom: 10 })
                    .borderColor('#243044')
                    .borderWidth({ bottom: 1 })
                    .focusable(true)
                    .onClick(() => this.openDetail(group.source.key, vod.id))
                  }, (vod: VodInfo) => `${group.source.key}:${vod.id}`)
                }
              }
              .width('100%')
              .padding(16)
              .backgroundColor(this.theme().cardBg)
              .borderRadius(14)
            }
            .margin({ top: 12 })
          }, (group: SourceSearchResult) => group.source.key)
        }
        .width('100%')
        .layoutWeight(1)
        .margin({ top: 12 })
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 40, right: 40, top: 30, bottom: 24 })
    .backgroundColor(this.theme().pageBg)
  }
}
