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

  homeLabels(): HomeLabels {
    return this.normalizeIndex(this.localeIndex, 2) === 1 ? EnglishHomeLabels : ChineseHomeLabels;
  }

  settingsLabels(): SettingsLabels {
    return this.normalizeIndex(this.localeIndex, 2) === 1 ? EnglishSettingsLabels : ChineseSettingsLabels;
  }

  featureLabels(): FeatureLabels {
    return this.normalizeIndex(this.localeIndex, 2) === 1 ? EnglishFeatureLabels : ChineseFeatureLabels;
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
  unloaded: '未加载'
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
  unloaded: 'Not loaded'
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
  pushCompatNotice: '已迁移 Android 远端推送出口：优先 POST /action do=push，失败后兼容 GET /api/updateUrl；配置存在 push_agent 时可按 Android 详情入口解析手工输入地址。远程 HTTP server 接收推送和二维码入口仍待迁移。'
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
  pushCompatNotice: 'Android remote push has been migrated: prefer POST /action do=push, then fallback to GET /api/updateUrl; when push_agent exists, manual URLs can use the Android detail entry. Remote HTTP server receiving and QR entries are still pending.'
};

export const appearanceService = new AppearanceService();
