import router from '@ohos.router';
import { SourceSearchResult, VodInfo } from '../models/TvBoxModels';
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
  @State statusText: string = '输入关键词后搜索已加载配置中的 XML/JSON/type=4 数据源';

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
    this.refreshHistory();
  }

  refreshHistory(): void {
    this.histories = vodDataStore.getSearchHistory().reverse();
  }

  async submitSearch(): Promise<void> {
    const value = this.keyword.trim();
    if (value.length === 0) {
      return;
    }
    vodDataStore.addSearchKeyword(value);
    this.refreshHistory();
    this.searching = true;
    this.statusText = `正在搜索：${value}`;
    this.groups = [];
    try {
      const results = await sourceService.searchAll(value);
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
      params: {
        sourceKey,
        vodId
      }
    });
  }

  build() {
    Column() {
      Text('< 返回').fontSize(18).fontColor(Color.White).alignSelf(ItemAlign.Start).onClick(() => router.back())
      Text('搜索').fontSize(36).fontWeight(FontWeight.Bold).fontColor(Color.White).margin({ top: 32 })
      Row() {
        TextInput({ text: this.keyword, placeholder: '输入搜索标题' })
          .height(52)
          .fontSize(18)
          .layoutWeight(1)
          .onChange((value: string) => this.keyword = value)
        Button(this.searching ? '搜索中' : '搜索').height(52).margin({ left: 12 }).onClick(() => this.submitSearch())
      }.width('100%').margin({ top: 24 })
      Text(this.statusText)
        .fontSize(15)
        .fontColor('#93a4b8')
        .margin({ top: 12 })
        .width('100%')
      Row() {
        Text('搜索历史').fontSize(18).fontColor(Color.White).layoutWeight(1)
        Text('清空').fontSize(14).fontColor('#fca5a5').onClick(() => {
          vodDataStore.clearSearchKeywords();
          this.refreshHistory();
        })
      }.width('100%').margin({ top: 28 })
      if (this.histories.length === 0) {
        Text('暂无搜索历史').fontSize(16).fontColor('#d1d5db').margin({ top: 16 })
      } else {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.histories, (item: SearchHistoryItem) => {
            Text(item.searchKeyWords)
              .fontSize(16)
              .fontColor(Color.White)
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .margin({ right: 10, top: 10 })
              .backgroundColor('#1f2937')
              .borderRadius(18)
              .onClick(() => {
                this.keyword = item.searchKeyWords;
                this.submitSearch();
              })
          }, (item: SearchHistoryItem) => `${item.id}`)
        }.width('100%')
      }
      if (this.groups.length > 0) {
        Text('搜索结果')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ top: 28 })
          .width('100%')
        List() {
          ForEach(this.groups, (group: SourceSearchResult) => {
            ListItem() {
              Column() {
                Row() {
                  Text(group.source.name)
                    .fontSize(18)
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
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                } else {
                  ForEach(group.result.list, (vod: VodInfo) => {
                    Row() {
                      Column() {
                        Text(vod.name)
                          .fontSize(16)
                          .fontColor(Color.White)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                        Text(`${vod.type === undefined || vod.type.length === 0 ? '未知类型' : vod.type} ${vod.note === undefined ? '' : vod.note}`)
                          .fontSize(12)
                          .fontColor('#93a4b8')
                          .margin({ top: 4 })
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                      }
                      .alignItems(HorizontalAlign.Start)
                      .layoutWeight(1)
                      Text('详情')
                        .fontSize(14)
                        .fontColor('#60a5fa')
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
              .backgroundColor('#151d2b')
              .borderRadius(14)
            }
          }, (group: SourceSearchResult) => group.source.key)
        }
        .width('100%')
        .layoutWeight(1)
        .margin({ top: 12 })
      } else {
        Blank().layoutWeight(1)
      }
    }.width('100%').height('100%').padding(48).backgroundColor('#0b1020')
  }
}
