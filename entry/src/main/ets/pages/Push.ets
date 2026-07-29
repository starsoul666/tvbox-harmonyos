import router from '@ohos.router';
import { HawkConfig } from '../constants/HawkConfig';
import { apiConfigService } from '../services/ApiConfigService';
import { appearanceService, FeatureLabels, ThemePalette } from '../services/AppearanceService';
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
  @State themeSelect: number = 0;
  @State localeSelect: number = 0;

  aboutToAppear(): void {
    this.initPage();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
    await appearanceService.init();
    this.themeSelect = await settingsStore.get<number>(HawkConfig.THEME_SELECT, 0);
    this.localeSelect = await settingsStore.get<number>(HawkConfig.HOME_LOCALE, 0);
    this.statusText = this.labels().pushInitialStatus;
    this.pushAgentText = this.labels().pushAgentUnloaded;
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
      this.pushAgentText = this.labels().pushAgentMissing;
      return;
    }
    this.hasPushAgent = pushAgent.type === 0 || pushAgent.type === 1 || pushAgent.type === 4;
    this.pushAgentText = this.hasPushAgent
      ? this.labels().pushAgentReady
      : `${this.labels().pushAgentSpiderPrefix}${pushAgent.type}${this.labels().pushAgentSpiderSuffix}`;
  }

  openPlay(): void {
    const value = this.url.trim();
    if (value.length === 0) {
      this.statusText = this.labels().pushUrlEmpty;
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
        episodeName: this.labels().pushPlayName
      }
    });
  }

  openPushAgentDetail(): void {
    const value = this.url.trim();
    if (value.length === 0) {
      this.statusText = this.labels().pushUrlEmpty;
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
      this.statusText = this.labels().pushUrlEmpty;
      return;
    }
    if (addr.length === 0) {
      this.statusText = this.labels().remoteAddrEmpty;
      return;
    }
    await settingsStore.put(HawkConfig.PUSH_TO_ADDR, addr);
    await settingsStore.put(HawkConfig.PUSH_TO_PORT, port);
    const baseUrl = this.remoteBaseUrl(addr, port);
    this.sending = true;
    this.statusText = `${this.labels().pushingPrefix}${baseUrl}`;
    try {
      await this.httpClient.postFormText(`${baseUrl}/action`, {
        do: 'push',
        url: value
      });
      this.statusText = this.labels().pushActionSuccess;
    } catch (firstError) {
      try {
        await this.httpClient.getText(`${baseUrl}/api/updateUrl?url=${encodeURIComponent(value)}`);
        this.statusText = this.labels().pushCompatSuccess;
      } catch (_secondError) {
        this.statusText = `${this.labels().pushFailedPrefix}${errorMessage(firstError)}`;
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

  theme(): ThemePalette {
    return appearanceService.themeByIndex(this.themeSelect);
  }

  labels(): FeatureLabels {
    appearanceService.setLocale(this.localeSelect);
    return appearanceService.featureLabels();
  }


  build() {
    Column() {
      Text(this.labels().back).fontSize(18).fontColor(this.theme().text).alignSelf(ItemAlign.Start).onClick(() => router.back())
      Text(this.labels().pushTitle).fontSize(36).fontWeight(FontWeight.Bold).fontColor(this.theme().text).margin({ top: 32 })
      TextInput({ text: this.url, placeholder: this.labels().pushUrlPlaceholder })
        .height(52)
        .fontSize(18)
        .margin({ top: 24 })
        .onChange((value: string) => this.url = value)
      Row() {
        Button(this.labels().directPlay)
          .height(44)
          .onClick(() => this.openPlay())
        Button(this.labels().pushAgentDetail)
          .height(44)
          .margin({ left: 12 })
          .enabled(this.hasPushAgent)
          .onClick(() => this.openPushAgentDetail())
        Button(this.sending ? this.labels().pushingButton : this.labels().pushRemoteButton)
          .height(44)
          .margin({ left: 12 })
          .enabled(!this.sending)
          .onClick(() => this.pushToRemote())
        Text(this.statusText)
          .fontSize(15)
          .fontColor(this.theme().text)
          .margin({ left: 16 })
          .layoutWeight(1)
      }.width('100%').margin({ top: 18 }).alignItems(VerticalAlign.Center)
      Row() {
        TextInput({ text: this.remoteAddr, placeholder: this.labels().remoteAddrPlaceholder })
          .height(48)
          .fontSize(16)
          .layoutWeight(1)
          .onChange((value: string) => this.remoteAddr = value)
        TextInput({ text: this.remotePort, placeholder: this.labels().remotePortPlaceholder })
          .height(48)
          .fontSize(16)
          .width(130)
          .margin({ left: 12 })
          .onChange((value: string) => this.remotePort = value)
      }
      .width('100%')
      .margin({ top: 18 })
      Text(this.labels().pushCompatNotice)
        .fontSize(14)
        .fontColor(this.theme().mutedText)
        .margin({ top: 24 })
      Text(this.pushAgentText)
        .fontSize(13)
        .fontColor(this.hasPushAgent ? '#93c5fd' : '#fbbf24')
        .margin({ top: 8 })
    }.width('100%').height('100%').padding(48).backgroundColor(this.theme().pageBg)
  }
}
