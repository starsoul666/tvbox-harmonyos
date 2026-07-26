import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { HawkConfig } from '../constants/HawkConfig';
import { HomeNumValues } from '../constants/AppDefaults';
import { VodInfo } from '../models/TvBoxModels';
import { settingsStore } from '../services/SettingsStore';
import { vodDataStore } from '../services/VodDataStore';

@Entry
@Component
struct History {
  @State records: VodInfo[] = [];
  @State deleteMode: boolean = false;

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
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
    promptAction.showToast({ message: '已清空播放历史' });
  }

  progressText(item: VodInfo): string {
    const progress = item.progress === undefined ? 0 : item.progress;
    const duration = item.duration === undefined ? 0 : item.duration;
    if (progress <= 0 || duration <= 0) {
      return '';
    }
    const percent = Math.floor((progress / duration) * 100);
    return `已看 ${percent > 100 ? 100 : percent}%`;
  }

  build() {
    Column() {
      Row() {
        Text('< 返回')
          .fontSize(18)
          .fontColor(Color.White)
          .focusable(true)
          .onClick(() => router.back())
        Text('历史')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ left: 20 })
          .layoutWeight(1)
        Text(`${this.records.length} 条`)
          .fontSize(14)
          .fontColor('#93a4b8')
          .margin({ right: 12 })
        Button(this.deleteMode ? '完成' : '删除')
          .height(38)
          .enabled(this.records.length > 0)
          .onClick(() => this.deleteMode = !this.deleteMode)
        Button('清空')
          .height(38)
          .margin({ left: 10 })
          .enabled(this.records.length > 0)
          .onClick(() => this.clearAll())
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.deleteMode) {
        Text('删除模式：点击条目即可移除该条历史')
          .fontSize(13)
          .fontColor('#fbbf24')
          .margin({ top: 10 })
          .width('100%')
      }

      if (this.records.length === 0) {
        Column() {
          Text('暂无播放历史').fontSize(17).fontColor('#d1d5db')
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
                    .fontColor(Color.White)
                    .width('100%')
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(`${item.playFlag || ''} ${item.playNote || ''}`)
                    .fontSize(14)
                    .fontColor('#cbd5e1')
                    .width('100%')
                    .margin({ top: 6 })
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(`${item.sourceKey || ''} ${this.progressText(item)}`)
                    .fontSize(12)
                    .fontColor('#93a4b8')
                    .width('100%')
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .margin({ left: 14 })
                if (this.deleteMode) {
                  Text('移除').fontSize(14).fontColor('#fca5a5')
                }
              }
              .width('100%')
              .padding(14)
              .backgroundColor(this.deleteMode ? '#2a1a1a' : '#111827')
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
    .backgroundColor('#0b1020')
  }
}
