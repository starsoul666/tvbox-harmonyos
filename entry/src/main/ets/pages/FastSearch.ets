import router from '@ohos.router';
import { HawkConfig } from '../constants/HawkConfig';
import { SourceSearchResult, VodInfo } from '../models/TvBoxModels';
import { appearanceService, FeatureLabels, ThemePalette } from '../services/AppearanceService';
import { settingsStore } from '../services/SettingsStore';
import { sourceService } from '../services/SourceService';
import { SearchHistoryItem, vodDataStore } from '../services/VodDataStore';
import { errorMessage } from '../utils/ErrorUtil';

@Entry
@Component
struct FastSearch {
  @State keyword: string = '';
  @State histories: SearchHistoryItem[] = [];
  @State groups: SourceSearchResult[] = [];
  @State searching: boolean = false;
  @State statusText: string = '快搜会使用 quickSearch=1 的 XML/JSON/type=4 数据源';
  @State themeSelect: number = 0;
  @State localeSelect: number = 0;

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
    await appearanceService.init();
    this.themeSelect = await settingsStore.get<number>(HawkConfig.THEME_SELECT, 0);
    this.localeSelect = await settingsStore.get<number>(HawkConfig.HOME_LOCALE, 0);
    this.statusText = this.labels().fastSearchInitialStatus;
    this.refreshHistory();
    const rawParams = router.getParams();
    if (rawParams !== undefined) {
      const params = rawParams as Record<string, string>;
      const keyword = params['keyword'] === undefined ? '' : String(params['keyword']);
      if (keyword.length > 0) {
        this.keyword = keyword;
        this.submitSearch();
      }
    }
  }

  refreshHistory(): void {
    this.histories = vodDataStore.getSearchHistory().reverse();
  }

  async submitSearch(): Promise<void> {
    const value = this.keyword.trim();
    if (value.length === 0 || this.searching) {
      return;
    }
    vodDataStore.addSearchKeyword(value);
    this.refreshHistory();
    this.searching = true;
    this.statusText = `${this.labels().fastSearchingPrefix}${value}`;
    this.groups = [];
    try {
      const results = await sourceService.searchAll(value, true);
      this.groups = results.filter((item: SourceSearchResult) => item.result.list.length > 0 || !!item.error);
      const hitCount = results.reduce((count: number, item: SourceSearchResult) => count + item.result.list.length, 0);
      const errorCount = results.filter((item: SourceSearchResult) => !!item.error).length;
      this.statusText = hitCount > 0 ? `${this.labels().fastSearchHitPrefix}${hitCount}${this.labels().fastSearchHitMiddle}${errorCount}${this.labels().fastSearchHitSuffix}` :
        errorCount > 0 ? `${this.labels().fastSearchNoHit}${this.labels().fastSearchHitMiddle}${errorCount}${this.labels().fastSearchHitSuffix}` : this.labels().fastSearchNoHit;
    } catch (error) {
      this.statusText = `${this.labels().fastSearchFailedPrefix}${errorMessage(error)}`;
    } finally {
      this.searching = false;
    }
  }

  openDetail(sourceKey: string, vodId: string): void {
    router.pushUrl({
      url: 'pages/Detail',
      params: {
        sourceKey,
        vodId
      }
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
      Text(this.labels().back).fontSize(18).fontColor(this.theme().text).alignSelf(ItemAlign.Start).onClick(() => router.back())
      Text(this.labels().fastSearchTitle).fontSize(36).fontWeight(FontWeight.Bold).fontColor(this.theme().text).margin({ top: 32 })
      Row() {
        TextInput({ text: this.keyword, placeholder: this.labels().keywordPlaceholder })
          .height(52)
          .fontSize(18)
          .layoutWeight(1)
          .onChange((value: string) => this.keyword = value)
        Button(this.searching ? this.labels().searchingButton : this.labels().fastSearchButton)
          .height(52)
          .margin({ left: 12 })
          .onClick(() => this.submitSearch())
      }.width('100%').margin({ top: 24 })
      Text(this.statusText)
        .fontSize(15)
        .fontColor(this.theme().mutedText)
        .margin({ top: 12 })
        .width('100%')
      if (this.histories.length > 0) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.histories, (item: SearchHistoryItem) => {
            Text(item.searchKeyWords)
              .fontSize(15)
              .fontColor(this.theme().text)
              .padding({ left: 14, right: 14, top: 7, bottom: 7 })
              .margin({ right: 10, top: 10 })
              .backgroundColor(this.theme().panelBg)
              .borderRadius(16)
              .onClick(() => {
                this.keyword = item.searchKeyWords;
                this.submitSearch();
              })
          }, (item: SearchHistoryItem) => `${item.id}`)
        }.width('100%').margin({ top: 18 })
      }
      if (this.groups.length > 0) {
        List() {
          ForEach(this.groups, (group: SourceSearchResult) => {
            ListItem() {
              Column() {
                Row() {
                  Text(group.source.name)
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(this.theme().text)
                    .layoutWeight(1)
                  Text(group.error !== undefined && group.error.length > 0 ? this.labels().failed : `${group.result.list.length}${this.labels().resultSuffix}`)
                    .fontSize(13)
                    .fontColor(group.error !== undefined && group.error.length > 0 ? '#fca5a5' : this.theme().mutedText)
                }.width('100%')
                if (group.error !== undefined && group.error.length > 0) {
                  Text(group.error === undefined ? '' : group.error)
                    .fontSize(12)
                    .fontColor('#fca5a5')
                    .margin({ top: 8 })
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                } else {
                  ForEach(group.result.list, (vod: VodInfo) => {
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
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width(180)
                    }
                    .width('100%')
                    .padding({ top: 10, bottom: 10 })
                    .borderColor('#243044')
                    .borderWidth({ bottom: 1 })
                    .onClick(() => this.openDetail(group.source.key, vod.id))
                  }, (vod: VodInfo) => `${group.source.key}:${vod.id}`)
                }
              }
              .width('100%')
              .padding(16)
              .backgroundColor(this.theme().cardBg)
              .borderRadius(14)
            }.margin({ top: 12 })
          }, (group: SourceSearchResult) => group.source.key)
        }.width('100%').layoutWeight(1).margin({ top: 20 })
      } else {
        Blank().layoutWeight(1)
      }
    }.width('100%').height('100%').padding(48).backgroundColor(this.theme().pageBg)
  }
}
