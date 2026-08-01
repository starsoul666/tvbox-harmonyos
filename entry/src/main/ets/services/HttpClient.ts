import http from '@ohos.net.http';
import { HawkConfig } from '../constants/HawkConfig';
import { DnsUrls } from '../constants/AppDefaults';
import { settingsStore } from './SettingsStore';

export interface HttpHeaders {
  [key: string]: string;
}

interface ProxySetting {
  host: string;
  port: number;
}

function parseProxy(raw: string): ProxySetting | null {
  const trimmed = raw.trim();
  if (trimmed.length === 0) {
    return null;
  }
  let rest = trimmed;
  if (rest.startsWith('http://')) {
    rest = rest.substring(7);
  } else if (rest.startsWith('https://')) {
    rest = rest.substring(8);
  }
  if (rest.startsWith('socks5://')) {
    rest = rest.substring(9);
  }
  const slashIndex = rest.indexOf('/');
  if (slashIndex >= 0) {
    rest = rest.substring(0, slashIndex);
  }
  const colonIndex = rest.lastIndexOf(':');
  if (colonIndex >= 0) {
    const host = rest.substring(0, colonIndex);
    const port = parseInt(rest.substring(colonIndex + 1), 10);
    if (host.length > 0 && port > 0) {
      return { host, port };
    }
  }
  return null;
}

export class HttpClient {
  private static readonly userAgent: string = 'okhttp/3.15';
  private static readonly accept: string =
    'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9';

  private dohUrl(): string {
    if (!settingsStore.isReady()) {
      return '';
    }
    const index = settingsStore.getSync<number>(HawkConfig.DOH_URL, 0);
    if (index <= 0 || index >= DnsUrls.length) {
      return '';
    }
    return DnsUrls[index];
  }

  private proxyHost(): string {
    if (!settingsStore.isReady()) {
      return '';
    }
    const raw = settingsStore.getSync<string>(HawkConfig.PROXY_SERVER, '');
    const parsed = parseProxy(raw);
    return parsed ? parsed.host : '';
  }

  private buildOptions(method: http.RequestMethod, headers: HttpHeaders, body: string | undefined,
    extraData: Record<string, unknown> | undefined): http.HttpRequestOptions {
    const header: Record<string, string> = {
      'User-Agent': HttpClient.userAgent,
      'Accept': HttpClient.accept,
      ...headers
    };
    const options: http.HttpRequestOptions = {
      method,
      header,
      readTimeout: 30000,
      connectTimeout: 10000
    };
    if (body !== undefined) {
      options.extraData = body;
    } else if (extraData !== undefined) {
      options.extraData = JSON.stringify(extraData);
    }
    const doh = this.dohUrl();
    if (doh.length > 0) {
      options.dnsOverHttps = doh;
    }
    if (this.proxyHost().length > 0) {
      options.usingProxy = true;
    }
    return options;
  }

  async getText(url: string, headers?: HttpHeaders): Promise<string> {
    const request = http.createHttp();
    try {
      const response = await request.request(url,
        this.buildOptions(http.RequestMethod.GET, headers || {}, undefined, undefined));
      return response.result.toString();
    } finally {
      request.destroy();
    }
  }

  async getJson<T>(url: string, headers?: HttpHeaders): Promise<T> {
    const text = await this.getText(url, headers);
    return JSON.parse(text) as T;
  }

  async postJsonText(url: string, body: Record<string, unknown>, headers?: HttpHeaders): Promise<string> {
    const request = http.createHttp();
    try {
      const response = await request.request(url,
        this.buildOptions(http.RequestMethod.POST,
          { 'Accept': 'application/json, text/plain, */*', 'Content-Type': 'application/json;charset=UTF-8', ...(headers || {}) },
          undefined, body));
      return response.result.toString();
    } finally {
      request.destroy();
    }
  }

  async postJson<T>(url: string, body: Record<string, unknown>, headers?: HttpHeaders): Promise<T> {
    const text = await this.postJsonText(url, body, headers);
    return JSON.parse(text) as T;
  }

  async postFormText(url: string, body: Record<string, string>, headers?: HttpHeaders): Promise<string> {
    const request = http.createHttp();
    try {
      const response = await request.request(url,
        this.buildOptions(http.RequestMethod.POST,
          { 'Accept': '*/*', 'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8', ...(headers || {}) },
          this.encodeForm(body), undefined));
      return response.result.toString();
    } finally {
      request.destroy();
    }
  }

  async requestText(method: string, url: string, headers?: HttpHeaders, body: string = ''): Promise<string> {
    const request = http.createHttp();
    try {
      const response = await request.request(url,
        this.buildOptions(method as http.RequestMethod,
          { 'Accept': '*/*', ...(headers || {}) },
          body, undefined));
      return response.result.toString();
    } finally {
      request.destroy();
    }
  }

  private encodeForm(body: Record<string, string>): string {
    const parts: string[] = [];
    const keys = Object.keys(body);
    for (const key of keys) {
      parts.push(`${encodeURIComponent(key)}=${encodeURIComponent(body[key])}`);
    }
    return parts.join('&');
  }
}
