import { HawkConfig } from './HawkConfig';

export interface SettingDefault {
  key: string;
  value: string | number | boolean;
  label: string;
  group: string;
}

/** Mirrors Android `App.initParams()`. */
export const AndroidCompatibleDefaults: SettingDefault[] = [
  { key: HawkConfig.DEBUG_OPEN, value: false, label: '调试模式', group: '系统' },

  { key: HawkConfig.HOME_SHOW_SOURCE, value: true, label: '数据源显示', group: '首页' },
  { key: HawkConfig.HOME_API, value: '', label: '首页默认源', group: '首页' },
  { key: HawkConfig.HOME_SEARCH_POSITION, value: false, label: '搜索按钮位置', group: '首页' },
  { key: HawkConfig.HOME_MENU_POSITION, value: true, label: '设置按钮位置', group: '首页' },
  { key: HawkConfig.HOME_REC, value: 1, label: '推荐来源', group: '首页' },
  { key: HawkConfig.HOME_NUM, value: 4, label: '历史条数', group: '首页' },
  { key: HawkConfig.HOME_DEFAULT_SHOW, value: false, label: '启动进入直播', group: '首页' },

  { key: HawkConfig.SHOW_PREVIEW, value: true, label: '窗口预览', group: '播放器' },
  { key: HawkConfig.PLAY_SCALE, value: 0, label: '画面缩放', group: '播放器' },
  { key: HawkConfig.BACKGROUND_PLAY_TYPE, value: 0, label: '后台播放', group: '播放器' },
  { key: HawkConfig.PLAY_TYPE, value: 1, label: '播放器类型', group: '播放器' },
  { key: HawkConfig.PLAY_RENDER, value: 0, label: '渲染方式', group: '播放器' },
  { key: HawkConfig.IJK_CODEC, value: '硬解码', label: 'IJK 解码', group: '播放器' },
  { key: HawkConfig.PLAY_TIME_STEP, value: 5, label: '快进步长', group: '播放器' },
  { key: HawkConfig.VIDEO_PURIFY, value: true, label: '广告过滤', group: '播放器' },
  { key: HawkConfig.DANMU_OPEN, value: true, label: '弹幕开关', group: '播放器' },
  { key: HawkConfig.DANMU_MAXLINE, value: 3, label: '弹幕行数', group: '播放器' },
  { key: HawkConfig.DANMU_SPEED, value: 1.5, label: '弹幕速度', group: '播放器' },
  { key: HawkConfig.DANMU_ALPHA, value: 0.9, label: '弹幕透明度', group: '播放器' },
  { key: HawkConfig.DANMU_SIZESCALE, value: 0.8, label: '弹幕字号', group: '播放器' },
  { key: HawkConfig.DANMU_COLOR, value: false, label: '弹幕彩色', group: '播放器' },

  { key: HawkConfig.HOME_LOCALE, value: 0, label: '语言', group: '系统' },
  { key: HawkConfig.THEME_SELECT, value: 0, label: '主题', group: '系统' },
  { key: HawkConfig.SEARCH_VIEW, value: 1, label: '搜索展示', group: '系统' },
  { key: HawkConfig.FAST_SEARCH_MODE, value: false, label: '快速搜索', group: '系统' },
  { key: HawkConfig.PARSE_WEBVIEW, value: true, label: '嗅探 WebView', group: '系统' },
  { key: HawkConfig.DOH_URL, value: 0, label: '安全 DNS', group: '系统' },

  { key: HawkConfig.LIVE_CHANNEL_REVERSE, value: false, label: '换台反转', group: '直播' },
  { key: HawkConfig.LIVE_CROSS_GROUP, value: false, label: '跨分组换台', group: '直播' },
  { key: HawkConfig.LIVE_SHOW_TIME, value: false, label: '显示时间', group: '直播' },
  { key: HawkConfig.LIVE_SHOW_NET_SPEED, value: false, label: '显示网速', group: '直播' },
  { key: HawkConfig.LIVE_SKIP_PASSWORD, value: false, label: '跳过密码分组', group: '直播' },
  { key: HawkConfig.LIVE_CONNECT_TIMEOUT, value: 1, label: '直播超时', group: '直播' },

  { key: HawkConfig.API_URL, value: '', label: '配置地址', group: '配置' },
  { key: HawkConfig.LIVE_URL, value: '', label: '直播地址', group: '配置' },
  { key: HawkConfig.EPG_URL, value: '', label: 'EPG 地址', group: '配置' }
];

/** Option labels reproduced from Android `ModelSettingFragment` / `PlayerHelper` / `OkGoHelper`. */
export const HomeRecOptions: string[] = ['豆瓣热播', '站点推荐', '观看历史'];
export const HomeNumValues: number[] = [20, 40, 60, 80, 100];
export const ScaleOptions: string[] = ['默认', '16:9', '4:3', '填充', '原始', '裁剪'];
export const BackgroundPlayOptions: string[] = ['关闭', '开启', '画中画'];
export const PlayerOptions: string[] = ['系统', 'IJK', 'Exo', '阿里', 'MX', 'Reex', 'Kodi'];
export const RenderOptions: string[] = ['SurfaceView', 'TextureView'];
export const IjkCodecOptions: string[] = ['软解码', '硬解码'];
export const LocaleOptions: string[] = ['中文', '英文'];
export const ThemeOptions: string[] = ['奈飞', '哆啦', '百事', '鸣人', '小黄', '八神', '樱花'];
export const SearchViewOptions: string[] = ['文字列表', '缩略图'];
export const DnsOptions: string[] = ['关闭', '腾讯', '阿里', '360', 'Google', 'AdGuard', 'Quad9'];
export const LiveTimeoutOptions: string[] = ['5秒', '10秒', '15秒', '20秒'];

/** Android `OkGoHelper.getDohUrl(int)`. */
export const DnsUrls: string[] = [
  '',
  'https://doh.pub/dns-query',
  'https://dns.alidns.com/dns-query',
  'https://doh.360.cn/dns-query',
  'https://dns.google/dns-query',
  'https://dns.adguard.com/dns-query',
  'https://dns.quad9.net/dns-query'
];

/**
 * HarmonyOS cannot ship the Android IJK/Exo/MX/Reex/Kodi kernels, so the
 * player selector maps everything onto AVPlayer. Kept for config compatibility.
 */
export const UnsupportedPlayerIndexes: number[] = [1, 2, 3, 4, 5, 6];
