import router from '@ohos.router';
import { VodCollect } from '../models/TvBoxModels';
import { settingsStore } from '../services/SettingsStore';
import { vodDataStore } from '../services/VodDataStore';

@Entry
@Component
struct Favorites {
  @State collects: VodCollect[] = [];

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
    this.collects = vodDataStore.getAllVodCollect();
  }

  openDetail(item: VodCollect): void {
    router.pushUrl({
      url: 'pages/Detail',
      params: {
        sourceKey: item.sourceKey,
        vodId: item.vodId
      }
    });
  }

  build() {
    Column() {
      Text('< 返回').fontSize(18).fontColor(Color.White).alignSelf(ItemAlign.Start).onClick(() => router.back())
      Text('收藏').fontSize(36).fontWeight(FontWeight.Bold).fontColor(Color.White).margin({ top: 60 })
      if (this.collects.length === 0) {
        Text('暂无收藏').fontSize(16).fontColor('#d1d5db').margin({ top: 24 })
      } else {
        List() {
          ForEach(this.collects, (item: VodCollect) => {
            ListItem() {
              Row() {
                Column() {
                  Text(item.vodName).fontSize(22).fontColor(Color.White).maxLines(1)
                  Text(item.sourceKey).fontSize(14).fontColor('#93a4b8').margin({ top: 6 })
                }.layoutWeight(1)
                Text('删除').fontSize(14).fontColor('#fca5a5').onClick(() => {
                  vodDataStore.deleteVodCollect(item.id);
                  this.collects = vodDataStore.getAllVodCollect();
                })
              }
              .width('100%')
              .padding(18)
              .backgroundColor('#111827')
              .borderRadius(12)
              .onClick(() => this.openDetail(item))
            }.margin({ top: 12 })
          }, (item: VodCollect) => item.id)
        }.width('100%').layoutWeight(1).margin({ top: 24 })
      }
    }.width('100%').height('100%').padding(48).backgroundColor('#0b1020')
  }
}
