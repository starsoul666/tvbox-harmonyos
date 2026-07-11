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
}
