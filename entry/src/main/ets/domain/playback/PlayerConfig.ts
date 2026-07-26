import { asArray, asRecord, JsonNode, parseJson, safeNumber, safeString } from '../../utils/JsonUtil';

/**
 * Android-compatible per-VOD player configuration stored in `VodInfo.playerCfg`.
 * Keys mirror `PlayFragment.initPlayerCfg()`:
 *   pl  player kernel, pr render, ijk codec, sc scale,
 *   sp  speed, st skip opening seconds, et skip ending seconds.
 * `headers` is a TVBox extension also used by the Drive page for WebDAV Basic auth.
 */
export class PlayerConfig {
  playerType: number = 1;
  renderType: number = 0;
  ijkCodec: string = '';
  scale: number = 0;
  speed: number = 1.0;
  skipStartSeconds: number = 0;
  skipEndSeconds: number = 0;
  headers: Record<string, string> = {};

  static parse(json: string): PlayerConfig {
    const config = new PlayerConfig();
    if (json.length === 0) {
      return config;
    }
    try {
      const root: Record<string, JsonNode> = asRecord(parseJson(json));
      config.playerType = safeNumber(root, 'pl', 1);
      config.renderType = safeNumber(root, 'pr', 0);
      config.ijkCodec = safeString(root, 'ijk');
      config.scale = safeNumber(root, 'sc', 0);
      config.speed = safeNumber(root, 'sp', 1.0);
      config.skipStartSeconds = safeNumber(root, 'st', 0);
      config.skipEndSeconds = safeNumber(root, 'et', 0);
      config.headers = PlayerConfig.parseHeaders(root);
    } catch (_error) {
      return new PlayerConfig();
    }
    return config;
  }

  /**
   * Android accepts both `headers: [{name, value}]` (config `rules`/live headers style)
   * and `headers: {name: value}` object form.
   */
  private static parseHeaders(root: Record<string, JsonNode>): Record<string, string> {
    const result: Record<string, string> = {};
    const raw: JsonNode = root['headers'];
    if (raw === null || raw === undefined) {
      return result;
    }
    if (Array.isArray(raw)) {
      for (const item of asArray(raw)) {
        const row: Record<string, JsonNode> = asRecord(item);
        const name = safeString(row, 'name');
        const value = safeString(row, 'value');
        if (name.length > 0 && value.length > 0) {
          result[name] = value;
        }
      }
      return result;
    }
    const row: Record<string, JsonNode> = asRecord(raw);
    for (const key of Object.keys(row)) {
      const value = safeString(row, key);
      if (value.length > 0) {
        result[key] = value;
      }
    }
    return result;
  }

  stringify(): string {
    const headerRows: HeaderRow[] = Object.keys(this.headers).map((name: string) => new HeaderRow(name, this.headers[name]));
    return JSON.stringify(new PlayerConfigJson(
      this.playerType,
      this.renderType,
      this.ijkCodec,
      this.scale,
      this.speed,
      this.skipStartSeconds,
      this.skipEndSeconds,
      headerRows
    ));
  }
}

class HeaderRow {
  name: string;
  value: string;

  constructor(name: string, value: string) {
    this.name = name;
    this.value = value;
  }
}

class PlayerConfigJson {
  pl: number;
  pr: number;
  ijk: string;
  sc: number;
  sp: number;
  st: number;
  et: number;
  headers: HeaderRow[];

  constructor(pl: number, pr: number, ijk: string, sc: number, sp: number, st: number, et: number, headers: HeaderRow[]) {
    this.pl = pl;
    this.pr = pr;
    this.ijk = ijk;
    this.sc = sc;
    this.sp = sp;
    this.st = st;
    this.et = et;
    this.headers = headers;
  }
}
