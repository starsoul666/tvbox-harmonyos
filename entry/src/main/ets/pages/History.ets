import router from '@ohos.router';
import { VodInfo } from '../models/TvBoxModels';
import { settingsStore } from '../services/SettingsStore';
import { vodDataStore } from '../services/VodDataStore';

@Entry
@Component
struct History {
  @State records: VodInfo[] = [];

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
    this.records = vodDataStore.getAllVodRecord(50);
  }

  openRecord(item: VodInfo): void {
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
          episodeName: item.playNote || ''
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

  build() {
    Column() {
      Text('< 返回').fontSize(18).fontColor(Color.White).alignSelf(ItemAlign.Start).onClick(() => router.back())
      Text('历史').fontSize(36).fontWeight(FontWeight.Bold).fontColor(Color.White).margin({ top: 60 })
      if (this.records.length === 0) {
        Text('暂无播放历史').fontSize(16).fontColor('#d1d5db').margin({ top: 24 })
      } else {
        List() {
          ForEach(this.records, (item: VodInfo) => {
            ListItem() {
              Column() {
                Text(item.name).fontSize(22).fontColor(Color.White).maxLines(1)
                Text(`${item.sourceKey || ''} ${item.playNote || item.note || ''}`).fontSize(14).fontColor('#93a4b8').margin({ top: 6 })
              }
              .width('100%')
              .padding(18)
              .backgroundColor('#111827')
              .borderRadius(12)
              .onClick(() => this.openRecord(item))
            }.margin({ top: 12 })
          }, (item: VodInfo) => `${item.sourceKey || ''}:${item.id}`)
        }.width('100%').layoutWeight(1).margin({ top: 24 })
      }
    }.width('100%').height('100%').padding(48).backgroundColor('#0b1020')
  }
}
