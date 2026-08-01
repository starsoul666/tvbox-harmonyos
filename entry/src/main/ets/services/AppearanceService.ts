import { ThemeOptions } from '../constants/AppDefaults';
import { HawkConfig } from '../constants/HawkConfig';
import { settingsStore } from './SettingsStore';

export interface ThemePalette {
  name: string;
  pageBg: string;
  panelBg: string;
  cardBg: string;
  cardActiveBg: string;
  fieldBg: string;
  primary: string;
  primarySoft: string;
  text: string;
  mutedText: string;
  subtleText: string;
  warningText: string;
}

export const ThemePalettes: ThemePalette[] = [
  {
    name: ThemeOptions[0],
    pageBg: '#0b1020',
    panelBg: '#1f2937',
    cardBg: '#151d2b',
    cardActiveBg: '#334155',
    fieldBg: '#111827',
    primary: '#2563eb',
    primarySoft: '#60a5fa',
    text: '#ffffff',
    mutedText: '#93a4b8',
    subtleText: '#64748b',
    warningText: '#fbbf24'
  },
  {
    name: ThemeOptions[1],
    pageBg: '#071827',
    panelBg: '#123047',
    cardBg: '#0d2436',
    cardActiveBg: '#1b4f72',
    fieldBg: '#082033',
    primary: '#0ea5e9',
    primarySoft: '#7dd3fc',
    text: '#f8fbff',
    mutedText: '#a9c7d8',
    subtleText: '#6f99ad',
    warningText: '#fde68a'
  },
  {
    name: ThemeOptions[2],
    pageBg: '#110b16',
    panelBg: '#2b1938',
    cardBg: '#21102d',
    cardActiveBg: '#4c2362',
    fieldBg: '#170b20',
    primary: '#9333ea',
    primarySoft: '#d8b4fe',
    text: '#fff7ff',
    mutedText: '#c9b2d8',
    subtleText: '#9274a5',
    warningText: '#fde68a'
  },
  {
    name: ThemeOptions[3],
    pageBg: '#190d08',
    panelBg: '#3a1d10',
    cardBg: '#2a140b',
    cardActiveBg: '#7c2d12',
    fieldBg: '#1f0e07',
    primary: '#ea580c',
    primarySoft: '#fdba74',
    text: '#fff8f1',
    mutedText: '#d8b5a1',
    subtleText: '#a57a62',
    warningText: '#fde047'
  },
  {
    name: ThemeOptions[4],
    pageBg: '#141204',
    panelBg: '#34300b',
    cardBg: '#252207',
    cardActiveBg: '#665c16',
    fieldBg: '#1b1905',
    primary: '#ca8a04',
    primarySoft: '#fde047',
    text: '#fffbe6',
    mutedText: '#d5cc8f',
    subtleText: '#938a50',
    warningText: '#fb7185'
  },
  {
    name: ThemeOptions[5],
    pageBg: '#07130f',
    panelBg: '#123327',
    cardBg: '#0c241b',
    cardActiveBg: '#166044',
    fieldBg: '#071b14',
    primary: '#059669',
    primarySoft: '#6ee7b7',
    text: '#f4fff9',
    mutedText: '#a9d3c1',
    subtleText: '#6b9a85',
    warningText: '#facc15'
  },
  {
    name: ThemeOptions[6],
    pageBg: '#180911',
    panelBg: '#3a1528',
    cardBg: '#2a0e1c',
    cardActiveBg: '#831843',
    fieldBg: '#200914',
    primary: '#db2777',
    primarySoft: '#f9a8d4',
    text: '#fff5fa',
    mutedText: '#d6a8bf',
    subtleText: '#9f6b83',
    warningText: '#fde68a'
  }
];

export interface HomeLabels {
  loadingConfig: string;
  waitingConfig: string;
  unloadedConfig: string;
  configLoadFailedPrefix: string;
  configReadyPrefix: string;
  configReadySuffix: string;
  configEmpty: string;
  spiderPendingPrefix: string;
  spiderPendingMiddle: string;
  spiderPendingSuffix: string;
  loadingHomePrefix: string;
  homeCategoryPrefix: string;
  homeCategoryMiddleHistory: string;
  homeCategoryMiddleRecommend: string;
  homeCategorySuffix: string;
  homeContentFailedPrefix: string;
  currentSource: string;
  homeContent: string;
  loading: string;
  dataSources: string;
  visibleSourceSuffix: string;
  live: string;
  search: string;
  fastSearch: string;
  history: string;
  favorites: string;
  push: string;
  drive: string;
  apps: string;
  settings: string;
}

export interface SettingsLabels {
  title: string;
  config: string;
  home: string;
  player: string;
  live: string;
  system: string;
  data: string;
  enabled: string;
  disabled: string;
  loadConfig: string;
  clearCache: string;
  history: string;
  homeSource: string;
  configUrl: string;
  configPlaceholder: string;
  livePlaceholder: string;
  epgPlaceholder: string;
  sourceDisplay: string;
  launchLive: string;
  recommendation: string;
  historyCount: string;
  scale: string;
  playerType: string;
  playerCompatNotice: string;
  renderMode: string;
  codec: string;
  backgroundPlay: string;
  seekStep: string;
  preview: string;
  purify: string;
  reverseChannel: string;
  crossGroup: string;
  showTime: string;
  showNetSpeed: string;
  skipPassword: string;
  liveTimeout: string;
  searchView: string;
  fastSearch: string;
  locale: string;
  theme: string;
  dns: string;
  sniffWebView: string;
  debug: string;
  clearWatchHistory: string;
  clearSearchHistory: string;
  pleaseInputConfig: string;
  loadSuccessPrefix: string;
  loadSuccessSuffix: string;
  loadFailedPrefix: string;
  cacheCleared: string;
  watchHistoryCleared: string;
  searchHistoryCleared: string;
  homeSourcePrefix: string;
  unloaded: string;
  proxy: string;
  proxyPlaceholder: string;
  backup: string;
  restore: string;
  resetApp: string;
  backupCreated: string;
  backupRestored: string;
  backupFailed: string;
  resetDone: string;
  noBackup: string;
  searchPosition: string;
  menuPosition: string;
  recStyle: string;
}

export interface FeatureLabels {
  back: string;
  clear: string;
  delete: string;
  done: string;
  remove: string;
  clickRemove: string;
  countSuffix: string;
  failed: string;
  resultSuffix: string;
  noCover: string;
  searchTitle: string;
  searchInitialStatus: string;
  searchNoSource: string;
  searchingPrefix: string;
  searchFailedPrefix: string;
  searchFoundPrefix: string;
  searchFoundMiddle: string;
  searchFoundSuffix: string;
  searchNoResult: string;
  searchInputPlaceholder: string;
  searchButton: string;
  searchingButton: string;
  searchSourcesButtonPrefix: string;
  fastSearchButton: string;
  searchSourceTitle: string;
  selectAll: string;
  selectNone: string;
  close: string;
  searchHistory: string;
  emptySearchHistory: string;
  fastSearchTitle: string;
  fastSearchInitialStatus: string;
  fastSearchingPrefix: string;
  fastSearchHitPrefix: string;
  fastSearchHitMiddle: string;
  fastSearchHitSuffix: string;
  fastSearchNoHit: string;
  fastSearchFailedPrefix: string;
  keywordPlaceholder: string;
  historyTitle: string;
  historyCleared: string;
  historyDeleteHint: string;
  emptyHistory: string;
  watchedPrefix: string;
  favoritesTitle: string;
  favoritesCleared: string;
  favoritesDeleteHint: string;
  emptyFavorites: string;
  pushTitle: string;
  pushInitialStatus: string;
  pushAgentUnloaded: string;
  pushAgentMissing: string;
  pushAgentReady: string;
  pushAgentSpiderPrefix: string;
  pushAgentSpiderSuffix: string;
  pushUrlEmpty: string;
  remoteAddrEmpty: string;
  pushingPrefix: string;
  pushActionSuccess: string;
  pushCompatSuccess: string;
  pushFailedPrefix: string;
  pushPlayName: string;
  pushUrlPlaceholder: string;
  directPlay: string;
  pushAgentDetail: string;
  pushingButton: string;
  pushRemoteButton: string;
  remoteAddrPlaceholder: string;
  remotePortPlaceholder: string;
  pushCompatNotice: string;
  searchFilterPlaceholder: string;
}

export interface DriveLabels {
  back: string;
  title: string;
  initialStatus: string;
  sortPrefix: string;
  sortNameAsc: string;
  sortNameDesc: string;
  sortTimeAsc: string;
  sortTimeDesc: string;
  editPrefix: string;
  addPrefix: string;
  editRecordPrefix: string;
  local: string;
  alist: string;
  webDav: string;
  namePlaceholderLocal: string;
  namePlaceholder: string;
  urlPlaceholderWebDav: string;
  urlPlaceholderAlist: string;
  usernamePlaceholder: string;
  passwordPlaceholderWebDav: string;
  passwordPlaceholderAlist: string;
  initPathPlaceholder: string;
  sandboxNotice: string;
  saveEdit: string;
  saveAndOpen: string;
  clear: string;
  listTitle: string;
  parent: string;
  emptyDrives: string;
  open: string;
  edit: string;
  delete: string;
  searchPlaceholder: string;
  loading: string;
  noMatch: string;
  emptyDir: string;
  folderBadge: string;
  play: string;
  file: string;
  enterFolder: string;
  needLocalPath: string;
  needNameAndUrl: string;
  editUnsupported: string;
  editingPrefix: string;
  editorCleared: string;
  unknownType: string;
  loadingPathPrefix: string;
  loadedCountPrefix: string;
  loadedCountMiddle: string;
  loadFailedPrefix: string;
  searchResultPrefix: string;
  searchResultMiddle: string;
  searchResultSuffix: string;
  nonVideoPrefix: string;
  backToList: string;
  deletedCurrent: string;
  driveTypeLocal: string;
  driveTypeWebDav: string;
  driveTypeAlist: string;
  driveTypeUnknownPrefix: string;
}

export interface AppsLabels {
  back: string;
  title: string;
  initialStatus: string;
  exitDeleteMode: string;
  deleteMode: string;
  editEntry: string;
  addEntry: string;
  namePlaceholder: string;
  bundlePlaceholder: string;
  abilityPlaceholder: string;
  modulePlaceholder: string;
  resolveAndSave: string;
  saveDirect: string;
  clear: string;
  deleteNotice: string;
  savedCountPrefix: string;
  refresh: string;
  empty: string;
  emptyHint: string;
  remove: string;
  edit: string;
  abilityMissing: string;
  systemApp: string;
  editingPrefix: string;
  bundleEmpty: string;
  savedPrefix: string;
  querySavedPrefix: string;
}

export interface CategoryLabels {
  back: string;
  title: string;
  loadingCategory: string;
  configLoadFailedPrefix: string;
  noSource: string;
  noClasses: string;
  loadFailedPrefix: string;
  loadingPrefix: string;
  empty: string;
  pageStatusPrefix: string;
  pageStatusMiddle: string;
  pageStatusCountMiddle: string;
  pageStatusSuffix: string;
  noCover: string;
  loading: string;
  collapseFilters: string;
  filters: string;
}

export interface DetailLabels {
  back: string;
  title: string;
  waitingParams: string;
  missingParams: string;
  configLoadFailedPrefix: string;
  sourceNotFoundPrefix: string;
  loadingDetailPrefix: string;
  detailEmpty: string;
  loadedPrefix: string;
  detailLoadFailedPrefix: string;
  collectRemoved: string;
  collectAdded: string;
  searching: string;
  changeSource: string;
  push: string;
  uncollect: string;
  collect: string;
  candidatesPrefix: string;
  close: string;
  loading: string;
  empty: string;
  noCover: string;
  unknownType: string;
  directorPrefix: string;
  actorPrefix: string;
  noDesc: string;
  playList: string;
  episodeSuffix: string;
  ascending: string;
  descending: string;
  noPlayUrl: string;
  searchingOtherPrefix: string;
  otherFoundPrefix: string;
  otherNoResult: string;
  changeSourceFailedPrefix: string;
  noPushUrl: string;
}

export interface PlayLabels {
  back: string;
  defaultTitle: string;
  preparing: string;
  playing: string;
  paused: string;
  ended: string;
  failed: string;
  failedPrefix: string;
  missingUrl: string;
  cannotPlayEmpty: string;
  externalTitle: string;
  episodeFallbackPrefix: string;
  episodeFallbackSuffix: string;
  resolving: string;
  resolveFailedFallback: string;
  resolveFailed: string;
  resolvingUrl: string;
  noUrl: string;
  pause: string;
  play: string;
  prevEpisode: string;
  nextEpisode: string;
  selectEpisodePrefix: string;
  trackSubtitle: string;
  skipIntroOutro: string;
  parse: string;
  skipStartPrefix: string;
  skipEndPrefix: string;
  minusSeconds: string;
  plusSeconds: string;
  setToCurrent: string;
  setToRemaining: string;
  audioTrack: string;
  noAudioTrack: string;
  subtitle: string;
  noSubtitle: string;
  danmuOn: string;
  danmuOff: string;
  subtitleOn: string;
  subtitleOff: string;
  screenDisplay: string;
}

export interface LiveLabels {
  back: string;
  defaultTitle: string;
  initializing: string;
  epgNotLoaded: string;
  failedPrefix: string;
  playFailed: string;
  configLoadFailedPrefix: string;
  loadingSubscription: string;
  loadedGroupsPrefix: string;
  subscriptionFailedPrefix: string;
  subscriptionLoadFailed: string;
  liveUnavailable: string;
  noChannels: string;
  noPlayableChannel: string;
  epgNoChannel: string;
  epgLoading: string;
  epgLoadedPrefix: string;
  epgLoadedMiddle: string;
  epgEmpty: string;
  epgLoadFailedPrefix: string;
  headerMatchedPrefix: string;
  headerDefaultPrefix: string;
  noTimeShift: string;
  futureProgram: string;
  epgFormatUnsupported: string;
  backToLivePrefix: string;
  timeShiftPrefix: string;
  paused: string;
  sourceFallbackPrefix: string;
  invalidChannelNumber: string;
  channelNotFoundPrefix: string;
  inputChannelNumberPrefix: string;
  badgePlaying: string;
  badgeCurrent: string;
  badgeUpcoming: string;
  badgeTimeShift: string;
  loadingChannels: string;
  noLiveUrl: string;
  liveUrlHint: string;
  pause: string;
  play: string;
  prevChannel: string;
  nextChannel: string;
  switchSource: string;
  reverseTogglePrefix: string;
  toggleOn: string;
  toggleOff: string;
  crossGroupTogglePrefix: string;
  channelNumberPlaceholder: string;
  jumpChannel: string;
  epgUrlPrefix: string;
  timeShiftSupported: string;
  prevDay: string;
  today: string;
  nextDay: string;
  groups: string;
  channels: string;
  sourceCountSuffix: string;
  passwordTitle: string;
  passwordPlaceholder: string;
  cancel: string;
  confirm: string;
  passwordError: string;
}

export class AppearanceService {
  themeIndex: number = 0;
  localeIndex: number = 0;

  async init(): Promise<void> {
    this.themeIndex = await settingsStore.get<number>(HawkConfig.THEME_SELECT, 0);
    this.localeIndex = await settingsStore.get<number>(HawkConfig.HOME_LOCALE, 0);
  }

  setTheme(index: number): void {
    this.themeIndex = this.normalizeIndex(index, ThemePalettes.length);
  }

  setLocale(index: number): void {
    this.localeIndex = this.normalizeIndex(index, 2);
  }

  theme(): ThemePalette {
    return ThemePalettes[this.normalizeIndex(this.themeIndex, ThemePalettes.length)];
  }

  themeByIndex(index: number): ThemePalette {
    return ThemePalettes[this.normalizeIndex(index, ThemePalettes.length)];
  }

  isEnglish(): boolean {
    return this.normalizeIndex(this.localeIndex, 2) === 1;
  }

  homeLabels(): HomeLabels {
    return this.isEnglish() ? EnglishHomeLabels : ChineseHomeLabels;
  }

  settingsLabels(): SettingsLabels {
    return this.isEnglish() ? EnglishSettingsLabels : ChineseSettingsLabels;
  }

  featureLabels(): FeatureLabels {
    return this.isEnglish() ? EnglishFeatureLabels : ChineseFeatureLabels;
  }

  driveLabels(): DriveLabels {
    return this.isEnglish() ? EnglishDriveLabels : ChineseDriveLabels;
  }

  appsLabels(): AppsLabels {
    return this.isEnglish() ? EnglishAppsLabels : ChineseAppsLabels;
  }

  categoryLabels(): CategoryLabels {
    return this.isEnglish() ? EnglishCategoryLabels : ChineseCategoryLabels;
  }

  detailLabels(): DetailLabels {
    return this.isEnglish() ? EnglishDetailLabels : ChineseDetailLabels;
  }

  playLabels(): PlayLabels {
    return this.isEnglish() ? EnglishPlayLabels : ChinesePlayLabels;
  }

  liveLabels(): LiveLabels {
    return this.isEnglish() ? EnglishLiveLabels : ChineseLiveLabels;
  }

  private normalizeIndex(index: number, count: number): number {
    return index >= 0 && index < count ? index : 0;
  }
}

const ChineseHomeLabels: HomeLabels = {
  loadingConfig: '正在加载配置...',
  waitingConfig: '等待配置地址',
  unloadedConfig: '未加载配置',
  configLoadFailedPrefix: '配置加载失败：',
  configReadyPrefix: '已解析 ',
  configReadySuffix: ' 个数据源',
  configEmpty: '进入设置填写配置地址后加载',
  spiderPendingPrefix: '当前源 ',
  spiderPendingMiddle: ' 为 type=',
  spiderPendingSuffix: '，首页内容待 Spider 迁移',
  loadingHomePrefix: '正在加载首页内容：',
  homeCategoryPrefix: '首页分类 ',
  homeCategoryMiddleHistory: ' 个，历史 ',
  homeCategoryMiddleRecommend: ' 个，推荐 ',
  homeCategorySuffix: ' 条',
  homeContentFailedPrefix: '首页内容加载失败：',
  currentSource: '当前源',
  homeContent: '首页内容',
  loading: '加载中',
  dataSources: '数据源',
  visibleSourceSuffix: ' 个可见源',
  live: '直播',
  search: '搜索',
  fastSearch: '快搜',
  history: '历史',
  favorites: '收藏',
  push: '推送',
  drive: '网盘',
  apps: '应用',
  settings: '设置'
};

const EnglishHomeLabels: HomeLabels = {
  loadingConfig: 'Loading config...',
  waitingConfig: 'Waiting for config URL',
  unloadedConfig: 'Config not loaded',
  configLoadFailedPrefix: 'Config load failed: ',
  configReadyPrefix: 'Parsed ',
  configReadySuffix: ' sources',
  configEmpty: 'Open Settings and enter a config URL',
  spiderPendingPrefix: 'Current source ',
  spiderPendingMiddle: ' is type=',
  spiderPendingSuffix: '; Spider migration is pending for home content',
  loadingHomePrefix: 'Loading home content: ',
  homeCategoryPrefix: 'Categories ',
  homeCategoryMiddleHistory: ', history ',
  homeCategoryMiddleRecommend: ', recommendations ',
  homeCategorySuffix: '',
  homeContentFailedPrefix: 'Home content failed: ',
  currentSource: 'Source',
  homeContent: 'Home content',
  loading: 'Loading',
  dataSources: 'Sources',
  visibleSourceSuffix: ' visible sources',
  live: 'Live',
  search: 'Search',
  fastSearch: 'Fast search',
  history: 'History',
  favorites: 'Favorites',
  push: 'Push',
  drive: 'Drive',
  apps: 'Apps',
  settings: 'Settings'
};

const ChineseSettingsLabels: SettingsLabels = {
  title: '设置',
  config: '配置',
  home: '首页',
  player: '播放器',
  live: '直播',
  system: '系统',
  data: '数据',
  enabled: '开启',
  disabled: '关闭',
  loadConfig: '加载配置',
  clearCache: '清除缓存',
  history: '历史',
  homeSource: '首页源',
  configUrl: '配置地址',
  configPlaceholder: '请输入 TVBox JSON 配置地址',
  livePlaceholder: '直播 M3U/TXT 地址',
  epgPlaceholder: 'EPG 地址',
  sourceDisplay: '数据源显示',
  launchLive: '启动进入直播',
  recommendation: '推荐来源',
  historyCount: '历史条数',
  scale: '画面缩放',
  playerType: '播放器类型',
  playerCompatNotice: 'HarmonyOS 使用系统 AVPlayer，其余内核仅保留配置兼容。',
  renderMode: '渲染方式',
  codec: 'IJK 解码',
  backgroundPlay: '后台播放',
  seekStep: '快进步长',
  preview: '窗口预览',
  purify: '广告过滤',
  reverseChannel: '换台反转',
  crossGroup: '跨分组换台',
  showTime: '显示时间',
  showNetSpeed: '显示网速',
  skipPassword: '跳过密码分组',
  liveTimeout: '直播超时',
  searchView: '搜索展示',
  fastSearch: '快速搜索',
  locale: '语言',
  theme: '主题',
  dns: '安全 DNS',
  sniffWebView: '嗅探 WebView',
  debug: '调试模式',
  clearWatchHistory: '清空观看历史',
  clearSearchHistory: '清空搜索历史',
  pleaseInputConfig: '请先填写配置地址',
  loadSuccessPrefix: '加载成功：',
  loadSuccessSuffix: ' 个源',
  loadFailedPrefix: '加载失败：',
  cacheCleared: '已清除配置缓存',
  watchHistoryCleared: '已清空观看历史',
  searchHistoryCleared: '已清空搜索历史',
  homeSourcePrefix: '首页源：',
  unloaded: '未加载',
  proxy: '代理服务器',
  proxyPlaceholder: 'http://IP:端口',
  backup: '数据备份',
  restore: '恢复备份',
  resetApp: '重置应用',
  backupCreated: '已创建备份',
  backupRestored: '已恢复备份',
  backupFailed: '备份失败',
  resetDone: '已重置应用',
  noBackup: '暂无备份',
  searchPosition: '搜索按钮位置',
  menuPosition: '设置按钮位置',
  recStyle: '推荐样式'
};

const EnglishSettingsLabels: SettingsLabels = {
  title: 'Settings',
  config: 'Config',
  home: 'Home',
  player: 'Player',
  live: 'Live',
  system: 'System',
  data: 'Data',
  enabled: 'On',
  disabled: 'Off',
  loadConfig: 'Load config',
  clearCache: 'Clear cache',
  history: 'History',
  homeSource: 'Home source',
  configUrl: 'Config URL',
  configPlaceholder: 'Enter TVBox JSON config URL',
  livePlaceholder: 'Live M3U/TXT URL',
  epgPlaceholder: 'EPG URL',
  sourceDisplay: 'Show sources',
  launchLive: 'Launch to Live',
  recommendation: 'Recommendation',
  historyCount: 'History count',
  scale: 'Scale',
  playerType: 'Player type',
  playerCompatNotice: 'HarmonyOS uses system AVPlayer. Other kernels are kept only for config compatibility.',
  renderMode: 'Render mode',
  codec: 'IJK codec',
  backgroundPlay: 'Background play',
  seekStep: 'Seek step',
  preview: 'Preview window',
  purify: 'Ad filter',
  reverseChannel: 'Reverse channel',
  crossGroup: 'Cross group',
  showTime: 'Show time',
  showNetSpeed: 'Show net speed',
  skipPassword: 'Skip password groups',
  liveTimeout: 'Live timeout',
  searchView: 'Search view',
  fastSearch: 'Fast search',
  locale: 'Language',
  theme: 'Theme',
  dns: 'Secure DNS',
  sniffWebView: 'Sniff WebView',
  debug: 'Debug mode',
  clearWatchHistory: 'Clear watch history',
  clearSearchHistory: 'Clear search history',
  pleaseInputConfig: 'Enter a config URL first',
  loadSuccessPrefix: 'Loaded: ',
  loadSuccessSuffix: ' sources',
  loadFailedPrefix: 'Load failed: ',
  cacheCleared: 'Config cache cleared',
  watchHistoryCleared: 'Watch history cleared',
  searchHistoryCleared: 'Search history cleared',
  homeSourcePrefix: 'Home source: ',
  unloaded: 'Not loaded',
  proxy: 'Proxy server',
  proxyPlaceholder: 'http://IP:port',
  backup: 'Backup',
  restore: 'Restore',
  resetApp: 'Reset app',
  backupCreated: 'Backup created',
  backupRestored: 'Backup restored',
  backupFailed: 'Backup failed',
  resetDone: 'App reset complete',
  noBackup: 'No backups',
  searchPosition: 'Search button position',
  menuPosition: 'Settings button position',
  recStyle: 'Recommendation style'
};

const ChineseFeatureLabels: FeatureLabels = {
  back: '< 返回',
  clear: '清空',
  delete: '删除',
  done: '完成',
  remove: '移除',
  clickRemove: '点击移除',
  countSuffix: ' 条',
  failed: '失败',
  resultSuffix: ' 条',
  noCover: '无封面',
  searchTitle: '搜索',
  searchInitialStatus: '输入关键词后搜索已加载配置中的数据源',
  searchNoSource: '请先勾选参与搜索的数据源',
  searchingPrefix: '正在搜索：',
  searchFailedPrefix: '搜索失败：',
  searchFoundPrefix: '共找到 ',
  searchFoundMiddle: ' 条结果，',
  searchFoundSuffix: ' 个源失败',
  searchNoResult: '未找到结果',
  searchInputPlaceholder: '输入搜索标题',
  searchButton: '搜索',
  searchingButton: '搜索中',
  searchSourcesButtonPrefix: '数据源 ',
  fastSearchButton: '快搜',
  searchSourceTitle: '参与搜索的数据源',
  selectAll: '全选',
  selectNone: '全不选',
  close: '关闭',
  searchHistory: '搜索历史',
  emptySearchHistory: '暂无搜索历史',
  fastSearchTitle: '快搜',
  fastSearchInitialStatus: '快搜会使用 quickSearch=1 的 XML/JSON/type=4 数据源',
  fastSearchingPrefix: '快搜中：',
  fastSearchHitPrefix: '快搜命中 ',
  fastSearchHitMiddle: ' 条，',
  fastSearchHitSuffix: ' 个源失败',
  fastSearchNoHit: '未命中',
  fastSearchFailedPrefix: '快搜失败：',
  keywordPlaceholder: '输入关键词',
  historyTitle: '历史',
  historyCleared: '已清空播放历史',
  historyDeleteHint: '删除模式：点击条目即可移除该条历史',
  emptyHistory: '暂无播放历史',
  watchedPrefix: '已看 ',
  favoritesTitle: '收藏',
  favoritesCleared: '已清空收藏',
  favoritesDeleteHint: '删除模式：点击条目即可移除该收藏',
  emptyFavorites: '暂无收藏',
  pushTitle: '推送',
  pushInitialStatus: '输入 http/https/m3u8/mp4 等播放地址后可直接播放',
  pushAgentUnloaded: 'push_agent 未加载',
  pushAgentMissing: '当前配置没有 push_agent，手工输入地址只能直接播放或推送到远端。',
  pushAgentReady: '当前配置包含 API 型 push_agent，可按 Android 详情入口解析手工输入地址。',
  pushAgentSpiderPrefix: '当前 push_agent 类型为 ',
  pushAgentSpiderSuffix: '，Spider push_agent 详情解析仍待迁移。',
  pushUrlEmpty: '播放地址不能为空',
  remoteAddrEmpty: '远端 TVBox 地址不能为空',
  pushingPrefix: '正在推送到 ',
  pushActionSuccess: '已按 Android /action 协议推送',
  pushCompatSuccess: '已按 /api/updateUrl 兼容接口推送',
  pushFailedPrefix: '远端推送失败：',
  pushPlayName: '推送播放',
  pushUrlPlaceholder: '输入播放地址',
  directPlay: '直接播放',
  pushAgentDetail: 'push_agent 详情',
  pushingButton: '推送中',
  pushRemoteButton: '推送到远端',
  remoteAddrPlaceholder: '远端 TVBox IP 或 http://host:port',
  remotePortPlaceholder: '端口',
  pushCompatNotice: '已迁移 Android 远端推送出口：优先 POST /action do=push，失败后兼容 GET /api/updateUrl；配置存在 push_agent 时可按 Android 详情入口解析手工输入地址。远程 HTTP server 接收推送和二维码入口仍待迁移。',
  searchFilterPlaceholder: '输入过滤词筛选结果'
};

const EnglishFeatureLabels: FeatureLabels = {
  back: '< Back',
  clear: 'Clear',
  delete: 'Delete',
  done: 'Done',
  remove: 'Remove',
  clickRemove: 'Click to remove',
  countSuffix: ' items',
  failed: 'Failed',
  resultSuffix: ' results',
  noCover: 'No cover',
  searchTitle: 'Search',
  searchInitialStatus: 'Enter keywords to search loaded sources',
  searchNoSource: 'Select at least one source to search',
  searchingPrefix: 'Searching: ',
  searchFailedPrefix: 'Search failed: ',
  searchFoundPrefix: 'Found ',
  searchFoundMiddle: ' results, ',
  searchFoundSuffix: ' sources failed',
  searchNoResult: 'No results found',
  searchInputPlaceholder: 'Enter title keyword',
  searchButton: 'Search',
  searchingButton: 'Searching',
  searchSourcesButtonPrefix: 'Sources ',
  fastSearchButton: 'Fast search',
  searchSourceTitle: 'Search sources',
  selectAll: 'All',
  selectNone: 'None',
  close: 'Close',
  searchHistory: 'Search history',
  emptySearchHistory: 'No search history',
  fastSearchTitle: 'Fast search',
  fastSearchInitialStatus: 'Fast search uses quickSearch=1 XML/JSON/type=4 sources',
  fastSearchingPrefix: 'Fast searching: ',
  fastSearchHitPrefix: 'Fast search hit ',
  fastSearchHitMiddle: ' results, ',
  fastSearchHitSuffix: ' sources failed',
  fastSearchNoHit: 'No hits',
  fastSearchFailedPrefix: 'Fast search failed: ',
  keywordPlaceholder: 'Enter keyword',
  historyTitle: 'History',
  historyCleared: 'Watch history cleared',
  historyDeleteHint: 'Delete mode: click an item to remove it from history',
  emptyHistory: 'No watch history',
  watchedPrefix: 'Watched ',
  favoritesTitle: 'Favorites',
  favoritesCleared: 'Favorites cleared',
  favoritesDeleteHint: 'Delete mode: click an item to remove it from favorites',
  emptyFavorites: 'No favorites',
  pushTitle: 'Push',
  pushInitialStatus: 'Enter an http/https/m3u8/mp4 playback URL to play directly',
  pushAgentUnloaded: 'push_agent not loaded',
  pushAgentMissing: 'Current config has no push_agent; manual URLs can only play directly or push to remote.',
  pushAgentReady: 'Current config has API push_agent, so manual URLs can resolve through Android detail flow.',
  pushAgentSpiderPrefix: 'Current push_agent type is ',
  pushAgentSpiderSuffix: '; Spider push_agent detail parsing is still pending.',
  pushUrlEmpty: 'Playback URL cannot be empty',
  remoteAddrEmpty: 'Remote TVBox address cannot be empty',
  pushingPrefix: 'Pushing to ',
  pushActionSuccess: 'Pushed through Android /action protocol',
  pushCompatSuccess: 'Pushed through compatible /api/updateUrl endpoint',
  pushFailedPrefix: 'Remote push failed: ',
  pushPlayName: 'Pushed playback',
  pushUrlPlaceholder: 'Enter playback URL',
  directPlay: 'Play directly',
  pushAgentDetail: 'push_agent detail',
  pushingButton: 'Pushing',
  pushRemoteButton: 'Push remote',
  remoteAddrPlaceholder: 'Remote TVBox IP or http://host:port',
  remotePortPlaceholder: 'Port',
  pushCompatNotice: 'Android remote push has been migrated: prefer POST /action do=push, then fallback to GET /api/updateUrl; when push_agent exists, manual URLs can use the Android detail entry. Remote HTTP server receiving and QR entries are still pending.',
  searchFilterPlaceholder: 'Enter keyword to filter results'
};

const ChineseDriveLabels: DriveLabels = {
  back: '< 返回',
  title: '网盘',
  initialStatus: '支持添加本地目录、Alist、WebDAV 并浏览播放视频文件',
  sortPrefix: '排序：',
  sortNameAsc: '名称升序',
  sortNameDesc: '名称降序',
  sortTimeAsc: '时间升序',
  sortTimeDesc: '时间降序',
  editPrefix: '编辑',
  addPrefix: '添加',
  editRecordPrefix: '编辑记录 #',
  local: '本地',
  alist: 'Alist',
  webDav: 'WebDAV',
  namePlaceholderLocal: '本地目录绝对路径，例如 /data/storage/el2/base/files',
  namePlaceholder: '名称',
  urlPlaceholderWebDav: 'WebDAV 地址，例如 https://example.com/dav',
  urlPlaceholderAlist: 'Alist 地址，例如 https://alist.example.com',
  usernamePlaceholder: 'WebDAV 用户名，可为空',
  passwordPlaceholderWebDav: 'WebDAV 密码，可为空',
  passwordPlaceholderAlist: '访问密码，可为空',
  initPathPlaceholder: '初始路径，默认 /',
  sandboxNotice: 'HarmonyOS Next 受系统沙箱限制，普通应用通常只能读取授权目录或应用可访问目录；这里先提供 Android StorageDrive 兼容的本地路径记录与浏览。',
  saveEdit: '保存修改',
  saveAndOpen: '保存并打开',
  clear: '清空',
  listTitle: '网盘列表',
  parent: '上级',
  emptyDrives: '暂无网盘，先添加一个本地目录、Alist 或 WebDAV。',
  open: '打开',
  edit: '编辑',
  delete: '删除',
  searchPlaceholder: '搜索当前目录文件名',
  loading: '加载中...',
  noMatch: '没有匹配项',
  emptyDir: '当前目录为空',
  folderBadge: '目录',
  play: '播放',
  file: '文件',
  enterFolder: '打开',
  needLocalPath: '请填写本地目录绝对路径',
  needNameAndUrl: '请填写名称和网盘地址',
  editUnsupported: '当前仅支持编辑本地目录、Alist、WebDAV 配置',
  editingPrefix: '正在编辑：',
  editorCleared: '已清空编辑区',
  unknownType: '未知网盘类型',
  loadingPathPrefix: '正在加载：',
  loadedCountPrefix: '已加载 ',
  loadedCountMiddle: ' 项：',
  loadFailedPrefix: '加载失败：',
  searchResultPrefix: '搜索 "',
  searchResultMiddle: '"：',
  searchResultSuffix: ' 项',
  nonVideoPrefix: '非视频文件：',
  backToList: '已回到网盘列表',
  deletedCurrent: '已删除当前网盘',
  driveTypeLocal: '本地目录',
  driveTypeWebDav: 'WebDAV',
  driveTypeAlist: 'Alist网页',
  driveTypeUnknownPrefix: '类型 '
};

const EnglishDriveLabels: DriveLabels = {
  back: '< Back',
  title: 'Drive',
  initialStatus: 'Add local, Alist, or WebDAV drives and browse/play video files',
  sortPrefix: 'Sort: ',
  sortNameAsc: 'Name asc',
  sortNameDesc: 'Name desc',
  sortTimeAsc: 'Time asc',
  sortTimeDesc: 'Time desc',
  editPrefix: 'Edit',
  addPrefix: 'Add',
  editRecordPrefix: 'Editing record #',
  local: 'Local',
  alist: 'Alist',
  webDav: 'WebDAV',
  namePlaceholderLocal: 'Local absolute path, e.g. /data/storage/el2/base/files',
  namePlaceholder: 'Name',
  urlPlaceholderWebDav: 'WebDAV URL, e.g. https://example.com/dav',
  urlPlaceholderAlist: 'Alist URL, e.g. https://alist.example.com',
  usernamePlaceholder: 'WebDAV username, optional',
  passwordPlaceholderWebDav: 'WebDAV password, optional',
  passwordPlaceholderAlist: 'Access token, optional',
  initPathPlaceholder: 'Initial path, default /',
  sandboxNotice: 'HarmonyOS Next sandbox restricts ordinary apps to authorized or app-accessible directories; this provides Android StorageDrive-compatible local path records and browsing.',
  saveEdit: 'Save changes',
  saveAndOpen: 'Save and open',
  clear: 'Clear',
  listTitle: 'Drive list',
  parent: 'Up',
  emptyDrives: 'No drives yet. Add a local, Alist, or WebDAV drive.',
  open: 'Open',
  edit: 'Edit',
  delete: 'Delete',
  searchPlaceholder: 'Search current folder',
  loading: 'Loading...',
  noMatch: 'No matches',
  emptyDir: 'This folder is empty',
  folderBadge: 'Folder',
  play: 'Play',
  file: 'File',
  enterFolder: 'Open',
  needLocalPath: 'Enter the local absolute path',
  needNameAndUrl: 'Enter a name and drive URL',
  editUnsupported: 'Only local, Alist, and WebDAV drives can be edited',
  editingPrefix: 'Editing: ',
  editorCleared: 'Editor cleared',
  unknownType: 'Unknown drive type',
  loadingPathPrefix: 'Loading: ',
  loadedCountPrefix: 'Loaded ',
  loadedCountMiddle: ' items: ',
  loadFailedPrefix: 'Load failed: ',
  searchResultPrefix: 'Search "',
  searchResultMiddle: '": ',
  searchResultSuffix: ' items',
  nonVideoPrefix: 'Not a video file: ',
  backToList: 'Returned to drive list',
  deletedCurrent: 'Current drive deleted',
  driveTypeLocal: 'Local folder',
  driveTypeWebDav: 'WebDAV',
  driveTypeAlist: 'Alist web',
  driveTypeUnknownPrefix: 'Type '
};

const ChineseAppsLabels: AppsLabels = {
  back: '< 返回',
  title: '应用',
  initialStatus: 'HarmonyOS 普通应用无法像 Android 一样直接枚举全部非系统应用，可添加 Bundle/Ability 后启动。',
  exitDeleteMode: '退出删除模式',
  deleteMode: '删除模式',
  editEntry: '编辑启动项',
  addEntry: '添加启动项',
  namePlaceholder: '名称，可留空',
  bundlePlaceholder: 'Bundle Name，例如 com.example.app',
  abilityPlaceholder: 'Ability Name，可先留空再解析',
  modulePlaceholder: 'Module Name，可选',
  resolveAndSave: '解析并保存',
  saveDirect: '直接保存',
  clear: '清空',
  deleteNotice: '删除模式在 HarmonyOS 版本中移除保存的启动项；系统卸载入口受平台权限限制，无法复刻 Android ACTION_DELETE。',
  savedCountPrefix: '已保存应用：',
  refresh: '刷新',
  empty: '暂无应用启动项',
  emptyHint: '先在左侧输入 Bundle Name 和 Ability Name。',
  remove: '移除',
  edit: '编辑',
  abilityMissing: '未指定 Ability，启动时由系统解析',
  systemApp: '系统应用',
  editingPrefix: '正在编辑：',
  bundleEmpty: 'Bundle Name 不能为空',
  savedPrefix: '已保存：',
  querySavedPrefix: '，已保存：'
};

const EnglishAppsLabels: AppsLabels = {
  back: '< Back',
  title: 'Apps',
  initialStatus: 'HarmonyOS ordinary apps cannot enumerate all non-system apps like Android; add a Bundle/Ability to launch.',
  exitDeleteMode: 'Exit delete mode',
  deleteMode: 'Delete mode',
  editEntry: 'Edit launcher item',
  addEntry: 'Add launcher item',
  namePlaceholder: 'Name, optional',
  bundlePlaceholder: 'Bundle Name, e.g. com.example.app',
  abilityPlaceholder: 'Ability Name, can be empty to resolve',
  modulePlaceholder: 'Module Name, optional',
  resolveAndSave: 'Resolve and save',
  saveDirect: 'Save directly',
  clear: 'Clear',
  deleteNotice: 'Delete mode removes saved launcher items on HarmonyOS; system uninstall is restricted by platform permissions and cannot replicate Android ACTION_DELETE.',
  savedCountPrefix: 'Saved apps: ',
  refresh: 'Refresh',
  empty: 'No launcher items',
  emptyHint: 'Enter a Bundle Name and Ability Name on the left.',
  remove: 'Remove',
  edit: 'Edit',
  abilityMissing: 'No Ability specified; resolved by the system at launch',
  systemApp: 'System app',
  editingPrefix: 'Editing: ',
  bundleEmpty: 'Bundle Name cannot be empty',
  savedPrefix: 'Saved: ',
  querySavedPrefix: ', saved: '
};

const ChineseCategoryLabels: CategoryLabels = {
  back: '< 返回',
  title: '分类',
  loadingCategory: '正在加载分类',
  configLoadFailedPrefix: '配置加载失败：',
  noSource: '没有可用数据源',
  noClasses: '该源没有返回分类',
  loadFailedPrefix: '分类加载失败：',
  loadingPrefix: '正在加载：',
  empty: '暂无内容',
  pageStatusPrefix: '',
  pageStatusMiddle: ' 第 ',
  pageStatusCountMiddle: ' 页，共 ',
  pageStatusSuffix: ' 条',
  noCover: '无封面',
  loading: '加载中',
  collapseFilters: '收起筛选',
  filters: '筛选'
};

const EnglishCategoryLabels: CategoryLabels = {
  back: '< Back',
  title: 'Category',
  loadingCategory: 'Loading categories',
  configLoadFailedPrefix: 'Config load failed: ',
  noSource: 'No source available',
  noClasses: 'This source returned no categories',
  loadFailedPrefix: 'Category load failed: ',
  loadingPrefix: 'Loading: ',
  empty: 'No content',
  pageStatusPrefix: '',
  pageStatusMiddle: ' page ',
  pageStatusCountMiddle: ', ',
  pageStatusSuffix: ' items',
  noCover: 'No cover',
  loading: 'Loading',
  collapseFilters: 'Hide filters',
  filters: 'Filters'
};

const ChineseDetailLabels: DetailLabels = {
  back: '< 返回',
  title: '详情',
  waitingParams: '等待详情参数',
  missingParams: '缺少 sourceKey 或 vodId',
  configLoadFailedPrefix: '配置加载失败：',
  sourceNotFoundPrefix: '找不到数据源：',
  loadingDetailPrefix: '正在加载详情：',
  detailEmpty: '详情为空',
  loadedPrefix: '已加载：',
  detailLoadFailedPrefix: '详情加载失败：',
  collectRemoved: '已取消收藏',
  collectAdded: '已收藏',
  searching: '搜索中',
  changeSource: '换源',
  push: '推送',
  uncollect: '取消收藏',
  collect: '收藏',
  candidatesPrefix: '换源结果 ',
  close: '关闭',
  loading: '加载中...',
  empty: '暂无详情数据',
  noCover: '无封面',
  unknownType: '未知类型',
  directorPrefix: '导演：',
  actorPrefix: '主演：',
  noDesc: '暂无简介',
  playList: '播放列表',
  episodeSuffix: ' 集',
  ascending: '正序',
  descending: '倒序',
  noPlayUrl: '暂无播放地址',
  searchingOtherPrefix: '正在其他源搜索：',
  otherFoundPrefix: '其他源找到 ',
  otherNoResult: '其他源没有结果',
  changeSourceFailedPrefix: '换源搜索失败：',
  noPushUrl: '没有可推送的播放地址'
};

const EnglishDetailLabels: DetailLabels = {
  back: '< Back',
  title: 'Detail',
  waitingParams: 'Waiting for detail parameters',
  missingParams: 'Missing sourceKey or vodId',
  configLoadFailedPrefix: 'Config load failed: ',
  sourceNotFoundPrefix: 'Source not found: ',
  loadingDetailPrefix: 'Loading detail: ',
  detailEmpty: 'Detail is empty',
  loadedPrefix: 'Loaded: ',
  detailLoadFailedPrefix: 'Detail load failed: ',
  collectRemoved: 'Removed from favorites',
  collectAdded: 'Added to favorites',
  searching: 'Searching',
  changeSource: 'Change source',
  push: 'Push',
  uncollect: 'Uncollect',
  collect: 'Favorite',
  candidatesPrefix: 'Candidates ',
  close: 'Close',
  loading: 'Loading...',
  empty: 'No detail data',
  noCover: 'No cover',
  unknownType: 'Unknown type',
  directorPrefix: 'Director: ',
  actorPrefix: 'Cast: ',
  noDesc: 'No description',
  playList: 'Play list',
  episodeSuffix: ' eps',
  ascending: 'Asc',
  descending: 'Desc',
  noPlayUrl: 'No playback URL',
  searchingOtherPrefix: 'Searching other sources: ',
  otherFoundPrefix: 'Found ',
  otherNoResult: 'No results from other sources',
  changeSourceFailedPrefix: 'Change-source search failed: ',
  noPushUrl: 'No playback URL to push'
};

const ChinesePlayLabels: PlayLabels = {
  back: '< 返回',
  defaultTitle: '播放',
  preparing: '准备播放',
  playing: '正在播放',
  paused: '已暂停',
  ended: '播放结束',
  failed: '播放失败',
  failedPrefix: '播放失败：',
  missingUrl: '缺少播放地址',
  cannotPlayEmpty: '无法播放：playUrl 为空',
  externalTitle: '外部播放',
  episodeFallbackPrefix: '第',
  episodeFallbackSuffix: '集',
  resolving: '解析中',
  resolveFailedFallback: '解析失败，暂用原始地址',
  resolveFailed: '解析失败',
  resolvingUrl: '正在解析播放地址',
  noUrl: '无播放地址',
  pause: '暂停',
  play: '播放',
  prevEpisode: '上一集',
  nextEpisode: '下一集',
  selectEpisodePrefix: '选集 ',
  trackSubtitle: '音轨字幕',
  skipIntroOutro: '跳过片头尾',
  parse: '解析',
  skipStartPrefix: '跳过片头 ',
  skipEndPrefix: '跳过片尾 ',
  minusSeconds: '-30',
  plusSeconds: '+30',
  setToCurrent: '设为当前',
  setToRemaining: '设为剩余',
  audioTrack: '音轨',
  noAudioTrack: '无可选音轨',
  subtitle: '字幕',
  noSubtitle: '无可选字幕',
  danmuOn: '弹幕ON',
  danmuOff: '弹幕OFF',
  subtitleOn: '字幕ON',
  subtitleOff: '字幕OFF',
  screenDisplay: '屏显'
};

const EnglishPlayLabels: PlayLabels = {
  back: '< Back',
  defaultTitle: 'Play',
  preparing: 'Preparing',
  playing: 'Playing',
  paused: 'Paused',
  ended: 'Playback ended',
  failed: 'Playback failed',
  failedPrefix: 'Playback failed: ',
  missingUrl: 'Missing playback URL',
  cannotPlayEmpty: 'Cannot play: playUrl is empty',
  externalTitle: 'External playback',
  episodeFallbackPrefix: 'Episode ',
  episodeFallbackSuffix: '',
  resolving: 'Resolving',
  resolveFailedFallback: 'Resolve failed; using raw URL',
  resolveFailed: 'Resolve failed',
  resolvingUrl: 'Resolving playback URL',
  noUrl: 'No playback URL',
  pause: 'Pause',
  play: 'Play',
  prevEpisode: 'Previous',
  nextEpisode: 'Next',
  selectEpisodePrefix: 'Episodes ',
  trackSubtitle: 'Audio/Sub',
  skipIntroOutro: 'Skip intro/outro',
  parse: 'Parse',
  skipStartPrefix: 'Skip intro ',
  skipEndPrefix: 'Skip outro ',
  minusSeconds: '-30',
  plusSeconds: '+30',
  setToCurrent: 'Set current',
  setToRemaining: 'Set remaining',
  audioTrack: 'Audio track',
  noAudioTrack: 'No audio track available',
  subtitle: 'Subtitle',
  noSubtitle: 'No subtitle available',
  danmuOn: 'Danmu ON',
  danmuOff: 'Danmu OFF',
  subtitleOn: 'Sub ON',
  subtitleOff: 'Sub OFF',
  screenDisplay: 'Screen display'
};

const ChineseLiveLabels: LiveLabels = {
  back: '< 返回',
  defaultTitle: '直播',
  initializing: '正在初始化直播',
  epgNotLoaded: 'EPG 未加载',
  failedPrefix: '直播播放失败，请切换频道或线路：',
  playFailed: '播放失败',
  configLoadFailedPrefix: '配置加载失败：',
  loadingSubscription: '正在加载直播订阅',
  loadedGroupsPrefix: '已加载 ',
  subscriptionFailedPrefix: '直播订阅加载失败：',
  subscriptionLoadFailed: '直播加载失败',
  liveUnavailable: '直播不可用',
  noChannels: '未找到直播频道',
  noPlayableChannel: '当前分组没有可播放频道',
  epgNoChannel: 'EPG 无可用频道',
  epgLoading: '正在加载 EPG',
  epgLoadedPrefix: 'EPG ',
  epgLoadedMiddle: '，',
  epgEmpty: ' 暂无节目',
  epgLoadFailedPrefix: 'EPG 加载失败：',
  headerMatchedPrefix: '已匹配直播头：',
  headerDefaultPrefix: '默认直播 UA：',
  noTimeShift: '当前频道不支持回看',
  futureProgram: '未来节目不能回看',
  epgFormatUnsupported: 'EPG 时间格式不支持回看',
  backToLivePrefix: '已切回直播：',
  timeShiftPrefix: '回看：',
  paused: '直播已暂停',
  sourceFallbackPrefix: '源',
  invalidChannelNumber: '请输入有效频道号',
  channelNotFoundPrefix: '未找到频道号：',
  inputChannelNumberPrefix: '输入频道号：',
  badgePlaying: '回看中',
  badgeCurrent: '当前',
  badgeUpcoming: '未播',
  badgeTimeShift: '回看',
  loadingChannels: '正在加载直播频道',
  noLiveUrl: '无直播播放地址',
  liveUrlHint: '请确认配置中的 lives 或设置中的 LIVE_URL',
  pause: '暂停',
  play: '播放',
  prevChannel: '上一台',
  nextChannel: '下一台',
  switchSource: '换源',
  reverseTogglePrefix: '反向换台：',
  toggleOn: '开',
  toggleOff: '关',
  crossGroupTogglePrefix: '跨组换台：',
  channelNumberPlaceholder: '频道号',
  jumpChannel: '跳转频道',
  epgUrlPrefix: 'EPG：',
  timeShiftSupported: '当前频道支持 EPG 回看',
  prevDay: '前一天',
  today: '今天',
  nextDay: '后一天',
  groups: '分组',
  channels: '频道',
  sourceCountSuffix: '源',
  passwordTitle: '请输入分组密码',
  passwordPlaceholder: '分组密码',
  cancel: '取消',
  confirm: '确认',
  passwordError: '密码错误'
};

const EnglishLiveLabels: LiveLabels = {
  back: '< Back',
  defaultTitle: 'Live',
  initializing: 'Initializing live',
  epgNotLoaded: 'EPG not loaded',
  failedPrefix: 'Live playback failed; switch channel or source: ',
  playFailed: 'Playback failed',
  configLoadFailedPrefix: 'Config load failed: ',
  loadingSubscription: 'Loading live subscription',
  loadedGroupsPrefix: 'Loaded ',
  subscriptionFailedPrefix: 'Live subscription load failed: ',
  subscriptionLoadFailed: 'Live load failed',
  liveUnavailable: 'Live unavailable',
  noChannels: 'No live channels found',
  noPlayableChannel: 'No playable channel in this group',
  epgNoChannel: 'EPG has no matching channel',
  epgLoading: 'Loading EPG',
  epgLoadedPrefix: 'EPG ',
  epgLoadedMiddle: ', ',
  epgEmpty: ' no programs',
  epgLoadFailedPrefix: 'EPG load failed: ',
  headerMatchedPrefix: 'Matched live headers: ',
  headerDefaultPrefix: 'Default live UA: ',
  noTimeShift: 'This channel does not support time-shift',
  futureProgram: 'Future programs cannot be time-shifted',
  epgFormatUnsupported: 'EPG time format does not support time-shift',
  backToLivePrefix: 'Back to live: ',
  timeShiftPrefix: 'Time-shift: ',
  paused: 'Live paused',
  sourceFallbackPrefix: 'Source',
  invalidChannelNumber: 'Enter a valid channel number',
  channelNotFoundPrefix: 'Channel number not found: ',
  inputChannelNumberPrefix: 'Channel number: ',
  badgePlaying: 'Playing',
  badgeCurrent: 'Now',
  badgeUpcoming: 'Later',
  badgeTimeShift: 'Replay',
  loadingChannels: 'Loading live channels',
  noLiveUrl: 'No live playback URL',
  liveUrlHint: 'Check lives in the config or LIVE_URL in Settings',
  pause: 'Pause',
  play: 'Play',
  prevChannel: 'Prev channel',
  nextChannel: 'Next channel',
  switchSource: 'Switch source',
  reverseTogglePrefix: 'Reverse: ',
  toggleOn: 'On',
  toggleOff: 'Off',
  crossGroupTogglePrefix: 'Cross group: ',
  channelNumberPlaceholder: 'Channel no.',
  jumpChannel: 'Jump',
  epgUrlPrefix: 'EPG: ',
  timeShiftSupported: 'This channel supports EPG time-shift',
  prevDay: 'Prev day',
  today: 'Today',
  nextDay: 'Next day',
  groups: 'Groups',
  channels: 'Channels',
  sourceCountSuffix: 'src',
  passwordTitle: 'Enter group password',
  passwordPlaceholder: 'Group password',
  cancel: 'Cancel',
  confirm: 'OK',
  passwordError: 'Wrong password'
};

export const appearanceService = new AppearanceService();
