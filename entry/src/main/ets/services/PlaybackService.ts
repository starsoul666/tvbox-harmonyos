import { ParseBean, SourceBean } from '../models/TvBoxModels';
import { asRecord, safeString } from '../utils/JsonUtil';
import { apiConfigService } from './ApiConfigService';
import { HttpClient, HttpHeaders } from './HttpClient';

export interface PlaybackResolveResult {
  url: string;
  parseName: string;
  status: string;
  warning?: string;
  headers?: HttpHeaders;
  /** Bilibili XML danmu URL or raw XML, from the source's `danmaku` field. */
  danmu?: string;
  /** Subtitle URL or raw SRT/VTT, from the source's `subt` or `subs` field. */
  subt?: string;
}

export class PlaybackService {
  private readonly httpClient: HttpClient = new HttpClient();
  private readonly fixedExtCache: Record<string, string> = {};

  async resolve(sourceKey: string, playFlag: string, rawUrl: string, selectedParseName: string = ''): Promise<PlaybackResolveResult> {
    const source = apiConfigService.state.sourceBeanList[sourceKey];
    if (source === undefined) {
      return this.directResult(rawUrl, '直接播放');
    }
    if (source.type === 0 || source.type === 1) {
      return this.resolveJsonOrXmlSource(source, playFlag, rawUrl, selectedParseName);
    }
    if (source.type === 4) {
      return this.resolveType4Source(source, playFlag, rawUrl, selectedParseName);
    }
    return {
      url: rawUrl,
      parseName: 'spider',
      status: 'Spider playerContent 尚未迁移，暂用原始地址',
      warning: 'Spider 播放解析待迁移'
    };
  }

  async resolveWithParse(parse: ParseBean, rawUrl: string): Promise<PlaybackResolveResult> {
    if (parse.type === 1) {
      return this.resolveJsonParse(parse, rawUrl);
    }
    if (parse.type === 0) {
      return {
        url: `${parse.url}${rawUrl}`,
        parseName: parse.name,
        status: `嗅探解析 ${parse.name} 尚未迁移，暂交给 Video 尝试`,
        warning: 'WebView 嗅探解析待迁移'
      };
    }
    return {
      url: rawUrl,
      parseName: parse.name,
      status: `${parse.name} 类型 ${parse.type} 尚未迁移，暂用原始地址`,
      warning: `解析类型 ${parse.type} 待迁移`
    };
  }

  private async resolveJsonOrXmlSource(source: SourceBean, playFlag: string, rawUrl: string, selectedParseName: string): Promise<PlaybackResolveResult> {
    const sitePlayUrl = source.playerUrl.trim();
    if (sitePlayUrl.length === 0 && this.isDirectVideo(rawUrl)) {
      return this.directResult(rawUrl, '直连视频地址');
    }

    const selectedParse = this.findParse(selectedParseName);
    if (selectedParse !== undefined) {
      return this.resolveWithParse(selectedParse, rawUrl);
    }

    const siteParse = this.parseFromSitePlayUrl(sitePlayUrl);
    if (siteParse !== undefined) {
      return this.resolveWithParse(siteParse, rawUrl);
    }

    if (sitePlayUrl.length > 0) {
      return {
        url: `${sitePlayUrl}${rawUrl}`,
        parseName: '站点解析',
        status: '使用站点 playUrl 拼接播放地址'
      };
    }

    if (apiConfigService.state.vipParseFlags.includes(playFlag) && apiConfigService.state.defaultParse !== undefined) {
      return this.resolveWithParse(apiConfigService.state.defaultParse, rawUrl);
    }

    return {
      url: rawUrl,
      parseName: '原始地址',
      status: '未命中直连格式或解析标记，暂用原始地址',
      warning: 'WebView 嗅探解析待迁移'
    };
  }

  private async resolveType4Source(source: SourceBean, playFlag: string, rawUrl: string, selectedParseName: string): Promise<PlaybackResolveResult> {
    const extend = await this.fixExtend(source.ext);
    const response = await this.httpClient.getText(this.buildPlayApiUrl(source.api, rawUrl, playFlag, extend));
    const root = asRecord(JSON.parse(response));
    const playUrl = safeString(root, 'playUrl');
    const url = safeString(root, 'url', rawUrl);
    const parse = safeString(root, 'parse', '1') === '1';
    const jx = safeString(root, 'jx', '0') === '1';
    const warning = this.subtitleWarning(root);
    const danmu = this.extractDanmu(root);
    const subt = this.extractSubtitle(root);

    if (parse || jx) {
      const useUserParse = (playUrl.length === 0 && apiConfigService.state.vipParseFlags.includes(playFlag)) || jx;
      const result = useUserParse
        ? await this.resolveWithDefaultOrSelectedParse(url, selectedParseName)
        : await this.resolveFromPlayUrl(playUrl, url);
      return {
        url: result.url,
        parseName: result.parseName,
        status: `type=4 ${result.status}`,
        warning: this.joinWarning(result.warning, warning),
        headers: result.headers,
        danmu,
        subt
      };
    }

    return {
      url: `${playUrl}${url}`,
      parseName: 'type=4',
      status: 'type=4 播放接口直连',
      warning,
      headers: this.parsePlaybackHeaders(root),
      danmu,
      subt
    };
  }

  private async resolveJsonParse(parse: ParseBean, rawUrl: string): Promise<PlaybackResolveResult> {
    const response = await this.httpClient.getText(`${parse.url}${encodeURIComponent(rawUrl)}`, this.parseExtHeaders(parse.ext));
    const root = asRecord(JSON.parse(response));
    const data = asRecord(root['data']);
    let url = safeString(data, 'url', safeString(root, 'url'));
    if (url.startsWith('//')) {
      url = `http:${url}`;
    }
    if (url.length === 0) {
      throw new Error(`${parse.name} 未返回 url`);
    }

    return {
      url,
      parseName: parse.name,
      status: `解析成功：${parse.name}`,
      headers: this.parsePlaybackHeaders(root),
      danmu: this.extractDanmu(root),
      subt: this.extractSubtitle(root)
    };
  }

  private async resolveWithDefaultOrSelectedParse(rawUrl: string, selectedParseName: string): Promise<PlaybackResolveResult> {
    const selectedParse = this.findParse(selectedParseName);
    if (selectedParse !== undefined) {
      return this.resolveWithParse(selectedParse, rawUrl);
    }
    if (apiConfigService.state.defaultParse !== undefined) {
      return this.resolveWithParse(apiConfigService.state.defaultParse, rawUrl);
    }
    return {
      url: rawUrl,
      parseName: '原始地址',
      status: '缺少默认解析，暂用原始地址',
      warning: '默认解析未配置'
    };
  }

  private async resolveFromPlayUrl(playUrl: string, rawUrl: string): Promise<PlaybackResolveResult> {
    const siteParse = this.parseFromSitePlayUrl(playUrl);
    if (siteParse !== undefined) {
      return this.resolveWithParse(siteParse, rawUrl);
    }
    return {
      url: rawUrl,
      parseName: '原始地址',
      status: '播放接口未返回解析地址，暂用原始地址',
      warning: 'playUrl 为空'
    };
  }

  private buildPlayApiUrl(api: string, rawUrl: string, playFlag: string, extend: string): string {
    const delimiter = api.includes('?') ? '&' : '?';
    return `${api}${delimiter}play=${encodeURIComponent(rawUrl)}&flag=${encodeURIComponent(playFlag)}&extend=${encodeURIComponent(extend)}`;
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

  private parseFromSitePlayUrl(playUrl: string): ParseBean | undefined {
    if (playUrl.startsWith('json:')) {
      return {
        name: '站点 JSON 解析',
        url: playUrl.substring(5),
        ext: '',
        type: 1,
        isDefault: false
      };
    }
    if (playUrl.startsWith('parse:')) {
      return this.findParse(playUrl.substring(6));
    }
    if (playUrl.length > 0) {
      return {
        name: '站点嗅探解析',
        url: playUrl,
        ext: '',
        type: 0,
        isDefault: false
      };
    }
    return undefined;
  }

  private parseExtHeaders(ext: string): HttpHeaders {
    if (ext.length === 0) {
      return {};
    }
    try {
      const root = asRecord(JSON.parse(ext));
      const header = asRecord(root['header']);
      const result: HttpHeaders = {};
      for (const key of Object.keys(header)) {
        result[key] = String(header[key]);
      }
      return result;
    } catch (_error) {
      return {};
    }
  }

  private parsePlaybackHeaders(root: Record<string, unknown>): HttpHeaders {
    const result: HttpHeaders = this.parseHeaderValue(root['header']);
    const userAgent = safeString(root, 'user-agent').trim();
    if (userAgent.length > 0) {
      result['User-Agent'] = userAgent;
    }
    const referer = safeString(root, 'referer').trim();
    if (referer.length > 0) {
      result['Referer'] = referer;
    }
    return result;
  }

  private parseHeaderValue(value: unknown): HttpHeaders {
    let header = asRecord(value);
    if (Object.keys(header).length === 0 && typeof value === 'string' && value.length > 0) {
      try {
        header = asRecord(JSON.parse(value));
      } catch (_error) {
        header = {};
      }
    }
    const result: HttpHeaders = {};
    for (const key of Object.keys(header)) {
      result[key] = String(header[key]);
    }
    return result;
  }

  private subtitleWarning(root: Record<string, unknown>): string {
    return '';
  }

  /** Extracts the `danmaku` field (URL or raw XML) from a play result. */
  private extractDanmu(root: Record<string, unknown>): string | undefined {
    const danmu = safeString(root, 'danmaku');
    return danmu.length > 0 ? danmu : undefined;
  }

  /**
   * Extracts subtitle info from a play result.
   * Checks `subt` (direct URL) first, then `subs` array (first entry's `url`).
   */
  private extractSubtitle(root: Record<string, unknown>): string | undefined {
    const subt = safeString(root, 'subt');
    if (subt.length > 0) {
      return subt;
    }
    const subs = root['subs'];
    if (subs !== undefined && Array.isArray(subs)) {
      const subsArray = subs as unknown[];
      if (subsArray.length > 0) {
        const first = asRecord(subsArray[0]);
        const url = safeString(first, 'url');
        if (url.length > 0) {
          return url;
        }
      }
    }
    return undefined;
  }

  private joinWarning(left: string | undefined, right: string): string | undefined {
    const first = left === undefined ? '' : left;
    if (first.length === 0) {
      return right.length === 0 ? undefined : right;
    }
    if (right.length === 0) {
      return first;
    }
    return `${first}；${right}`;
  }

  private findParse(name: string): ParseBean | undefined {
    if (name.length === 0) {
      return undefined;
    }
    return apiConfigService.state.parseBeanList.find((item: ParseBean) => item.name === name);
  }

  private directResult(url: string, status: string): PlaybackResolveResult {
    return {
      url,
      parseName: '直接播放',
      status
    };
  }

  private isDirectVideo(url: string): boolean {
    const lower = url.toLowerCase();
    if (lower.includes('=http')) {
      return false;
    }
    return lower.startsWith('rtmp://') ||
      lower.startsWith('rtsp://') ||
      lower.includes('.m3u8') ||
      lower.includes('.mp4') ||
      lower.includes('.flv') ||
      lower.includes('.mkv') ||
      lower.includes('.webm') ||
      lower.includes('.avi') ||
      lower.includes('.mov') ||
      lower.includes('.ts');
  }
}

export const playbackService = new PlaybackService();
