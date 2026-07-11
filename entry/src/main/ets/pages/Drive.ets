import router from '@ohos.router';

@Entry
@Component
struct Drive {
  build() {
    Column() {
      Text('< 返回').fontSize(18).fontColor(Color.White).alignSelf(ItemAlign.Start).onClick(() => router.back())
      Text('网盘').fontSize(36).fontWeight(FontWeight.Bold).fontColor(Color.White).margin({ top: 60 })
      Text('DriveActivity：待迁移 Local / Alist / WebDAV 浏览和播放。').fontSize(16).fontColor('#d1d5db').margin({ top: 24 })
    }.width('100%').height('100%').padding(48).backgroundColor('#0b1020')
  }
}
