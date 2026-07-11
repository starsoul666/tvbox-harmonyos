import router from '@ohos.router';

@Entry
@Component
struct Push {
  @State url: string = '';
  @State statusText: string = '输入 http/https/m3u8/mp4 等播放地址后可直接播放';

  openPlay(): void {
    const value = this.url.trim();
    if (value.length === 0) {
      this.statusText = '播放地址不能为空';
      return;
    }
    router.pushUrl({
      url: 'pages/Play',
      params: {
        sourceKey: '',
        vodId: value,
        playFlag: 'push',
        playIndex: '0',
        playUrl: value,
        rawUrl: value,
        episodeName: '推送播放'
      }
    });
  }

  build() {
    Column() {
      Text('< 返回').fontSize(18).fontColor(Color.White).alignSelf(ItemAlign.Start).onClick(() => router.back())
      Text('推送').fontSize(36).fontWeight(FontWeight.Bold).fontColor(Color.White).margin({ top: 32 })
      TextInput({ text: this.url, placeholder: '输入播放地址' })
        .height(52)
        .fontSize(18)
        .margin({ top: 24 })
        .onChange((value: string) => this.url = value)
      Row() {
        Button('直接播放')
          .height(44)
          .onClick(() => this.openPlay())
        Text(this.statusText)
          .fontSize(15)
          .fontColor('#d1d5db')
          .margin({ left: 16 })
          .layoutWeight(1)
      }.width('100%').margin({ top: 18 }).alignItems(VerticalAlign.Center)
      Text('远程 HTTP server 接收推送、二维码入口和 push_agent 详情页仍待迁移。')
        .fontSize(14)
        .fontColor('#93a4b8')
        .margin({ top: 24 })
    }.width('100%').height('100%').padding(48).backgroundColor('#0b1020')
  }
}
