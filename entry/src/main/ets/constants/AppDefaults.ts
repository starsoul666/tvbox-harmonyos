import { HawkConfig } from './HawkConfig';

export interface SettingDefault {
  key: string;
  value: string | number | boolean;
  label: string;
  group: string;
}

export const AndroidCompatibleDefaults: SettingDefault[] = [
  { key: HawkConfig.DEBUG_OPEN, value: false, label: '调试模式', group: '系统' },

  { key: HawkConfig.HOME_SHOW_SOURCE, value: true, label: '数据源显示', group: '首页' },
  { key: HawkConfig.HOME_API, value: '', label: '首页默认源', group: '首页' },
  { key: HawkConfig.HOME_SEARCH_POSITION, value: false, label: '搜索按钮位置', group: '首页' },
  { key: HawkConfig.HOME_MENU_POSITION, value: true, label: '设置按钮位置', group: '首页' },
  { key: HawkConfig.HOME_REC, value: 1, label: '推荐来源', group: '首页' },
  { key: HawkConfig.HOME_NUM, value: 4, label: '历史条数', group: '首页' },

  { key: HawkConfig.SHOW_PREVIEW, value: true, label: '窗口预览', group: '播放器' },
  { key: HawkConfig.PLAY_SCALE, value: 0, label: '画面缩放', group: '播放器' },
  { key: HawkConfig.BACKGROUND_PLAY_TYPE, value: 0, label: '后台播放', group: '播放器' },
  { key: HawkConfig.PLAY_TYPE, value: 1, label: '播放器类型', group: '播放器' },
  { key: HawkConfig.IJK_CODEC, value: '硬解码', label: 'IJK 解码', group: '播放器' },

  { key: HawkConfig.HOME_LOCALE, value: 0, label: '语言', group: '系统' },
  { key: HawkConfig.THEME_SELECT, value: 0, label: '主题', group: '系统' },
  { key: HawkConfig.SEARCH_VIEW, value: 1, label: '搜索展示', group: '系统' },
  { key: HawkConfig.PARSE_WEBVIEW, value: true, label: '嗅探 WebView', group: '系统' },
  { key: HawkConfig.DOH_URL, value: 0, label: '安全 DNS', group: '系统' },

  { key: HawkConfig.API_URL, value: '', label: '配置地址', group: '配置' },
  { key: HawkConfig.LIVE_URL, value: '', label: '直播地址', group: '配置' },
  { key: HawkConfig.EPG_URL, value: '', label: 'EPG 地址', group: '配置' }
];
