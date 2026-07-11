import fs from '@ohos.file.fs';
import util from '@ohos.util';
import { AlistDriveConfig, DriveFileItem, LocalDriveConfig, StorageDrive, WebDavDriveConfig } from '../models/TvBoxModels';
import { asArray, asRecord, safeString } from '../utils/JsonUtil';
import { HttpClient, HttpHeaders } from './HttpClient';

export class DriveService {
  private readonly httpClient: HttpClient = new HttpClient();
  private readonly videoTypes: string[] = [
    'mp4', 'mkv', 'm3u8', 'flv', 'avi', 'mov', 'wmv', 'rmvb', 'ts', 'webm',
    'mpeg', 'mpg', '3gp', 'm4v', 'f4v', 'asf', 'dat', 'vob', 'ogv', 'divx'
  ];

  parseAlistConfig(drive: StorageDrive): AlistDriveConfig {
    try {
      const root = asRecord(JSON.parse(drive.configJson));
      return {
        url: safeString(root, 'url'),
        password: safeString(root, 'password'),
        initPath: this.normalizePath(safeString(root, 'initPath', '/'))
      };
    } catch (_error) {
      return { url: '', password: '', initPath: '/' };
    }
  }

  parseWebDavConfig(drive: StorageDrive): WebDavDriveConfig {
    try {
      const root = asRecord(JSON.parse(drive.configJson));
      return {
        url: safeString(root, 'url'),
        username: safeString(root, 'username'),
        password: safeString(root, 'password'),
        initPath: this.normalizePath(safeString(root, 'initPath', '/'))
      };
    } catch (_error) {
      return { url: '', username: '', password: '', initPath: '/' };
    }
  }

  parseLocalConfig(drive: StorageDrive): LocalDriveConfig {
    try {
      const root = asRecord(JSON.parse(drive.configJson));
      const configured = safeString(root, 'rootPath');
      if (configured.length > 0) {
        return { rootPath: this.normalizeLocalPath(configured) };
      }
    } catch (_error) {
    }
    return { rootPath: this.normalizeLocalPath(drive.name) };
  }

  async listLocal(drive: StorageDrive, path: string): Promise<DriveFileItem[]> {
    const rootPath = this.parseLocalConfig(drive).rootPath;
    if (rootPath.length === 0) {
      throw new Error('本地目录为空');
    }
    const targetPath = this.constrainLocalPath(path.length > 0 ? path : rootPath, rootPath);
    let names: string[] = [];
    try {
      names = fs.listFileSync(targetPath);
    } catch (_error) {
      throw new Error(`无法读取本地目录：${targetPath}`);
    }
    const result: DriveFileItem[] = [];
    for (const name of names) {
      const childPath = this.joinLocalPath(targetPath, name);
      try {
        const stat = fs.statSync(childPath);
        const isFile = stat.isFile();
        const isDirectory = stat.isDirectory();
        if (!isFile && !isDirectory) {
          continue;
        }
        result.push(this.toDriveFile(name, targetPath, isFile, '', this.resolveLocalFileUrl(childPath), 0, childPath, stat.mtime * 1000));
      } catch (_error) {
      }
    }
    return result;
  }

  resolveLocalFileUrl(path: string): string {
    const normalized = this.normalizeLocalPath(path);
    if (normalized.startsWith('file://')) {
      return normalized;
    }
    return encodeURI(`file://${normalized}`);
  }

  parentLocalPath(path: string, rootPath: string): string {
    const safeRoot = this.normalizeLocalPath(rootPath);
    const safePath = this.constrainLocalPath(path, safeRoot);
    if (safePath === safeRoot) {
      return safeRoot;
    }
    const index = safePath.lastIndexOf('/');
    const parent = index <= 0 ? safeRoot : safePath.substring(0, index);
    return this.constrainLocalPath(parent, safeRoot);
  }

  async listAlist(drive: StorageDrive, path: string): Promise<DriveFileItem[]> {
    const config = this.parseAlistConfig(drive);
    const origin = this.getOrigin(config.url);
    if (origin.length === 0) {
      throw new Error('Alist 地址格式不正确');
    }
    const targetPath = this.normalizePath(path);
    const headers = this.alistHeaders(origin);
    try {
      return await this.listAlistV3(origin, config.password, targetPath, headers);
    } catch (firstError) {
      try {
        return await this.listAlistV2(origin, config.password, targetPath, headers);
      } catch (_secondError) {
        throw firstError;
      }
    }
  }

  resolveAlistFileUrl(drive: StorageDrive, item: DriveFileItem): string {
    if (item.fileUrl.length > 0) {
      return item.fileUrl;
    }
    const config = this.parseAlistConfig(drive);
    const origin = this.getOrigin(config.url);
    return encodeURI(`${origin}/d${item.path}`);
  }

  async listWebDav(drive: StorageDrive, path: string): Promise<DriveFileItem[]> {
    const config = this.parseWebDavConfig(drive);
    if (config.url.trim().length === 0) {
      throw new Error('WebDAV 地址为空');
    }
    const targetPath = this.normalizePath(path);
    const url = this.joinWebDavUrl(config.url, targetPath);
    const response = await this.httpClient.requestText('PROPFIND', url, this.webDavHeaders(config), this.webDavPropfindBody());
    return this.parseWebDavResponse(response, targetPath, url);
  }

  resolveWebDavFileUrl(drive: StorageDrive, item: DriveFileItem): string {
    const config = this.parseWebDavConfig(drive);
    return this.joinWebDavUrl(config.url, item.path);
  }

  getWebDavAuthorization(drive: StorageDrive): string {
    const config = this.parseWebDavConfig(drive);
    if (config.username.length === 0 && config.password.length === 0) {
      return '';
    }
    return this.basicAuthorization(config.username, config.password);
  }

  isVideoFile(item: DriveFileItem): boolean {
    if (!item.isFile) {
      return false;
    }
    const fileType = item.fileType.toLowerCase();
    return this.videoTypes.includes(fileType);
  }

  sortItems(items: DriveFileItem[], sortType: number): DriveFileItem[] {
    const next = [...items];
    next.sort((left: DriveFileItem, right: DriveFileItem) => {
      if (left.isFile !== right.isFile) {
        return left.isFile ? 1 : -1;
      }
      switch (sortType) {
        case 1:
          return right.name.localeCompare(left.name, 'zh-Hans-CN');
        case 2:
          return left.lastModified - right.lastModified;
        case 3:
          return right.lastModified - left.lastModified;
        default:
          return left.name.localeCompare(right.name, 'zh-Hans-CN');
      }
    });
    return next;
  }

  joinPath(parent: string, name: string): string {
    const safeParent = this.normalizePath(parent);
    return safeParent === '/' ? `/${name}` : `${safeParent}/${name}`;
  }

  parentPath(path: string): string {
    const safePath = this.normalizePath(path);
    if (safePath === '/') {
      return '/';
    }
    const index = safePath.lastIndexOf('/');
    return index <= 0 ? '/' : safePath.substring(0, index);
  }

  formatTime(value: number): string {
    if (!Number.isFinite(value) || value <= 0) {
      return '';
    }
    const date = new Date(value);
    const month = date.getMonth() + 1;
    const day = date.getDate();
    const hour = date.getHours();
    const minute = date.getMinutes();
    const safeMonth = month < 10 ? `0${month}` : `${month}`;
    const safeDay = day < 10 ? `0${day}` : `${day}`;
    const safeHour = hour < 10 ? `0${hour}` : `${hour}`;
    const safeMinute = minute < 10 ? `0${minute}` : `${minute}`;
    return `${date.getFullYear()}-${safeMonth}-${safeDay} ${safeHour}:${safeMinute}`;
  }

  private async listAlistV3(origin: string, password: string, path: string, headers: HttpHeaders): Promise<DriveFileItem[]> {
    const response = await this.httpClient.postJson<Record<string, unknown>>(`${origin}/api/fs/list`, {
      path,
      password,
      page: 1,
      per_page: 200,
      refresh: false
    }, headers);
    const codeValue = response['code'];
    if (Number(codeValue) !== 200) {
      throw new Error(safeString(response, 'message', 'Alist v3 列表请求失败'));
    }
    const data = asRecord(response['data']);
    const content = asArray(data['content']);
    const result: DriveFileItem[] = [];
    for (const item of content) {
      const row = asRecord(item);
      const name = safeString(row, 'name');
      if (name.length === 0) {
        continue;
      }
      const isDir = row['is_dir'] === true;
      result.push(this.toDriveFile(name, path, !isDir, safeString(row, 'modified'), '', 3));
    }
    return result;
  }

  private async listAlistV2(origin: string, password: string, path: string, headers: HttpHeaders): Promise<DriveFileItem[]> {
    const response = await this.httpClient.postJson<Record<string, unknown>>(`${origin}/api/public/path`, {
      path,
      password,
      page_num: 1,
      page_size: 200
    }, headers);
    const codeValue = response['code'];
    if (Number(codeValue) !== 200) {
      throw new Error(safeString(response, 'message', 'Alist v2 列表请求失败'));
    }
    const data = asRecord(response['data']);
    const files = asArray(data['files']);
    const result: DriveFileItem[] = [];
    for (const item of files) {
      const row = asRecord(item);
      const name = safeString(row, 'name');
      if (name.length === 0) {
        continue;
      }
      const isFile = Number(row['type']) !== 1;
      result.push(this.toDriveFile(name, path, isFile, safeString(row, 'updated_at'), safeString(row, 'url'), 2));
    }
    return result;
  }

  private toDriveFile(
    name: string,
    parentPath: string,
    isFile: boolean,
    modified: string,
    fileUrl: string,
    version: number,
    absolutePath: string = '',
    modifiedTime: number = 0
  ): DriveFileItem {
    const typeIndex = name.lastIndexOf('.');
    const fileType = isFile && typeIndex >= 0 && typeIndex < name.length - 1
      ? name.substring(typeIndex + 1).toLowerCase()
      : '';
    return {
      name,
      path: absolutePath.length > 0 ? absolutePath : this.joinPath(parentPath, name),
      isFile,
      fileType,
      lastModified: modifiedTime > 0 ? modifiedTime : this.parseDate(modified),
      fileUrl,
      version
    };
  }

  private parseDate(value: string): number {
    if (value.length === 0) {
      return 0;
    }
    const parsed = Date.parse(value);
    return Number.isNaN(parsed) ? 0 : parsed;
  }

  private normalizePath(path: string): string {
    const value = path.trim();
    if (value.length === 0) {
      return '/';
    }
    const withHead = value.startsWith('/') ? value : `/${value}`;
    return withHead.length > 1 && withHead.endsWith('/') ? withHead.substring(0, withHead.length - 1) : withHead;
  }

  private normalizeLocalPath(path: string): string {
    const value = path.trim();
    if (value.length <= 1) {
      return value;
    }
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  private constrainLocalPath(path: string, rootPath: string): string {
    const safeRoot = this.normalizeLocalPath(rootPath);
    const safePath = this.normalizeLocalPath(path);
    if (safePath === safeRoot || safePath.startsWith(`${safeRoot}/`)) {
      return safePath;
    }
    return safeRoot;
  }

  private joinLocalPath(parentPath: string, name: string): string {
    const safeParent = this.normalizeLocalPath(parentPath);
    return safeParent.endsWith('/') ? `${safeParent}${name}` : `${safeParent}/${name}`;
  }

  private getOrigin(url: string): string {
    const trimmed = url.trim();
    if (trimmed.length === 0) {
      return '';
    }
    const protocolIndex = trimmed.indexOf('://');
    if (protocolIndex < 0) {
      return '';
    }
    const pathStart = trimmed.indexOf('/', protocolIndex + 3);
    const origin = pathStart < 0 ? trimmed : trimmed.substring(0, pathStart);
    return origin.endsWith('/') ? origin.substring(0, origin.length - 1) : origin;
  }

  private alistHeaders(origin: string): HttpHeaders {
    return {
      'Origin': origin,
      'Referer': origin,
      'Accept': 'application/json, text/plain, */*'
    };
  }

  private webDavHeaders(config: WebDavDriveConfig): HttpHeaders {
    const headers: HttpHeaders = {
      'Depth': '1',
      'Content-Type': 'application/xml; charset=utf-8'
    };
    const authorization = this.basicAuthorization(config.username, config.password);
    if (authorization.length > 0) {
      headers['Authorization'] = authorization;
    }
    return headers;
  }

  private webDavPropfindBody(): string {
    return '<?xml version="1.0" encoding="utf-8"?><propfind xmlns="DAV:"><prop><displayname/><resourcetype/><getlastmodified/></prop></propfind>';
  }

  private parseWebDavResponse(response: string, targetPath: string, requestUrl: string): DriveFileItem[] {
    const result: DriveFileItem[] = [];
    const blocks = response.match(/<(?:[A-Za-z0-9_]+:)?response[\s\S]*?<\/(?:[A-Za-z0-9_]+:)?response>/g) || [];
    for (const block of blocks) {
      const href = this.xmlText(block, 'href');
      if (href.length === 0) {
        continue;
      }
      const decodedHref = this.decodeXml(this.safeDecodeURIComponent(href));
      const name = this.webDavName(decodedHref, this.xmlText(block, 'displayname'));
      const isDirectory = /<(?:[A-Za-z0-9_]+:)?collection\s*\/?>/.test(block);
      if (this.isWebDavSelf(decodedHref, targetPath, requestUrl, isDirectory) || name.length === 0) {
        continue;
      }
      const modified = this.xmlText(block, 'getlastmodified');
      result.push(this.toDriveFile(name, targetPath, !isDirectory, modified, '', 0));
    }
    return result;
  }

  private xmlText(block: string, tag: string): string {
    const pattern = new RegExp(`<(?:[A-Za-z0-9_]+:)?${tag}[^>]*>([\\s\\S]*?)<\\/(?:[A-Za-z0-9_]+:)?${tag}>`, 'i');
    const match = block.match(pattern);
    return match === null ? '' : this.decodeXml(match[1].trim());
  }

  private decodeXml(value: string): string {
    return value
      .replace(/&amp;/g, '&')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&quot;/g, '"')
      .replace(/&apos;/g, "'");
  }

  private safeDecodeURIComponent(value: string): string {
    try {
      return decodeURIComponent(value);
    } catch (_error) {
      return value;
    }
  }

  private webDavName(href: string, displayName: string): string {
    if (displayName.length > 0) {
      return displayName;
    }
    const path = this.extractUrlPath(href);
    const trimmed = path.endsWith('/') ? path.substring(0, path.length - 1) : path;
    const index = trimmed.lastIndexOf('/');
    return index < 0 ? trimmed : trimmed.substring(index + 1);
  }

  private isWebDavSelf(href: string, targetPath: string, requestUrl: string, isDirectory: boolean): boolean {
    if (!isDirectory) {
      return false;
    }
    const cleanHref = this.normalizePath(this.extractUrlPath(href));
    const cleanRequest = this.normalizePath(this.extractUrlPath(requestUrl));
    const cleanTarget = this.normalizePath(targetPath);
    return cleanHref === cleanRequest || cleanHref === cleanTarget || cleanHref.endsWith(cleanTarget);
  }

  private extractUrlPath(value: string): string {
    const protocolIndex = value.indexOf('://');
    const rawPath = protocolIndex >= 0
      ? this.pathFromAbsoluteUrl(value, protocolIndex)
      : value;
    const queryIndex = rawPath.indexOf('?');
    const withoutQuery = queryIndex >= 0 ? rawPath.substring(0, queryIndex) : rawPath;
    const hashIndex = withoutQuery.indexOf('#');
    return hashIndex >= 0 ? withoutQuery.substring(0, hashIndex) : withoutQuery;
  }

  private pathFromAbsoluteUrl(value: string, protocolIndex: number): string {
    const pathStart = value.indexOf('/', protocolIndex + 3);
    return pathStart < 0 ? '/' : value.substring(pathStart);
  }

  private joinWebDavUrl(baseUrl: string, path: string): string {
    const base = baseUrl.trim();
    const safeBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    const safePath = this.normalizePath(path);
    return encodeURI(`${safeBase}${safePath === '/' ? '/' : safePath}`);
  }

  private basicAuthorization(username: string, password: string): string {
    if (username.length === 0 && password.length === 0) {
      return '';
    }
    const encoder = new util.TextEncoder();
    const bytes = encoder.encodeInto(`${username}:${password}`);
    const helper = new util.Base64Helper();
    return `Basic ${helper.encodeToStringSync(bytes)}`;
  }
}

export const driveService = new DriveService();
