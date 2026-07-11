import http from '@ohos.net.http';

export interface HttpHeaders {
  [key: string]: string;
}

export class HttpClient {
  private static readonly userAgent: string = 'okhttp/3.15';
  private static readonly accept: string =
    'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9';

  async getText(url: string, headers?: HttpHeaders): Promise<string> {
    const request = http.createHttp();
    try {
      const response = await request.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'User-Agent': HttpClient.userAgent,
          'Accept': HttpClient.accept,
          ...(headers || {})
        },
        readTimeout: 30000,
        connectTimeout: 10000
      });
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
      const response = await request.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'User-Agent': HttpClient.userAgent,
          'Accept': 'application/json, text/plain, */*',
          'Content-Type': 'application/json;charset=UTF-8',
          ...(headers || {})
        },
        extraData: JSON.stringify(body),
        readTimeout: 30000,
        connectTimeout: 10000
      });
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
      const response = await request.request(url, {
        method: http.RequestMethod.POST,
        header: {
          'User-Agent': HttpClient.userAgent,
          'Accept': '*/*',
          'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8',
          ...(headers || {})
        },
        extraData: this.encodeForm(body),
        readTimeout: 30000,
        connectTimeout: 10000
      });
      return response.result.toString();
    } finally {
      request.destroy();
    }
  }

  async requestText(method: string, url: string, headers?: HttpHeaders, body: string = ''): Promise<string> {
    const request = http.createHttp();
    try {
      const response = await request.request(url, {
        method: method as http.RequestMethod,
        header: {
          'User-Agent': HttpClient.userAgent,
          'Accept': '*/*',
          ...(headers || {})
        },
        extraData: body,
        readTimeout: 30000,
        connectTimeout: 10000
      });
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
