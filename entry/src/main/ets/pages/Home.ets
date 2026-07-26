import router from '@ohos.router';
import { HawkConfig } from '../constants/HawkConfig';
import { MovieSort, SourceBean, VodInfo } from '../models/TvBoxModels';
import { apiConfigService } from '../services/ApiConfigService';
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
  @State sourceName: string = '未加载配置';
  @State statusText: string = '等待配置地址';
  @State contentStatus: string = '';
  @State contentLoading: boolean = false;
  @State sourceCount: number = 0;
  @State sources: SourceBean[] = [];
  @State categories: MovieSort[] = [];
  @State recommendations: VodInfo[] = [];
  @State entries: HomeEntry[] = [
    { title: '直播', page: 'pages/Live', desc: 'LivePlayActivity' },
    { title: '搜索', page: 'pages/Search', desc: 'SearchActivity' },
    { title: '快搜', page: 'pages/FastSearch', desc: 'FastSearchActivity' },
    { title: '历史', page: 'pages/History', desc: 'HistoryActivity' },
    { title: '收藏', page: 'pages/Favorites', desc: 'CollectActivity' },
    { title: '推送', page: 'pages/Push', desc: 'PushActivity' },
    { title: '网盘', page: 'pages/Drive', desc: 'DriveActivity' },
    { title: '应用', page: 'pages/Apps', desc: 'AppsActivity' },
    { title: '设置', page: 'pages/Settings', desc: 'SettingActivity' }
  ];

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
    const apiUrl = await settingsStore.get<string>(HawkConfig.API_URL, '');
    if (apiUrl && Object.keys(apiConfigService.state.sourceBeanList).length === 0) {
      try {
        this.statusText = '正在加载配置...';
        await apiConfigService.loadConfigFromSettings(true);
      } catch (error) {
        this.statusText = `配置加载失败：${JSON.stringify(error)}`;
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
    this.sourceName = state.homeSource?.name || '未加载配置';
    this.statusText = sources.length > 0 ? `已解析 ${sources.length} 个数据源` : '进入设置填写配置地址后加载';
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
    this.categories = [];
    this.recommendations = [];
    if (source === undefined) {
      this.contentStatus = '';
      return;
    }
    if (source.type !== 0 && source.type !== 1 && source.type !== 4) {
      this.contentStatus = `当前源 ${source.name} 为 type=${source.type}，首页内容待 Spider 迁移`;
      return;
    }
    this.contentLoading = true;
    this.contentStatus = `正在加载首页内容：${source.name}`;
    try {
      const content = await sourceService.getHomeContent(source);
      this.categories = content.classes;
      this.recommendations = content.list;
      this.contentStatus = `首页分类 ${content.classes.length} 个，推荐 ${content.list.length} 条`;
    } catch (error) {
      this.contentStatus = `首页内容加载失败：${errorMessage(error)}`;
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


  build() {
    Column() {
      Row() {
        Column() {
          Text('TVBox')
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Text(this.statusText)
            .fontSize(16)
            .fontColor('#aab2c0')
            .margin({ top: 8 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Column() {
          Text('当前源')
            .fontSize(14)
            .fontColor('#aab2c0')
          Text(this.sourceName)
            .fontSize(18)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .padding({ left: 48, right: 48, top: 32, bottom: 24 })

      Grid() {
        ForEach(this.entries, (entry: HomeEntry) => {
          GridItem() {
            Column() {
              Text(entry.title)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
              Text(entry.desc)
                .fontSize(13)
                .fontColor('#93a4b8')
                .margin({ top: 10 })
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .borderRadius(18)
            .backgroundColor('#1f2937')
            .focusable(true)
            .onClick(() => this.open(entry.page))
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(18)
      .columnsGap(18)
      .padding({ left: 48, right: 48 })

      if (this.sources.length > 0) {
        Column() {
          if (this.contentStatus.length > 0) {
            Row() {
              Text('首页内容')
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
              Text(this.contentLoading ? '加载中' : this.contentStatus)
                .fontSize(14)
                .fontColor('#93a4b8')
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
                    .fontColor(Color.White)
                    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                    .margin({ right: 10 })
                    .backgroundColor('#1f2937')
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
            List() {
              ForEach(this.recommendations.slice(0, 8), (vod: VodInfo) => {
                ListItem() {
                  Row() {
                    Text(vod.name)
                      .fontSize(16)
                      .fontColor(Color.White)
                      .layoutWeight(1)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(vod.note === undefined ? '' : vod.note)
                      .fontSize(12)
                      .fontColor('#93a4b8')
                      .width(160)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                  }
                  .padding({ left: 14, right: 14, top: 10, bottom: 10 })
                  .backgroundColor('#111827')
                  .borderRadius(10)
                  .onClick(() => this.openVod(vod))
                }.margin({ top: 8 })
              }, (vod: VodInfo) => `${vod.sourceKey || ''}:${vod.id}`)
            }
            .height(150)
            .margin({ top: 10 })
          }

          Row() {
            Text('数据源')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            Text(`${this.sources.length} 个可见源`)
              .fontSize(14)
              .fontColor('#93a4b8')
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
                    .fontColor(Color.White)
                    .layoutWeight(1)
                  Text(source.api)
                    .fontSize(12)
                    .fontColor('#93a4b8')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('50%')
                }
                .padding({ left: 16, right: 16, top: 12, bottom: 12 })
                .backgroundColor(source.key === apiConfigService.state.homeSource?.key ? '#334155' : '#151d2b')
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
    .backgroundColor('#0b1020')
  }
}
