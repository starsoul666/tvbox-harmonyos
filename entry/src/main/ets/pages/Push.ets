import router from '@ohos.router';
import { HawkConfig } from '../constants/HawkConfig';
import { apiConfigService } from '../services/ApiConfigService';
import { HttpClient } from '../services/HttpClient';
import { settingsStore } from '../services/SettingsStore';
import { errorMessage } from '../utils/ErrorUtil';

@Entry
@Component
struct Push {
  private readonly httpClient: HttpClient = new HttpClient();

  @State url: string = '';
  @State remoteAddr: string = '';
  @State remotePort: string = '9978';
  @State statusText: string = '输入 http/https/m3u8/mp4 等播放地址后可直接播放';
  @State sending: boolean = false;
  @State hasPushAgent: boolean = false;
  @State pushAgentText: string = 'push_agent 未加载';

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
    await this.ensureConfigLoaded();
    this.remoteAddr = await settingsStore.get<string>(HawkConfig.PUSH_TO_ADDR, '');
    this.remotePort = await settingsStore.get<string>(HawkConfig.PUSH_TO_PORT, '9978');
    const rawParams = router.getParams();
    if (rawParams !== undefined) {
      const params = rawParams as Record<string, string>;
      if (params['url'] !== undefined) {
        this.url = String(params['url']);
      }
    }
  }

  async ensureConfigLoaded(): Promise<void> {
    if (Object.keys(apiConfigService.state.sourceBeanList).length === 0) {
      try {
        await apiConfigService.loadConfigFromSettings(true);
      } catch (_error) {
      }
    }
    const pushAgent = apiConfigService.state.sourceBeanList['push_agent'];
    if (pushAgent === undefined) {
      this.hasPushAgent = false;
      this.pushAgentText = '当前配置没有 push_agent，手工输入地址只能直接播放或推送到远端。';
      return;
    }
    this.hasPushAgent = pushAgent.type === 0 || pushAgent.type === 1 || pushAgent.type === 4;
    this.pushAgentText = this.hasPushAgent
      ? '当前配置包含 API 型 push_agent，可按 Android 详情入口解析手工输入地址。'
      : `当前 push_agent 类型为 ${pushAgent.type}，Spider push_agent 详情解析仍待迁移。`;
  }

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

  openPushAgentDetail(): void {
    const value = this.url.trim();
    if (value.length === 0) {
      this.statusText = '播放地址不能为空';
      return;
    }
    if (!this.hasPushAgent) {
      this.statusText = this.pushAgentText;
      return;
    }
    router.pushUrl({
      url: 'pages/Detail',
      params: {
        sourceKey: 'push_agent',
        vodId: value
      }
    });
  }

  async pushToRemote(): Promise<void> {
    const value = this.url.trim();
    const addr = this.remoteAddr.trim();
    const port = this.remotePort.trim().length === 0 ? '9978' : this.remotePort.trim();
    if (value.length === 0) {
      this.statusText = '播放地址不能为空';
      return;
    }
    if (addr.length === 0) {
      this.statusText = '远端 TVBox 地址不能为空';
      return;
    }
    await settingsStore.put(HawkConfig.PUSH_TO_ADDR, addr);
    await settingsStore.put(HawkConfig.PUSH_TO_PORT, port);
    const baseUrl = this.remoteBaseUrl(addr, port);
    this.sending = true;
    this.statusText = `正在推送到 ${baseUrl}`;
    try {
      await this.httpClient.postFormText(`${baseUrl}/action`, {
        do: 'push',
        url: value
      });
      this.statusText = '已按 Android /action 协议推送';
    } catch (firstError) {
      try {
        await this.httpClient.getText(`${baseUrl}/api/updateUrl?url=${encodeURIComponent(value)}`);
        this.statusText = '已按 /api/updateUrl 兼容接口推送';
      } catch (_secondError) {
        this.statusText = `远端推送失败：${errorMessage(firstError)}`;
      }
    } finally {
      this.sending = false;
    }
  }

  remoteBaseUrl(addr: string, port: string): string {
    const trimmed = addr.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed.endsWith('/') ? trimmed.substring(0, trimmed.length - 1) : trimmed;
    }
    return `http://${trimmed}:${port}`;
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
        Button('push_agent 详情')
          .height(44)
          .margin({ left: 12 })
          .enabled(this.hasPushAgent)
          .onClick(() => this.openPushAgentDetail())
        Button(this.sending ? '推送中' : '推送到远端')
          .height(44)
          .margin({ left: 12 })
          .enabled(!this.sending)
          .onClick(() => this.pushToRemote())
        Text(this.statusText)
          .fontSize(15)
          .fontColor('#d1d5db')
          .margin({ left: 16 })
          .layoutWeight(1)
      }.width('100%').margin({ top: 18 }).alignItems(VerticalAlign.Center)
      Row() {
        TextInput({ text: this.remoteAddr, placeholder: '远端 TVBox IP 或 http://host:port' })
          .height(48)
          .fontSize(16)
          .layoutWeight(1)
          .onChange((value: string) => this.remoteAddr = value)
        TextInput({ text: this.remotePort, placeholder: '端口' })
          .height(48)
          .fontSize(16)
          .width(130)
          .margin({ left: 12 })
          .onChange((value: string) => this.remotePort = value)
      }
      .width('100%')
      .margin({ top: 18 })
      Text('已迁移 Android 远端推送出口：优先 POST /action do=push，失败后兼容 GET /api/updateUrl；配置存在 push_agent 时可按 Android 详情入口解析手工输入地址。远程 HTTP server 接收推送和二维码入口仍待迁移。')
        .fontSize(14)
        .fontColor('#93a4b8')
        .margin({ top: 24 })
      Text(this.pushAgentText)
        .fontSize(13)
        .fontColor(this.hasPushAgent ? '#93c5fd' : '#fbbf24')
        .margin({ top: 8 })
    }.width('100%').height('100%').padding(48).backgroundColor('#0b1020')
  }
}
