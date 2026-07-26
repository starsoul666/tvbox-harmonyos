export interface SourceBean {
  key: string;
  name: string;
  api: string;
  type: number; // Android: 0 xml, 1 json, 3 spider
  searchable: number;
  quickSearch: number;
  filterable: number;
  hide: number;
  playerUrl: string;
  ext: string;
  jar: string;
  categories: string[];
  playerType: number;
  clickSelector: string;
  style: string;
}

export interface ParseBean {
  name: string;
  url: string;
  ext: string;
  type: number; // Android: 0 sniff, 1 json, 2 json ext, 3 aggregate
  isDefault: boolean;
}

export interface IJKOption {
  name: string;
  category: number;
  value: string;
}

export interface IJKCode {
  group: string;
  options: IJKOption[];
}

export interface LiveChannelItem {
  channelName: string;
  channelNum: number;
  sourceNum: number;
  includeBack: boolean;
  sourceNames: string[];
  sourceUrls: string[];
  epgUrls: string[];
  epgNames: string[];
  password?: string;
}

export interface LiveChannelGroup {
  groupName: string;
  groupPassword?: string;
  liveChannels: LiveChannelItem[];
}

export interface VodSeries {
  name: string;
  url: string;
  selected?: boolean;
}

export interface VodSeriesFlag {
  name: string;
  selected?: boolean;
}

export interface VodInfo {
  last?: string;
  id: string;
  tid?: number;
  name: string;
  type?: string;
  dt?: string;
  pic?: string;
  lang?: string;
  area?: string;
  year?: number;
  state?: string;
  note?: string;
  actor?: string;
  director?: string;
  des?: string;
  seriesFlags: VodSeriesFlag[];
  seriesMap: Record<string, VodSeries[]>;
  playFlag?: string;
  playIndex: number;
  playGroup: number;
  playGroupCount: number;
  playNote?: string;
  rawUrl?: string;
  progress?: number;
  duration?: number;
  sourceKey?: string;
  playerCfg?: string;
  reverseSort?: boolean;
}

export interface MovieSort {
  sortId: string;
  sortName: string;
}

export interface SearchResult {
  list: VodInfo[];
  page: number;
  pagecount: number;
  limit: number;
  total: number;
}

export interface SourceHomeContent {
  classes: MovieSort[];
  filters?: Record<string, unknown>;
  list: VodInfo[];
}

export interface SourceSearchResult {
  source: SourceBean;
  result: SearchResult;
  error?: string;
}

export interface VodRecord {
  id: string;
  vodId: string;
  sourceKey: string;
  vodName: string;
  vodPic?: string;
  playFlag?: string;
  episodeName?: string;
  episodeIndex: number;
  progress: number;
  duration: number;
  updateTime: number;
}

export interface VodCollect {
  id: string;
  vodId: string;
  sourceKey: string;
  vodName: string;
  vodPic?: string;
  updateTime: number;
}

export const DriveType = {
  LOCAL: 0,
  WEBDAV: 1,
  ALISTWEB: 2
} as const;

export type DriveTypeValue = typeof DriveType[keyof typeof DriveType];

export interface StorageDrive {
  id: number;
  name: string;
  type: number;
  configJson: string;
}

export interface AlistDriveConfig {
  url: string;
  password: string;
  initPath: string;
}

export interface WebDavDriveConfig {
  url: string;
  username: string;
  password: string;
  initPath: string;
}

export interface LocalDriveConfig {
  rootPath: string;
}

export interface DriveFileItem {
  name: string;
  path: string;
  isFile: boolean;
  fileType: string;
  lastModified: number;
  fileUrl: string;
  version: number;
}

export interface AppLaunchItem {
  id: number;
  name: string;
  bundleName: string;
  abilityName: string;
  moduleName: string;
  iconText: string;
  systemApp: boolean;
  userAdded: boolean;
  updateTime: number;
}

export interface ParseRule {
  host?: string;
  hosts?: string[];
  rule?: string[];
  filter?: string[];
  regex?: string[];
  script?: string[];
}

export interface TvBoxConfigState {
  sourceBeanList: Record<string, SourceBean>;
  homeSource?: SourceBean;
  parseBeanList: ParseBean[];
  defaultParse?: ParseBean;
  liveChannelGroupList: LiveChannelGroup[];
  liveSourceUrl: string;
  liveEpgUrl: string;
  livePlayerType: number;
  vipParseFlags: string[];
  ijkCodes: IJKCode[];
  ads: string[];
  parseRules: ParseRule[];
  spider: string;
  wallpaper: string;
  jarCache: string;
  livePlayHeaders?: unknown[];
}

export class PlayerCfgHeader {
  name: string;
  value: string;

  constructor(name: string, value: string) {
    this.name = name;
    this.value = value;
  }
}

export class PlayerCfg {
  headers: PlayerCfgHeader[];

  constructor(headers: PlayerCfgHeader[]) {
    this.headers = headers;
  }
}
