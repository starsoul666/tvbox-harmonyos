import router from '@ohos.router';
import { HawkConfig } from '../constants/HawkConfig';
import { LiveChannelGroup, LiveChannelItem } from '../models/TvBoxModels';
import { apiConfigService } from '../services/ApiConfigService';
import { settingsStore } from '../services/SettingsStore';

@Entry
@Component
struct Live {
  private controller: VideoController = new VideoController();

  @State groups: LiveChannelGroup[] = [];
  @State selectedGroupIndex: number = 0;
  @State selectedChannelIndex: number = 0;
  @State selectedSourceIndex: number = 0;
  @State playUrl: string = '';
  @State statusText: string = '正在初始化直播';
  @State errorText: string = '';
  @State groupName: string = '';
  @State channelName: string = '';
  @State sourceName: string = '';
  @State isPlaying: boolean = true;
  @State loading: boolean = false;
  @State liveUrl: string = '';
  @State epgUrl: string = '';

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
    await this.ensureConfigLoaded();
    this.liveUrl = apiConfigService.state.liveSourceUrl;
    this.epgUrl = apiConfigService.state.liveEpgUrl;
    if (this.liveUrl.length === 0) {
      this.liveUrl = await settingsStore.get<string>(HawkConfig.LIVE_URL, '');
    } else if ((await settingsStore.get<string>(HawkConfig.LIVE_URL, '')).length === 0) {
      await settingsStore.put(HawkConfig.LIVE_URL, this.liveUrl);
    }
    if (this.epgUrl.length === 0) {
      this.epgUrl = await settingsStore.get<string>(HawkConfig.EPG_URL, '');
    } else if ((await settingsStore.get<string>(HawkConfig.EPG_URL, '')).length === 0) {
      await settingsStore.put(HawkConfig.EPG_URL, this.epgUrl);
    }

    this.groups = apiConfigService.state.liveChannelGroupList;
    if (this.groups.length === 0 && this.liveUrl.length > 0) {
      await this.loadSubscription(this.liveUrl);
    }
    this.restoreSelection();
    this.openSelectedChannel(false);
  }

  async ensureConfigLoaded(): Promise<void> {
    if (Object.keys(apiConfigService.state.sourceBeanList).length === 0 &&
      apiConfigService.state.liveChannelGroupList.length === 0) {
      try {
        await apiConfigService.loadConfigFromSettings(true);
      } catch (error) {
        this.errorText = `配置加载失败：${this.stringifyError(error)}`;
      }
    }
  }

  async loadSubscription(url: string): Promise<void> {
    this.loading = true;
    this.statusText = '正在加载直播订阅';
    try {
      this.groups = await apiConfigService.loadLiveSubscription(url);
      this.statusText = `已加载 ${this.groups.length} 个直播分组`;
    } catch (error) {
      this.errorText = `直播订阅加载失败：${this.stringifyError(error)}`;
      this.statusText = '直播加载失败';
    } finally {
      this.loading = false;
    }
  }

  restoreSelection(): void {
    if (this.groups.length === 0) {
      return;
    }
    const savedGroup = settingsStore.getSync<string>(HawkConfig.LIVE_CHANNEL_GROUP, '');
    const savedChannel = settingsStore.getSync<string>(HawkConfig.LIVE_CHANNEL, '');
    let groupIndex = savedGroup.length > 0
      ? this.groups.findIndex((group: LiveChannelGroup) => group.groupName === savedGroup)
      : 0;
    if (groupIndex < 0) {
      groupIndex = 0;
    }
    this.selectedGroupIndex = groupIndex;
    const channels = this.getChannels(groupIndex);
    let channelIndex = savedChannel.length > 0
      ? channels.findIndex((channel: LiveChannelItem) => channel.channelName === savedChannel)
      : 0;
    if (channelIndex < 0) {
      channelIndex = 0;
    }
    this.selectedChannelIndex = channelIndex;
    this.selectedSourceIndex = 0;
  }

  getChannels(groupIndex: number): LiveChannelItem[] {
    if (groupIndex < 0 || groupIndex >= this.groups.length) {
      return [];
    }
    return this.groups[groupIndex].liveChannels;
  }

  getCurrentChannel(): LiveChannelItem | undefined {
    const channels = this.getChannels(this.selectedGroupIndex);
    if (this.selectedChannelIndex < 0 || this.selectedChannelIndex >= channels.length) {
      return undefined;
    }
    return channels[this.selectedChannelIndex];
  }

  async selectGroup(index: number): Promise<void> {
    if (index < 0 || index >= this.groups.length) {
      return;
    }
    this.selectedGroupIndex = index;
    this.selectedChannelIndex = 0;
    this.selectedSourceIndex = 0;
    await this.openSelectedChannel(true);
  }

  async selectChannel(index: number): Promise<void> {
    const channels = this.getChannels(this.selectedGroupIndex);
    if (index < 0 || index >= channels.length) {
      return;
    }
    this.selectedChannelIndex = index;
    this.selectedSourceIndex = 0;
    await this.openSelectedChannel(true);
  }

  async selectSource(index: number): Promise<void> {
    const channel = this.getCurrentChannel();
    if (channel === undefined || index < 0 || index >= channel.sourceUrls.length) {
      return;
    }
    this.selectedSourceIndex = index;
    await this.openSelectedChannel(true);
  }

  async openSelectedChannel(saveSelection: boolean): Promise<void> {
    if (this.groups.length === 0) {
      this.statusText = this.errorText.length > 0 ? '直播不可用' : '未找到直播频道';
      this.playUrl = '';
      return;
    }
    const group = this.groups[this.selectedGroupIndex];
    const channel = this.getCurrentChannel();
    if (channel === undefined || channel.sourceUrls.length === 0) {
      this.statusText = '当前分组没有可播放频道';
      this.playUrl = '';
      return;
    }
    if (this.selectedSourceIndex >= channel.sourceUrls.length) {
      this.selectedSourceIndex = 0;
    }
    this.groupName = group.groupName;
    this.channelName = channel.channelName;
    this.sourceName = this.getSourceLabel(channel, this.selectedSourceIndex);
    this.playUrl = channel.sourceUrls[this.selectedSourceIndex];
    this.errorText = '';
    this.statusText = `${this.groupName} / ${this.channelName} / ${this.sourceName}`;
    this.isPlaying = true;
    if (saveSelection) {
      await settingsStore.put(HawkConfig.LIVE_CHANNEL_GROUP, this.groupName);
      await settingsStore.put(HawkConfig.LIVE_CHANNEL, this.channelName);
    }
  }

  async switchChannel(offset: number): Promise<void> {
    const channels = this.getChannels(this.selectedGroupIndex);
    if (channels.length === 0) {
      return;
    }
    let index = this.selectedChannelIndex + offset;
    if (index < 0) {
      index = channels.length - 1;
    } else if (index >= channels.length) {
      index = 0;
    }
    this.selectedChannelIndex = index;
    this.selectedSourceIndex = 0;
    await this.openSelectedChannel(true);
  }

  async switchSource(offset: number): Promise<void> {
    const channel = this.getCurrentChannel();
    if (channel === undefined || channel.sourceUrls.length <= 1) {
      return;
    }
    let index = this.selectedSourceIndex + offset;
    if (index < 0) {
      index = channel.sourceUrls.length - 1;
    } else if (index >= channel.sourceUrls.length) {
      index = 0;
    }
    this.selectedSourceIndex = index;
    await this.openSelectedChannel(true);
  }

  togglePlay(): void {
    if (this.playUrl.length === 0) {
      return;
    }
    if (this.isPlaying) {
      this.controller.pause();
      this.isPlaying = false;
      this.statusText = '直播已暂停';
    } else {
      this.controller.start();
      this.isPlaying = true;
      this.statusText = `${this.groupName} / ${this.channelName} / ${this.sourceName}`;
    }
  }

  getSourceLabel(channel: LiveChannelItem, index: number): string {
    if (index >= 0 && index < channel.sourceNames.length && channel.sourceNames[index].length > 0) {
      return channel.sourceNames[index];
    }
    return `源${index + 1}`;
  }

  getCurrentSourceUrls(): string[] {
    const channel = this.getCurrentChannel();
    return channel === undefined ? [] : channel.sourceUrls;
  }

  getCurrentSourceLabel(index: number): string {
    const channel = this.getCurrentChannel();
    return channel === undefined ? `源${index + 1}` : this.getSourceLabel(channel, index);
  }

  channelNumber(channel: LiveChannelItem, index: number): string {
    const num = channel.channelNum > 0 ? channel.channelNum : index + 1;
    return num < 10 ? `00${num}` : num < 100 ? `0${num}` : `${num}`;
  }

  stringifyError(error: unknown): string {
    if (error instanceof Error) {
      return error.message;
    }
    const text = JSON.stringify(error);
    return text === undefined || text.length === 0 ? String(error) : text;
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        if (this.playUrl.length > 0) {
          Video({
            src: this.playUrl,
            currentProgressRate: PlaybackSpeed.Speed_Forward_1_00_X,
            controller: this.controller
          })
            .width('100%')
            .height('100%')
            .autoPlay(true)
            .controls(false)
            .objectFit(ImageFit.Contain)
            .onPrepared(() => {
              this.statusText = `${this.groupName} / ${this.channelName} / ${this.sourceName}`;
              this.isPlaying = true;
            })
            .onError(() => {
              this.errorText = '直播播放失败，请切换频道或线路';
              this.statusText = '播放失败';
              this.isPlaying = false;
            })
        } else {
          Column() {
            Text(this.loading ? '正在加载直播频道' : '无直播播放地址')
              .fontSize(30)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
            Text(this.errorText.length > 0 ? this.errorText : '请确认配置中的 lives 或设置中的 LIVE_URL')
              .fontSize(16)
              .fontColor(this.errorText.length > 0 ? '#fca5a5' : '#cbd5e1')
              .margin({ top: 12 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)

      Row() {
        Column() {
          Row() {
            Text('< 返回')
              .fontSize(18)
              .fontColor(Color.White)
              .onClick(() => router.back())
            Column() {
              Text(this.channelName.length > 0 ? this.channelName : '直播')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(this.statusText)
                .fontSize(14)
                .fontColor(this.errorText.length > 0 ? '#fca5a5' : '#cbd5e1')
                .margin({ top: 4 })
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)
            .margin({ left: 24 })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          if (this.errorText.length > 0) {
            Text(this.errorText)
              .fontSize(14)
              .fontColor('#fca5a5')
              .margin({ top: 10 })
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }

          Row() {
            Button(this.isPlaying ? '暂停' : '播放')
              .height(40)
              .enabled(this.playUrl.length > 0)
              .onClick(() => this.togglePlay())
            Button('上一台')
              .height(40)
              .margin({ left: 10 })
              .enabled(this.getChannels(this.selectedGroupIndex).length > 1)
              .onClick(() => {
                this.switchChannel(-1);
              })
            Button('下一台')
              .height(40)
              .margin({ left: 10 })
              .enabled(this.getChannels(this.selectedGroupIndex).length > 1)
              .onClick(() => {
                this.switchChannel(1);
              })
            Button('换源')
              .height(40)
              .margin({ left: 10 })
              .enabled(this.getCurrentSourceUrls().length > 1)
              .onClick(() => {
                this.switchSource(1);
              })
          }
          .margin({ top: 16 })

          if (this.epgUrl.length > 0) {
            Text(`EPG：${this.epgUrl}`)
              .fontSize(12)
              .fontColor('#93a4b8')
              .margin({ top: 10 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .layoutWeight(1)
        .padding({ left: 44, right: 24, top: 28, bottom: 28 })

        Column() {
          Text('分组')
            .fontSize(16)
            .fontColor('#cbd5e1')
            .margin({ bottom: 10 })
          Scroll() {
            Column() {
              ForEach(this.groups, (group: LiveChannelGroup, index: number) => {
                Text(`${group.groupName}${group.groupPassword === undefined || group.groupPassword.length === 0 ? '' : ' *'}`)
                  .width('100%')
                  .fontSize(15)
                  .fontColor(Color.White)
                  .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                  .margin({ bottom: 8 })
                  .borderRadius(8)
                  .backgroundColor(index === this.selectedGroupIndex ? '#2563eb' : '#1f2937')
                  .onClick(() => {
                    this.selectGroup(index);
                  })
              }, (group: LiveChannelGroup) => group.groupName)
            }
          }
          .layoutWeight(1)
        }
        .width(180)
        .padding({ top: 28, bottom: 28 })

        Column() {
          Text('频道')
            .fontSize(16)
            .fontColor('#cbd5e1')
            .margin({ bottom: 10 })
          Scroll() {
            Column() {
              ForEach(this.getChannels(this.selectedGroupIndex), (channel: LiveChannelItem, index: number) => {
                Row() {
                  Text(this.channelNumber(channel, index))
                    .fontSize(13)
                    .fontColor('#93c5fd')
                    .width(42)
                  Text(channel.channelName)
                    .fontSize(15)
                    .fontColor(Color.White)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .layoutWeight(1)
                  Text(`${channel.sourceUrls.length}源`)
                    .fontSize(12)
                    .fontColor('#93a4b8')
                    .margin({ left: 8 })
                }
                .width('100%')
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .margin({ bottom: 8 })
                .borderRadius(8)
                .backgroundColor(index === this.selectedChannelIndex ? '#2563eb' : '#1f2937')
                .onClick(() => {
                  this.selectChannel(index);
                })
              }, (channel: LiveChannelItem) => channel.channelName)
            }
          }
          .layoutWeight(1)

          if (this.getCurrentSourceUrls().length > 1) {
            Scroll() {
              Row() {
                ForEach(this.getCurrentSourceUrls(), (_url: string, index: number) => {
                  Text(this.getCurrentSourceLabel(index))
                    .fontSize(12)
                    .fontColor(Color.White)
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .margin({ right: 8 })
                    .borderRadius(12)
                    .backgroundColor(index === this.selectedSourceIndex ? '#16a34a' : '#334155')
                    .onClick(() => {
                      this.selectSource(index);
                    })
                }, (_url: string, index: number) => `${index}`)
              }
            }
            .scrollable(ScrollDirection.Horizontal)
            .height(42)
            .margin({ top: 10 })
          }
        }
        .width(300)
        .padding({ left: 16, right: 44, top: 28, bottom: 28 })
      }
      .width('100%')
      .height(330)
      .backgroundColor('#99000000')
    }
    .width('100%')
    .height('100%')
  }
}
