import router from '@ohos.router';
import { HawkConfig } from '../constants/HawkConfig';
import { MovieSort, SortFilter, SortFilterValue, SourceBean, VodInfo } from '../models/TvBoxModels';
import { apiConfigService } from '../services/ApiConfigService';
import { appearanceService, ThemePalette } from '../services/AppearanceService';
import { settingsStore } from '../services/SettingsStore';
import { sourceService } from '../services/SourceService';
import { errorMessage } from '../utils/ErrorUtil';

/**
 * Android `HomeActivity` category tab + `GridFragment` list.
 * Handles category switching, filter selection, paging and infinite scroll.
 */
@Entry
@Component
struct Category {
  private loadSeq: number = 0;

  @State source: SourceBean | null = null;
  @State categories: MovieSort[] = [];
  @State categoryIndex: number = 0;
  @State items: VodInfo[] = [];
  @State page: number = 1;
  @State pageCount: number = 1;
  @State loading: boolean = false;
  @State statusText: string = '正在加载分类';
  @State filterVisible: boolean = false;
  @State filterSelect: Record<string, string> = {};
  @State thumbnailView: boolean = true;
  @State themeSelect: number = 0;

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
    await appearanceService.init();
    this.themeSelect = await settingsStore.get<number>(HawkConfig.THEME_SELECT, 0);
    this.thumbnailView = (await settingsStore.get<number>(HawkConfig.SEARCH_VIEW, 1)) === 1;
    if (Object.keys(apiConfigService.state.sourceBeanList).length === 0) {
      try {
        await apiConfigService.loadConfigFromSettings(true);
      } catch (error) {
        this.statusText = `配置加载失败：${errorMessage(error as Error)}`;
        return;
      }
    }
    const rawParams = router.getParams();
    const params = rawParams === undefined ? {} as Record<string, string> : rawParams as Record<string, string>;
    const sourceKey = params['sourceKey'] === undefined ? '' : String(params['sourceKey']);
    const typeId = params['typeId'] === undefined ? '' : String(params['typeId']);

    const source = sourceKey.length > 0
      ? apiConfigService.state.sourceBeanList[sourceKey]
      : apiConfigService.state.homeSource;
    if (source === undefined) {
      this.statusText = '没有可用数据源';
      return;
    }
    this.source = source;

    try {
      const content = await sourceService.getHomeContent(source);
      this.categories = content.classes;
      if (this.categories.length === 0) {
        this.statusText = '该源没有返回分类';
        return;
      }
      const requested = this.categories.findIndex((item: MovieSort) => item.sortId === typeId);
      this.categoryIndex = requested >= 0 ? requested : 0;
      await this.loadPage(1, true);
    } catch (error) {
      this.statusText = `分类加载失败：${errorMessage(error as Error)}`;
    }
  }

  currentCategory(): MovieSort | undefined {
    return this.categoryIndex >= 0 && this.categoryIndex < this.categories.length
      ? this.categories[this.categoryIndex]
      : undefined;
  }

  async selectCategory(index: number): Promise<void> {
    if (index === this.categoryIndex || this.loading) {
      return;
    }
    this.categoryIndex = index;
    this.filterSelect = {};
    this.filterVisible = false;
    await this.loadPage(1, true);
  }

  async selectFilter(filter: SortFilter, value: SortFilterValue): Promise<void> {
    const clearing = this.filterSelect[filter.key] === value.value;
    const next: Record<string, string> = {};
    for (const key of Object.keys(this.filterSelect)) {
      if (key !== filter.key) {
        next[key] = this.filterSelect[key];
      }
    }
    if (!clearing) {
      next[filter.key] = value.value;
    }
    this.filterSelect = next;
    await this.loadPage(1, true);
  }

  isFilterSelected(filter: SortFilter, value: SortFilterValue): boolean {
    return this.filterSelect[filter.key] === value.value;
  }

  async loadPage(page: number, replace: boolean): Promise<void> {
    const source = this.source;
    const category = this.currentCategory();
    if (source === null || category === undefined) {
      return;
    }
    const seq = this.loadSeq + 1;
    this.loadSeq = seq;
    this.loading = true;
    if (replace) {
      this.items = [];
      this.statusText = `正在加载：${category.sortName}`;
    }
    try {
      const result = await sourceService.getCategoryList(source, category.sortId, page, this.filterSelect);
      if (seq !== this.loadSeq) {
        return;
      }
      this.page = result.page > 0 ? result.page : page;
      this.pageCount = result.pagecount > 0 ? result.pagecount : 1;
      this.items = replace ? result.list : this.items.concat(result.list);
      this.statusText = this.items.length === 0
        ? '暂无内容'
        : `${category.sortName} 第 ${this.page}/${this.pageCount} 页，共 ${this.items.length} 条`;
    } catch (error) {
      if (seq !== this.loadSeq) {
        return;
      }
      this.statusText = `加载失败：${errorMessage(error as Error)}`;
    } finally {
      if (seq === this.loadSeq) {
        this.loading = false;
      }
    }
  }

  async loadNextPage(): Promise<void> {
    if (this.loading || this.page >= this.pageCount) {
      return;
    }
    await this.loadPage(this.page + 1, false);
  }

  openVod(vod: VodInfo): void {
    const sourceKey = vod.sourceKey === undefined ? (this.source === null ? '' : this.source.key) : vod.sourceKey;
    if (sourceKey.length === 0 || vod.id.length === 0) {
      return;
    }
    router.pushUrl({
      url: 'pages/Detail',
      params: { sourceKey, vodId: vod.id }
    });
  }

  theme(): ThemePalette {
    return appearanceService.themeByIndex(this.themeSelect);
  }

  @Builder
  vodCard(vod: VodInfo) {
    Column() {
      if (vod.pic !== undefined && vod.pic.length > 0) {
        Image(vod.pic)
          .width('100%')
          .layoutWeight(1)
          .borderRadius(10)
          .objectFit(ImageFit.Cover)
          .alt($r('app.media.app_icon'))
      } else {
        Column() {
          Text('无封面').fontSize(14).fontColor(this.theme().subtleText)
        }
        .width('100%')
        .layoutWeight(1)
        .borderRadius(10)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.theme().fieldBg)
      }
      Text(vod.name)
        .fontSize(14)
        .fontColor(this.theme().text)
        .width('100%')
        .margin({ top: 8 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text(vod.note === undefined ? '' : vod.note)
        .fontSize(12)
        .fontColor(this.theme().mutedText)
        .width('100%')
        .margin({ top: 2 })
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height('100%')
    .padding(8)
    .borderRadius(12)
    .backgroundColor(this.theme().cardBg)
    .focusable(true)
    .onClick(() => this.openVod(vod))
  }

  build() {
    Column() {
      Row() {
        Text('< 返回')
          .fontSize(18)
          .fontColor(this.theme().text)
          .focusable(true)
          .onClick(() => router.back())
        Text(this.source === null ? '分类' : this.source.name)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme().text)
          .margin({ left: 24 })
          .layoutWeight(1)
        if (this.currentCategoryHasFilters()) {
          Button(this.filterVisible ? '收起筛选' : '筛选')
            .height(36)
            .margin({ right: 10 })
            .onClick(() => this.filterVisible = !this.filterVisible)
        }
        Text(this.statusText)
          .fontSize(13)
          .fontColor(this.theme().mutedText)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.categories.length > 0) {
        Scroll() {
          Row() {
            ForEach(this.categories, (category: MovieSort, index: number) => {
              Text(category.sortName)
                .fontSize(15)
                .fontColor(this.theme().text)
                .padding({ left: 16, right: 16, top: 9, bottom: 9 })
                .margin({ right: 10 })
                .backgroundColor(this.categoryIndex === index ? this.theme().primary : this.theme().panelBg)
                .borderRadius(16)
                .focusable(true)
                .onClick(() => this.selectCategory(index))
            }, (category: MovieSort) => category.sortId)
          }
        }
        .scrollable(ScrollDirection.Horizontal)
        .width('100%')
        .margin({ top: 16 })
      }

      if (this.filterVisible) {
        Column() {
          ForEach(this.currentFilters(), (filter: SortFilter) => {
            Column() {
              Text(filter.name).fontSize(14).fontColor(this.theme().mutedText).width('100%')
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(filter.values, (value: SortFilterValue) => {
                  Text(value.name)
                    .fontSize(13)
                    .fontColor(this.theme().text)
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .margin({ right: 8, top: 6 })
                    .backgroundColor(this.isFilterSelected(filter, value) ? this.theme().primary : this.theme().panelBg)
                    .borderRadius(8)
                    .focusable(true)
                    .onClick(() => this.selectFilter(filter, value))
                }, (value: SortFilterValue) => `${filter.key}-${value.value}`)
              }
              .width('100%')
            }
            .width('100%')
            .margin({ top: 10 })
          }, (filter: SortFilter) => filter.key)
        }
        .width('100%')
        .padding(14)
        .margin({ top: 12 })
        .backgroundColor(this.theme().cardBg)
        .borderRadius(12)
      }

      if (this.items.length === 0 && !this.loading) {
        Column() {
          Text(this.statusText).fontSize(17).fontColor(this.theme().mutedText)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Grid() {
          ForEach(this.items, (vod: VodInfo) => {
            GridItem() {
              this.vodCard(vod)
            }
            .height(240)
          }, (vod: VodInfo, index: number) => `${vod.sourceKey || ''}:${vod.id}:${index}`)
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
        .columnsGap(14)
        .rowsGap(14)
        .width('100%')
        .layoutWeight(1)
        .margin({ top: 14 })
        .onReachEnd(() => this.loadNextPage())
      }

      if (this.loading) {
        Row() {
          LoadingProgress().width(24).height(24).color(this.theme().primarySoft)
          Text('加载中').fontSize(14).fontColor(this.theme().mutedText).margin({ left: 10 })
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 8, bottom: 8 })
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 40, right: 40, top: 30, bottom: 24 })
    .backgroundColor(this.theme().pageBg)
  }

  currentFilters(): SortFilter[] {
    const category = this.currentCategory();
    return category === undefined ? [] : category.filters;
  }

  currentCategoryHasFilters(): boolean {
    return this.currentFilters().length > 0;
  }
}
