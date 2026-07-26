import router from '@ohos.router';
import { HawkConfig } from '../constants/HawkConfig';
import { SourceBean, SourceSearchResult, VodInfo } from '../models/TvBoxModels';
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

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
    this.fastSearchMode = await settingsStore.get<boolean>(HawkConfig.FAST_SEARCH_MODE, false);
    this.thumbnailView = (await settingsStore.get<number>(HawkConfig.SEARCH_VIEW, 1)) === 1;
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
      this.statusText = '请先勾选参与搜索的数据源';
      return;
    }
    vodDataStore.addSearchKeyword(value);
    this.refreshHistory();
    this.searching = true;
    this.statusText = `正在搜索：${value}`;
    this.groups = [];
    try {
      const results = await sourceService.searchAll(value, this.fastSearchMode, this.checkedKeys);
      this.groups = results.filter((item: SourceSearchResult) => item.result.list.length > 0 || !!item.error);
      const hitCount = results.reduce((count: number, item: SourceSearchResult) => count + item.result.list.length, 0);
      const errorCount = results.filter((item: SourceSearchResult) => !!item.error).length;
      if (hitCount > 0) {
        this.statusText = `共找到 ${hitCount} 条结果，${errorCount} 个源失败`;
      } else {
        this.statusText = errorCount > 0 ? `未找到结果，${errorCount} 个源失败` : '未找到结果';
      }
    } catch (error) {
      this.statusText = `搜索失败：${errorMessage(error as Error)}`;
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

  build() {
    Column() {
      Row() {
        Text('< 返回')
          .fontSize(18)
          .fontColor(Color.White)
          .focusable(true)
          .onClick(() => router.back())
        Text('搜索')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ left: 20 })
          .layoutWeight(1)
        Button(`数据源 ${this.checkedKeys.length}/${this.sources.length}`)
          .height(38)
          .enabled(this.sources.length > 0)
          .onClick(() => this.showSourcePicker = !this.showSourcePicker)
        Button('快搜')
          .height(38)
          .margin({ left: 10 })
          .onClick(() => router.pushUrl({ url: 'pages/FastSearch', params: { keyword: this.keyword } }))
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Row() {
        TextInput({ text: this.keyword, placeholder: '输入搜索标题' })
          .height(50)
          .fontSize(17)
          .layoutWeight(1)
          .onChange((value: string) => this.keyword = value)
          .onSubmit(() => this.submitSearch())
        Button(this.searching ? '搜索中' : '搜索')
          .height(50)
          .margin({ left: 12 })
          .enabled(!this.searching)
          .onClick(() => this.submitSearch())
      }
      .width('100%')
      .margin({ top: 18 })

      Text(this.statusText)
        .fontSize(14)
        .fontColor('#93a4b8')
        .margin({ top: 10 })
        .width('100%')

      if (this.showSourcePicker) {
        Column() {
          Row() {
            Text('参与搜索的数据源').fontSize(16).fontColor(Color.White).layoutWeight(1)
            Button('全选').height(32).onClick(() => this.selectAllSources())
            Button('全不选').height(32).margin({ left: 8 }).onClick(() => this.selectNoSources())
            Text('关闭')
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
                .fontColor(Color.White)
                .padding({ left: 12, right: 12, top: 7, bottom: 7 })
                .margin({ right: 8, top: 8 })
                .backgroundColor(this.isChecked(source) ? '#2563eb' : '#1f2937')
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
        .backgroundColor('#151d2b')
        .borderRadius(12)
      }

      if (this.groups.length === 0) {
        Row() {
          Text('搜索历史').fontSize(17).fontColor(Color.White).layoutWeight(1)
          Text('清空')
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
          Text('暂无搜索历史').fontSize(15).fontColor('#64748b').margin({ top: 12 }).width('100%')
        } else {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.histories, (item: SearchHistoryItem) => {
              Text(item.searchKeyWords)
                .fontSize(15)
                .fontColor(Color.White)
                .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                .margin({ right: 10, top: 10 })
                .backgroundColor('#1f2937')
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
                    .fontColor(Color.White)
                    .layoutWeight(1)
                  Text(group.error !== undefined && group.error.length > 0 ? '失败' : `${group.result.list.length} 条`)
                    .fontSize(13)
                    .fontColor(group.error !== undefined && group.error.length > 0 ? '#fca5a5' : '#93a4b8')
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
                    ForEach(group.result.list, (vod: VodInfo) => {
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
                            Text('无封面').fontSize(12).fontColor('#64748b')
                          }
                          .width('100%')
                          .height(150)
                          .borderRadius(8)
                          .justifyContent(FlexAlign.Center)
                          .backgroundColor('#111827')
                        }
                        Text(vod.name)
                          .fontSize(13)
                          .fontColor(Color.White)
                          .width('100%')
                          .margin({ top: 6 })
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                        Text(vod.note === undefined ? '' : vod.note)
                          .fontSize(11)
                          .fontColor('#93a4b8')
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
                  ForEach(group.result.list, (vod: VodInfo) => {
                    Row() {
                      Text(vod.name)
                        .fontSize(15)
                        .fontColor(Color.White)
                        .layoutWeight(1)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text(`${vod.type === undefined || vod.type.length === 0 ? '' : vod.type} ${vod.note === undefined ? '' : vod.note}`)
                        .fontSize(12)
                        .fontColor('#93a4b8')
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
              .backgroundColor('#151d2b')
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
    .backgroundColor('#0b1020')
  }
}
