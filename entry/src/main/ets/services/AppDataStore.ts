import fs from '@ohos.file.fs';
import { AppLaunchItem } from '../models/TvBoxModels';
import { settingsStore } from './SettingsStore';

export class AppDataStore {
  private readonly storeFile: string = 'appLaunchItems.json';

  private filePath(): string {
    const filesDir = settingsStore.getFilesDir();
    return filesDir ? `${filesDir}/${this.storeFile}` : '';
  }

  private readItems(): AppLaunchItem[] {
    const path = this.filePath();
    if (!path) {
      return [];
    }
    try {
      const parsed: unknown = JSON.parse(fs.readTextSync(path));
      if (!Array.isArray(parsed)) {
        return [];
      }
      const result: AppLaunchItem[] = [];
      for (const item of parsed) {
        const row = item as Record<string, unknown>;
        const id = this.toNumber(row['id']);
        const updateTime = this.toNumber(row['updateTime']);
        const bundleName = this.toText(row['bundleName']);
        if (id <= 0 || bundleName.length === 0) {
          continue;
        }
        result.push({
          id,
          name: this.toText(row['name']) || bundleName,
          bundleName,
          abilityName: this.toText(row['abilityName']),
          moduleName: this.toText(row['moduleName']),
          iconText: this.toText(row['iconText']) || this.initialText(bundleName),
          systemApp: row['systemApp'] === true,
          userAdded: row['userAdded'] !== false,
          updateTime: updateTime > 0 ? updateTime : id
        });
      }
      return this.sortItems(result);
    } catch (_error) {
      return [];
    }
  }

  private writeItems(data: AppLaunchItem[]): void {
    const path = this.filePath();
    if (!path) {
      return;
    }
    try {
      const file = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      try {
        fs.writeSync(file.fd, JSON.stringify(this.sortItems(data)));
      } finally {
        fs.closeSync(file);
      }
    } catch (_error) {
    }
  }

  private toText(value: unknown): string {
    if (value === undefined || value === null) {
      return '';
    }
    return String(value).trim();
  }

  private toNumber(value: unknown): number {
    if (typeof value === 'number') {
      return Number.isFinite(value) ? Math.trunc(value) : 0;
    }
    if (typeof value === 'string') {
      const parsed = Number(value);
      return Number.isFinite(parsed) ? Math.trunc(parsed) : 0;
    }
    return 0;
  }

  private initialText(value: string): string {
    const text = value.trim();
    return text.length > 0 ? text.substring(0, 1).toUpperCase() : 'A';
  }

  private sortItems(data: AppLaunchItem[]): AppLaunchItem[] {
    return [...data].sort((left: AppLaunchItem, right: AppLaunchItem) => {
      return left.name.localeCompare(right.name);
    });
  }

  getAll(): AppLaunchItem[] {
    return this.readItems();
  }

  save(item: AppLaunchItem): AppLaunchItem {
    const items = this.readItems();
    const existingIndex = items.findIndex((row: AppLaunchItem) => row.id === item.id);
    const duplicateIndex = items.findIndex((row: AppLaunchItem) => {
      return row.bundleName === item.bundleName && row.abilityName === item.abilityName && row.id !== item.id;
    });
    const duplicateId = duplicateIndex >= 0 ? items[duplicateIndex].id : 0;
    const nextId = duplicateId > 0 ? duplicateId : (item.id > 0 ? item.id : Date.now());
    const next: AppLaunchItem = {
      id: nextId,
      name: item.name.trim() || item.bundleName,
      bundleName: item.bundleName.trim(),
      abilityName: item.abilityName.trim(),
      moduleName: item.moduleName.trim(),
      iconText: item.iconText.trim() || this.initialText(item.name || item.bundleName),
      systemApp: item.systemApp,
      userAdded: item.userAdded,
      updateTime: Date.now()
    };
    if (duplicateIndex >= 0) {
      items[duplicateIndex] = next;
      this.writeItems(items.filter((row: AppLaunchItem) => row.id !== item.id || row.id === next.id));
      return next;
    }
    if (existingIndex >= 0) {
      items[existingIndex] = next;
      this.writeItems(items);
      return next;
    }
    this.writeItems([...items, next]);
    return next;
  }

  delete(id: number): void {
    const items = this.readItems();
    this.writeItems(items.filter((item: AppLaunchItem) => item.id !== id));
  }

  clear(): void {
    this.writeItems([]);
  }
}

export const appDataStore = new AppDataStore();
