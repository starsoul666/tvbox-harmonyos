import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { AndroidCompatibleDefaults, SettingDefault } from '../constants/AppDefaults';
import { HawkConfig } from '../constants/HawkConfig';
import { apiConfigService } from '../services/ApiConfigService';
import { settingsStore } from '../services/SettingsStore';

@Entry
@Component
struct Settings {
  @State apiUrl: string = '';
  @State liveUrl: string = '';
  @State epgUrl: string = '';
  @State status: string = '未加载';
  @State sourceCount: number = 0;
  @State defaults: SettingDefault[] = AndroidCompatibleDefaults;

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
    this.apiUrl = await settingsStore.get<string>(HawkConfig.API_URL, '');
    this.liveUrl = await settingsStore.get<string>(HawkConfig.LIVE_URL, '');
    this.epgUrl = await settingsStore.get<string>(HawkConfig.EPG_URL, '');
    this.sourceCount = Object.keys(apiConfigService.state.sourceBeanList).length;
  }

  async saveApiUrl(value: string): Promise<void> {
    this.apiUrl = value;
    await settingsStore.put(HawkConfig.API_URL, value);
  }

  async saveLiveUrl(value: string): Promise<void> {
    this.liveUrl = value;
    await settingsStore.put(HawkConfig.LIVE_URL, value);
  }

  async saveEpgUrl(value: string): Promise<void> {
    this.epgUrl = value;
    await settingsStore.put(HawkConfig.EPG_URL, value);
  }

  async loadConfig(): Promise<void> {
    try {
      this.status = '加载中...';
      await apiConfigService.loadConfig(this.apiUrl);
      this.sourceCount = Object.keys(apiConfigService.state.sourceBeanList).length;
      if (this.liveUrl.length === 0 && apiConfigService.state.liveSourceUrl.length > 0) {
        await this.saveLiveUrl(apiConfigService.state.liveSourceUrl);
      }
      if (this.epgUrl.length === 0 && apiConfigService.state.liveEpgUrl.length > 0) {
        await this.saveEpgUrl(apiConfigService.state.liveEpgUrl);
      }
      this.status = `加载成功：${this.sourceCount} 个源`;
      promptAction.showToast({ message: this.status });
    } catch (error) {
      this.status = `加载失败：${JSON.stringify(error)}`;
      promptAction.showToast({ message: '配置加载失败' });
    }
  }

  build() {
    Column() {
      Row() {
        Text('<')
          .fontSize(28)
          .fontColor(Color.White)
          .width(56)
          .textAlign(TextAlign.Center)
          .onClick(() => router.back())
        Text('设置')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .layoutWeight(1)
      }
      .height(72)
      .padding({ left: 24, right: 40 })

      List() {
        ListItem() {
          Column() {
            Text('配置地址')
              .fontSize(18)
              .fontColor(Color.White)
            TextInput({ text: this.apiUrl, placeholder: '请输入 TVBox JSON 配置地址' })
              .height(48)
              .fontSize(16)
              .margin({ top: 12 })
              .onChange((value: string) => {
                this.saveApiUrl(value);
              })
            Row() {
              Button('加载配置')
                .height(42)
                .onClick(() => {
                  this.loadConfig();
                })
              Text(this.status)
                .fontSize(14)
                .fontColor('#aab2c0')
                .margin({ left: 16 })
            }
            .margin({ top: 12 })
          }
          .padding(20)
          .backgroundColor('#1f2937')
          .borderRadius(16)
        }

        ListItem() {
          Column() {
            Text('直播设置')
              .fontSize(18)
              .fontColor(Color.White)
            TextInput({ text: this.liveUrl, placeholder: '直播 M3U/TXT 地址，可由配置 lives 自动填充' })
              .height(48)
              .fontSize(16)
              .margin({ top: 12 })
              .onChange((value: string) => {
                this.saveLiveUrl(value);
              })
            TextInput({ text: this.epgUrl, placeholder: 'EPG 地址' })
              .height(48)
              .fontSize(16)
              .margin({ top: 12 })
              .onChange((value: string) => {
                this.saveEpgUrl(value);
              })
            Text('对应 Android HawkConfig.LIVE_URL / EPG_URL，Live 页面会读取并加载频道。')
              .fontSize(13)
              .fontColor('#93a4b8')
              .margin({ top: 10 })
          }
          .padding(20)
          .margin({ top: 16 })
          .backgroundColor('#1f2937')
          .borderRadius(16)
        }

        ListItem() {
          Text('Android 默认设置镜像')
            .fontSize(20)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)
            .padding({ top: 24, bottom: 12 })
        }

        ForEach(this.defaults, (item: SettingDefault) => {
          ListItem() {
            Row() {
              Column() {
                Text(item.label)
                  .fontSize(17)
                  .fontColor(Color.White)
                Text(`${item.group} / ${item.key}`)
                  .fontSize(12)
                  .fontColor('#93a4b8')
                  .margin({ top: 4 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)
              Text(String(item.value))
                .fontSize(15)
                .fontColor('#d1d5db')
            }
            .padding(16)
            .backgroundColor('#151d2b')
            .borderRadius(12)
          }
        })
      }
      .padding({ left: 48, right: 48, bottom: 32 })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0b1020')
  }
}
