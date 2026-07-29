import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { HawkConfig } from '../constants/HawkConfig';
import { HomeNumValues } from '../constants/AppDefaults';
import { VodInfo } from '../models/TvBoxModels';
import { appearanceService, FeatureLabels, ThemePalette } from '../services/AppearanceService';
import { settingsStore } from '../services/SettingsStore';
import { vodDataStore } from '../services/VodDataStore';

@Entry
@Component
struct History {
  @State records: VodInfo[] = [];
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
    await this.refresh();
  }

  onPageShow(): void {
    this.refresh();
  }

  /** Android `HOME_NUM` controls how many history rows are kept visible. */
  async refresh(): Promise<void> {
    const numIndex = await settingsStore.get<number>(HawkConfig.HOME_NUM, 4);
    const limit = numIndex >= 0 && numIndex < HomeNumValues.length ? HomeNumValues[numIndex] : HomeNumValues[0];
    this.records = vodDataStore.getAllVodRecord(limit);
  }

  openRecord(item: VodInfo): void {
    if (this.deleteMode) {
      vodDataStore.deleteVodRecord(item.sourceKey || '', item.id);
      this.refresh();
      return;
    }
    if (item.last !== undefined && item.last.length > 0) {
      router.pushUrl({
        url: 'pages/Play',
        params: {
          sourceKey: item.sourceKey || '',
          vodId: item.id,
          playFlag: item.playFlag || '',
          playIndex: `${item.playIndex}`,
          playUrl: item.last,
          rawUrl: item.rawUrl || item.last,
          episodeName: item.playNote || '',
          playerCfg: item.playerCfg || ''
        }
      });
      return;
    }
    router.pushUrl({
      url: 'pages/Detail',
      params: {
        sourceKey: item.sourceKey || '',
        vodId: item.id
      }
    });
  }

  clearAll(): void {
    vodDataStore.deleteVodRecordAll();
    this.deleteMode = false;
    this.refresh();
    promptAction.showToast({ message: this.labels().historyCleared });
  }

  progressText(item: VodInfo): string {
    const progress = item.progress === undefined ? 0 : item.progress;
    const duration = item.duration === undefined ? 0 : item.duration;
    if (progress <= 0 || duration <= 0) {
      return '';
    }
    const percent = Math.floor((progress / duration) * 100);
    return `${this.labels().watchedPrefix}${percent > 100 ? 100 : percent}%`;
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
        Text(this.labels().historyTitle)
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme().text)
          .margin({ left: 20 })
          .layoutWeight(1)
        Text(`${this.records.length}${this.labels().countSuffix}`)
          .fontSize(14)
          .fontColor(this.theme().mutedText)
          .margin({ right: 12 })
        Button(this.deleteMode ? this.labels().done : this.labels().delete)
          .height(38)
          .enabled(this.records.length > 0)
          .onClick(() => this.deleteMode = !this.deleteMode)
        Button(this.labels().clear)
          .height(38)
          .margin({ left: 10 })
          .enabled(this.records.length > 0)
          .onClick(() => this.clearAll())
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.deleteMode) {
        Text(this.labels().historyDeleteHint)
          .fontSize(13)
          .fontColor('#fbbf24')
          .margin({ top: 10 })
          .width('100%')
      }

      if (this.records.length === 0) {
        Column() {
          Text(this.labels().emptyHistory).fontSize(17).fontColor(this.theme().mutedText)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.records, (item: VodInfo) => {
            ListItem() {
              Row() {
                if (item.pic !== undefined && item.pic.length > 0) {
                  Image(item.pic)
                    .width(70)
                    .height(96)
                    .borderRadius(8)
                    .objectFit(ImageFit.Cover)
                    .alt($r('app.media.app_icon'))
                }
                Column() {
                  Text(item.name)
                    .fontSize(18)
                    .fontColor(this.theme().text)
                    .width('100%')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(`${item.playFlag || ''} ${item.playNote || ''}`)
                    .fontSize(14)
                    .fontColor(this.theme().text)
                    .width('100%')
                    .margin({ top: 6 })
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(`${item.sourceKey || ''} ${this.progressText(item)}`)
                    .fontSize(12)
                    .fontColor(this.theme().mutedText)
                    .width('100%')
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .margin({ left: 14 })
                if (this.deleteMode) {
                  Text(this.labels().remove).fontSize(14).fontColor('#fca5a5')
                }
              }
              .width('100%')
              .padding(14)
              .backgroundColor(this.deleteMode ? '#2a1a1a' : this.theme().fieldBg)
              .borderRadius(12)
              .focusable(true)
              .onClick(() => this.openRecord(item))
            }
            .margin({ top: 12 })
          }, (item: VodInfo) => `${item.sourceKey || ''}:${item.id}`)
        }
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
