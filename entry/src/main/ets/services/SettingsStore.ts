import preferences from '@ohos.data.preferences';
import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { AndroidCompatibleDefaults } from '../constants/AppDefaults';
import { HawkConfig } from '../constants/HawkConfig';

interface BackupBundle {
  version: number;
  timestamp: number;
  settings: Record<string, preferences.ValueType>;
  vodRecord: string;
  vodCollect: string;
  searchHistory: string;
}

export class SettingsStore {
  private static readonly storeName: string = 'tvbox_hawk_compatible_settings';
  private pref?: preferences.Preferences;
  private context?: common.Context;

  async init(context: common.Context): Promise<void> {
    this.context = context;
    if (this.pref) {
      return;
    }
    this.pref = await preferences.getPreferences(context, SettingsStore.storeName);
    await this.ensureDefaults();
  }

  async ensureDefaults(): Promise<void> {
    if (!this.pref) {
      return;
    }
    for (const item of AndroidCompatibleDefaults) {
      if (!(await this.pref.has(item.key))) {
        await this.pref.put(item.key, item.value);
      }
    }
    await this.pref.flush();
  }

  async get<T>(key: string, fallback: T): Promise<T> {
    if (!this.pref) {
      return fallback;
    }
    return await this.pref.get(key, fallback as preferences.ValueType) as T;
  }

  getSync<T>(key: string, fallback: T): T {
    if (!this.pref) {
      return fallback;
    }
    return this.pref.getSync(key, fallback as preferences.ValueType) as T;
  }

  isReady(): boolean {
    return this.pref !== undefined;
  }

  async put(key: string, value: preferences.ValueType): Promise<void> {
    if (!this.pref) {
      return;
    }
    await this.pref.put(key, value);
    await this.pref.flush();
  }

  getFilesDir(): string {
    return this.context?.filesDir || '';
  }

  async clearAll(): Promise<void> {
    if (!this.pref) {
      return;
    }
    await this.pref.clear();
    await this.pref.flush();
    await this.ensureDefaults();
  }

  private backupDir(): string {
    const base = this.getFilesDir();
    return base ? `${base}/backup` : '';
  }

  async createBackup(): Promise<string> {
    const dir = this.backupDir();
    if (!dir || !this.pref) {
      return '';
    }
    try {
      fs.mkdirSync(dir);
    } catch (_error) {
      // Directory may already exist.
    }
    const settings: Record<string, preferences.ValueType> = {};
    const allKeys = await this.pref.getAll() as Record<string, preferences.ValueType>;
    const keys = Object.keys(allKeys);
    for (const key of keys) {
      settings[key] = allKeys[key];
    }
    const bundle: BackupBundle = {
      version: 1,
      timestamp: Date.now(),
      settings,
      vodRecord: this.readRawFile('vodRecord.json'),
      vodCollect: this.readRawFile('vodCollect.json'),
      searchHistory: this.readRawFile('searchHistory.json')
    };
    const fileName = `backup_${bundle.timestamp}.json`;
    const filePath = `${dir}/${fileName}`;
    try {
      const file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      try {
        fs.writeSync(file.fd, JSON.stringify(bundle));
      } finally {
        fs.closeSync(file);
      }
    } catch (_error) {
      return '';
    }
    return fileName;
  }

  async restoreBackup(fileName: string): Promise<boolean> {
    const dir = this.backupDir();
    if (!dir || !this.pref) {
      return false;
    }
    const filePath = `${dir}/${fileName}`;
    let content: string;
    try {
      content = fs.readTextSync(filePath);
    } catch (_error) {
      return false;
    }
    let bundle: BackupBundle;
    try {
      bundle = JSON.parse(content) as BackupBundle;
    } catch (_error) {
      return false;
    }
    if (!bundle.settings) {
      return false;
    }
    await this.pref.clear();
    const keys = Object.keys(bundle.settings);
    for (const key of keys) {
      await this.pref.put(key, bundle.settings[key]);
    }
    await this.pref.flush();
    if (bundle.vodRecord) {
      this.writeRawFile('vodRecord.json', bundle.vodRecord);
    }
    if (bundle.vodCollect) {
      this.writeRawFile('vodCollect.json', bundle.vodCollect);
    }
    if (bundle.searchHistory) {
      this.writeRawFile('searchHistory.json', bundle.searchHistory);
    }
    return true;
  }

  listBackups(): string[] {
    const dir = this.backupDir();
    if (!dir) {
      return [];
    }
    let entries: string[] = [];
    try {
      entries = fs.listFileSync(dir);
    } catch (_error) {
      return [];
    }
    return entries
      .filter((name: string) => name.startsWith('backup_') && name.endsWith('.json'))
      .sort((a: string, b: string) => b.localeCompare(a));
  }

  deleteBackup(fileName: string): void {
    const dir = this.backupDir();
    if (!dir) {
      return;
    }
    try {
      fs.unlinkSync(`${dir}/${fileName}`);
    } catch (_error) {
    }
  }

  private readRawFile(name: string): string {
    const path = this.filePath(name);
    if (!path) {
      return '';
    }
    try {
      return fs.readTextSync(path);
    } catch (_error) {
      return '';
    }
  }

  private writeRawFile(name: string, content: string): void {
    const path = this.filePath(name);
    if (!path) {
      return;
    }
    try {
      const file = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      try {
        fs.writeSync(file.fd, content);
      } finally {
        fs.closeSync(file);
      }
    } catch (_error) {
    }
  }

  private filePath(name: string): string {
    const filesDir = this.getFilesDir();
    return filesDir ? `${filesDir}/${name}` : '';
  }
}

export const settingsStore = new SettingsStore();
