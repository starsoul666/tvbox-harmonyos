import { MovieSort, SearchResult, SortFilter, SortFilterValue, SourceBean, SourceHomeContent, SourceSearchResult, VodInfo, VodSeries, VodSeriesFlag } from '../models/TvBoxModels';
import { asArray, asRecord, JsonNode, parseJson, safeNumber, safeString } from '../utils/JsonUtil';
import { base64Encode } from '../utils/Base64Util';
import { apiConfigService } from './ApiConfigService';
import { HttpClient } from './HttpClient';
import { errorMessage } from '../utils/ErrorUtil';

class SeriesData {
  flags: VodSeriesFlag[];
  map: Record<string, VodSeries[]>;

  constructor(flags: VodSeriesFlag[], map: Record<string, VodSeries[]>) {
    this.flags = flags;
    this.map = map;
  }
}

export class SourceService {
  private readonly httpClient: HttpClient = new HttpClient();
  private readonly fixedExtCache: Record<string, string> = {};

  async getHomeContent(source: SourceBean): Promise<SourceHomeContent> {
    if (source.type === 0) {
      const xml = await this.httpClient.getText(source.api);
      return this.parseXmlHomeContent(xml, source.key);
    }
    if (source.type === 4) {
      const root = await this.requestJsonRoot(this.appendQuery(source.api, {
        filter: 'true',
        extend: await this.fixExtend(source.ext)
      }));
      return this.parseJsonHomeContent(root, source.key);
    }
    this.assertSupportedApiSource(source);
    const root = await this.requestJsonRoot(source.api);
    return this.parseJsonHomeContent(root, source.key);
  }

  private parseJsonHomeContent(root: Record<string, JsonNode>, sourceKey: string): SourceHomeContent {
    const filterMap: Record<string, SortFilter[]> = this.parseFilters(root['filters']);
    const classes: MovieSort[] = [];
    for (const item of asArray(root['class'])) {
      const obj: Record<string, JsonNode> = asRecord(item);
      const sortId = safeString(obj, 'type_id', safeString(obj, 'id')).trim();
      const sortName = safeString(obj, 'type_name', safeString(obj, 'name')).trim();
      if (sortId.length === 0 || sortName.length === 0) {
        continue;
      }
      const filters: SortFilter[] = filterMap[sortId] === undefined ? [] : filterMap[sortId];
      classes.push({ sortId, sortName, filters });
    }
    return {
      classes,
      list: this.parseVodList(root, sourceKey)
    };
  }

  /** Android `SourceViewModel.sortJson()` filters block: `{typeId: [{key,name,value:[{n,v}]}]}`. */
  private parseFilters(node: JsonNode): Record<string, SortFilter[]> {
    const result: Record<string, SortFilter[]> = {};
    const root: Record<string, JsonNode> = asRecord(node);
    for (const typeId of Object.keys(root)) {
      const raw: JsonNode = root[typeId];
      const rows: JsonNode[] = Array.isArray(raw) ? asArray(raw) : [raw];
      const filters: SortFilter[] = [];
      for (const row of rows) {
        const filter = this.parseFilter(asRecord(row));
        if (filter !== undefined) {
          filters.push(filter);
        }
      }
      if (filters.length > 0) {
        result[typeId] = filters;
      }
    }
    return result;
  }

  private parseFilter(obj: Record<string, JsonNode>): SortFilter | undefined {
    const key = safeString(obj, 'key').trim();
    const name = safeString(obj, 'name').trim();
    if (key.length === 0) {
      return undefined;
    }
    const values: SortFilterValue[] = [];
    for (const item of asArray(obj['value'])) {
      const row: Record<string, JsonNode> = asRecord(item);
      values.push({ name: safeString(row, 'n'), value: safeString(row, 'v') });
    }
    return { key, name: name.length > 0 ? name : key, values };
  }

  /** Android `SourceViewModel.getList()`, including per-type filter encoding. */
  async getCategoryList(source: SourceBean, typeId: string, page: number,
    filterSelect: Record<string, string> = {}): Promise<SearchResult> {
    this.assertSupportedApiSource(source);
    const hasFilters = Object.keys(filterSelect).length > 0;
    if (source.type === 4) {
      // type=4 sends the selected filters as a base64 `ext` payload.
      const url = this.appendQuery(source.api, {
        ac: 'detail',
        filter: 'true',
        t: typeId,
        pg: `${page}`,
        ext: hasFilters ? base64Encode(JSON.stringify(filterSelect)) : ''
      });
      const root = await this.requestJsonRoot(url);
      return this.parseSearchResult(root, source.key);
    }
    // type=0/1 send each filter as its own query param plus a combined `f` payload.
    const params: Record<string, string> = {
      ac: source.type === 0 ? 'videolist' : 'detail',
      t: typeId,
      pg: `${page}`
    };
    for (const key of Object.keys(filterSelect)) {
      params[key] = filterSelect[key];
    }
    if (hasFilters) {
      params['f'] = JSON.stringify(filterSelect);
    }
    const url = this.appendQuery(source.api, params);
    if (source.type === 0) {
      return this.parseXmlSearchResult(await this.httpClient.getText(url), source.key);
    }
    const root = await this.requestJsonRoot(url);
    return this.parseSearchResult(root, source.key);
  }

  async getDetail(source: SourceBean, vodId: string): Promise<VodInfo | undefined> {
    let detailSource = source;
    let detailVodId = vodId;
    const pushTarget = this.resolvePushTarget(vodId);
    if (pushTarget.length > 0) {
      const pushAgent = apiConfigService.state.sourceBeanList['push_agent'];
      if (pushAgent !== undefined) {
        detailSource = pushAgent;
        detailVodId = pushTarget;
      }
    }
    this.assertSupportedApiSource(detailSource);
    const params: Record<string, string> = {
      ac: detailSource.type === 0 ? 'videolist' : 'detail',
      ids: detailVodId
    };
    if (detailSource.ext.length > 0) {
      params['extend'] = await this.fixExtend(detailSource.ext);
    }
    const url = this.appendQuery(detailSource.api, params);
    if (detailSource.type === 0) {
      const result = this.parseXmlSearchResult(await this.httpClient.getText(url), detailSource.key);
      return result.list.length > 0 ? result.list[0] : undefined;
    }
    const root = await this.requestJsonRoot(url);
    const list = this.parseVodList(root, detailSource.key);
    return list.length > 0 ? list[0] : undefined;
  }

  async search(source: SourceBean, keyword: string): Promise<SearchResult> {
    return this.searchInternal(source, keyword, false);
  }

  async quickSearch(source: SourceBean, keyword: string): Promise<SearchResult> {
    return this.searchInternal(source, keyword, true);
  }

  private async searchInternal(source: SourceBean, keyword: string, quick: boolean): Promise<SearchResult> {
    this.assertSupportedApiSource(source);
    const params: Record<string, string> = { wd: keyword };
    if (source.type === 1) {
      params['ac'] = 'detail';
    }
    if (source.type === 4) {
      params['ac'] = 'detail';
      params['quick'] = quick ? 'true' : 'false';
    }
    const url = this.appendQuery(source.api, params);
    if (source.type === 0) {
      return this.parseXmlSearchResult(await this.httpClient.getText(url), source.key);
    }
    const root = await this.requestJsonRoot(url);
    return this.parseSearchResult(root, source.key);
  }

  async searchAll(keyword: string, quick: boolean = false): Promise<SourceSearchResult[]> {
    let sources = this.visibleSearchableSources(quick);
    if (sources.length === 0) {
      await apiConfigService.loadConfigFromSettings(true);
      sources = this.visibleSearchableSources(quick);
    }

    const tasks = sources.map(async (source: SourceBean): Promise<SourceSearchResult> => {
      try {
        return {
          source,
          result: quick ? await this.quickSearch(source, keyword) : await this.search(source, keyword)
        };
      } catch (error) {
        return {
          source,
          result: this.emptyResult(),
          error: errorMessage(error)
        };
      }
    });
    return Promise.all(tasks);
  }

  parseSearchResult(root: Record<string, JsonNode>, sourceKey: string): SearchResult {
    return {
      list: this.parseVodList(root, sourceKey),
      page: safeNumber(root, 'page', 1),
      pagecount: safeNumber(root, 'pagecount', 1),
      limit: safeNumber(root, 'limit', 0),
      total: safeNumber(root, 'total', 0)
    };
  }

  parseVodList(root: Record<string, JsonNode>, sourceKey: string): VodInfo[] {
    return asArray(root['list']).map((item: JsonNode): VodInfo => this.parseVodInfo(asRecord(item), sourceKey))
      .filter((item: VodInfo) => item.id.length > 0 && item.name.length > 0);
  }

  parseVodInfo(obj: Record<string, JsonNode>, sourceKey: string): VodInfo {
    const id = safeString(obj, 'vod_id', safeString(obj, 'id')).trim();
    const name = safeString(obj, 'vod_name', safeString(obj, 'name')).trim();
    const playFrom = safeString(obj, 'vod_play_from');
    const playUrl = safeString(obj, 'vod_play_url');
    const seriesData = this.parseSeries(playFrom, playUrl);
    const year = safeNumber(obj, 'vod_year', 0);
    return {
      id,
      tid: safeNumber(obj, 'type_id', 0),
      name,
      type: safeString(obj, 'type_name'),
      pic: safeString(obj, 'vod_pic'),
      lang: safeString(obj, 'vod_lang'),
      area: safeString(obj, 'vod_area'),
      year: year > 0 ? year : undefined,
      state: safeString(obj, 'vod_state'),
      note: safeString(obj, 'vod_remarks'),
      actor: safeString(obj, 'vod_actor'),
      director: safeString(obj, 'vod_director'),
      des: safeString(obj, 'vod_content'),
      seriesFlags: seriesData.flags,
      seriesMap: seriesData.map,
      playIndex: 0,
      playGroup: 0,
      playGroupCount: seriesData.flags.length,
      sourceKey
    };
  }

  private async requestJsonRoot(url: string): Promise<Record<string, JsonNode>> {
    const text = await this.httpClient.getText(url);
    return asRecord(parseJson(text));
  }

  private visibleSearchableSources(quick: boolean): SourceBean[] {
    const state = apiConfigService.state;
    return Object.keys(state.sourceBeanList)
      .map((key: string) => state.sourceBeanList[key])
      .filter((source: SourceBean) =>
        source.hide === 0 &&
          source.searchable !== 0 &&
          (!quick || source.quickSearch !== 0) &&
          (source.type === 0 || source.type === 1 || source.type === 4) &&
          source.api.length > 0);
  }

  private assertSupportedApiSource(source: SourceBean): void {
    if (source.type !== 0 && source.type !== 1 && source.type !== 4) {
      throw new Error(`暂只支持 XML/JSON/type=4 API 源，当前源类型：${source.type}`);
    }
    if (source.api.length === 0) {
      throw new Error('源 API 为空');
    }
  }

  private resolvePushTarget(vodId: string): string {
    if (!vodId.startsWith('push://')) {
      return '';
    }
    const payload = vodId.substring(7);
    if (payload.startsWith('b64:')) {
      return this.decodeBase64Url(payload.substring(4));
    }
    return this.decodeUrlComponent(payload);
  }

  private decodeUrlComponent(value: string): string {
    try {
      return decodeURIComponent(value.split('+').join(' '));
    } catch (_error) {
      return value;
    }
  }

  private decodeBase64Url(value: string): string {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let normalized = value.split('-').join('+').split('_').join('/');
    while (normalized.length % 4 !== 0) {
      normalized += '=';
    }
    const bytes: number[] = [];
    let buffer = 0;
    let bits = 0;
    for (let index = 0; index < normalized.length; index += 1) {
      const char = normalized.charAt(index);
      if (char === '=') {
        break;
      }
      const valueIndex = alphabet.indexOf(char);
      if (valueIndex < 0) {
        continue;
      }
      buffer = (buffer << 6) | valueIndex;
      bits += 6;
      if (bits >= 8) {
        bits -= 8;
        bytes.push((buffer >> bits) & 0xff);
      }
    }
    return this.decodeUtf8(bytes);
  }

  private decodeUtf8(bytes: number[]): string {
    let escaped = '';
    for (const byte of bytes) {
      const hex = byte.toString(16);
      escaped += `%${hex.length === 1 ? `0${hex}` : hex}`;
    }
    try {
      return decodeURIComponent(escaped);
    } catch (_error) {
      let result = '';
      for (const byte of bytes) {
        result += String.fromCharCode(byte);
      }
      return result;
    }
  }

  private appendQuery(baseUrl: string, params: Record<string, string>): string {
    const parts: string[] = [];
    Object.keys(params).forEach((key: string) => {
      const value = params[key];
      if (value !== undefined && value !== '') {
        parts.push(`${encodeURIComponent(key)}=${encodeURIComponent(value)}`);
      }
    });
    if (parts.length === 0) {
      return baseUrl;
    }
    const joiner = baseUrl.includes('?') ? '&' : '?';
    return `${baseUrl}${joiner}${parts.join('&')}`;
  }

  private parseXmlHomeContent(xml: string, sourceKey: string): SourceHomeContent {
    return {
      classes: this.parseXmlClasses(xml),
      list: this.parseXmlVideos(xml, sourceKey)
    };
  }

  private parseXmlSearchResult(xml: string, sourceKey: string): SearchResult {
    const listTag = this.firstTag(xml, 'list');
    return {
      list: this.parseXmlVideos(xml, sourceKey),
      page: this.toNumber(this.attr(listTag, 'page'), 1),
      pagecount: this.toNumber(this.attr(listTag, 'pagecount'), 1),
      limit: this.toNumber(this.attr(listTag, 'pagesize'), 0),
      total: this.toNumber(this.attr(listTag, 'recordcount'), 0)
    };
  }

  private parseXmlClasses(xml: string): MovieSort[] {
    const result: MovieSort[] = [];
    const classBody = this.tagBody(xml, 'class');
    const tyRegex = /<ty\b([^>]*)>([\s\S]*?)<\/ty>/g;
    let match = tyRegex.exec(classBody);
    while (match !== null) {
      const sortId = this.attr(match[1], 'id').trim();
      const sortName = this.cleanXmlText(match[2]).trim();
      if (sortId.length > 0 && sortName.length > 0) {
        result.push({ sortId, sortName, filters: [] });
      }
      match = tyRegex.exec(classBody);
    }
    return result;
  }

  private parseXmlVideos(xml: string, sourceKey: string): VodInfo[] {
    const result: VodInfo[] = [];
    const videoRegex = /<video\b[^>]*>([\s\S]*?)<\/video>/g;
    let match = videoRegex.exec(xml);
    while (match !== null) {
      const vod = this.parseXmlVideo(match[1], sourceKey);
      if (vod.id.length > 0 && vod.name.length > 0) {
        result.push(vod);
      }
      match = videoRegex.exec(xml);
    }
    return result;
  }

  private parseXmlVideo(body: string, sourceKey: string): VodInfo {
    const seriesData = this.parseXmlSeries(body);
    const year = this.toNumber(this.tagText(body, 'year'), 0);
    return {
      id: this.tagText(body, 'id').trim(),
      tid: this.toNumber(this.tagText(body, 'tid'), 0),
      name: this.tagText(body, 'name').trim(),
      type: this.tagText(body, 'type'),
      pic: this.tagText(body, 'pic'),
      lang: this.tagText(body, 'lang'),
      area: this.tagText(body, 'area'),
      year: year > 0 ? year : undefined,
      state: this.tagText(body, 'state'),
      note: this.tagText(body, 'note'),
      actor: this.tagText(body, 'actor'),
      director: this.tagText(body, 'director'),
      des: this.tagText(body, 'des'),
      seriesFlags: seriesData.flags,
      seriesMap: seriesData.map,
      playIndex: 0,
      playGroup: 0,
      playGroupCount: seriesData.flags.length,
      sourceKey
    };
  }

  private parseXmlSeries(videoBody: string): SeriesData {
    const flags: VodSeriesFlag[] = [];
    const map: Record<string, VodSeries[]> = {};
    const dlBody = this.tagBody(videoBody, 'dl');
    const ddRegex = /<dd\b([^>]*)>([\s\S]*?)<\/dd>/g;
    let match = ddRegex.exec(dlBody);
    while (match !== null) {
      const fallbackName = `播放源${flags.length + 1}`;
      const flagName = this.attr(match[1], 'flag').trim() || fallbackName;
      flags.push({ name: flagName, selected: flags.length === 0 });
      map[flagName] = this.parseEpisodes(this.cleanXmlText(match[2]));
      match = ddRegex.exec(dlBody);
    }
    return new SeriesData(flags, map);
  }

  private firstTag(xml: string, tag: string): string {
    const regex = new RegExp(`<${tag}\\b([^>]*)>`, 'i');
    const match = regex.exec(xml);
    return match === null ? '' : match[1];
  }

  private tagBody(xml: string, tag: string): string {
    const regex = new RegExp(`<${tag}\\b[^>]*>([\\s\\S]*?)<\\/${tag}>`, 'i');
    const match = regex.exec(xml);
    return match === null ? '' : match[1];
  }

  private tagText(xml: string, tag: string): string {
    return this.cleanXmlText(this.tagBody(xml, tag));
  }

  private attr(attrs: string, name: string): string {
    const regex = new RegExp(`${name}\\s*=\\s*["']([^"']*)["']`, 'i');
    const match = regex.exec(attrs);
    return match === null ? '' : this.decodeXmlEntities(match[1]);
  }

  private cleanXmlText(value: string): string {
    let text = value.trim();
    if (text.startsWith('<![CDATA[') && text.endsWith(']]>')) {
      text = text.substring(9, text.length - 3);
    }
    return this.decodeXmlEntities(text.trim());
  }

  private decodeXmlEntities(value: string): string {
    return value
      .split('&lt;').join('<')
      .split('&gt;').join('>')
      .split('&amp;').join('&')
      .split('&quot;').join('"')
      .split('&apos;').join("'");
  }

  private toNumber(value: string, fallback: number): number {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? Math.trunc(parsed) : fallback;
  }

  private async fixExtend(extend: string): Promise<string> {
    if (!extend.startsWith('http')) {
      return extend;
    }
    if (extend.startsWith('http://127.0.0.1') || extend.startsWith('http://localhost')) {
      return extend;
    }
    const cached = this.fixedExtCache[extend];
    if (cached !== undefined) {
      return cached;
    }
    const response = await this.httpClient.getText(extend);
    const fixed = this.tryMinifyJson(response);
    this.fixedExtCache[extend] = fixed;
    return fixed;
  }

  private tryMinifyJson(content: string): string {
    try {
      return JSON.stringify(JSON.parse(content));
    } catch (_error) {
      return content;
    }
  }

  private parseSeries(playFrom: string, playUrl: string): SeriesData {
    const fromParts = playFrom.length > 0 ? playFrom.split('$$$') : [];
    const urlParts = playUrl.length > 0 ? playUrl.split('$$$') : [];
    const flags: VodSeriesFlag[] = [];
    const map: Record<string, VodSeries[]> = {};
    const groupCount = Math.max(fromParts.length, urlParts.length);

    for (let groupIndex = 0; groupIndex < groupCount; groupIndex++) {
      const rawFlagName = groupIndex < fromParts.length ? fromParts[groupIndex].trim() : '';
      const flagName = rawFlagName.length > 0 ? rawFlagName : `播放源${groupIndex + 1}`;
      flags.push({ name: flagName, selected: groupIndex === 0 });
      map[flagName] = this.parseEpisodes(groupIndex < urlParts.length ? urlParts[groupIndex] : '');
    }
    return new SeriesData(flags, map);
  }

  private parseEpisodes(raw: string): VodSeries[] {
    if (raw.length === 0) {
      return [];
    }
    const episodes: VodSeries[] = [];
    raw.split('#').forEach((part: string) => {
      const item = part.trim();
      if (item.length === 0) {
        return;
      }
      const marker = item.indexOf('$');
      if (marker >= 0) {
        episodes.push({
          name: item.substring(0, marker).length > 0 ? item.substring(0, marker) : `${episodes.length + 1}`,
          url: item.substring(marker + 1),
          selected: episodes.length === 0
        });
      } else {
        episodes.push({
          name: `${episodes.length + 1}`,
          url: item,
          selected: episodes.length === 0
        });
      }
    });
    return episodes;
  }

  private emptyResult(): SearchResult {
    return {
      list: [],
      page: 1,
      pagecount: 1,
      limit: 0,
      total: 0
    };
  }

}

export const sourceService = new SourceService();
