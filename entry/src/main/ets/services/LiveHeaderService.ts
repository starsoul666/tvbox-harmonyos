import { asArray, asRecord } from '../utils/JsonUtil';
import { HttpHeaders } from './HttpClient';

export interface LiveHeaderMatch {
  headers: HttpHeaders;
  matched: boolean;
}

export class LiveHeaderService {
  readonly defaultUserAgent: string = 'Lavf/59.27.100';

  match(configRows: unknown[] | undefined, url: string): LiveHeaderMatch {
    const fallback: LiveHeaderMatch = {
      headers: { 'User-Agent': this.defaultUserAgent },
      matched: false
    };
    if (configRows === undefined) {
      return fallback;
    }

    for (const item of configRows) {
      const row = asRecord(item);
      const flags = asArray(row['flag']);
      const headerData = asRecord(row['header']);
      if (!this.matchesAnyFlag(flags, url)) {
        continue;
      }
      const headers = this.readHeaders(headerData);
      return Object.keys(headers).length > 0
        ? { headers, matched: true }
        : fallback;
    }
    return fallback;
  }

  private matchesAnyFlag(flags: unknown[], url: string): boolean {
    for (const item of flags) {
      if (url.includes(String(item))) {
        return true;
      }
    }
    return false;
  }

  private readHeaders(record: Record<string, unknown>): HttpHeaders {
    const headers: HttpHeaders = {};
    for (const key of Object.keys(record)) {
      headers[key] = String(record[key]);
    }
    return headers;
  }
}

export const liveHeaderService = new LiveHeaderService();
