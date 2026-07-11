import fs from '@ohos.file.fs';
import { StorageDrive } from '../models/TvBoxModels';
import { settingsStore } from './SettingsStore';

export class DriveDataStore {
  private readonly storeFile: string = 'storageDrive.json';

  private filePath(): string {
    const filesDir = settingsStore.getFilesDir();
    return filesDir ? `${filesDir}/${this.storeFile}` : '';
  }

  private readDrives(): StorageDrive[] {
    const path = this.filePath();
    if (!path) {
      return [];
    }
    try {
      const parsed: unknown = JSON.parse(fs.readTextSync(path));
      if (!Array.isArray(parsed)) {
        return [];
      }
      const result: StorageDrive[] = [];
      for (const item of parsed) {
        const row = item as Record<string, unknown>;
        const idValue = row['id'];
        const nameValue = row['name'];
        const typeValue = row['type'];
        const configValue = row['configJson'];
        const id = typeof idValue === 'number' ? idValue : Number(idValue);
        const type = typeof typeValue === 'number' ? typeValue : Number(typeValue);
        if (Number.isFinite(id) && Number.isFinite(type) && nameValue !== undefined) {
          result.push({
            id: Math.trunc(id),
            name: String(nameValue),
            type: Math.trunc(type),
            configJson: configValue === undefined ? '' : String(configValue)
          });
        }
      }
      return result;
    } catch (_error) {
      return [];
    }
  }

  private writeDrives(data: StorageDrive[]): void {
    const path = this.filePath();
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
    }
  }

  getAll(): StorageDrive[] {
    return this.readDrives();
  }

  save(drive: StorageDrive): StorageDrive {
    const drives = this.readDrives();
    const existingIndex = drives.findIndex((item: StorageDrive) => item.id === drive.id);
    if (existingIndex >= 0) {
      drives[existingIndex] = drive;
      this.writeDrives(drives);
      return drive;
    }
    const nextId = drives.reduce((max: number, item: StorageDrive) => Math.max(max, item.id), 0) + 1;
    const next: StorageDrive = {
      id: nextId,
      name: drive.name,
      type: drive.type,
      configJson: drive.configJson
    };
    this.writeDrives([...drives, next]);
    return next;
  }

  delete(id: number): void {
    const drives = this.readDrives();
    this.writeDrives(drives.filter((item: StorageDrive) => item.id !== id));
  }
}

export const driveDataStore = new DriveDataStore();
