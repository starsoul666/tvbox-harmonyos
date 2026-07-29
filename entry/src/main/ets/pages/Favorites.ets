import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { HawkConfig } from '../constants/HawkConfig';
import { VodCollect } from '../models/TvBoxModels';
import { appearanceService, FeatureLabels, ThemePalette } from '../services/AppearanceService';
import { settingsStore } from '../services/SettingsStore';
import { vodDataStore } from '../services/VodDataStore';

@Entry
@Component
struct Favorites {
  @State collects: VodCollect[] = [];
  @State deleteMode: boolean = false;
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
    this.refresh();
  }

  onPageShow(): void {
    this.refresh();
  }

  refresh(): void {
    this.collects = vodDataStore.getAllVodCollect();
  }

  openDetail(item: VodCollect): void {
    if (this.deleteMode) {
      vodDataStore.deleteVodCollect(item.id);
      this.refresh();
      return;
    }
    router.pushUrl({
      url: 'pages/Detail',
      params: {
        sourceKey: item.sourceKey,
        vodId: item.vodId
      }
    });
  }

  clearAll(): void {
    vodDataStore.deleteVodCollectAll();
    this.deleteMode = false;
    this.refresh();
    promptAction.showToast({ message: this.labels().favoritesCleared });
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
        Text(this.labels().favoritesTitle)
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme().text)
          .margin({ left: 20 })
          .layoutWeight(1)
        Text(`${this.collects.length}${this.labels().countSuffix}`)
          .fontSize(14)
          .fontColor(this.theme().mutedText)
          .margin({ right: 12 })
        Button(this.deleteMode ? this.labels().done : this.labels().delete)
          .height(38)
          .enabled(this.collects.length > 0)
          .onClick(() => this.deleteMode = !this.deleteMode)
        Button(this.labels().clear)
          .height(38)
          .margin({ left: 10 })
          .enabled(this.collects.length > 0)
          .onClick(() => this.clearAll())
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.deleteMode) {
        Text(this.labels().favoritesDeleteHint)
          .fontSize(13)
          .fontColor('#fbbf24')
          .margin({ top: 10 })
          .width('100%')
      }

      if (this.collects.length === 0) {
        Column() {
          Text(this.labels().emptyFavorites).fontSize(17).fontColor(this.theme().mutedText)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Grid() {
          ForEach(this.collects, (item: VodCollect) => {
            GridItem() {
              Column() {
                if (item.vodPic !== undefined && item.vodPic.length > 0) {
                  Image(item.vodPic)
                    .width('100%')
                    .layoutWeight(1)
                    .borderRadius(10)
                    .objectFit(ImageFit.Cover)
                    .alt($r('app.media.app_icon'))
                } else {
                  Column() {
                    Text(this.labels().noCover).fontSize(13).fontColor(this.theme().subtleText)
                  }
                  .width('100%')
                  .layoutWeight(1)
                  .borderRadius(10)
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor(this.theme().fieldBg)
                }
                Text(item.vodName)
                  .fontSize(14)
                  .fontColor(this.theme().text)
                  .width('100%')
                  .margin({ top: 8 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.deleteMode ? this.labels().clickRemove : item.sourceKey)
                  .fontSize(12)
                  .fontColor(this.deleteMode ? '#fca5a5' : this.theme().mutedText)
                  .width('100%')
                  .margin({ top: 2 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .height('100%')
              .padding(8)
              .borderRadius(12)
              .backgroundColor(this.deleteMode ? '#2a1a1a' : this.theme().cardBg)
              .focusable(true)
              .onClick(() => this.openDetail(item))
            }
            .height(240)
          }, (item: VodCollect) => item.id)
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
        .columnsGap(14)
        .rowsGap(14)
        .width('100%')
        .layoutWeight(1)
        .margin({ top: 14 })
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 40, right: 40, top: 30, bottom: 24 })
    .backgroundColor(this.theme().pageBg)
  }
}
