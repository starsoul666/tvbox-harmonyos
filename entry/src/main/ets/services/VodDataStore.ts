import fs from '@ohos.file.fs';
import { VodCollect, VodInfo } from '../models/TvBoxModels';
import { settingsStore } from './SettingsStore';

interface StoredVodRecord {
  vodId: string;
  sourceKey: string;
  updateTime: number;
  dataJson: string;
}

export interface SearchHistoryItem {
  id: number;
  searchKeyWords: string;
}

function now(): number {
  return Date.now();
}

function recordKey(sourceKey: string, vodId: string): string {
  return `${sourceKey}::${vodId}`;
}

export class VodDataStore {
  private filePath(name: string): string {
    const filesDir = settingsStore.getFilesDir();
    return filesDir ? `${filesDir}/${name}` : '';
  }

  private readArray<T>(name: string): T[] {
    const path = this.filePath(name);
    if (!path) {
      return [];
    }
    try {
      const parsed: unknown = JSON.parse(fs.readTextSync(path));
      return Array.isArray(parsed) ? parsed as T[] : [];
    } catch (_error) {
      return [];
    }
  }

  private writeArray<T>(name: string, data: T[]): void {
    const path = this.filePath(name);
    if (!path) {
      return;
    }
    try {
      const file = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      try {
        fs.writeSync(file.fd, JSON.stringify(data));
      } finally {
        fs.closeSync(file);
      }
    } catch (_error) {
      // Persistence failures should not block playback/search UI flow.
    }
  }

  insertVodRecord(sourceKey: string, vodInfo: VodInfo): void {
    const records = this.readArray<StoredVodRecord>('vodRecord.json');
    const key = recordKey(sourceKey, vodInfo.id);
    const compactInfo: Record<string, unknown> = JSON.parse(JSON.stringify(vodInfo)) as Record<string, unknown>;
    const currentFlag = vodInfo.playFlag || '';
    if (currentFlag.length > 0 && vodInfo.seriesMap[currentFlag] !== undefined) {
      compactInfo['seriesFlags'] = [{ name: currentFlag }];
      compactInfo['seriesMap'] = { [currentFlag]: vodInfo.seriesMap[currentFlag] };
    } else {
      delete compactInfo['seriesFlags'];
      delete compactInfo['seriesMap'];
    }
    const nextRecord: StoredVodRecord = {
      vodId: vodInfo.id,
      sourceKey,
      updateTime: now(),
      dataJson: JSON.stringify(compactInfo)
    };
    const next = records.filter((item: StoredVodRecord) => recordKey(item.sourceKey, item.vodId) !== key);
    next.unshift(nextRecord);
    this.writeArray('vodRecord.json', next);
  }

  getVodInfo(sourceKey: string, vodId: string): VodInfo | undefined {
    const records = this.readArray<StoredVodRecord>('vodRecord.json');
    const found = records.find((item: StoredVodRecord) => item.sourceKey === sourceKey && item.vodId === vodId);
    if (!found || !found.dataJson) {
      return undefined;
    }
    try {
      const info = JSON.parse(found.dataJson) as VodInfo;
      this.ensureVodDefaults(info);
      return info.name ? info : undefined;
    } catch (_error) {
      return undefined;
    }
  }

  getAllVodRecord(limit: number = 50): VodInfo[] {
    const records = this.readArray<StoredVodRecord>('vodRecord.json')
      .sort((left: StoredVodRecord, right: StoredVodRecord) => right.updateTime - left.updateTime)
      .slice(0, limit);
    const result: VodInfo[] = [];
    for (const record of records) {
      try {
        const info = JSON.parse(record.dataJson) as VodInfo;
        if (info.name) {
          this.ensureVodDefaults(info);
          info.sourceKey = record.sourceKey;
          result.push(info);
        }
      } catch (_error) {
      }
    }
    return result;
  }

  private ensureVodDefaults(info: VodInfo): void {
    if (info.seriesFlags === undefined) {
      info.seriesFlags = [];
    }
    if (info.seriesMap === undefined) {
      info.seriesMap = {};
    }
  }

  deleteVodRecord(sourceKey: string, vodId: string): void {
    const records = this.readArray<StoredVodRecord>('vodRecord.json');
    this.writeArray('vodRecord.json', records.filter((item: StoredVodRecord) => {
      return !(item.sourceKey === sourceKey && item.vodId === vodId);
    }));
  }

  deleteVodRecordAll(): void {
    this.writeArray<StoredVodRecord>('vodRecord.json', []);
  }

  insertVodCollect(sourceKey: string, vodInfo: VodInfo): void {
    const collects = this.readArray<VodCollect>('vodCollect.json');
    const exists = collects.some((item: VodCollect) => item.sourceKey === sourceKey && item.vodId === vodInfo.id);
    if (exists) {
      return;
    }
    const next: VodCollect = {
      id: recordKey(sourceKey, vodInfo.id),
      vodId: vodInfo.id,
      sourceKey,
      vodName: vodInfo.name,
      vodPic: vodInfo.pic,
      updateTime: now()
    };
    this.writeArray('vodCollect.json', [next, ...collects]);
  }

  isVodCollect(sourceKey: string, vodId: string): boolean {
    return this.readArray<VodCollect>('vodCollect.json')
      .some((item: VodCollect) => item.sourceKey === sourceKey && item.vodId === vodId);
  }

  getAllVodCollect(): VodCollect[] {
    return this.readArray<VodCollect>('vodCollect.json')
      .sort((left: VodCollect, right: VodCollect) => right.updateTime - left.updateTime);
  }

  deleteVodCollect(id: string): void {
    const collects = this.readArray<VodCollect>('vodCollect.json');
    this.writeArray('vodCollect.json', collects.filter((item: VodCollect) => item.id !== id));
  }

  deleteVodCollectByVod(sourceKey: string, vodId: string): void {
    const collects = this.readArray<VodCollect>('vodCollect.json');
    this.writeArray('vodCollect.json', collects.filter((item: VodCollect) => {
      return !(item.sourceKey === sourceKey && item.vodId === vodId);
    }));
  }

  deleteVodCollectAll(): void {
    this.writeArray<VodCollect>('vodCollect.json', []);
  }

  getSearchHistory(): SearchHistoryItem[] {
    return this.readArray<SearchHistoryItem>('searchHistory.json');
  }

  keywordsExist(keyword: string): boolean {
    return this.getSearchHistory().some((item: SearchHistoryItem) => item.searchKeyWords === keyword);
  }

  addSearchKeyword(keyword: string): void {
    const value = keyword.trim();
    if (!value || this.keywordsExist(value)) {
      return;
    }
    const history = this.getSearchHistory();
    if (history.length > 29) {
      history.shift();
    }
    history.push({ id: now(), searchKeyWords: value });
    this.writeArray('searchHistory.json', history);
  }

  clearSearchKeywords(): void {
    this.writeArray<SearchHistoryItem>('searchHistory.json', []);
  }
}

export const vodDataStore = new VodDataStore();
