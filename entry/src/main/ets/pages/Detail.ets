import router from '@ohos.router';
import { SourceBean, VodInfo, VodSeries, VodSeriesFlag } from '../models/TvBoxModels';
import { apiConfigService } from '../services/ApiConfigService';
import { settingsStore } from '../services/SettingsStore';
import { sourceService } from '../services/SourceService';
import { vodDataStore } from '../services/VodDataStore';

@Entry
@Component
struct Detail {
  @State sourceKey: string = '';
  @State vodId: string = '';
  @State sourceName: string = '';
  @State vod: VodInfo | null = null;
  @State loading: boolean = false;
  @State statusText: string = '等待详情参数';
  @State isCollect: boolean = false;

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
    const rawParams = router.getParams();
    const params = rawParams === undefined ? {} as Record<string, string> : rawParams as Record<string, string>;
    this.sourceKey = params['sourceKey'] === undefined ? '' : String(params['sourceKey']);
    this.vodId = params['vodId'] === undefined ? '' : String(params['vodId']);
    if (this.sourceKey.length === 0 || this.vodId.length === 0) {
      this.statusText = '缺少 sourceKey 或 vodId';
      return;
    }

    if (Object.keys(apiConfigService.state.sourceBeanList).length === 0) {
      try {
        await apiConfigService.loadConfigFromSettings(true);
      } catch (error) {
        this.statusText = `配置加载失败：${this.stringifyError(error)}`;
        return;
      }
    }

    const source = apiConfigService.state.sourceBeanList[this.sourceKey];
    if (source === undefined) {
      this.statusText = `找不到数据源：${this.sourceKey}`;
      return;
    }
    this.sourceName = source.name;
    await this.loadDetail(source);
  }

  async loadDetail(source: SourceBean): Promise<void> {
    this.loading = true;
    this.statusText = `正在加载详情：${this.sourceName}`;
    try {
      const detail = await sourceService.getDetail(source, this.vodId);
      if (detail === undefined) {
        this.vod = null;
        this.statusText = '详情为空';
      } else {
        this.vod = detail;
        this.isCollect = vodDataStore.isVodCollect(this.sourceKey, detail.id);
        this.statusText = `已加载：${this.sourceName}`;
      }
    } catch (error) {
      this.vod = null;
      this.statusText = `详情加载失败：${this.stringifyError(error)}`;
    } finally {
      this.loading = false;
    }
  }

  toggleCollect(): void {
    if (this.vod === null) {
      return;
    }
    if (this.isCollect) {
      vodDataStore.deleteVodCollectByVod(this.sourceKey, this.vod.id);
      this.isCollect = false;
    } else {
      vodDataStore.insertVodCollect(this.sourceKey, this.vod);
      this.isCollect = true;
    }
  }

  openPlay(flag: VodSeriesFlag, episode: VodSeries, index: number, groupIndex: number): void {
    if (this.vod === null) {
      return;
    }
    const snapshot = JSON.parse(JSON.stringify(this.vod)) as VodInfo;
    snapshot.playFlag = flag.name;
    snapshot.playIndex = index;
    snapshot.playGroup = groupIndex;
    snapshot.playNote = episode.name;
    snapshot.rawUrl = episode.url;
    snapshot.last = episode.url;
    vodDataStore.insertVodRecord(this.sourceKey, snapshot);
    router.pushUrl({
      url: 'pages/Play',
      params: {
        sourceKey: this.sourceKey,
        vodId: snapshot.id,
        playFlag: flag.name,
        playIndex: `${index}`,
        playUrl: episode.url,
        rawUrl: episode.url,
        episodeName: episode.name,
        episodesJson: JSON.stringify(this.getSeries(flag.name))
      }
    });
  }

  getSeries(flagName: string): VodSeries[] {
    if (this.vod === null) {
      return [];
    }
    const series = this.vod.seriesMap[flagName];
    return series === undefined ? [] : series;
  }

  stringifyError(error: unknown): string {
    if (error instanceof Error) {
      return error.message;
    }
    const text = JSON.stringify(error);
    return text === undefined || text.length === 0 ? String(error) : text;
  }

  valueOrEmpty(value: string | undefined): string {
    return value === undefined ? '' : value;
  }

  valueOr(value: string | undefined, fallback: string): string {
    return value === undefined || value.length === 0 ? fallback : value;
  }

  build() {
    Column() {
      Row() {
        Text('< 返回')
          .fontSize(18)
          .fontColor(Color.White)
          .onClick(() => router.back())
        Text('详情')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ left: 24 })
          .layoutWeight(1)
        Button(this.isCollect ? '取消收藏' : '收藏')
          .height(40)
          .enabled(this.vod !== null)
          .onClick(() => this.toggleCollect())
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.statusText)
        .fontSize(15)
        .fontColor('#93a4b8')
        .margin({ top: 14 })
        .width('100%')

      if (this.loading) {
        Column() {
          LoadingProgress().width(48).height(48).color('#60a5fa')
          Text('加载中...')
            .fontSize(16)
            .fontColor('#d1d5db')
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.vod === null) {
        Text('暂无详情数据')
          .fontSize(18)
          .fontColor('#d1d5db')
          .margin({ top: 48 })
      } else {
        Scroll() {
          Column() {
            Row() {
              if (this.vod.pic !== undefined && this.vod.pic.length > 0) {
                Image(this.valueOrEmpty(this.vod.pic))
                  .width(150)
                  .height(210)
                  .borderRadius(10)
                  .objectFit(ImageFit.Cover)
              } else {
                Column() {
                  Text('无封面').fontSize(16).fontColor('#93a4b8')
                }
                .width(150)
                .height(210)
                .borderRadius(10)
                .justifyContent(FlexAlign.Center)
                .backgroundColor('#111827')
              }
              Column() {
                Text(this.vod.name)
                  .fontSize(28)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`${this.valueOr(this.vod.type, '未知类型')} ${this.vod.year === undefined ? '' : this.vod.year} ${this.valueOrEmpty(this.vod.area)}`)
                  .fontSize(15)
                  .fontColor('#93a4b8')
                  .margin({ top: 12 })
                Text(this.valueOrEmpty(this.vod.note))
                  .fontSize(15)
                  .fontColor('#d1d5db')
                  .margin({ top: 8 })
                Text(`导演：${this.valueOrEmpty(this.vod.director)}`)
                  .fontSize(14)
                  .fontColor('#d1d5db')
                  .margin({ top: 12 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`主演：${this.valueOrEmpty(this.vod.actor)}`)
                  .fontSize(14)
                  .fontColor('#d1d5db')
                  .margin({ top: 6 })
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              .margin({ left: 24 })
            }
            .width('100%')

            Text(this.valueOr(this.vod.des, '暂无简介'))
              .fontSize(15)
              .fontColor('#d1d5db')
              .lineHeight(24)
              .margin({ top: 24 })
              .width('100%')

            Text('播放列表')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .margin({ top: 28 })
              .width('100%')

            if (this.vod.seriesFlags.length === 0) {
              Text('暂无播放地址')
                .fontSize(16)
                .fontColor('#93a4b8')
                .margin({ top: 12 })
            } else {
              ForEach(this.vod.seriesFlags, (flag: VodSeriesFlag, groupIndex: number) => {
                Column() {
                  Text(flag.name)
                    .fontSize(18)
                    .fontColor(Color.White)
                    .fontWeight(FontWeight.Medium)
                    .width('100%')
                  Flex({ wrap: FlexWrap.Wrap }) {
                    ForEach(this.getSeries(flag.name), (episode: VodSeries, index: number) => {
                      Text(episode.name)
                        .fontSize(14)
                        .fontColor(Color.White)
                        .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                        .margin({ right: 10, top: 10 })
                        .backgroundColor('#1f2937')
                        .borderRadius(8)
                        .onClick(() => this.openPlay(flag, episode, index, groupIndex))
                    }, (episode: VodSeries) => `${flag.name}:${episode.name}:${episode.url}`)
                  }
                  .width('100%')
                }
                .width('100%')
                .padding({ top: 18, bottom: 10 })
              }, (flag: VodSeriesFlag) => flag.name)
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .layoutWeight(1)
        .margin({ top: 24 })
      }
    }
    .width('100%')
    .height('100%')
    .padding(48)
    .backgroundColor('#0b1020')
  }
}
