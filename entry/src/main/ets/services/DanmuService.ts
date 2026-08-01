import { HttpClient } from './HttpClient';
import { errorMessage } from '../utils/ErrorUtil';

/**
 * A single danmaku comment parsed from Bilibili XML format.
 *
 * Android uses the FlameDanmaku library (`master.flame.danmaku`). HarmonyOS has no
 * equivalent, so we parse the same XML format into plain objects and render with
 * ArkUI animated Text components.
 */
export interface DanmuItem {
  /** Appearance time in milliseconds from video start. */
  timeMs: number;
  /** 1=scroll RL, 4=bottom, 5=top. Only scroll RL is rendered in the first pass. */
  type: number;
  /** Font size in px (pre-scale). */
  size: number;
  /** RGB color as 0xRRGGBB. */
  color: number;
  /** Comment text. */
  text: string;
}

export interface DanmuConfig {
  open: boolean;
  maxLine: number;
  speed: number;
  alpha: number;
  sizeScale: number;
  randomColor: boolean;
}

export class DanmuService {
  private readonly httpClient: HttpClient = new HttpClient();

  /**
   * Resolves the danmu source and parses it into DanmuItem[].
   *
   * The `source` can be:
   * - An HTTP/HTTPS URL to a Bilibili XML file
   * - A raw XML string starting with `<?xml` or `<i`
   * - Empty (returns [])
   */
  async load(source: string): Promise<DanmuItem[]> {
    const trimmed = source.trim();
    if (trimmed.length === 0) {
      return [];
    }
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      try {
        const xml = await this.httpClient.getText(trimmed);
        return this.parseXml(xml);
      } catch (error) {
        throw new Error(`Danmu fetch failed: ${errorMessage(error)}`);
      }
    }
    if (trimmed.startsWith('<?xml') || trimmed.startsWith('<i')) {
      return this.parseXml(trimmed);
    }
    return [];
  }

  /**
   * Parses Bilibili danmaku XML: `<i><d p="time,type,size,color,...">text</d>...</i>`
   *
   * The `p` attribute is a comma-separated string. We only need the first 4 fields:
   * time (seconds), type, size, color. Fields 5-8 (timestamp, pool, user, rowid) are ignored.
   */
  parseXml(xml: string): DanmuItem[] {
    const items: DanmuItem[] = [];
    const regex = /<d\s+[^>]*p="([^"]*)"[^>]*>([^<]*)<\/d>/g;
    let match: RegExpExecArray | null;
    while ((match = regex.exec(xml)) !== null) {
      const params = match[1].split(',');
      if (params.length < 4) {
        continue;
      }
      const timeSec = Number(params[0]);
      const type = Number(params[1]);
      const size = Number(params[2]);
      const color = Number(params[3]) & 0x00FFFFFF;
      const text = this.decodeXmlEntities(match[2]);
      if (!Number.isFinite(timeSec) || text.length === 0) {
        continue;
      }
      items.push({
        timeMs: Math.round(timeSec * 1000),
        type: Number.isFinite(type) ? type : 1,
        size: Number.isFinite(size) ? size : 25,
        color: Number.isFinite(color) ? color : 0xFFFFFF,
        text
      });
    }
    items.sort((a: DanmuItem, b: DanmuItem) => a.timeMs - b.timeMs);
    return items;
  }

  private decodeXmlEntities(text: string): string {
    return text
      .replace(/&amp;/g, '&')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&quot;/g, '"')
      .replace(/&apos;/g, '\'');
  }
}

export const danmuService = new DanmuService();
