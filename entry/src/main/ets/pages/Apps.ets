import router from '@ohos.router';

@Entry
@Component
struct Apps {
  build() {
    Column() {
      Text('< 返回').fontSize(18).fontColor(Color.White).alignSelf(ItemAlign.Start).onClick(() => router.back())
      Text('应用').fontSize(36).fontWeight(FontWeight.Bold).fontColor(Color.White).margin({ top: 60 })
      Text('AppsActivity：Android 包管理能力需映射到 HarmonyOS 可用 API。').fontSize(16).fontColor('#d1d5db').margin({ top: 24 })
    }.width('100%').height('100%').padding(48).backgroundColor('#0b1020')
  }
}
