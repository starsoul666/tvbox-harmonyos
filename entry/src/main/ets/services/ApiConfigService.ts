import fs from '@ohos.file.fs';
import util from '@ohos.util';
import { HawkConfig } from '../constants/HawkConfig';
import {
  IJKCode,
  LiveChannelItem,
  LiveChannelGroup,
  ParseBean,
  ParseRule,
  SourceBean,
  TvBoxConfigState
} from '../models/TvBoxModels';
import { asArray, asRecord, safeNumber, safeString, safeStringList } from '../utils/JsonUtil';
import { md5Hex } from '../utils/HashUtil';
import { decryptCbc, decryptEcb, hexToBytes, isJsonText, rightPadding } from '../utils/AesUtil';
import { HttpClient } from './HttpClient';
import { settingsStore } from './SettingsStore';

export class ApiConfigService {
  private readonly httpClient: HttpClient = new HttpClient();

  state: TvBoxConfigState = {
    sourceBeanList: {},
    parseBeanList: [],
    liveChannelGroupList: [],
    liveSourceUrl: '',
    liveEpgUrl: '',
    livePlayerType: -1,
    vipParseFlags: [],
    ijkCodes: [],
    ads: [],
    parseRules: [],
    spider: '',
    wallpaper: '',
    jarCache: 'true'
  };

  async loadConfigFromSettings(useCache: boolean = true): Promise<TvBoxConfigState> {
    const apiUrl = await settingsStore.get<string>(HawkConfig.API_URL, '');
    if (!apiUrl) {
      throw new Error('源地址为空');
    }
    return this.loadConfig(apiUrl, useCache);
  }

  async loadConfig(apiUrl: string, useCache: boolean = true): Promise<TvBoxConfigState> {
    const homeKey = await settingsStore.get<string>(HawkConfig.HOME_API, '');
    if (useCache) {
      const cached = this.readConfigCache(apiUrl);
      if (cached) {
        return this.parseJson(apiUrl, cached, homeKey);
      }
    }

    const configKey = this.extractConfigKey(apiUrl);
    const configUrl = this.normalizeConfigUrl(apiUrl);
    try {
      const body = await this.httpClient.getText(configUrl);
      let json = this.findResult(body, configKey);
      if (apiUrl.startsWith('clan')) {
        json = this.clanContentFix(configUrl, json);
      }
      json = this.fixContentPath(apiUrl, json);
      const parsed = this.parseJson(apiUrl, json, homeKey);
      this.writeConfigCache(apiUrl, json);
      return parsed;
    } catch (error) {
      const cached = this.readConfigCache(apiUrl);
      if (cached) {
        return this.parseJson(apiUrl, cached, homeKey);
      }
      throw error;
    }
  }

  parseJson(_apiUrl: string, jsonStr: string, homeKey: string = ''): TvBoxConfigState {
    const root = asRecord(JSON.parse(jsonStr));
    const sourceBeanList: Record<string, SourceBean> = {};
    let firstVisibleSite: SourceBean | undefined = undefined;

    const sitesRoot = root['video'] ? asRecord(root['video']) : root;
    const sites = asArray(sitesRoot['sites']);
    for (const item of sites) {
      const obj = asRecord(item);
      const key = safeString(obj, 'key').trim();
      if (!key) {
        continue;
      }
      const source: SourceBean = {
        key,
        name: safeString(obj, 'name', key).trim(),
        type: safeNumber(obj, 'type', 0),
        api: safeString(obj, 'api').trim(),
        searchable: safeNumber(obj, 'searchable', 1),
        quickSearch: safeNumber(obj, 'quickSearch', 1),
        filterable: key.startsWith('py_') ? 1 : safeNumber(obj, 'filterable', 1),
        hide: safeNumber(obj, 'hide', 0),
        playerUrl: safeString(obj, 'playUrl'),
        ext: safeString(obj, 'ext'),
        jar: safeString(obj, 'jar'),
        categories: safeStringList(obj, 'categories'),
        playerType: safeNumber(obj, 'playerType', -1),
        clickSelector: safeString(obj, 'click'),
        style: safeString(obj, 'style')
      };
      if (!firstVisibleSite && source.hide === 0) {
        firstVisibleSite = source;
      }
      sourceBeanList[key] = source;
    }

    const configuredHome = homeKey ? sourceBeanList[homeKey] : undefined;
    const homeSource = configuredHome && configuredHome.hide === 0 ? configuredHome : firstVisibleSite;
    const parseBeanList = this.parseParses(root);
    const defaultParseName = settingsStore.isReady() ? settingsStore.getSync<string>(HawkConfig.DEFAULT_PARSE, '') : '';
    const configuredDefaultParse = defaultParseName
      ? parseBeanList.find((item: ParseBean) => item.name === defaultParseName)
      : undefined;
    const defaultParse = configuredDefaultParse === undefined && parseBeanList.length > 0
      ? parseBeanList[0]
      : configuredDefaultParse;
    for (const parse of parseBeanList) {
      parse.isDefault = defaultParse !== undefined && parse.name === defaultParse.name;
    }
    const liveInfo = this.parseLives(root);
    const ijkCodes = this.parseIjk(root);

    this.state = {
      sourceBeanList,
      homeSource,
      parseBeanList,
      defaultParse,
      liveChannelGroupList: liveInfo.groups,
      liveSourceUrl: liveInfo.sourceUrl,
      liveEpgUrl: liveInfo.epgUrl,
      livePlayerType: liveInfo.playerType,
      vipParseFlags: safeStringList(root, 'flags'),
      ijkCodes,
      ads: safeStringList(root, 'ads'),
      parseRules: this.parseRules(root),
      spider: safeString(root, 'spider'),
      wallpaper: safeString(root, 'wallpaper'),
      jarCache: safeString(root, 'jarCache', 'true'),
      livePlayHeaders: asArray(root['livePlayHeaders'])
    };
    return this.state;
  }

  async setHomeSource(source: SourceBean): Promise<void> {
    this.state.homeSource = source;
    await settingsStore.put(HawkConfig.HOME_API, source.key);
  }

  async setDefaultParse(parse: ParseBean): Promise<void> {
    for (const item of this.state.parseBeanList) {
      item.isDefault = item.name === parse.name;
    }
    this.state.defaultParse = parse;
    await settingsStore.put(HawkConfig.DEFAULT_PARSE, parse.name);
  }

  private parseParses(root: Record<string, unknown>): ParseBean[] {
    const result: ParseBean[] = [];
    for (const item of asArray(root['parses'])) {
      const obj = asRecord(item);
      const name = safeString(obj, 'name').trim();
      const url = safeString(obj, 'url').trim();
      if (!name || !url) {
        continue;
      }
      result.push({
        name,
        url,
        ext: obj['ext'] ? JSON.stringify(obj['ext']) : '',
        type: safeNumber(obj, 'type', 0),
        isDefault: result.length === 0
      });
    }
    return result;
  }

  async loadLiveSubscription(url: string): Promise<LiveChannelGroup[]> {
    const liveUrl = url.trim();
    if (liveUrl.length === 0) {
      return [];
    }
    const fixedUrl = liveUrl.startsWith('clan://') ? this.clanToAddress(liveUrl) : liveUrl;
    const content = await this.httpClient.getText(fixedUrl);
    const groups = this.parseLiveText(content);
    return groups;
  }

  private parseLives(root: Record<string, unknown>): {
    groups: LiveChannelGroup[];
    sourceUrl: string;
    epgUrl: string;
    playerType: number;
  } {
    const groups: LiveChannelGroup[] = [];
    const lives = asArray(root['lives']);
    let sourceUrl = '';
    let epgUrl = '';
    let playerType = -1;
    if (lives.length === 0) {
      return { groups, sourceUrl, epgUrl, playerType };
    }

    for (let groupIndex = 0; groupIndex < lives.length; groupIndex++) {
      const item = lives[groupIndex];
      const obj = asRecord(item);
      playerType = playerType === -1 ? safeNumber(obj, 'playerType', -1) : playerType;
      if (epgUrl.length === 0) {
        epgUrl = safeString(obj, 'epg').trim();
      }

      const directGroup = this.parseLiveGroup(obj, groups.length);
      if (directGroup !== undefined) {
        groups.push(directGroup);
        continue;
      }

      const url = safeString(obj, 'url');
      if (sourceUrl.length === 0 && url.length > 0) {
        sourceUrl = this.extractLiveProxyExt(url);
      }
    }
    this.normalizeLiveChannelNumbers(groups);
    return { groups, sourceUrl, epgUrl, playerType };
  }

  private parseLiveGroup(obj: Record<string, unknown>, _groupIndex: number): LiveChannelGroup | undefined {
    const channelItems = asArray(obj['channels']);
    if (channelItems.length === 0) {
      return undefined;
    }
    const rawGroupName = safeString(obj, 'group', safeString(obj, 'name', '未分组')).trim();
    const splitIndex = rawGroupName.indexOf('_');
    const groupName = splitIndex === -1 ? rawGroupName : rawGroupName.substring(0, splitIndex);
    const groupPassword = splitIndex === -1 ? '' : rawGroupName.substring(splitIndex + 1);
    const liveChannels: LiveChannelItem[] = [];
    for (const item of channelItems) {
      const channel = asRecord(item);
      const name = safeString(channel, 'name').trim();
      const urls = safeStringList(channel, 'urls');
      if (name.length === 0 || urls.length === 0) {
        continue;
      }
      const sourceUrls: string[] = [];
      const sourceNames: string[] = [];
      for (const rawUrl of urls) {
        const parsed = this.splitLiveSource(rawUrl, sourceUrls.length + 1);
        if (parsed.url.length > 0 && !sourceUrls.includes(parsed.url)) {
          sourceUrls.push(parsed.url);
          sourceNames.push(parsed.name);
        }
      }
      if (sourceUrls.length === 0) {
        continue;
      }
      liveChannels.push({
        channelName: name,
        channelNum: 0,
        sourceNum: sourceUrls.length,
        includeBack: false,
        sourceNames,
        sourceUrls,
        epgUrls: [],
        epgNames: []
      });
    }
    return liveChannels.length === 0
      ? undefined
      : { groupName, groupPassword, liveChannels };
  }

  private extractLiveProxyExt(url: string): string {
    const trimmed = url.trim();
    if (trimmed.length === 0) {
      return '';
    }
    if (!trimmed.includes('proxy://')) {
      return trimmed;
    }
    const extIndex = trimmed.indexOf('ext=');
    if (extIndex === -1) {
      return trimmed;
    }
    let ext = trimmed.substring(extIndex + 4);
    const andIndex = ext.indexOf('&');
    if (andIndex !== -1) {
      ext = ext.substring(0, andIndex);
    }
    let decodedExt = ext;
    try {
      decodedExt = decodeURIComponent(ext);
    } catch (_error) {
      decodedExt = ext;
    }
    if (decodedExt.startsWith('http') || decodedExt.startsWith('clan://')) {
      return decodedExt;
    }
    try {
      return this.decodeBase64Text(decodedExt);
    } catch (_decodeError) {
      return decodedExt;
    }
  }

  private parseLiveText(content: string): LiveChannelGroup[] {
    const trimmed = content.trim();
    return trimmed.startsWith('#EXTM3U') ? this.parseM3uLive(trimmed) : this.parseTxtLive(trimmed);
  }

  private parseM3uLive(content: string): LiveChannelGroup[] {
    const groupMap: Record<string, Record<string, string[]>> = {};
    const groupOrder: string[] = [];
    const lines = content.split('\n');
    for (let i = 0; i < lines.length; i++) {
      const infoLine = lines[i].trim();
      if (!infoLine.startsWith('#EXTINF')) {
        continue;
      }
      let url = '';
      for (let j = i + 1; j < lines.length; j++) {
        const candidate = lines[j].trim();
        if (candidate.length === 0 || candidate.startsWith('#')) {
          continue;
        }
        url = candidate;
        i = j;
        break;
      }
      if (!this.isLiveUrl(url)) {
        continue;
      }
      const groupName = this.extractM3uGroup(infoLine);
      const channelName = this.extractM3uName(infoLine);
      this.addLiveUrl(groupMap, groupOrder, groupName, channelName, url);
    }
    return this.liveMapToGroups(groupMap, groupOrder);
  }

  private parseTxtLive(content: string): LiveChannelGroup[] {
    const groupMap: Record<string, Record<string, string[]>> = {};
    const groupOrder: string[] = [];
    let groupName = '未分组';
    const lines = content.split('\n');
    for (const line of lines) {
      const trimmed = line.trim();
      if (trimmed.length === 0) {
        continue;
      }
      const commaIndex = trimmed.indexOf(',');
      if (commaIndex === -1) {
        continue;
      }
      const name = trimmed.substring(0, commaIndex).trim();
      const urlText = trimmed.substring(commaIndex + 1).trim();
      if (urlText.includes('#genre#')) {
        groupName = name.length > 0 ? name : '未分组';
        continue;
      }
      for (const part of urlText.split('#')) {
        const url = part.trim();
        if (this.isLiveUrl(url)) {
          this.addLiveUrl(groupMap, groupOrder, groupName, name, url);
        }
      }
    }
    return this.liveMapToGroups(groupMap, groupOrder);
  }

  private addLiveUrl(
    groupMap: Record<string, Record<string, string[]>>,
    groupOrder: string[],
    groupName: string,
    channelName: string,
    url: string
  ): void {
    const safeGroup = groupName.length > 0 ? groupName : '未分组';
    const safeName = channelName.length > 0 ? channelName : '未命名';
    if (groupMap[safeGroup] === undefined) {
      groupMap[safeGroup] = {};
      groupOrder.push(safeGroup);
    }
    if (groupMap[safeGroup][safeName] === undefined) {
      groupMap[safeGroup][safeName] = [];
    }
    if (!groupMap[safeGroup][safeName].includes(url)) {
      groupMap[safeGroup][safeName].push(url);
    }
  }

  private liveMapToGroups(groupMap: Record<string, Record<string, string[]>>, groupOrder: string[]): LiveChannelGroup[] {
    const groups: LiveChannelGroup[] = [];
    let channelNum = 0;
    for (const groupName of groupOrder) {
      const channels = groupMap[groupName];
      const liveChannels: LiveChannelItem[] = [];
      for (const channelName of Object.keys(channels)) {
        const urls = channels[channelName];
        const sourceNames: string[] = [];
        for (let i = 0; i < urls.length; i++) {
          sourceNames.push(`源${i + 1}`);
        }
        liveChannels.push({
          channelName,
          channelNum: ++channelNum,
          sourceNum: urls.length,
          includeBack: false,
          sourceNames,
          sourceUrls: urls,
          epgUrls: [],
          epgNames: []
        });
      }
      if (liveChannels.length > 0) {
        groups.push({ groupName, liveChannels });
      }
    }
    return groups;
  }

  private normalizeLiveChannelNumbers(groups: LiveChannelGroup[]): void {
    let channelNum = 0;
    for (const group of groups) {
      for (const channel of group.liveChannels) {
        channel.channelNum = ++channelNum;
        channel.sourceNum = channel.sourceUrls.length;
      }
    }
  }

  private splitLiveSource(rawUrl: string, fallbackIndex: number): { url: string; name: string } {
    const dollarIndex = rawUrl.indexOf('$');
    if (dollarIndex === -1) {
      return { url: rawUrl.trim(), name: `源${fallbackIndex}` };
    }
    const url = rawUrl.substring(0, dollarIndex).trim();
    const name = rawUrl.substring(dollarIndex + 1).trim();
    return { url, name: name.length > 0 ? name : `源${fallbackIndex}` };
  }

  private extractM3uGroup(line: string): string {
    const marker = 'group-title="';
    const start = line.indexOf(marker);
    if (start === -1) {
      return '未分组';
    }
    const valueStart = start + marker.length;
    const end = line.indexOf('"', valueStart);
    return end === -1 ? '未分组' : line.substring(valueStart, end).trim();
  }

  private extractM3uName(line: string): string {
    const commaIndex = line.lastIndexOf(',');
    if (commaIndex === -1 || commaIndex + 1 >= line.length) {
      return '未命名';
    }
    return line.substring(commaIndex + 1).trim();
  }

  private isLiveUrl(url: string): boolean {
    return url.startsWith('http') || url.startsWith('rtsp') || url.startsWith('rtmp');
  }

  private parseRules(root: Record<string, unknown>): ParseRule[] {
    return asArray(root['rules']).map((item: unknown): ParseRule => {
      const obj = asRecord(item);
      return {
        host: safeString(obj, 'host') || undefined,
        hosts: safeStringList(obj, 'hosts'),
        rule: safeStringList(obj, 'rule'),
        filter: safeStringList(obj, 'filter'),
        regex: safeStringList(obj, 'regex'),
        script: safeStringList(obj, 'script')
      };
    });
  }

  private parseIjk(root: Record<string, unknown>): IJKCode[] {
    return asArray(root['ijk']).map((item: unknown): IJKCode => {
      const obj = asRecord(item);
      return {
        group: safeString(obj, 'group'),
        options: asArray(obj['options']).map((option: unknown) => {
          const opt = asRecord(option);
          return {
            name: safeString(opt, 'name'),
            category: safeNumber(opt, 'category', 0),
            value: safeString(opt, 'value')
          };
        })
      };
    });
  }

  private normalizeConfigUrl(apiUrl: string): string {
    const pk = ';pk;';
    const base = apiUrl.includes(pk) ? apiUrl.split(pk)[0] : apiUrl;
    if (base.startsWith('http')) {
      return base;
    }
    if (base.startsWith('clan')) {
      return this.clanToAddress(base);
    }
    return `http://${base}`;
  }

  private extractConfigKey(apiUrl: string): string {
    const pk = ';pk;';
    if (!apiUrl.includes(pk)) {
      return '';
    }
    const parts = apiUrl.split(pk);
    return parts.length > 1 ? parts[1] : '';
  }

  private readConfigCache(apiUrl: string): string {
    const path = this.configCachePath(apiUrl);
    if (!path) {
      return '';
    }
    try {
      return fs.readTextSync(path);
    } catch (_error) {
      return '';
    }
  }

  private writeConfigCache(apiUrl: string, json: string): void {
    const path = this.configCachePath(apiUrl);
    if (!path) {
      return;
    }
    try {
      const file = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      try {
        fs.writeSync(file.fd, json);
      } finally {
        fs.closeSync(file);
      }
    } catch (_error) {
      // Cache is an optimization. Ignore write failures and keep runtime behavior.
    }
  }

  private configCachePath(apiUrl: string): string {
    const filesDir = settingsStore.getFilesDir();
    return filesDir ? `${filesDir}/${md5Hex(apiUrl)}` : '';
  }

  private clanToAddress(lanLink: string): string {
    if (lanLink.startsWith('clan://localhost/')) {
      throw new Error('暂不支持 clan://localhost，本地代理能力尚未迁移');
    }
    const link = lanLink.substring(7);
    const end = link.indexOf('/');
    if (end === -1) {
      throw new Error(`clan 地址格式错误：${lanLink}`);
    }
    return `http://${link.substring(0, end)}/file/${link.substring(end + 1)}`;
  }

  private fixContentPath(apiUrl: string, content: string): string {
    if (!content.includes('"./')) {
      return content;
    }
    let url = apiUrl.split(';pk;')[0].replace('file://', 'clan://localhost/');
    if (!url.startsWith('http') && !url.startsWith('clan://')) {
      url = `http://${url}`;
    }
    if (url.startsWith('clan://')) {
      url = this.clanToAddress(url);
    }
    const base = url.substring(0, url.lastIndexOf('/') + 1);
    return content.split('./').join(base);
  }

  private clanContentFix(lanAddress: string, content: string): string {
    const marker = '/file/';
    const markerIndex = lanAddress.indexOf(marker);
    if (markerIndex === -1) {
      return content;
    }
    const base = lanAddress.substring(0, markerIndex + marker.length);
    return content.split('clan://').join(base);
  }

  private findResult(content: string, configKey: string): string {
    const trimmed = content.trim();
    if (isJsonText(trimmed)) {
      return trimmed;
    }
    const embeddedBase64 = this.extractAndroidEmbeddedBase64(trimmed);
    if (embeddedBase64) {
      return this.findResult(this.decodeBase64Text(embeddedBase64).trim(), configKey);
    }
    if (trimmed.startsWith('2423')) {
      return this.decryptAndroidCbcConfig(trimmed);
    }
    if (configKey && !isJsonText(trimmed)) {
      return decryptEcb(trimmed, configKey);
    }
    return trimmed;
  }

  private decryptAndroidCbcConfig(content: string): string {
    const dataStart = content.indexOf('2324') + 4;
    const data = content.substring(dataStart, content.length - 26);
    const meta = util.TextDecoder.create('utf-8').decode(hexToBytes(content)).toLowerCase();
    const keyStart = meta.indexOf('$#') + 2;
    const keyEnd = meta.indexOf('#$');
    const key = rightPadding(meta.substring(keyStart, keyEnd), '0', 16);
    const iv = rightPadding(meta.substring(meta.length - 13), '0', 16);
    return decryptCbc(data, key, iv);
  }

  private extractAndroidEmbeddedBase64(content: string): string {
    const match = /[A-Za-z0]{8}\*\*/.exec(content);
    if (!match || match.index === undefined) {
      return '';
    }
    return content.substring(match.index + match[0].length);
  }

  private decodeBase64Text(content: string): string {
    const helper = new util.Base64Helper();
    let normalized = content.trim().split('-').join('+').split('_').join('/');
    while (normalized.length % 4 !== 0) {
      normalized = `${normalized}=`;
    }
    const decodedBytes = helper.decodeSync(normalized);
    const decoder = util.TextDecoder.create('utf-8');
    return decoder.decode(decodedBytes);
  }
}

export const apiConfigService = new ApiConfigService();
