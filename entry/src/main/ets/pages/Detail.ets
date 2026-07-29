import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { HawkConfig } from '../constants/HawkConfig';
import { visibleOrder, toSourceIndex } from '../domain/playback/PlaybackOrder';
import { SourceBean, SourceSearchResult, VodInfo, VodSeries, VodSeriesFlag } from '../models/TvBoxModels';
import { apiConfigService } from '../services/ApiConfigService';
import { appearanceService, ThemePalette } from '../services/AppearanceService';
import { settingsStore } from '../services/SettingsStore';
import { sourceService } from '../services/SourceService';
import { vodDataStore } from '../services/VodDataStore';
import { errorMessage } from '../utils/ErrorUtil';

/** One "change source" candidate found by quick search on another site. */
class SourceCandidate {
  sourceKey: string;
  sourceName: string;
  vodId: string;
  vodName: string;
  note: string;

  constructor(sourceKey: string, sourceName: string, vodId: string, vodName: string, note: string) {
    this.sourceKey = sourceKey;
    this.sourceName = sourceName;
    this.vodId = vodId;
    this.vodName = vodName;
    this.note = note;
  }
}

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
  @State flagIndex: number = 0;
  @State reverseSort: boolean = false;
  @State descExpanded: boolean = false;
  @State candidates: SourceCandidate[] = [];
  @State searchingSources: boolean = false;
  @State showCandidates: boolean = false;
  @State lastPlayIndex: number = -1;
  @State themeSelect: number = 0;

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
    await appearanceService.init();
    this.themeSelect = await settingsStore.get<number>(HawkConfig.THEME_SELECT, 0);
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
        this.statusText = `配置加载失败：${errorMessage(error as Error)}`;
        return;
      }
    }

    if (this.vodId.startsWith('push://') && apiConfigService.state.sourceBeanList['push_agent'] !== undefined) {
      this.sourceKey = 'push_agent';
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
        this.flagIndex = 0;
        this.isCollect = vodDataStore.isVodCollect(this.sourceKey, detail.id);
        this.statusText = `已加载：${this.sourceName}`;
        this.restoreHistoryPosition(detail);
      }
    } catch (error) {
      this.vod = null;
      this.statusText = `详情加载失败：${errorMessage(error as Error)}`;
    } finally {
      this.loading = false;
    }
  }

  /** Android highlights the last watched episode when reopening a detail page. */
  restoreHistoryPosition(detail: VodInfo): void {
    const saved = vodDataStore.getVodInfo(this.sourceKey, detail.id);
    if (saved === undefined || saved.playFlag === undefined) {
      this.lastPlayIndex = -1;
      return;
    }
    const flagPosition = detail.seriesFlags.findIndex((flag: VodSeriesFlag) => flag.name === saved.playFlag);
    if (flagPosition >= 0) {
      this.flagIndex = flagPosition;
    }
    this.lastPlayIndex = saved.playIndex;
  }

  toggleCollect(): void {
    if (this.vod === null) {
      return;
    }
    if (this.isCollect) {
      vodDataStore.deleteVodCollectByVod(this.sourceKey, this.vod.id);
      this.isCollect = false;
      promptAction.showToast({ message: '已取消收藏' });
    } else {
      vodDataStore.insertVodCollect(this.sourceKey, this.vod);
      this.isCollect = true;
      promptAction.showToast({ message: '已收藏' });
    }
  }

  currentFlag(): VodSeriesFlag | undefined {
    if (this.vod === null || this.vod.seriesFlags.length === 0) {
      return undefined;
    }
    const index = this.flagIndex >= 0 && this.flagIndex < this.vod.seriesFlags.length ? this.flagIndex : 0;
    return this.vod.seriesFlags[index];
  }

  currentSeries(): VodSeries[] {
    const flag = this.currentFlag();
    if (flag === undefined || this.vod === null) {
      return [];
    }
    const series = this.vod.seriesMap[flag.name];
    return series === undefined ? [] : series;
  }

  /** Android reverse button flips the visible episode list. */
  visibleSeries(): VodSeries[] {
    return visibleOrder(this.currentSeries(), this.reverseSort);
  }

  isLastPlayed(visibleIndex: number): boolean {
    if (this.lastPlayIndex < 0) {
      return false;
    }
    return toSourceIndex(visibleIndex, this.currentSeries().length, this.reverseSort) === this.lastPlayIndex;
  }

  openPlay(visibleIndex: number): void {
    const flag = this.currentFlag();
    if (this.vod === null || flag === undefined) {
      return;
    }
    const series = this.currentSeries();
    const sourceIndex = toSourceIndex(visibleIndex, series.length, this.reverseSort);
    if (sourceIndex < 0 || sourceIndex >= series.length) {
      return;
    }
    const episode = series[sourceIndex];
    const snapshot = JSON.parse(JSON.stringify(this.vod)) as VodInfo;
    snapshot.playFlag = flag.name;
    snapshot.playIndex = sourceIndex;
    snapshot.playGroup = this.flagIndex;
    snapshot.playNote = episode.name;
    snapshot.rawUrl = episode.url;
    snapshot.last = episode.url;
    snapshot.reverseSort = this.reverseSort;
    vodDataStore.insertVodRecord(this.sourceKey, snapshot);
    this.lastPlayIndex = sourceIndex;
    router.pushUrl({
      url: 'pages/Play',
      params: {
        sourceKey: this.sourceKey,
        vodId: snapshot.id,
        playFlag: flag.name,
        playIndex: `${sourceIndex}`,
        playUrl: episode.url,
        rawUrl: episode.url,
        episodeName: episode.name,
        episodesJson: JSON.stringify(series)
      }
    });
  }

  /** Android `DetailActivity` change-source flow: quick search other sites by title. */
  async searchOtherSources(): Promise<void> {
    if (this.vod === null || this.searchingSources) {
      return;
    }
    this.showCandidates = true;
    this.searchingSources = true;
    this.candidates = [];
    const keyword = this.vod.name;
    this.statusText = `正在其他源搜索：${keyword}`;
    try {
      const results = await sourceService.searchAll(keyword, true);
      const found: SourceCandidate[] = [];
      for (const group of results) {
        if (group.error !== undefined && group.error.length > 0) {
          continue;
        }
        for (const item of group.result.list) {
          if (group.source.key === this.sourceKey && item.id === this.vodId) {
            continue;
          }
          found.push(new SourceCandidate(
            group.source.key,
            group.source.name,
            item.id,
            item.name,
            item.note === undefined ? '' : item.note
          ));
        }
      }
      this.candidates = found;
      this.statusText = found.length > 0 ? `其他源找到 ${found.length} 条` : '其他源没有结果';
    } catch (error) {
      this.statusText = `换源搜索失败：${errorMessage(error as Error)}`;
    } finally {
      this.searchingSources = false;
    }
  }

  async switchToCandidate(candidate: SourceCandidate): Promise<void> {
    const source = apiConfigService.state.sourceBeanList[candidate.sourceKey];
    if (source === undefined) {
      return;
    }
    this.showCandidates = false;
    this.sourceKey = candidate.sourceKey;
    this.sourceName = source.name;
    this.vodId = candidate.vodId;
    this.reverseSort = false;
    await this.loadDetail(source);
  }

  pushToRemote(): void {
    const flag = this.currentFlag();
    const series = this.currentSeries();
    if (flag === undefined || series.length === 0) {
      promptAction.showToast({ message: '没有可推送的播放地址' });
      return;
    }
    router.pushUrl({
      url: 'pages/Push',
      params: { url: series[0].url }
    });
  }

  valueOrEmpty(value: string | undefined): string {
    return value === undefined ? '' : value;
  }

  valueOr(value: string | undefined, fallback: string): string {
    return value === undefined || value.length === 0 ? fallback : value;
  }

  theme(): ThemePalette {
    return appearanceService.themeByIndex(this.themeSelect);
  }

  build() {
    Column() {
      Row() {
        Text('< 返回')
          .fontSize(18)
          .fontColor(this.theme().text)
          .focusable(true)
          .onClick(() => router.back())
        Text('详情')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme().text)
          .margin({ left: 20 })
        Text(this.sourceName)
          .fontSize(14)
          .fontColor(this.theme().primarySoft)
          .margin({ left: 12 })
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Button(this.searchingSources ? '搜索中' : '换源')
          .height(38)
          .enabled(this.vod !== null && !this.searchingSources)
          .onClick(() => this.searchOtherSources())
        Button('推送')
          .height(38)
          .margin({ left: 10 })
          .enabled(this.vod !== null)
          .onClick(() => this.pushToRemote())
        Button(this.isCollect ? '取消收藏' : '收藏')
          .height(38)
          .margin({ left: 10 })
          .enabled(this.vod !== null)
          .onClick(() => this.toggleCollect())
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text(this.statusText)
        .fontSize(14)
        .fontColor(this.theme().mutedText)
        .margin({ top: 12 })
        .width('100%')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      if (this.showCandidates) {
        Column() {
          Row() {
            Text(`换源结果 ${this.candidates.length}`)
              .fontSize(16)
              .fontColor(this.theme().text)
              .layoutWeight(1)
            Text('关闭')
              .fontSize(14)
              .fontColor('#fca5a5')
              .focusable(true)
              .onClick(() => this.showCandidates = false)
          }
          .width('100%')
          List() {
            ForEach(this.candidates, (candidate: SourceCandidate) => {
              ListItem() {
                Row() {
                  Text(candidate.sourceName)
                    .fontSize(14)
                    .fontColor(this.theme().primarySoft)
                    .width(140)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(candidate.vodName)
                    .fontSize(14)
                    .fontColor(this.theme().text)
                    .layoutWeight(1)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(candidate.note)
                    .fontSize(12)
                    .fontColor(this.theme().mutedText)
                    .width(120)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('100%')
                .padding({ top: 9, bottom: 9 })
                .focusable(true)
                .onClick(() => this.switchToCandidate(candidate))
              }
            }, (candidate: SourceCandidate) => `${candidate.sourceKey}:${candidate.vodId}`)
          }
          .height(180)
          .margin({ top: 6 })
        }
        .width('100%')
        .padding(14)
        .margin({ top: 12 })
        .backgroundColor(this.theme().cardBg)
        .borderRadius(12)
      }

      if (this.loading) {
        Column() {
          LoadingProgress().width(48).height(48).color(this.theme().primarySoft)
          Text('加载中...').fontSize(16).fontColor(this.theme().mutedText).margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.vod === null) {
        Column() {
          Text('暂无详情数据').fontSize(18).fontColor(this.theme().mutedText)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
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
                  .alt($r('app.media.app_icon'))
              } else {
                Column() {
                  Text('无封面').fontSize(16).fontColor(this.theme().mutedText)
                }
                .width(150)
                .height(210)
                .borderRadius(10)
                .justifyContent(FlexAlign.Center)
                .backgroundColor(this.theme().fieldBg)
              }
              Column() {
                Text(this.vod.name)
                  .fontSize(28)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.theme().text)
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`${this.valueOr(this.vod.type, '未知类型')} ${this.vod.year === undefined ? '' : this.vod.year} ${this.valueOrEmpty(this.vod.area)}`)
                  .fontSize(15)
                  .fontColor(this.theme().mutedText)
                  .margin({ top: 12 })
                Text(this.valueOrEmpty(this.vod.note))
                  .fontSize(15)
                  .fontColor(this.theme().text)
                  .margin({ top: 8 })
                Text(`导演：${this.valueOrEmpty(this.vod.director)}`)
                  .fontSize(14)
                  .fontColor(this.theme().text)
                  .margin({ top: 12 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`主演：${this.valueOrEmpty(this.vod.actor)}`)
                  .fontSize(14)
                  .fontColor(this.theme().text)
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
              .fontColor(this.theme().text)
              .lineHeight(24)
              .margin({ top: 20 })
              .width('100%')
              .maxLines(this.descExpanded ? 100 : 3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .focusable(true)
              .onClick(() => this.descExpanded = !this.descExpanded)

            Row() {
              Text('播放列表')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.theme().text)
                .layoutWeight(1)
              Text(`${this.currentSeries().length} 集`)
                .fontSize(14)
                .fontColor(this.theme().mutedText)
                .margin({ right: 12 })
              Button(this.reverseSort ? '正序' : '倒序')
                .height(34)
                .enabled(this.currentSeries().length > 1)
                .onClick(() => this.reverseSort = !this.reverseSort)
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .margin({ top: 24 })

            if (this.vod.seriesFlags.length === 0) {
              Text('暂无播放地址')
                .fontSize(16)
                .fontColor(this.theme().mutedText)
                .margin({ top: 12 })
                .width('100%')
            } else {
              Scroll() {
                Row() {
                  ForEach(this.vod.seriesFlags, (flag: VodSeriesFlag, index: number) => {
                    Text(flag.name)
                      .fontSize(14)
                      .fontColor(this.theme().text)
                      .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                      .margin({ right: 10 })
                      .backgroundColor(this.flagIndex === index ? this.theme().primary : this.theme().panelBg)
                      .borderRadius(8)
                      .focusable(true)
                      .onClick(() => this.flagIndex = index)
                  }, (flag: VodSeriesFlag) => flag.name)
                }
              }
              .scrollable(ScrollDirection.Horizontal)
              .width('100%')
              .margin({ top: 12 })

              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.visibleSeries(), (episode: VodSeries, index: number) => {
                  Text(episode.name)
                    .fontSize(14)
                    .fontColor(this.isLastPlayed(index) ? '#fbbf24' : this.theme().text)
                    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                    .margin({ right: 10, top: 10 })
                    .backgroundColor(this.isLastPlayed(index) ? '#3f3517' : this.theme().panelBg)
                    .borderRadius(8)
                    .focusable(true)
                    .onClick(() => this.openPlay(index))
                }, (episode: VodSeries) => `${episode.name}:${episode.url}`)
              }
              .width('100%')
              .margin({ bottom: 24 })
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .layoutWeight(1)
        .margin({ top: 18 })
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 40, right: 40, top: 30, bottom: 20 })
    .backgroundColor(this.theme().pageBg)
  }
}
