import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { VodCollect } from '../models/TvBoxModels';
import { settingsStore } from '../services/SettingsStore';
import { vodDataStore } from '../services/VodDataStore';

@Entry
@Component
struct Favorites {
  @State collects: VodCollect[] = [];
  @State deleteMode: boolean = false;

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
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
    promptAction.showToast({ message: '已清空收藏' });
  }

  build() {
    Column() {
      Row() {
        Text('< 返回')
          .fontSize(18)
          .fontColor(Color.White)
          .focusable(true)
          .onClick(() => router.back())
        Text('收藏')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .margin({ left: 20 })
          .layoutWeight(1)
        Text(`${this.collects.length} 条`)
          .fontSize(14)
          .fontColor('#93a4b8')
          .margin({ right: 12 })
        Button(this.deleteMode ? '完成' : '删除')
          .height(38)
          .enabled(this.collects.length > 0)
          .onClick(() => this.deleteMode = !this.deleteMode)
        Button('清空')
          .height(38)
          .margin({ left: 10 })
          .enabled(this.collects.length > 0)
          .onClick(() => this.clearAll())
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.deleteMode) {
        Text('删除模式：点击条目即可移除该收藏')
          .fontSize(13)
          .fontColor('#fbbf24')
          .margin({ top: 10 })
          .width('100%')
      }

      if (this.collects.length === 0) {
        Column() {
          Text('暂无收藏').fontSize(17).fontColor('#d1d5db')
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
                    Text('无封面').fontSize(13).fontColor('#64748b')
                  }
                  .width('100%')
                  .layoutWeight(1)
                  .borderRadius(10)
                  .justifyContent(FlexAlign.Center)
                  .backgroundColor('#111827')
                }
                Text(item.vodName)
                  .fontSize(14)
                  .fontColor(Color.White)
                  .width('100%')
                  .margin({ top: 8 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.deleteMode ? '点击移除' : item.sourceKey)
                  .fontSize(12)
                  .fontColor(this.deleteMode ? '#fca5a5' : '#93a4b8')
                  .width('100%')
                  .margin({ top: 2 })
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .height('100%')
              .padding(8)
              .borderRadius(12)
              .backgroundColor(this.deleteMode ? '#2a1a1a' : '#151d2b')
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
    .backgroundColor('#0b1020')
  }
}
