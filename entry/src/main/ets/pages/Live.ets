import router from '@ohos.router';
import { KeyCode } from '@ohos.multimodalInput.keyCode';
import { HawkConfig } from '../constants/HawkConfig';
import { LiveChannelGroup, LiveChannelItem } from '../models/TvBoxModels';
import { apiConfigService } from '../services/ApiConfigService';
import { epgAliasService } from '../services/EpgAliasService';
import { EpgProgram, epgService } from '../services/EpgService';
import { liveHeaderService, LiveHeaderMatch } from '../services/LiveHeaderService';
import { PlayerSurface } from '../components/player/PlayerSurface';
import { MediaSourceRequest } from '../domain/playback/PlaybackModels';
import { PlaybackSession } from '../domain/playback/PlaybackSession';
import { settingsStore } from '../services/SettingsStore';
import { errorMessage } from '../utils/ErrorUtil';

class ChannelPosition {
  groupIndex: number;
  channelIndex: number;

  constructor(groupIndex: number, channelIndex: number) {
    this.groupIndex = groupIndex;
    this.channelIndex = channelIndex;
  }
}

@Entry
@Component
struct Live {
  private session: PlaybackSession = new PlaybackSession();
  private liveHeaders: Record<string, string> = {};
  private channelNumberJumpTimer: number = -1;
  private clockTimer: number = -1;

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
  @State epgDateOffset: number = 0;
  @State epgDateText: string = '';
  @State epgPrograms: EpgProgram[] = [];
  @State epgStatus: string = 'EPG 未加载';
  @State epgLoading: boolean = false;
  @State unlockedGroupNames: string[] = [];
  @State showPasswordPanel: boolean = false;
  @State pendingGroupIndex: number = -1;
  @State groupPasswordInput: string = '';
  @State groupPasswordError: string = '';
  @State liveChannelReverse: boolean = false;
  @State liveCrossGroup: boolean = false;
  @State channelNumberInput: string = '';
  @State currentLogoUrl: string = '';
  @State timeShiftProgramIndex: number = -1;
  @State timeShiftDateText: string = '';
  @State timeShiftLabel: string = '';
  @State liveHeaderNotice: string = '';
  @State liveSkipPassword: boolean = false;
  @State liveShowTime: boolean = false;
  @State liveShowNetSpeed: boolean = false;
  @State clockText: string = '';

  aboutToAppear(): void {
    this.bindSession();
    this.initPage();
  }

  bindSession(): void {
    this.session.onStateChange = (state: string) => {
      if (state === 'playing') {
        this.isPlaying = true;
        this.errorText = '';
        this.statusText = this.currentPlayStatus();
      } else if (state === 'paused') {
        this.isPlaying = false;
      }
    };
    this.session.onError = (message: string) => {
      this.errorText = `直播播放失败，请切换频道或线路：${message}`;
      this.statusText = '播放失败';
      this.isPlaying = false;
    };
  }

  aboutToDisappear(): void {
    this.session.release();
    this.clearClock();
    this.clearChannelNumberTimer();
  }

  async initPage(): Promise<void> {
    await settingsStore.init(getContext(this));
    await epgAliasService.init(getContext(this).resourceManager);
    this.liveChannelReverse = await settingsStore.get<boolean>(HawkConfig.LIVE_CHANNEL_REVERSE, false);
    this.liveCrossGroup = await settingsStore.get<boolean>(HawkConfig.LIVE_CROSS_GROUP, false);
    this.liveSkipPassword = await settingsStore.get<boolean>(HawkConfig.LIVE_SKIP_PASSWORD, false);
    this.liveShowTime = await settingsStore.get<boolean>(HawkConfig.LIVE_SHOW_TIME, false);
    this.liveShowNetSpeed = await settingsStore.get<boolean>(HawkConfig.LIVE_SHOW_NET_SPEED, false);
    this.startClock();
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
    if (this.epgUrl.length === 0) {
      this.epgUrl = epgService.defaultEpgUrl;
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
        this.errorText = `配置加载失败：${errorMessage(error)}`;
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
      this.errorText = `直播订阅加载失败：${errorMessage(error)}`;
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
    const group = this.groups[index];
    if (!this.isGroupUnlocked(group)) {
      this.pendingGroupIndex = index;
      this.groupPasswordInput = '';
      this.groupPasswordError = '';
      this.showPasswordPanel = true;
      return;
    }
    await this.openGroupIndex(index);
  }

  async openGroupIndex(index: number): Promise<void> {
    this.selectedGroupIndex = index;
    this.selectedChannelIndex = 0;
    this.selectedSourceIndex = 0;
    await this.openSelectedChannel(true);
  }

  /** Android `LIVE_SKIP_PASSWORD` bypasses the prompt for password-protected groups. */
  isGroupUnlocked(group: LiveChannelGroup): boolean {
    if (group.groupPassword === undefined || group.groupPassword.length === 0) {
      return true;
    }
    if (this.liveSkipPassword) {
      return true;
    }
    return this.unlockedGroupNames.includes(group.groupName);
  }

  startClock(): void {
    if (!this.liveShowTime || this.clockTimer !== -1) {
      return;
    }
    this.updateClock();
    this.clockTimer = setInterval(() => this.updateClock(), 1000);
  }

  updateClock(): void {
    const now = new Date();
    const hh = now.getHours() < 10 ? `0${now.getHours()}` : `${now.getHours()}`;
    const mm = now.getMinutes() < 10 ? `0${now.getMinutes()}` : `${now.getMinutes()}`;
    const ss = now.getSeconds() < 10 ? `0${now.getSeconds()}` : `${now.getSeconds()}`;
    this.clockText = `${hh}:${mm}:${ss}`;
  }

  clearClock(): void {
    if (this.clockTimer !== -1) {
      clearInterval(this.clockTimer);
      this.clockTimer = -1;
    }
  }

  async submitGroupPassword(): Promise<void> {
    if (this.pendingGroupIndex < 0 || this.pendingGroupIndex >= this.groups.length) {
      this.showPasswordPanel = false;
      return;
    }
    const group = this.groups[this.pendingGroupIndex];
    if (group.groupPassword === undefined || this.groupPasswordInput === group.groupPassword) {
      this.unlockedGroupNames = this.unlockedGroupNames.concat([group.groupName]);
      this.showPasswordPanel = false;
      await this.openGroupIndex(this.pendingGroupIndex);
      return;
    }
    this.groupPasswordError = '密码错误';
  }

  cancelGroupPassword(): void {
    this.showPasswordPanel = false;
    this.pendingGroupIndex = -1;
    this.groupPasswordInput = '';
    this.groupPasswordError = '';
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
    const epgInfo = epgAliasService.getEpgInfo(channel.channelName);
    this.currentLogoUrl = epgInfo === undefined ? '' : epgInfo.logo;
    const sourceUrl = channel.sourceUrls[this.selectedSourceIndex];
    channel.includeBack = this.isTimeShiftSource(sourceUrl);
    this.updateLiveHeaderNotice(sourceUrl);
    this.timeShiftProgramIndex = -1;
    this.timeShiftDateText = '';
    this.timeShiftLabel = '';
    this.errorText = '';
    this.statusText = this.currentPlayStatus();
    await this.startLivePlayback(sourceUrl);
    if (saveSelection) {
      await settingsStore.put(HawkConfig.LIVE_CHANNEL_GROUP, this.groupName);
      await settingsStore.put(HawkConfig.LIVE_CHANNEL, this.channelName);
    }
    await this.loadCurrentEpg(0);
  }

  async loadCurrentEpg(dateOffset: number = this.epgDateOffset): Promise<void> {
    const channel = this.getCurrentChannel();
    if (channel === undefined) {
      this.epgPrograms = [];
      this.epgStatus = 'EPG 无可用频道';
      return;
    }
    this.epgDateOffset = dateOffset;
    this.epgLoading = true;
    this.epgStatus = '正在加载 EPG';
    try {
      const result = await epgService.loadPrograms(this.epgUrl, this.epgChannelName(channel), dateOffset);
      this.epgDateText = result.dateText;
      this.epgPrograms = result.programs;
      this.epgStatus = result.programs.length > 0 ? `EPG ${result.dateText}，${result.programs.length} 条` : `EPG ${result.dateText} 暂无节目`;
    } catch (error) {
      this.epgPrograms = [];
      this.epgStatus = `EPG 加载失败：${errorMessage(error)}`;
    } finally {
      this.epgLoading = false;
    }
  }

  epgChannelName(channel: LiveChannelItem): string {
    if (channel.epgNames.length > 0 && channel.epgNames[0].length > 0) {
      return channel.epgNames[0];
    }
    const epgInfo = epgAliasService.getEpgInfo(channel.channelName);
    if (epgInfo !== undefined && epgInfo.epgId.length > 0) {
      return epgInfo.epgId;
    }
    return channel.channelName;
  }

  isTimeShiftSource(url: string): boolean {
    return url.includes('PLTV/8888');
  }

  /** Android `livePlayHeaders` rules; headers are now really sent through AVPlayer. */
  updateLiveHeaderNotice(url: string): void {
    const match: LiveHeaderMatch = liveHeaderService.match(apiConfigService.state.livePlayHeaders, url);
    this.liveHeaders = match.headers;
    const keys = Object.keys(match.headers);
    this.liveHeaderNotice = match.matched
      ? `已匹配直播头：${keys.join('、')}`
      : `默认直播 UA：${match.headers['User-Agent']}`;
  }

  async startLivePlayback(url: string): Promise<void> {
    this.playUrl = url;
    if (url.length === 0) {
      return;
    }
    await this.session.setSource(new MediaSourceRequest(url, this.liveHeaders, 0));
    this.isPlaying = true;
  }

  async playEpgProgram(program: EpgProgram): Promise<void> {
    const channel = this.getCurrentChannel();
    if (channel === undefined || channel.sourceUrls.length === 0) {
      return;
    }
    if (!channel.includeBack) {
      this.statusText = '当前频道不支持回看';
      return;
    }
    if (program.isFuture) {
      this.statusText = '未来节目不能回看';
      return;
    }
    if (program.playSeekStart.length === 0 || program.playSeekEnd.length === 0) {
      this.statusText = 'EPG 时间格式不支持回看';
      return;
    }
    const sourceUrl = channel.sourceUrls[this.selectedSourceIndex];
    if (program.isCurrent) {
      this.timeShiftProgramIndex = -1;
      this.timeShiftDateText = '';
      this.timeShiftLabel = '';
      this.statusText = `已切回直播：${program.title}`;
      await this.startLivePlayback(sourceUrl);
    } else {
      this.timeShiftProgramIndex = program.index;
      this.timeShiftDateText = this.epgDateText;
      this.timeShiftLabel = `回看：${program.title}`;
      this.statusText = this.currentPlayStatus();
      await this.startLivePlayback(`${sourceUrl}?playseek=${program.playSeekStart}-${program.playSeekEnd}`);
    }
  }

  async switchChannel(offset: number): Promise<void> {
    const next = this.resolveNextChannel(offset);
    if (next === undefined) {
      return;
    }
    this.selectedGroupIndex = next.groupIndex;
    this.selectedChannelIndex = next.channelIndex;
    this.selectedSourceIndex = 0;
    await this.openSelectedChannel(true);
  }

  resolveNextChannel(offset: number): ChannelPosition | undefined {
    const direction = offset >= 0 ? 1 : -1;
    const channels = this.getChannels(this.selectedGroupIndex);
    if (channels.length === 0) {
      return undefined;
    }
    const channelIndex = this.selectedChannelIndex + direction;
    if (channelIndex >= 0 && channelIndex < channels.length) {
      return new ChannelPosition(this.selectedGroupIndex, channelIndex);
    }
    if (!this.liveCrossGroup) {
      return new ChannelPosition(this.selectedGroupIndex, direction > 0 ? 0 : channels.length - 1);
    }
    const groupIndex = this.findNextOpenGroup(this.selectedGroupIndex, direction);
    const targetChannels = this.getChannels(groupIndex);
    if (targetChannels.length === 0) {
      return new ChannelPosition(this.selectedGroupIndex, direction > 0 ? 0 : channels.length - 1);
    }
    return new ChannelPosition(groupIndex, direction > 0 ? 0 : targetChannels.length - 1);
  }

  findNextOpenGroup(currentIndex: number, direction: number): number {
    if (this.groups.length <= 1) {
      return currentIndex;
    }
    let groupIndex = currentIndex;
    for (let step = 0; step < this.groups.length - 1; step++) {
      groupIndex += direction > 0 ? 1 : -1;
      if (groupIndex >= this.groups.length) {
        groupIndex = 0;
      } else if (groupIndex < 0) {
        groupIndex = this.groups.length - 1;
      }
      const group = this.groups[groupIndex];
      if (this.isGroupUnlocked(group) && group.liveChannels.length > 0) {
        return groupIndex;
      }
    }
    return currentIndex;
  }

  async toggleLiveChannelReverse(): Promise<void> {
    this.liveChannelReverse = !this.liveChannelReverse;
    await settingsStore.put(HawkConfig.LIVE_CHANNEL_REVERSE, this.liveChannelReverse);
  }

  async toggleLiveCrossGroup(): Promise<void> {
    this.liveCrossGroup = !this.liveCrossGroup;
    await settingsStore.put(HawkConfig.LIVE_CROSS_GROUP, this.liveCrossGroup);
  }

  async jumpToChannelNumber(clearWhenMissing: boolean = false): Promise<void> {
    this.clearChannelNumberTimer();
    const num = Number(this.channelNumberInput.trim());
    if (Number.isNaN(num) || num <= 0) {
      this.statusText = '请输入有效频道号';
      if (clearWhenMissing) {
        this.channelNumberInput = '';
      }
      return;
    }
    for (let groupIndex = 0; groupIndex < this.groups.length; groupIndex++) {
      const group = this.groups[groupIndex];
      if (!this.isGroupUnlocked(group)) {
        continue;
      }
      for (let channelIndex = 0; channelIndex < group.liveChannels.length; channelIndex++) {
        if (group.liveChannels[channelIndex].channelNum === num) {
          this.selectedGroupIndex = groupIndex;
          this.selectedChannelIndex = channelIndex;
          this.selectedSourceIndex = 0;
          this.channelNumberInput = '';
          await this.openSelectedChannel(true);
          return;
        }
      }
    }
    this.statusText = `未找到频道号：${this.channelNumberInput.trim()}`;
    if (clearWhenMissing) {
      this.channelNumberInput = '';
    }
  }

  clearChannelNumberTimer(): void {
    if (this.channelNumberJumpTimer >= 0) {
      clearTimeout(this.channelNumberJumpTimer);
      this.channelNumberJumpTimer = -1;
    }
  }

  scheduleChannelNumberJump(): void {
    this.clearChannelNumberTimer();
    this.channelNumberJumpTimer = setTimeout(() => {
      this.jumpToChannelNumber(true);
    }, 2000);
  }

  appendRemoteDigit(digit: number): void {
    this.channelNumberInput = `${this.channelNumberInput}${digit}`;
    this.statusText = `输入频道号：${this.channelNumberInput}`;
    this.scheduleChannelNumberJump();
  }

  remoteDigit(keyCode: number): number {
    if (keyCode >= KeyCode.KEYCODE_0 && keyCode <= KeyCode.KEYCODE_9) {
      return keyCode - KeyCode.KEYCODE_0;
    }
    if (keyCode >= KeyCode.KEYCODE_NUMPAD_0 && keyCode <= KeyCode.KEYCODE_NUMPAD_9) {
      return keyCode - KeyCode.KEYCODE_NUMPAD_0;
    }
    return -1;
  }

  handleRemoteKey(event: KeyEvent): boolean {
    if (event.type !== KeyType.Down) {
      return false;
    }
    const digit = this.remoteDigit(event.keyCode);
    if (digit >= 0) {
      this.appendRemoteDigit(digit);
      return true;
    }
    switch (event.keyCode) {
      case KeyCode.KEYCODE_DPAD_UP:
        this.switchChannel(this.liveChannelReverse ? 1 : -1);
        return true;
      case KeyCode.KEYCODE_DPAD_DOWN:
        this.switchChannel(this.liveChannelReverse ? -1 : 1);
        return true;
      case KeyCode.KEYCODE_DPAD_RIGHT:
        this.switchSource(1);
        return true;
      case KeyCode.KEYCODE_DPAD_LEFT:
        this.switchSource(-1);
        return true;
      case KeyCode.KEYCODE_DPAD_CENTER:
      case KeyCode.KEYCODE_ENTER:
      case KeyCode.KEYCODE_NUMPAD_ENTER:
        if (this.channelNumberInput.trim().length > 0) {
          this.jumpToChannelNumber(true);
          return true;
        }
        return false;
      case KeyCode.KEYCODE_MEDIA_PLAY_PAUSE:
        this.togglePlay();
        return true;
      default:
        return false;
    }
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
      this.session.pause();
      this.isPlaying = false;
      this.statusText = '直播已暂停';
    } else {
      this.session.play();
      this.isPlaying = true;
      this.statusText = this.currentPlayStatus();
    }
  }

  currentPlayStatus(): string {
    const baseText = `${this.groupName} / ${this.channelName} / ${this.sourceName}`;
    return this.timeShiftLabel.length === 0 ? baseText : `${baseText} / ${this.timeShiftLabel}`;
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

  canSwitchChannel(): boolean {
    if (this.getChannels(this.selectedGroupIndex).length > 1) {
      return true;
    }
    if (!this.liveCrossGroup) {
      return false;
    }
    let openGroupCount = 0;
    for (const group of this.groups) {
      if (this.isGroupUnlocked(group) && group.liveChannels.length > 0) {
        openGroupCount++;
      }
    }
    return openGroupCount > 1;
  }

  channelNumber(channel: LiveChannelItem, index: number): string {
    const num = channel.channelNum > 0 ? channel.channelNum : index + 1;
    return num < 10 ? `00${num}` : num < 100 ? `0${num}` : `${num}`;
  }

  currentChannelSupportsBack(): boolean {
    const channel = this.getCurrentChannel();
    return channel !== undefined && channel.includeBack;
  }

  epgProgramBadge(program: EpgProgram): string {
    if (this.timeShiftProgramIndex === program.index && this.timeShiftDateText === this.epgDateText) {
      return '回看中';
    }
    if (program.isCurrent) {
      return '当前';
    }
    if (program.isFuture) {
      return '未播';
    }
    return this.currentChannelSupportsBack() &&
      program.playSeekStart.length > 0 &&
      program.playSeekEnd.length > 0
      ? '回看'
      : '';
  }

  epgProgramBackground(program: EpgProgram): string {
    if (this.timeShiftProgramIndex === program.index && this.timeShiftDateText === this.epgDateText) {
      return '#064e3b';
    }
    return program.isCurrent ? '#3f2e08' : '#1f2937';
  }


  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        PlayerSurface({ session: this.session })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)

      if (this.playUrl.length === 0) {
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

      Row() {
        Column() {
          Row() {
            Text('< 返回')
              .fontSize(18)
              .fontColor(Color.White)
              .onClick(() => router.back())
            if (this.currentLogoUrl.length > 0) {
              Image(this.currentLogoUrl)
                .width(54)
                .height(54)
                .objectFit(ImageFit.Contain)
                .margin({ left: 18 })
            }
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
            if (this.liveShowTime && this.clockText.length > 0) {
              Text(this.clockText)
                .fontSize(20)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.White)
                .margin({ left: 16 })
            }
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
              .enabled(this.canSwitchChannel())
              .onClick(() => {
                this.switchChannel(this.liveChannelReverse ? 1 : -1);
              })
            Button('下一台')
              .height(40)
              .margin({ left: 10 })
              .enabled(this.canSwitchChannel())
              .onClick(() => {
                this.switchChannel(this.liveChannelReverse ? -1 : 1);
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

          Row() {
            Button(`反向换台：${this.liveChannelReverse ? '开' : '关'}`)
              .height(34)
              .backgroundColor(this.liveChannelReverse ? '#2563eb' : '#374151')
              .onClick(() => this.toggleLiveChannelReverse())
            Button(`跨组换台：${this.liveCrossGroup ? '开' : '关'}`)
              .height(34)
              .margin({ left: 10 })
              .backgroundColor(this.liveCrossGroup ? '#2563eb' : '#374151')
              .onClick(() => this.toggleLiveCrossGroup())
          }
          .margin({ top: 10 })

          Row() {
            TextInput({ text: this.channelNumberInput, placeholder: '频道号' })
              .height(34)
              .fontSize(13)
              .width(120)
              .onChange((value: string) => this.channelNumberInput = value)
            Button('跳转频道')
              .height(34)
              .margin({ left: 10 })
              .enabled(this.channelNumberInput.trim().length > 0)
              .onClick(() => this.jumpToChannelNumber())
          }
          .margin({ top: 10 })

          if (this.epgUrl.length > 0) {
            Text(`EPG：${this.epgUrl}`)
              .fontSize(12)
              .fontColor('#93a4b8')
              .margin({ top: 10 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }

          if (this.currentChannelSupportsBack()) {
            Text(this.timeShiftLabel.length > 0 ? this.timeShiftLabel : '当前频道支持 EPG 回看')
              .fontSize(12)
              .fontColor('#86efac')
              .margin({ top: 8 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }

          if (this.liveHeaderNotice.length > 0) {
            Text(this.liveHeaderNotice)
              .fontSize(12)
              .fontColor('#93a4b8')
              .margin({ top: 8 })
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }

          Column() {
            Row() {
              Text(this.epgStatus)
                .fontSize(14)
                .fontColor(this.epgStatus.startsWith('EPG 加载失败') ? '#fca5a5' : '#cbd5e1')
                .layoutWeight(1)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Button('前一天')
                .height(34)
                .enabled(!this.epgLoading)
                .onClick(() => this.loadCurrentEpg(this.epgDateOffset - 1))
              Button('今天')
                .height(34)
                .margin({ left: 8 })
                .enabled(!this.epgLoading)
                .onClick(() => this.loadCurrentEpg(0))
              Button('后一天')
                .height(34)
                .margin({ left: 8 })
                .enabled(!this.epgLoading)
                .onClick(() => this.loadCurrentEpg(this.epgDateOffset + 1))
            }
            .width('100%')

            if (this.epgPrograms.length > 0) {
              Scroll() {
                Column() {
                  ForEach(this.epgPrograms, (program: EpgProgram) => {
                    Row() {
                      Text(`${program.start}-${program.end}`)
                        .fontSize(12)
                        .fontColor(program.isCurrent ? '#fbbf24' : '#93a4b8')
                        .width(92)
                      Text(program.title)
                        .fontSize(13)
                        .fontColor(program.isCurrent ? '#fbbf24' : Color.White)
                        .layoutWeight(1)
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      if (this.epgProgramBadge(program).length > 0) {
                        Text(this.epgProgramBadge(program))
                          .fontSize(12)
                          .fontColor(program.isFuture ? '#94a3b8' : '#fbbf24')
                          .margin({ left: 8 })
                      }
                    }
                    .width('100%')
                    .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                    .margin({ top: 6 })
                    .borderRadius(8)
                    .backgroundColor(this.epgProgramBackground(program))
                    .onClick(() => {
                      this.playEpgProgram(program);
                    })
                  }, (program: EpgProgram) => `${this.epgDateText}-${program.index}`)
                }
              }
              .height(112)
              .margin({ top: 8 })
            }
          }
          .width('100%')
          .margin({ top: 14 })
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
      .height(430)
      .backgroundColor('#99000000')

      if (this.showPasswordPanel) {
        Column() {
          Text('请输入分组密码')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
          Text(this.pendingGroupIndex >= 0 && this.pendingGroupIndex < this.groups.length
            ? this.groups[this.pendingGroupIndex].groupName
            : '')
            .fontSize(14)
            .fontColor('#93a4b8')
            .margin({ top: 8 })
          TextInput({ text: this.groupPasswordInput, placeholder: '分组密码' })
            .height(42)
            .fontSize(15)
            .margin({ top: 16 })
            .onChange((value: string) => {
              this.groupPasswordInput = value;
              this.groupPasswordError = '';
            })
          if (this.groupPasswordError.length > 0) {
            Text(this.groupPasswordError)
              .fontSize(13)
              .fontColor('#fca5a5')
              .margin({ top: 8 })
          }
          Row() {
            Button('取消')
              .height(38)
              .layoutWeight(1)
              .backgroundColor('#374151')
              .onClick(() => this.cancelGroupPassword())
            Button('确认')
              .height(38)
              .layoutWeight(1)
              .margin({ left: 10 })
              .onClick(() => this.submitGroupPassword())
          }
          .width('100%')
          .margin({ top: 16 })
        }
        .width(360)
        .padding(22)
        .backgroundColor('#111827')
        .borderRadius(14)
      }
    }
    .width('100%')
    .height('100%')
    .focusable(true)
    .defaultFocus(true)
    .onKeyEvent((event: KeyEvent) => this.handleRemoteKey(event))
  }
}
