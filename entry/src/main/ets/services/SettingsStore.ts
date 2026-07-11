import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { AndroidCompatibleDefaults } from '../constants/AppDefaults';

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
}

export const settingsStore = new SettingsStore();
